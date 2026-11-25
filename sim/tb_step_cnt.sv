// 模块 tb_step_cnt 验证计数暂停, 回绕, 分频及消抖周期边界.
// 参数: 无.
// 端口: 无.
// 时钟与复位: 使用 EGO1 频率仿真, 在 clk 下降沿释放低有效复位.
`timescale 1ns/1ps
module tb_step_cnt;
    // 用板载时钟计算仿真节拍. 21 ns 向上取整为 3 个周期.
    localparam int NS_PER_SECOND = 1_000_000_000;
    localparam int CLK_PERIOD_NS = NS_PER_SECOND / board::CLK_FREQ;
    localparam int HALF_PERIOD_NS = CLK_PERIOD_NS / 2;
    localparam int PERIOD_CYCLES = 3;
    localparam int MIN_CYCLES = 1;
    localparam int SLOW_DEBOUNCE_NS = 2 * CLK_PERIOD_NS + 1;
    localparam int FAST_DEBOUNCE_NS = 1;
    localparam [2:0] LOW = 3'b000;
    localparam [2:0] HIGH = 3'b100;
    localparam [2:0] RISE = 3'b110;
    localparam [2:0] FALL = 3'b001;

    logic clk;
    logic rst_n;
    logic en;
    logic pulse;
    logic [1:0] step;
    logic step_one;
    logic div_en;
    logic div_one_en;
    logic [2:0] slow_output;
    logic [2:0] fast_output;

    step_cnt #(.CNT_STATES(PERIOD_CYCLES)) u_step_cnt_0 (
        .clk(clk), .rst_n(rst_n), .en(en), .step(step)
    );
    step_cnt #(.CNT_STATES(MIN_CYCLES)) u_step_cnt_1 (
        .clk(clk), .rst_n(rst_n), .en(en), .step(step_one)
    );
    clk_div #(.DIVISOR(PERIOD_CYCLES)) u_clk_div_0 (
        .clk(clk), .rst_n(rst_n), .en(div_en)
    );
    clk_div #(.DIVISOR(MIN_CYCLES)) u_clk_div_1 (
        .clk(clk), .rst_n(rst_n), .en(div_one_en)
    );
    pulse_debounce #(
        .CLK_FREQ(board::CLK_FREQ),
        .DEBOUNCE_TIME_NS(SLOW_DEBOUNCE_NS)
    ) u_pulse_debounce_0 (
        .clk(clk), .rst_n(rst_n), .pulse(pulse),
        .level(slow_output[2]), .rise(slow_output[1]), .fall(slow_output[0])
    );
    pulse_debounce #(
        .CLK_FREQ(board::CLK_FREQ),
        .DEBOUNCE_TIME_NS(FAST_DEBOUNCE_NS)
    ) u_pulse_debounce_1 (
        .clk(clk), .rst_n(rst_n), .pulse(pulse),
        .level(fast_output[2]), .rise(fast_output[1]), .fall(fast_output[0])
    );

    always #(HALF_PERIOD_NS) clk = ~clk;

    task expect_cycle;
        input [1:0] expected_step;
        input expected_div;
        input [2:0] expected_slow;
        input [2:0] expected_fast;
        begin
            @(posedge clk);
            #1;
            if ({step, step_one, div_en, div_one_en, slow_output, fast_output} !==
                {expected_step, 1'b0, expected_div, 1'b1, expected_slow, expected_fast}) begin
                $display("ERROR: tb_step_cnt step %h/%b div %b/%b debounce %b/%b at %0t",
                    step, step_one, div_en, div_one_en, slow_output, fast_output, $time);
                $finish;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b1;
        en = 1'b1;
        pulse = 1'b0;
        #1 rst_n = 1'b0;
        @(negedge clk);
        if ({step, step_one, div_en, div_one_en, slow_output, fast_output} !== 11'b0) begin
            $display("ERROR: tb_step_cnt outputs did not reset");
            $finish;
        end
        rst_n = 1'b1;

        expect_cycle(2'd1, 1'b0, LOW, LOW);
        expect_cycle(2'd2, 1'b0, LOW, LOW);
        @(negedge clk);
        en = 1'b0;
        pulse = 1'b1;
        expect_cycle(2'd2, 1'b1, LOW, RISE);
        expect_cycle(2'd2, 1'b0, LOW, HIGH);
        expect_cycle(2'd2, 1'b0, RISE, HIGH);
        @(negedge clk);
        en = 1'b1;
        pulse = 1'b0;
        expect_cycle(2'd0, 1'b1, HIGH, FALL);
        expect_cycle(2'd1, 1'b0, HIGH, LOW);
        expect_cycle(2'd2, 1'b0, FALL, LOW);
        expect_cycle(2'd0, 1'b1, LOW, LOW);

        $display("PASS: tb_step_cnt");
        $finish;
    end
endmodule
