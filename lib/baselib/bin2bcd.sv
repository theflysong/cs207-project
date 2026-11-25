// 模块 bin2bcd 并行转换 N 路二进制数, 无时钟和复位.
// 参数:
// - N: 并行输入路数, 默认 4, 至少为 1, 总线位宽必须为正整数.
// - BIN_WIDTH: 每路二进制输入位宽, 默认 8, 至少为 1.
// - BCD_DIGITS: 每路十进制位数, 默认 3, 至少为 1 且能容纳全部 BIN_WIDTH 位输入.
// 端口:
// - bin_in: 输入, N 组 BIN_WIDTH 位无符号数, 第 0 组位于最低位.
// - bcd_out: 输出, N 组 BCD 结果, 组合更新, 第 0 组位于最低位, 每组个位在最低位.
module bin2bcd #(
    parameter int N = 4,
    parameter int BIN_WIDTH = 8,
    parameter int BCD_DIGITS = 3
) (
    input logic [N * BIN_WIDTH - 1:0] bin_in,
    output logic [N * BCD_DIGITS * baselib::HEX_DIGIT_WIDTH - 1:0] bcd_out
);
    // 每组输出的总位宽由其十进制数字数推导.
    localparam int BCD_WIDTH = BCD_DIGITS * baselib::HEX_DIGIT_WIDTH;

    // synthesis translate_off
    initial begin
        if (N < 1) begin
            $display("ERROR: bin2bcd requires N >= 1");
            $finish;
        end
    end
    // synthesis translate_on

    genvar channel;
    generate
        for (channel = 0; channel < N; channel = channel + 1) begin : gen_channel
            bin2bcd_u #(
                .BIN_WIDTH(BIN_WIDTH),
                .BCD_DIGITS(BCD_DIGITS)
            ) u_bin2bcd_u_0 (
                .bin_in(bin_in[channel * BIN_WIDTH +: BIN_WIDTH]),
                .bcd_out(bcd_out[channel * BCD_WIDTH +: BCD_WIDTH])
            );
        end
    endgenerate
endmodule
