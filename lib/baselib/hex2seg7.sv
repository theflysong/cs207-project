// 模块 hex2seg7 并行组合译码 N 位十六进制数字, 无时钟和复位.
// 参数:
// - N: 数字个数, 默认 4, 至少为 1, 总线位宽必须为正整数.
// - POLARITY: 段码极性, 默认共阳极, 取 baselib::SEG7_ANODE 或 baselib::SEG7_CATHODE.
// 端口:
// - hex_in: 输入, N 组 4 位十六进制数字, 第 0 组位于最低位.
// - seg7_out: 输出, N 组 8 位段码, 第 0 组位于最低位, 随输入组合更新.
module hex2seg7 #(
    parameter int N = 4,
    parameter POLARITY = baselib::SEG7_ANODE
) (
    input logic [N * baselib::HEX_DIGIT_WIDTH - 1:0] hex_in,
    output logic [N * baselib::SEG7_WIDTH - 1:0] seg7_out
);
    // synthesis translate_off
    initial begin
        if (N < 1) begin
            $display("ERROR: hex2seg7 requires N >= 1");
            $finish;
        end
    end
    // synthesis translate_on

    genvar digit;
    generate
        for (digit = 0; digit < N; digit = digit + 1) begin : gen_digit
            hex2seg7_u #(
                .POLARITY(POLARITY)
            ) u_hex2seg7_u_0 (
                .hex_in(hex_in[digit * baselib::HEX_DIGIT_WIDTH +: baselib::HEX_DIGIT_WIDTH]),
                .seg7_out(seg7_out[digit * baselib::SEG7_WIDTH +: baselib::SEG7_WIDTH])
            );
        end
    endgenerate
endmodule
