// 模块 bcd2seg7_u 组合译码一个BCD数字, 无时钟和复位.
// 参数:
// - POLARITY: 段码极性, 默认共阳极, 取 baselib::SEG7_ANODE 或 baselib::SEG7_CATHODE.
// 端口:
// - bcd_in: 输入, 4 位BCD数字, 10..15 显示为空白.
// - seg7_out: 输出, 8 位段码, 组合更新. 位序为 {dp, g, f, e, d, c, b, a}.
module bcd2seg7_u #(
    parameter POLARITY = baselib::SEG7_ANODE
) (
    input wire [baselib::HEX_DIGIT_WIDTH-1:0] bcd_in,
    output wire [baselib::SEG7_WIDTH-1:0] seg7_out
);
    wire [baselib::SEG7_WIDTH-1:0] segments;

    // 仅有限的 BCD 数值可使用公共段码表.
    assign segments = (bcd_in <= baselib::BCD_MAX_DIGIT)
        ? baselib::hex_to_seg7(bcd_in) : baselib::SEG7_BLANK;
    // synthesis translate_off
    initial begin
        if (POLARITY !== baselib::SEG7_ANODE && POLARITY !== baselib::SEG7_CATHODE) begin
            $display("ERROR: bcd2seg7_u requires a valid segment polarity");
            $finish;
        end
    end
    // synthesis translate_on

    assign seg7_out = (POLARITY == baselib::SEG7_ANODE) ? ~segments : segments;
endmodule
