// 模块 traffic_light_2_seg7 组合译码交通灯颜色, 无时钟和复位.
// 参数:
// - POLARITY: 段码极性, 默认共阳极, 取 baselib::SEG7_ANODE 或 baselib::SEG7_CATHODE.
// 端口:
// - light: 输入, 2 位灯色编码, 定义见 traffic_encoding, 非法编码消隐.
// - seg7_out: 输出, 8 位段码, 组合更新, 分别显示 r, g, y. 位序为 {dp, g, f, e, d, c, b, a}.
module traffic_light_2_seg7 #(
    parameter POLARITY = baselib::SEG7_ANODE
) (
    input wire [traffic_encoding::LIGHT_WIDTH-1:0] light,
    output wire [baselib::SEG7_WIDTH-1:0] seg7_out
);
    // 当前工程采用的高有效字母段码.
    localparam [baselib::SEG7_WIDTH-1:0] SEG7_RED = 8'h31;
    localparam [baselib::SEG7_WIDTH-1:0] SEG7_GREEN = 8'h3d;
    localparam [baselib::SEG7_WIDTH-1:0] SEG7_YELLOW = 8'h6e;

    logic [baselib::SEG7_WIDTH-1:0] segments;

    always @* begin
        case (light)
            traffic_encoding::LIGHT_RED_CODE: segments = SEG7_RED;
            traffic_encoding::LIGHT_GREEN_CODE: segments = SEG7_GREEN;
            traffic_encoding::LIGHT_YELLOW_CODE: segments = SEG7_YELLOW;
            default: segments = baselib::SEG7_BLANK;
        endcase
    end

    // synthesis translate_off
    initial begin
        if (POLARITY !== baselib::SEG7_ANODE && POLARITY !== baselib::SEG7_CATHODE) begin
            $display("ERROR: traffic_light_2_seg7 requires a valid segment polarity");
            $finish;
        end
    end
    // synthesis translate_on

    assign seg7_out = (POLARITY == baselib::SEG7_ANODE) ? ~segments : segments;
endmodule
