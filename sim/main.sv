`timescale 1ns/1ps

`ifndef __VCD_FILE__
`define __VCD_FILE__ "main.vcd"
`endif

module tb_main;
    localparam int CLK_FREQ = board::CLK_FREQ;
    localparam realtime HALF_CLK_PERIOD = 1_000_000_000.0 / (2.0 * CLK_FREQ);
    localparam int DEBOUNCE_TIME = 1_000;
    localparam int DEBOUNCE_CYCLES = (DEBOUNCE_TIME / 1_000) * (CLK_FREQ / 1_000) / 1_000;
    localparam int SCAN_CYCLES = 10;

    logic clk = 1'b0;
    always #(HALF_CLK_PERIOD) clk = ~clk;

    logic rst_n;
    logic [4:0] btn;
    wire [7:0] seg7_ss0, seg7_ss1, seg7_cs;

    // 缩短消抖和扫描周期，硬件默认参数仍为 20 ms / 4 kHz。
    main #(
        .DEBOUNCE_TIME(DEBOUNCE_TIME),
        .SEG7_SCAN_FREQ(CLK_FREQ / SCAN_CYCLES)
    ) dut (
        .clk(clk), .rst_n(rst_n), .sw(8'b0), .btn(btn),
        .seg7_ss0(seg7_ss0), .seg7_ss1(seg7_ss1), .seg7_cs(seg7_cs)
    );

    function automatic logic [39:0] expected_bcd(input logic [31:0] value);
        logic [31:0] remaining;
        remaining = value;
        expected_bcd = '0;
        for (int digit = 0; digit < 10; digit++) begin
            expected_bcd[digit*4 +: 4] = 4'(remaining % 10);
            remaining = remaining / 10;
        end
    endfunction

    function automatic logic [7:0] expected_segment(input logic [3:0] digit);
        case (digit)
            4'd0: expected_segment = 8'h3f;
            4'd1: expected_segment = 8'h06;
            4'd2: expected_segment = 8'h5b;
            4'd3: expected_segment = 8'h4f;
            4'd4: expected_segment = 8'h66;
            4'd5: expected_segment = 8'h6d;
            4'd6: expected_segment = 8'h7d;
            4'd7: expected_segment = 8'h07;
            4'd8: expected_segment = 8'h7f;
            4'd9: expected_segment = 8'h6f;
            default: expected_segment = 8'h00;
        endcase
    endfunction

    task automatic wait_cycles(input int cycles);
        repeat (cycles) @(negedge clk);
    endtask

    task automatic check_display(input logic [31:0] expected_count);
        logic [39:0] digits;
        logic [3:0] scanned;
        int scan_digit;
        digits = expected_bcd(expected_count);
        scanned = '0;

        // 连续检查一个完整扫描周期，验证两组段选与各位片选的对应关系。
        repeat (4 * SCAN_CYCLES) begin
            @(negedge clk);
            if (dut.__cnt !== expected_count)
                $fatal(1, "main count: got=%0d expected=%0d", dut.__cnt, expected_count);
            if (dut.__bcd_code !== digits)
                $fatal(1, "main BCD: count=%0d got=%h expected=%h",
                       expected_count, dut.__bcd_code, digits);
            for (int bank = 0; bank < 2; bank++) begin
                for (int digit = 0; digit < 4; digit++) begin
                    if (dut.__seg_sels[bank][digit] !==
                        expected_segment(digits[(bank*4+digit)*4 +: 4]))
                        $fatal(1, "main segments: count=%0d bank=%0d digit=%0d got=%h",
                               expected_count, bank, digit, dut.__seg_sels[bank][digit]);
                end
            end

            case (seg7_cs)
                8'h11: scan_digit = 0;
                8'h22: scan_digit = 1;
                8'h44: scan_digit = 2;
                8'h88: scan_digit = 3;
                default: $fatal(1, "main scan: invalid chip select=%h", seg7_cs);
            endcase
            scanned[scan_digit] = 1'b1;
            if (seg7_ss1 !== expected_segment(digits[scan_digit*4 +: 4]) ||
                seg7_ss0 !== expected_segment(digits[(scan_digit+4)*4 +: 4]))
                $fatal(1, "main scan: count=%0d select=%h ss0=%h ss1=%h",
                       expected_count, seg7_cs, seg7_ss0, seg7_ss1);
        end
        if (scanned !== 4'b1111)
            $fatal(1, "main scan: incomplete scan=%b", scanned);
    endtask

    task automatic press_button(input logic [31:0] expected_count);
        btn[2] = 1'b1;
        wait_cycles(DEBOUNCE_CYCLES + 4);
        check_display(expected_count);
        btn[2] = 1'b0;
        wait_cycles(DEBOUNCE_CYCLES + 4);
        check_display(expected_count);
    endtask

    initial begin
        rst_n = 1'b0;
        btn = '0;
        $dumpfile(`__VCD_FILE__);
        $dumpvars(0, tb_main);

        wait_cycles(2);
        #1;
        if (dut.__cnt !== 32'd0 || seg7_cs !== 8'h11 ||
            seg7_ss0 !== 8'h3f || seg7_ss1 !== 8'h3f)
            $fatal(1, "main reset: count=%0d cs=%h ss0=%h ss1=%h",
                   dut.__cnt, seg7_cs, seg7_ss0, seg7_ss1);
        @(negedge clk);
        rst_n = 1'b1;
        check_display(32'd0);

        // 短促抖动不计数。
        repeat (3) begin
            btn[2] = 1'b1;
            wait_cycles(DEBOUNCE_CYCLES / 4);
            btn[2] = 1'b0;
            wait_cycles(DEBOUNCE_CYCLES / 4);
        end
        check_display(32'd0);

        // 长按只计一次，松开不计数。
        btn[2] = 1'b1;
        wait_cycles(DEBOUNCE_CYCLES + 4);
        check_display(32'd1);
        wait_cycles(2 * DEBOUNCE_CYCLES);
        check_display(32'd1);
        btn[2] = 1'b0;
        wait_cycles(DEBOUNCE_CYCLES + 4);
        check_display(32'd1);

        for (int count = 2; count <= 10; count++)
            press_button(32'(count));

        // 注入计数边界，避免仿真数亿次按键；仍经过真实转换与扫描链路。
        force dut.__cnt = 32'd99_999_999;
        #1;
        release dut.__cnt;
        check_display(32'd99_999_999);
        press_button(32'd100_000_000);

        force dut.__cnt = 32'hffff_ffff;
        #1;
        release dut.__cnt;
        check_display(32'hffff_ffff);
        press_button(32'd0);
        press_button(32'd1);

        // 运行中异步复位计数器和扫描器。
        rst_n = 1'b0;
        #1;
        if (dut.__cnt !== 32'd0 || seg7_cs !== 8'h11 ||
            seg7_ss0 !== 8'h3f || seg7_ss1 !== 8'h3f)
            $fatal(1, "main runtime reset failed");
        wait_cycles(2);
        rst_n = 1'b1;
        check_display(32'd0);
        press_button(32'd1);

        $display("PASS: main reset, debounce, counting, BCD, 8-digit scan and overflow");
        $finish;
    end

    initial begin
        #1_000_000;
        $fatal(1, "main simulation timeout");
    end
endmodule
