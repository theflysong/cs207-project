// 模块 drv_seg7 轮询 EGO1 的两组数码管, 每次各选中一位.
// 参数:
// - SEG7_SCAN_FREQ: 换位频率, 单位 Hz, 默认 4,000, 范围 1..board::CLK_FREQ.
// 端口:
// - clk: 输入, 1 位板载工作时钟, 上升沿更新扫描位置.
// - rst_n: 输入, 1 位低有效异步复位, 释放需与 clk 同步. 复位时选中位 0 和 4.
// - seg7_patterns: 输入, 8 组 8 位段码, 第一维按数码管编号 0..7 索引, 第二维为段码位.
// - seg7_ss0: 输出, 8 位段码, 对应数码管 4..7, 组合更新, 位序为 {dp, g, f, e, d, c, b, a}.
// - seg7_ss1: 输出, 8 位段码, 对应数码管 0..3, 组合更新, 位序同 seg7_ss0.
// - seg7_cs: 输出, 8 位高有效片选, 每组各有一位为高, 随扫描位置更新.
module drv_seg7 #(
    parameter int SEG7_SCAN_FREQ = 4_000
) (
    input logic clk,
    input logic rst_n,
    input board::seg7_patterns_t seg7_patterns,
    output logic [baselib::SEG7_WIDTH - 1:0] seg7_ss0,
    output logic [baselib::SEG7_WIDTH - 1:0] seg7_ss1,
    output logic [board::SEG7_DIGIT_COUNT - 1:0] seg7_cs
);
    // 除法向下取整. 分频使能寄存后再推进扫描, 首次换位多等一拍.
    localparam int DIGITS_PER_BANK = board::SEG7_DIGITS_PER_BANK;
    localparam int SCAN_WIDTH = baselib::count_width(DIGITS_PER_BANK);
    localparam int CYCLES_PER_DIGIT = (SEG7_SCAN_FREQ > 0 && SEG7_SCAN_FREQ <= board::CLK_FREQ)
        ? board::CLK_FREQ / SEG7_SCAN_FREQ : 1;
    localparam [board::SEG7_DIGIT_COUNT - 1:0] FIRST_DIGIT_PAIR = 8'h11;

    logic scan_en;
    logic [SCAN_WIDTH - 1:0] scan_digit;

    // synthesis translate_off
    initial begin
        if (SEG7_SCAN_FREQ < 1 || SEG7_SCAN_FREQ > board::CLK_FREQ) begin
            $display("ERROR: drv_seg7 requires 1 <= SEG7_SCAN_FREQ <= board::CLK_FREQ");
            $finish;
        end
    end
    // synthesis translate_on

    clk_div #(
        .DIVISOR(CYCLES_PER_DIGIT)
    ) u_clk_div_0 (
        .clk(clk),
        .rst_n(rst_n),
        .en(scan_en)
    );

    step_cnt #(
        .CNT_STATES(DIGITS_PER_BANK)
    ) u_step_cnt_0 (
        .clk(clk),
        .rst_n(rst_n),
        .en(scan_en),
        .step(scan_digit)
    );

    assign seg7_ss1 = seg7_patterns[scan_digit];
    assign seg7_ss0 = seg7_patterns[DIGITS_PER_BANK + scan_digit];
    assign seg7_cs = FIRST_DIGIT_PAIR << scan_digit;
endmodule
