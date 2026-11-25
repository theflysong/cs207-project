// 模块 main 根据 EGO1 第 0 个按键的消抖电平选择数值, 在数码管上显示十进制数.
// 参数:
// - DEBOUNCE_TIME: 按键消抖时间, 单位 ns, 默认 20,000,000, 范围 1..2^31-1.
// - SEG7_SCAN_FREQ: 数码管换位频率, 单位 Hz, 默认 4,000, 范围 1..board::CLK_FREQ.
// 端口:
// - clk: 输入, 1 位 EGO1 板载时钟, 上升沿工作.
// - rst_n: 输入, 1 位外部低有效异步复位, 数码管驱动的复位经过两级 clk 触发器同步释放.
// - sw: 输入, 8 位板载开关, 保留给后续功能, 当前不采样.
// - btn: 输入, 5 位高有效板载按键, 第 0 位消抖后选择显示数值, 其余位保留.
// - seg7_ss0: 输出, 8 位高有效段码, 对应十进制显示的高 4 位, 前导位置显示空白.
// - seg7_ss1: 输出, 8 位高有效段码, 对应十进制显示的低 4 位, 第 0 位是个位.
// - seg7_cs: 输出, 8 位高有效片选, 随 clk 扫描位置更新, 复位时选中位 0 和 4.
module main #(
    parameter int DEBOUNCE_TIME = 20_000_000,
    parameter int SEG7_SCAN_FREQ = 4_000
) (
    input wire clk,
    input wire rst_n,
    input wire [7:0] sw,
    input wire [4:0] btn,
    output wire [7:0] seg7_ss0,
    output wire [7:0] seg7_ss1,
    output wire [7:0] seg7_cs
);
    localparam int VALUE_WIDTH = 24;

    wire [board::SEG7_DIGIT_COUNT - 1:0][baselib::SEG7_WIDTH - 1:0] seg7_patterns;

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

    logic [4:0] btn_level;
    logic [4:0] btn_rise;
    logic [4:0] btn_fall;

    pulse_debounce #(
        .CLK_FREQ(board::CLK_FREQ),
        .DEBOUNCE_TIME_NS(DEBOUNCE_TIME)
    ) u_pulse_debounce_0 (
        .clk(clk),
        .rst_n(rst_n),
        .pulse(btn[0]),
        .level(btn_level[0]),
        .rise(btn_rise[0]),
        .fall(btn_fall[0])
    );

    logic [VALUE_WIDTH - 1:0] value;
    wire [board::SEG7_DIGIT_COUNT - 1:0][baselib::HEX_DIGIT_WIDTH - 1:0] value_bcd;
    wire [board::SEG7_DIGIT_COUNT - 1:0][baselib::SEG7_WIDTH - 1:0] value_patterns;

    always @* begin
        if (btn_level[0]) begin
            value = 24'd114514;
        end else begin
            value = 24'd1919810;
        end
    end

    bin2bcd_u #(
        .BIN_WIDTH(VALUE_WIDTH),
        .BCD_DIGITS(board::SEG7_DIGIT_COUNT)
    ) u_bin2bcd_u_0 (
        .bin_in(value),
        .bcd_out(value_bcd)
    );

    bcd2seg7 #(
        .N(board::SEG7_DIGIT_COUNT),
        .POLARITY(baselib::SEG7_CATHODE)
    ) u_bcd2seg7_0 (
        .bcd_in(value_bcd),
        .seg7_out(value_patterns)
    );

    // 个位始终显示. 当前位及更高位全部为零时, 当前位显示空白.
    assign seg7_patterns[0] = value_patterns[0];
    
    genvar digit;
    generate
        for (digit = 1; digit < board::SEG7_DIGIT_COUNT; digit = digit + 1) begin : gen_value_digit
            assign seg7_patterns[digit] = (|value_bcd[board::SEG7_DIGIT_COUNT - 1:digit])
                ? value_patterns[digit] : baselib::SEG7_BLANK;
        end
    endgenerate

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
