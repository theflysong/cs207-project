`timescale 1ns/1ps

`ifndef __VCD_FILE__
`define __VCD_FILE__ "bin2bcd.vcd"
`endif

module tb_bin2bcd;
    localparam int DEFAULT_N = 4;
    localparam int WIDE_N = 3;
    localparam int WIDE_BIN_WIDTH = 10;

    logic [31:0] bin_in;
    wire [11:0] bcd_unit_default;
    wire [15:0] bcd_unit_wide;
    wire [39:0] bcd_unit_full;
    logic [DEFAULT_N-1:0][7:0] bin_default;
    wire [DEFAULT_N-1:0][11:0] bcd_default;
    logic [WIDE_N-1:0][WIDE_BIN_WIDTH-1:0] bin_wide;
    wire [WIDE_N-1:0][15:0] bcd_wide;

    bin2bcd_u unit_default_dut (
        .bin_in(bin_in[7:0]), .bcd_out(bcd_unit_default)
    );
    bin2bcd_u #(.BIN_WIDTH(WIDE_BIN_WIDTH), .BCD_WIDTH(16)) unit_wide_dut (
        .bin_in(bin_in[WIDE_BIN_WIDTH-1:0]), .bcd_out(bcd_unit_wide)
    );
    bin2bcd_u #(.BIN_WIDTH(32), .BCD_WIDTH(40)) unit_full_dut (
        .bin_in(bin_in), .bcd_out(bcd_unit_full)
    );

    bin2bcd default_dut (
        .bin_in(bin_default), .bcd_out(bcd_default)
    );
    bin2bcd #(.N(WIDE_N), .BIN_WIDTH(WIDE_BIN_WIDTH), .BCD_WIDTH(16)) wide_dut (
        .bin_in(bin_wide), .bcd_out(bcd_wide)
    );

    // 用十进制除法建立参考值，不依赖 DUT 的移位加三算法。
    function automatic logic [39:0] expected_bcd(input logic [31:0] value);
        logic [31:0] remaining;
        remaining = value;
        expected_bcd = '0;
        for (int digit = 0; digit < 10; digit++) begin
            expected_bcd[digit*4 +: 4] = 4'(remaining % 10);
            remaining = remaining / 10;
        end
    endfunction

    task automatic check_value(input logic [31:0] value);
        bin_in = value;
        for (int lane = 0; lane < DEFAULT_N; lane++)
            bin_default[lane] = 8'(value + 73 * lane);
        for (int lane = 0; lane < WIDE_N; lane++)
            bin_wide[lane] = WIDE_BIN_WIDTH'(value + 317 * lane);
        // 等组合逻辑稳定后再检查，避免输入变化时的瞬态误报。
        #1;

        if (bcd_unit_default !== 12'(expected_bcd(bin_in[7:0])))
            $fatal(1, "bin2bcd_u default: input=%0d got=%h expected=%h",
                   bin_in[7:0], bcd_unit_default, 12'(expected_bcd(bin_in[7:0])));
        if (bcd_unit_wide !== 16'(expected_bcd(bin_in[WIDE_BIN_WIDTH-1:0])))
            $fatal(1, "bin2bcd_u wide: input=%0d got=%h expected=%h",
                   bin_in[WIDE_BIN_WIDTH-1:0], bcd_unit_wide,
                   16'(expected_bcd(bin_in[WIDE_BIN_WIDTH-1:0])));
        if (bcd_unit_full !== expected_bcd(bin_in))
            $fatal(1, "bin2bcd_u 32-bit: input=%0d got=%h expected=%h",
                   bin_in, bcd_unit_full, expected_bcd(bin_in));

        for (int lane = 0; lane < DEFAULT_N; lane++) begin
            if (bcd_default[lane] !== 12'(expected_bcd(bin_default[lane])))
                $fatal(1, "bin2bcd default: lane=%0d input=%0d got=%h expected=%h",
                       lane, bin_default[lane], bcd_default[lane],
                       12'(expected_bcd(bin_default[lane])));
        end
        for (int lane = 0; lane < WIDE_N; lane++) begin
            if (bcd_wide[lane] !== 16'(expected_bcd(bin_wide[lane])))
                $fatal(1, "bin2bcd wide: lane=%0d input=%0d got=%h expected=%h",
                       lane, bin_wide[lane], bcd_wide[lane],
                       16'(expected_bcd(bin_wide[lane])));
        end
    endtask

    initial begin
        $dumpfile(`__VCD_FILE__);
        $dumpvars(0, tb_bin2bcd);

        // 穷举 10 位输入，同时覆盖默认 8 位输入的全部取值。
        for (int value = 0; value < (1 << WIDE_BIN_WIDTH); value++)
            check_value(32'(value));

        // 进位边界、32 位最大值，以及从大值回到零的输入变化。
        check_value(32'd9);
        check_value(32'd10);
        check_value(32'd99);
        check_value(32'd100);
        check_value(32'd255);
        check_value(32'd256);
        check_value(32'd999);
        check_value(32'd1000);
        check_value(32'd65_535);
        check_value(32'd99_999_999);
        check_value(32'd100_000_000);
        check_value(32'hffff_ffff);
        check_value(32'd0);

        $display("PASS: bin2bcd_u 8/10/32-bit and bin2bcd N=4/3, exhaustive 10-bit inputs and boundaries");
        $finish;
    end
endmodule
