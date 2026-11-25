// 模块 main 在 EGO1 上用 btn[0] 切换预置棋盘, 并展示前 8 格和第 9 格.
// 参数:
// - DEBOUNCE_TIME: 按键消抖时间, 单位 ns, 默认 20,000,000, 范围 1..2^31-1.
// - SEG7_SCAN_FREQ: 数码管换位频率, 单位 Hz, 默认 4,000, 范围 1..board::CLK_FREQ.
// 端口:
// - clk: 输入, 1 位 EGO1 板载时钟, 上升沿工作.
// - rst_n: 输入, 1 位外部低有效异步复位, 经过两级 clk 触发器同步释放.
// - sw: 输入, 8 位板载开关, 保留给后续功能, 当前不采样.
// - btn: 输入, 5 位高有效板载按键. 每次确认第 0 位按下后推进一个局面.
// - seg7_ss0: 输出, 8 位高有效段码, 扫描左侧 4 位数码管.
// - seg7_ss1: 输出, 8 位高有效段码, 扫描右侧 4 位数码管.
// - seg7_cs: 输出, 8 位高有效片选, 随 clk 扫描位置更新, 复位时选中位 0 和 4.
// - led: 输出, 8 位高有效 LED, 高 4 位显示第 9 格, 低 4 位全灭.
module main #(
    parameter int DEBOUNCE_TIME = 20_000_000,
    parameter int SEG7_SCAN_FREQ = 4_000
) (
    input logic clk,
    input logic rst_n,
    input logic [board::SW_COUNT - 1:0] sw,
    input logic [board::BTN_COUNT - 1:0] btn,
    output logic [board::SEG7_WIDTH - 1:0] seg7_ss0,
    output logic [board::SEG7_WIDTH - 1:0] seg7_ss1,
    output logic [board::SEG7_DIGIT_COUNT - 1:0] seg7_cs,
    output logic [board::LED_COUNT - 1:0] led
);
    game::layout_t layout;
    board::seg7_patterns_t seg7_patterns;

    // 数码管驱动的复位异步置位, 在 clk 的第二个上升沿同步释放.
    (* ASYNC_REG = "TRUE" *) logic reset_sync_stage_n;
    (* ASYNC_REG = "TRUE" *) logic core_rst_n;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_sync_stage_n <= 1'b0;
            core_rst_n <= 1'b0;
        end else begin
            reset_sync_stage_n <= 1'b1;
            core_rst_n <= reset_sync_stage_n;
        end
    end

    // 外部按键先经两级 clk 触发器同步, 再进入消抖模块.
    (* ASYNC_REG = "TRUE" *) logic [1:0] btn_sync;
    logic next_layout;

    always @(posedge clk or negedge core_rst_n) begin
        if (!core_rst_n) begin
            btn_sync <= 2'b00;
        end else begin
            btn_sync <= {btn_sync[0], btn[0]};
        end
    end

    pulse_debounce #(
        .CLK_FREQ(board::CLK_FREQ),
        .DEBOUNCE_TIME_NS(DEBOUNCE_TIME)
    ) u_pulse_debounce_0 (
        .clk(clk),
        .rst_n(core_rst_n),
        .pulse(btn_sync[1]),
        .level(),
        .rise(next_layout),
        .fall()
    );

    board_view_test u_board_view_test_0 (
        .clk(clk),
        .rst_n(core_rst_n),
        .next_layout(next_layout),
        .layout(layout)
    );

    board_view u_board_view_0 (
        .layout(layout),
        .seg7_pattern(seg7_patterns),
        .led(led)
    );

    drv_seg7 #(
        .SEG7_SCAN_FREQ(SEG7_SCAN_FREQ)
    ) u_drv_seg7_0 (
        .clk(clk),
        .rst_n(core_rst_n),
        .seg7_patterns(seg7_patterns),
        .seg7_ss0(seg7_ss0),
        .seg7_ss1(seg7_ss1),
        .seg7_cs(seg7_cs)
    );
endmodule
