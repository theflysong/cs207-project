`timescale 1ns/1ps

`ifndef __VCD_FILE__
`define __VCD_FILE__ "drv_seg7.vcd"
`endif

// 各扫描频率独立检查结构体接口和扫描时序。
module tb_drv_seg7_case #(
    parameter int unsigned SEG7_SCAN_FREQ = 4_000,
    parameter int EXPECTED_CYCLES = board::CLK_FREQ / 4_000,
    parameter bit USE_DEFAULT = 1'b0
) (
    input  logic clk,
    output logic done
);
    logic rst_n;
    wire baselib::clk_rst_t clk_rst;
    driver::seg7_input_t seg_in;
    wire driver::seg7_output_t seg_out;
    logic [7:0] pattern [0:1][0:3];
    int model_cycles;

    assign clk_rst = '{clk: clk, rst_n: rst_n};

    if (USE_DEFAULT) begin : gen_default
        drv_seg7 dut (
            .clk_rst(clk_rst), .seg_in(seg_in), .seg_out(seg_out)
        );
    end else begin : gen_custom
        drv_seg7 #(.SEG7_SCAN_FREQ(SEG7_SCAN_FREQ)) dut (
            .clk_rst(clk_rst), .seg_in(seg_in), .seg_out(seg_out)
        );
    end

    task automatic apply_pattern;
        for (int bank = 0; bank < 2; bank++)
            for (int digit = 0; digit < 4; digit++)
                seg_in.seg_sels[bank][digit] = pattern[bank][digit];
    endtask

    task automatic check_outputs;
        int digit;
        driver::seg7_output_t expected;
        digit = (model_cycles / EXPECTED_CYCLES) % 4;
        for (int bank = 0; bank < 2; bank++) begin
            expected.seg7_cs[bank] = 4'b0001 << digit;
            expected.seg7_ss[bank] = pattern[bank][digit];
        end

        if (seg_out !== expected)
            $fatal(1, "%m: period=%0d cycle=%0d digit=%0d cs=%h expected_cs=%h segments=%h expected_segments=%h",
                   EXPECTED_CYCLES, model_cycles, digit,
                   seg_out.seg7_cs, expected.seg7_cs, seg_out.seg7_ss, expected.seg7_ss);
    endtask

    task automatic check_tick;
        @(posedge clk);
        #1;
        if (rst_n)
            model_cycles++;
        else
            model_cycles = 0;
        check_outputs();
    endtask

    initial begin
        done = 1'b0;
        rst_n = 1'b0;
        model_cycles = 0;
        // 显式按组、按位赋值，八个互异字节也覆盖小数点位的透传。
        pattern[0][0] = 8'h81;
        pattern[0][1] = 8'h92;
        pattern[0][2] = 8'ha3;
        pattern[0][3] = 8'hb4;
        pattern[1][0] = 8'hc5;
        pattern[1][1] = 8'hd6;
        pattern[1][2] = 8'he7;
        pattern[1][3] = 8'hf8;
        apply_pattern();
        #1;
        check_outputs();
        repeat (2) check_tick();
        @(negedge clk);
        rst_n = 1'b1;

        // 检查两轮扫描、每位保持时长及第 3 位回到第 0 位。
        repeat (8 * EXPECTED_CYCLES + 3) check_tick();

        // 在时钟边沿之间改变段码，当前位应立即更新，片选应保持。
        @(negedge clk);
        for (int bank = 0; bank < 2; bank++)
            for (int digit = 0; digit < 4; digit++)
                pattern[bank][digit] = ~pattern[bank][digit];
        apply_pattern();
        #1;
        check_outputs();
        repeat (4 * EXPECTED_CYCLES) check_tick();

        // 在扫描过程中异步复位，随后从完整的第 0 位周期重新开始。
        @(negedge clk);
        #2;
        rst_n = 1'b0;
        model_cycles = 0;
        #1;
        check_outputs();
        repeat (2) check_tick();
        @(negedge clk);
        rst_n = 1'b1;
        repeat (4 * EXPECTED_CYCLES + 2) check_tick();

        // 完成的用例保持复位，避免等待其他配置时继续产生扫描波形。
        rst_n = 1'b0;
        model_cycles = 0;
        #1;
        check_outputs();
        done = 1'b1;
        $display("PASS: %m, %0d clock cycles per digit", EXPECTED_CYCLES);
    end
endmodule

module tb_drv_seg7;
    localparam realtime HALF_CLK_PERIOD = 1_000_000_000.0 / (2.0 * board::CLK_FREQ);
    logic clk = 1'b0;
    always #(HALF_CLK_PERIOD) clk = ~clk;

    wire [3:0] done;

    tb_drv_seg7_case #(.USE_DEFAULT(1'b1)) default_case (
        .clk(clk), .done(done[0])
    );
    tb_drv_seg7_case #(
        .SEG7_SCAN_FREQ(board::CLK_FREQ / 5), .EXPECTED_CYCLES(5)
    ) fast_case (
        .clk(clk), .done(done[1])
    );
    tb_drv_seg7_case #(
        .SEG7_SCAN_FREQ(board::CLK_FREQ), .EXPECTED_CYCLES(1)
    ) single_cycle_case (
        .clk(clk), .done(done[2])
    );
    tb_drv_seg7_case #(
        .SEG7_SCAN_FREQ(board::CLK_FREQ / 3), .EXPECTED_CYCLES(3)
    ) truncated_case (
        .clk(clk), .done(done[3])
    );

    initial begin
        $dumpfile(`__VCD_FILE__);
        $dumpvars(0, tb_drv_seg7);
        wait (&done);
        #1;
        $display("PASS: drv_seg7 frequencies, clock/reset struct, input/output structs, 2D digits, scan timing and live updates");
        $finish;
    end

    initial begin
        #10_000_000;
        $fatal(1, "drv_seg7 simulation timeout");
    end
endmodule
