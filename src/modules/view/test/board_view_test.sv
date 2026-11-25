// 模块 board_view_test 在预置的棋盘间循环切换.
// 状态在 clk 上升沿推进, 局面随预置编号组合更新.
// 参数: 无.
// 端口:
// - clk: 输入, 1 位工作时钟, 上升沿采样.
// - rst_n: 输入, 1 位低有效异步复位, 同步释放, 复位时选择第一个局面.
// - next_layout: 输入, 1 位高有效单周期使能, 每个有效上升沿切换一次局面.
// - layout: 输出, 复位或切换后显示的 9 格局面, 每格 4 位.
module board_view_test (
    input logic clk,
    input logic rst_n,
    input logic next_layout,
    output game::layout_t layout
);
    localparam int PRESET_COUNT = 4;
    localparam int LAYOUT_BITS = game::LAYOUT_GRIDS * game::GRID_WIDTH;

    // 每个常量按棋盘从左到右, 从上到下依次写入 9 个棋子.
    localparam [LAYOUT_BITS - 1:0] PRESET_START = 36'h123456708;
    localparam [LAYOUT_BITS - 1:0] PRESET_WIN = 36'h123456780;
    localparam [LAYOUT_BITS - 1:0] PRESET_FIRST_EMPTY = 36'h012345687;
    localparam [LAYOUT_BITS - 1:0] PRESET_INVALID = 36'h12945A789;

    logic [baselib::count_width(PRESET_COUNT) - 1:0] preset_index;
    logic [LAYOUT_BITS - 1:0] layout_bits;

    step_cnt #(
        .CNT_STATES(PRESET_COUNT)
    ) u_step_cnt_0 (
        .clk(clk),
        .rst_n(rst_n),
        .en(next_layout),
        .step(preset_index)
    );

    always @* begin
        case (preset_index)
            2'd1: layout_bits = PRESET_WIN;
            2'd2: layout_bits = PRESET_FIRST_EMPTY;
            2'd3: layout_bits = PRESET_INVALID;
            default: layout_bits = PRESET_START;
        endcase
    end

    genvar grid;
    generate
        for (grid = 0; grid < game::LAYOUT_GRIDS; grid = grid + 1) begin : gen_grid
            assign layout[grid] = layout_bits[(game::LAYOUT_GRIDS - 1 - grid) * game::GRID_WIDTH +: game::GRID_WIDTH];
        end
    endgenerate
endmodule
