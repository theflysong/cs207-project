// 模块 main 将 EGO1 的第 0 个按键连接到交通灯示例, 用数码管第 0 位显示颜色.
// 参数:
// - DEBOUNCE_TIME: 按键消抖时间, 单位 ns, 默认 20,000,000, 范围 1..2^31-1.
// - SEG7_SCAN_FREQ: 数码管换位频率, 单位 Hz, 默认 4,000, 范围 1..board::CLK_FREQ.
// 端口:
// - clk: 输入, 1 位 EGO1 板载时钟, 上升沿工作.
// - rst_n: 输入, 1 位外部低有效复位, 异步置位, 经过两级 clk 触发器同步释放.
// - sw: 输入, 8 位板载开关, 保留给后续功能, 当前不采样.
// - btn: 输入, 5 位高有效板载按键, 第 0 位先同步再消抖, 其余位保留.
// - seg7_ss0: 输出, 8 位高有效段码, 对应数码管 4..7, 当前均为空白.
// - seg7_ss1: 输出, 8 位高有效段码, 对应数码管 0..3, 位 0 显示灯色, 其余为空白.
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
    // 复位异步置位. 只有 clk 的第二个上升沿才能释放内部复位.
    (* ASYNC_REG = "TRUE" *) logic reset_sync_stage_n;
    (* ASYNC_REG = "TRUE" *) logic core_rst_n;

    // 按键经两级采样后才进入消抖模块.
    (* ASYNC_REG = "TRUE" *) logic button_sync_stage;
    (* ASYNC_REG = "TRUE" *) logic button_sync;

    wire button_rise;
    wire [traffic_encoding::LIGHT_WIDTH-1:0] light;
    wire [baselib::SEG7_WIDTH-1:0] light_pattern;
    wire [board::SEG7_DIGIT_COUNT*baselib::SEG7_WIDTH-1:0] seg7_patterns;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_sync_stage_n <= 1'b0;
            core_rst_n <= 1'b0;
        end else begin
            reset_sync_stage_n <= 1'b1;
            core_rst_n <= reset_sync_stage_n;
        end
    end

    always @(posedge clk or negedge core_rst_n) begin
        if (!core_rst_n) begin
            button_sync_stage <= 1'b0;
            button_sync <= 1'b0;
        end else begin
            button_sync_stage <= btn[0];
            button_sync <= button_sync_stage;
        end
    end

    pulse_debounce #(
        .CLK_FREQ(board::CLK_FREQ),
        .DEBOUNCE_TIME_NS(DEBOUNCE_TIME)
    ) u_pulse_debounce_0 (
        .clk(clk),
        .rst_n(core_rst_n),
        .pulse(button_sync),
        .level(),
        .rise(button_rise),
        .fall()
    );

    traffic_light u_traffic_light_0 (
        .clk(clk),
        .rst_n(core_rst_n),
        .advance(button_rise),
        .light(light)
    );

    traffic_light_2_seg7 #(
        .POLARITY(baselib::SEG7_CATHODE)
    ) u_traffic_light_2_seg7_0 (
        .light(light),
        .seg7_out(light_pattern)
    );

    // 数码管 0 位于最低段码字段, 其余数位消隐.
    assign seg7_patterns = {{(board::SEG7_DIGIT_COUNT-1){baselib::SEG7_BLANK}}, light_pattern};

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
