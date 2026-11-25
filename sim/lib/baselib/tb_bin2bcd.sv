// 模块 tb_bin2bcd 穷举默认二进制位宽, 核对多路转换和两种数码管极性.
// 参数: 无.
// 端口: 无.
// 时钟与复位: 被测逻辑为纯组合逻辑, 每次驱动后留 1 ns 稳定时间.
`timescale 1ns/1ps
module tb_bin2bcd;
    // 每次送入两个不同数字, 检查并行接口的字段顺序.
    localparam int CHANNELS = 2;
    localparam int BIN_WIDTH = 8;
    localparam int DIGIT_WIDTH = 4;
    localparam int BCD_DIGITS = 3;
    localparam int BCD_WIDTH = BCD_DIGITS * DIGIT_WIDTH;
    localparam int SEG7_WIDTH = 8;
    localparam int BIN_VALUES = 2 ** BIN_WIDTH;
    localparam int HEX_VALUES = 2 ** DIGIT_WIDTH;
    localparam int DECIMAL_BASE = 10;
    localparam [HEX_VALUES*SEG7_WIDTH-1:0] REFERENCE_SEGMENTS =
        128'h71_79_5e_39_7c_77_6f_7f_07_7d_6d_66_4f_5b_06_3f;

    logic [BIN_WIDTH-1:0] low_binary;
    logic [BIN_WIDTH-1:0] high_binary;
    logic [DIGIT_WIDTH-1:0] low_digit;
    logic [DIGIT_WIDTH-1:0] high_digit;
    wire [CHANNELS*BCD_WIDTH-1:0] bcd;
    wire [CHANNELS*SEG7_WIDTH-1:0] bcd_cathode;
    wire [CHANNELS*SEG7_WIDTH-1:0] bcd_anode;
    wire [CHANNELS*SEG7_WIDTH-1:0] hex_cathode;
    wire [CHANNELS*SEG7_WIDTH-1:0] hex_anode;
    logic [CHANNELS*SEG7_WIDTH-1:0] expected_hex;
    logic [CHANNELS*SEG7_WIDTH-1:0] expected_bcd_seg7;
    int value;
    int opposite;

    bin2bcd #(.N(CHANNELS)) u_bin2bcd_0 (
        .bin_in({high_binary, low_binary}), .bcd_out(bcd)
    );
    bcd2seg7 #(
        .N(CHANNELS), .POLARITY(baselib::SEG7_CATHODE)
    ) u_bcd2seg7_0 (
        .bcd_in({high_digit, low_digit}), .seg7_out(bcd_cathode)
    );
    bcd2seg7 #(.N(CHANNELS)) u_bcd2seg7_1 (
        .bcd_in({high_digit, low_digit}), .seg7_out(bcd_anode)
    );
    hex2seg7 #(
        .N(CHANNELS), .POLARITY(baselib::SEG7_CATHODE)
    ) u_hex2seg7_0 (
        .hex_in({high_digit, low_digit}), .seg7_out(hex_cathode)
    );
    hex2seg7 #(.N(CHANNELS)) u_hex2seg7_1 (
        .hex_in({high_digit, low_digit}), .seg7_out(hex_anode)
    );

    function automatic [BCD_WIDTH-1:0] decimal_digits(input int binary_value);
        reg [DIGIT_WIDTH-1:0] hundreds;
        reg [DIGIT_WIDTH-1:0] tens;
        reg [DIGIT_WIDTH-1:0] units;
        begin
            hundreds = binary_value / (DECIMAL_BASE * DECIMAL_BASE);
            tens = (binary_value / DECIMAL_BASE) % DECIMAL_BASE;
            units = binary_value % DECIMAL_BASE;
            decimal_digits = {hundreds, tens, units};
        end
    endfunction

    function automatic [SEG7_WIDTH-1:0] reference_bcd_seg7(input int digit);
        begin
            if (digit < DECIMAL_BASE) begin
                reference_bcd_seg7 = REFERENCE_SEGMENTS[digit*SEG7_WIDTH +: SEG7_WIDTH];
            end else begin
                reference_bcd_seg7 = {SEG7_WIDTH{1'b0}};
            end
        end
    endfunction

    initial begin
        for (value = 0; value < BIN_VALUES; value = value + 1) begin
            opposite = BIN_VALUES - 1 - value;
            low_binary = value[BIN_WIDTH-1:0];
            high_binary = opposite[BIN_WIDTH-1:0];
            #1;
            if (bcd !== {decimal_digits(opposite), decimal_digits(value)}) begin
                $display("ERROR: tb_bin2bcd unexpected BCD %h for inputs %0d and %0d",
                    bcd, opposite, value);
                $finish;
            end
        end

        for (value = 0; value < HEX_VALUES; value = value + 1) begin
            opposite = HEX_VALUES - 1 - value;
            low_digit = value[DIGIT_WIDTH-1:0];
            high_digit = opposite[DIGIT_WIDTH-1:0];
            expected_hex = {REFERENCE_SEGMENTS[opposite*SEG7_WIDTH +: SEG7_WIDTH],
                REFERENCE_SEGMENTS[value*SEG7_WIDTH +: SEG7_WIDTH]};
            expected_bcd_seg7 = {reference_bcd_seg7(opposite), reference_bcd_seg7(value)};
            #1;
            if (hex_cathode !== expected_hex || hex_anode !== ~expected_hex ||
                bcd_cathode !== expected_bcd_seg7 || bcd_anode !== ~expected_bcd_seg7) begin
                $display("ERROR: tb_bin2bcd segment mismatch for digits %h and %h",
                    high_digit, low_digit);
                $finish;
            end
        end

        $display("PASS: tb_bin2bcd");
        $finish;
    end
endmodule
