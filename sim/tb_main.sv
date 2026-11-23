// 模块 tb_main 验证按键消抖, 灯色循环及两组数码管的扫描.
// 参数: 无.
// 端口: 无.
// 时钟与复位: 以 EGO1 频率运行, 从外部异步拉低复位.
`timescale 1ns/1ps
module tb_main;
    // 将扫描和消抖周期缩短到少量时钟, 保留对取整的验证.
    localparam int NS_PER_SECOND = 1_000_000_000;
    localparam int CLK_PERIOD_NS = NS_PER_SECOND / board::CLK_FREQ;
    localparam int HALF_PERIOD_NS = CLK_PERIOD_NS / 2;
    localparam int SCAN_CYCLES = 2;
    localparam int SCAN_FREQ_HZ = board::CLK_FREQ / SCAN_CYCLES;
    localparam int DEBOUNCE_NS = 2 * CLK_PERIOD_NS + 1;
    localparam int OBSERVATION_CYCLES = 2 * board::SEG7_DIGIT_COUNT;
    localparam [7:0] RED_PATTERN = 8'h31;
    localparam [7:0] GREEN_PATTERN = 8'h3d;
    localparam [7:0] YELLOW_PATTERN = 8'h6e;
    localparam [7:0] BLANK_PATTERN = 8'h00;
    localparam [7:0] PAIR_0 = 8'h11;
    localparam [7:0] PAIR_1 = 8'h22;
    localparam [7:0] PAIR_2 = 8'h44;
    localparam [7:0] PAIR_3 = 8'h88;
    localparam [63:0] DRIVER_PATTERNS = 64'h87_86_85_84_13_12_11_10;

    logic clk;
    logic rst_n;
    logic [4:0] btn;
    wire [7:0] seg7_ss0;
    wire [7:0] seg7_ss1;
    wire [7:0] seg7_cs;
    wire [7:0] driver_ss0;
    wire [7:0] driver_ss1;
    wire [7:0] driver_cs;

    main #(
        .DEBOUNCE_TIME(DEBOUNCE_NS),
        .SEG7_SCAN_FREQ(SCAN_FREQ_HZ)
    ) u_main_0 (
        .clk(clk),
        .rst_n(rst_n),
        .sw(8'b0),
        .btn(btn),
        .seg7_ss0(seg7_ss0),
        .seg7_ss1(seg7_ss1),
        .seg7_cs(seg7_cs)
    );

    drv_seg7 #(
        .SEG7_SCAN_FREQ(SCAN_FREQ_HZ)
    ) u_drv_seg7_0 (
        .clk(clk),
        .rst_n(rst_n),
        .seg7_patterns(DRIVER_PATTERNS),
        .seg7_ss0(driver_ss0),
        .seg7_ss1(driver_ss1),
        .seg7_cs(driver_cs)
    );

    always #(HALF_PERIOD_NS) clk = ~clk;

    task expect_driver;
        input [7:0] expected_pair;
        reg [7:0] expected_ss0;
        reg [7:0] expected_ss1;
        begin
            case (expected_pair)
                PAIR_0: begin expected_ss0 = 8'h84; expected_ss1 = 8'h10; end
                PAIR_1: begin expected_ss0 = 8'h85; expected_ss1 = 8'h11; end
                PAIR_2: begin expected_ss0 = 8'h86; expected_ss1 = 8'h12; end
                PAIR_3: begin expected_ss0 = 8'h87; expected_ss1 = 8'h13; end
                default: begin expected_ss0 = BLANK_PATTERN; expected_ss1 = BLANK_PATTERN; end
            endcase
            if ({driver_cs, driver_ss0, driver_ss1} !==
                {expected_pair, expected_ss0, expected_ss1}) begin
                $display("ERROR: tb_main driver pair %h expected %h, banks %h %h at %0t",
                    driver_cs, expected_pair, driver_ss0, driver_ss1, $time);
                $finish;
            end
        end
    endtask

    task expect_display;
        input [7:0] color;
        reg [7:0] expected_ss1;
        begin
            expected_ss1 = (seg7_cs == PAIR_0) ? color : BLANK_PATTERN;
            case (seg7_cs)
                PAIR_0, PAIR_1, PAIR_2, PAIR_3: begin
                    if ({seg7_ss0, seg7_ss1} !== {BLANK_PATTERN, expected_ss1}) begin
                        $display("ERROR: tb_main unexpected segments %h %h for pair %h at %0t",
                            seg7_ss0, seg7_ss1, seg7_cs, $time);
                        $finish;
                    end
                end
                default: begin
                    $display("ERROR: tb_main invalid scan pair %h at %0t", seg7_cs, $time);
                    $finish;
                end
            endcase
        end
    endtask

    task expect_scan_cycle;
        input [7:0] main_pair;
        input [7:0] driver_pair;
        begin
            @(posedge clk);
            #1;
            if (seg7_cs !== main_pair) begin
                $display("ERROR: tb_main scan pair %h expected %h at %0t", seg7_cs, main_pair, $time);
                $finish;
            end
            expect_display(RED_PATTERN);
            expect_driver(driver_pair);
        end
    endtask

    task drive_button;
        input level;
        begin
            @(negedge clk);
            btn[0] = level;
        end
    endtask

    task observe_color;
        input [7:0] color;
        reg color_seen;
        integer cycle;
        begin
            color_seen = 1'b0;
            for (cycle = 0; cycle < OBSERVATION_CYCLES; cycle = cycle + 1) begin
                @(posedge clk);
                #1;
                expect_display(color);
                if (seg7_cs == PAIR_0) begin
                    color_seen = 1'b1;
                end
            end
            if (!color_seen) begin
                $display("ERROR: tb_main scan did not return to digit 0");
                $finish;
            end
        end
    endtask

    task press_and_release;
        input [7:0] next_color;
        begin
            drive_button(1'b1);
            // 两级输入同步, 三次稳定采样, 最后由状态机接收边沿.
            repeat (6) @(posedge clk);
            observe_color(next_color);
            drive_button(1'b0);
            observe_color(next_color);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b1;
        btn = 5'b0;
        #1 rst_n = 1'b0;
        @(negedge clk);
        expect_display(RED_PATTERN);
        expect_driver(PAIR_0);
        rst_n = 1'b1;

        // 对照独立驱动的时序, 顶层扫描在复位释放后晚两拍.
        expect_scan_cycle(PAIR_0, PAIR_0);
        expect_scan_cycle(PAIR_0, PAIR_0);
        expect_scan_cycle(PAIR_0, PAIR_1);
        expect_scan_cycle(PAIR_0, PAIR_1);
        expect_scan_cycle(PAIR_1, PAIR_2);
        expect_scan_cycle(PAIR_1, PAIR_2);
        expect_scan_cycle(PAIR_2, PAIR_3);
        expect_scan_cycle(PAIR_2, PAIR_3);
        expect_scan_cycle(PAIR_3, PAIR_0);
        expect_scan_cycle(PAIR_3, PAIR_0);
        expect_scan_cycle(PAIR_0, PAIR_1);

        drive_button(1'b1);
        repeat (2) @(posedge clk);
        drive_button(1'b0);
        observe_color(RED_PATTERN);

        press_and_release(GREEN_PATTERN);
        press_and_release(YELLOW_PATTERN);
        press_and_release(RED_PATTERN);
        press_and_release(GREEN_PATTERN);

        // 在两个采样边沿之间触发复位, 确认立即返回红灯和首对数位.
        rst_n = 1'b0;
        #1;
        expect_display(RED_PATTERN);
        if (seg7_cs !== PAIR_0) begin
            $display("ERROR: tb_main asynchronous reset did not select the initial digit pair");
            $finish;
        end

        $display("PASS: tb_main");
        $finish;
    end
endmodule
