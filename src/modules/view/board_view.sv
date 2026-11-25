// 模块 board_view 将局面转换为高有效数码管段码和 LED 编码.
// 这是一个纯组合模块, 输出随局面更新.
// 参数: 无.
// 端口:
// - layout: 输入, 9 个 4 位棋子编号, 下标从左到右, 从上到下递增.
// - seg7_pattern: 输出, 8 组高有效段码, 最高下标对应最左侧数码管.
// - led: 输出, 高 4 位按二进制显示第 9 格, 低 4 位全灭.
module board_view (
    input game::layout_t layout,
    output board::seg7_patterns_t seg7_pattern,
    output logic [board::LED_COUNT - 1:0] led
);
    localparam [game::GRID_WIDTH - 1:0] MAX_TILE = 4'd8;
    localparam [game::GRID_WIDTH - 1:0] INVALID_TILE_LED = 4'b1111;

    logic [game::GRID_WIDTH - 1:0] last_tile;
    logic [game::GRID_WIDTH - 1:0] last_tile_led;

    genvar digit;
    generate
        for (digit = 0; digit < board::SEG7_DIGIT_COUNT; digit = digit + 1) begin : gen_digit
            assign seg7_pattern[board::SEG7_DIGIT_COUNT - 1 - digit] =
                (layout[digit] == 0) ? baselib::SEG7_BLANK :
                (layout[digit] <= MAX_TILE) ? baselib::hex_to_seg7(layout[digit]) : baselib::SEG7_E;
        end
    endgenerate

    assign last_tile = layout[game::LAYOUT_GRIDS - 1];
    assign last_tile_led = (last_tile <= MAX_TILE) ? last_tile : INVALID_TILE_LED;
    assign led = {last_tile_led, {(board::LED_COUNT - game::GRID_WIDTH){1'b0}}};
endmodule