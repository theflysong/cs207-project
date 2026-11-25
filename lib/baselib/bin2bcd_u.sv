// 模块 bin2bcd_u 用逐位移位和十进制修正进行组合转换, 无时钟和复位.
// 参数:
// - BIN_WIDTH: 无符号二进制输入位宽, 默认 8, 至少为 1.
// - BCD_DIGITS: 十进制位数, 默认 3, 至少为 1 且能容纳全部 BIN_WIDTH 位输入.
// 端口:
// - bin_in: 输入, BIN_WIDTH 位无符号数.
// - bcd_out: 输出, 组合更新, 每个 BCD 数字占 4 位, 个位位于最低位.
module bin2bcd_u #(
    parameter int BIN_WIDTH = 8,
    parameter int BCD_DIGITS = 3
) (
    input logic [BIN_WIDTH - 1:0] bin_in,
    output logic [BCD_DIGITS * baselib::HEX_DIGIT_WIDTH - 1:0] bcd_out
);
    // 每个 BCD 数字用一组 4 位, 大于等于 5 时先加 3 再移位.
    localparam int DIGIT_WIDTH = baselib::HEX_DIGIT_WIDTH;
    localparam int BCD_WIDTH = BCD_DIGITS * DIGIT_WIDTH;
    localparam [DIGIT_WIDTH - 1:0] CORRECTION_THRESHOLD = 4'd5;
    localparam [DIGIT_WIDTH - 1:0] CORRECTION = 4'd3;

    // synthesis translate_off
    // 向量可精确容纳 10^BCD_DIGITS, 用右移比较它是否至少为 2^BIN_WIDTH.
    localparam [DIGIT_WIDTH - 1:0] DECIMAL_BASE = 4'd10;
    function automatic bcd_has_capacity(input int binary_width);
        logic [BCD_WIDTH:0] capacity;
        integer digit_index;
        begin
            capacity = {{BCD_WIDTH{1'b0}}, 1'b1};
            for (digit_index = 0; digit_index < BCD_DIGITS; digit_index = digit_index + 1) begin
                capacity = capacity * DECIMAL_BASE;
            end
            bcd_has_capacity = (capacity >> binary_width) != {(BCD_WIDTH + 1){1'b0}};
        end
    endfunction

    initial begin
        if (BIN_WIDTH < 1 || BCD_DIGITS < 1 || !bcd_has_capacity(BIN_WIDTH)) begin
            $display("ERROR: bin2bcd_u cannot represent all %0d input bits in %0d BCD digits",
                BIN_WIDTH, BCD_DIGITS);
            $finish;
        end
    end
    // synthesis translate_on

    function automatic [BCD_WIDTH - 1:0] convert(input [BIN_WIDTH - 1:0] value);
        logic [BCD_WIDTH - 1:0] shifted;
        integer bit_index;
        integer digit_index;
        begin
            shifted = {BCD_WIDTH{1'b0}};
            for (bit_index = BIN_WIDTH - 1; bit_index >= 0; bit_index = bit_index - 1) begin
                for (digit_index = 0; digit_index < BCD_DIGITS; digit_index = digit_index + 1) begin
                    if (shifted[digit_index * DIGIT_WIDTH +: DIGIT_WIDTH] >= CORRECTION_THRESHOLD) begin
                        shifted[digit_index * DIGIT_WIDTH +: DIGIT_WIDTH] =
                            shifted[digit_index * DIGIT_WIDTH +: DIGIT_WIDTH] + CORRECTION;
                    end
                end
                shifted = shifted << 1;
                shifted[0] = value[bit_index];
            end
            convert = shifted;
        end
    endfunction

    assign bcd_out = convert(bin_in);
endmodule
