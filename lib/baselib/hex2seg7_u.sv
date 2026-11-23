// 模块 hex2seg7_u 组合译码一个十六进制数字, 无时钟和复位.
// 参数:
// - POLARITY: 段码极性, 默认共阳极, 取 baselib::SEG7_ANODE 或 baselib::SEG7_CATHODE.
// 端口:
// - hex_in: 输入, 4 位十六进制数字, 范围 0..15.
// - seg7_out: 输出, 8 位段码, 组合更新. 位序为 {dp, g, f, e, d, c, b, a}.
module hex2seg7_u #(
    parameter POLARITY = baselib::SEG7_ANODE
) (
    input wire [baselib::HEX_DIGIT_WIDTH-1:0] hex_in,
    output wire [baselib::SEG7_WIDTH-1:0] seg7_out
);
    wire [baselib::SEG7_WIDTH-1:0] segments;

    assign segments = baselib::hex_to_seg7(hex_in);
    // synthesis translate_off
    initial begin
        if (POLARITY !== baselib::SEG7_ANODE && POLARITY !== baselib::SEG7_CATHODE) begin
            $display("ERROR: hex2seg7_u requires a valid segment polarity");
            $finish;
        end
    end
    // synthesis translate_on

    assign seg7_out = (POLARITY == baselib::SEG7_ANODE) ? ~segments : segments;
endmodule
