// 模块 pulse_debounce 连续采样相反电平达到指定周期后更新输出.
// 参数:
// - CLK_FREQ: 输入时钟频率, 单位 Hz, 默认 0 表示未配置, 有效范围 1..2^31-1.
// - DEBOUNCE_TIME_NS: 消抖时间, 单位 ns, 默认 0 表示未配置, 有效范围 1..2^31-1.
// 端口:
// - clk: 输入, 1 位工作时钟, 上升沿采样.
// - rst_n: 输入, 1 位低有效异步复位, 清除电平与计数, 释放需与 clk 同步.
// - pulse: 输入, 1 位已同步的待消抖电平.
// - level: 输出, 1 位消抖后电平, 从 0 开始, 在达标的采样边沿更新.
// - rise: 输出, 1 位高有效上升沿, 消抖后电平变高时持续一个周期.
// - fall: 输出, 1 位高有效下降沿, 消抖后电平变低时持续一个周期.
module pulse_debounce #(
    parameter int CLK_FREQ = 0,
    parameter int DEBOUNCE_TIME_NS = 0
) (
    input wire clk,
    input wire rst_n,
    input wire pulse,
    output wire level,
    output wire rise,
    output wire fall
);
    // 用 64 位向量相乘, 向上取整到完整周期.
    localparam [63:0] NS_PER_SECOND = 64'd1_000_000_000;
    localparam [63:0] CLOCK_HZ = {32'd0, CLK_FREQ};
    localparam [63:0] TIME_NS = {32'd0, DEBOUNCE_TIME_NS};
    localparam [63:0] DEBOUNCE_CYCLES = (CLK_FREQ > 0 && DEBOUNCE_TIME_NS > 0)
        ? (CLOCK_HZ * TIME_NS + NS_PER_SECOND - 1'b1) / NS_PER_SECOND : 64'd1;
    localparam int CNT_WIDTH = baselib::count_width(DEBOUNCE_CYCLES);
    localparam [63:0] LAST_COUNT_VALUE = DEBOUNCE_CYCLES - 1'b1;
    localparam [CNT_WIDTH-1:0] LAST_COUNT = LAST_COUNT_VALUE[CNT_WIDTH-1:0];

    logic [CNT_WIDTH-1:0] count;
    logic debounced;

    // synthesis translate_off
    initial begin
        if (CLK_FREQ < 1 || DEBOUNCE_TIME_NS < 1) begin
            $display("ERROR: pulse_debounce requires positive CLK_FREQ and DEBOUNCE_TIME_NS");
            $finish;
        end
    end
    // synthesis translate_on

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= {CNT_WIDTH{1'b0}};
            debounced <= 1'b0;
        end else if (pulse == debounced) begin
            count <= {CNT_WIDTH{1'b0}};
        end else if (count == LAST_COUNT) begin
            count <= {CNT_WIDTH{1'b0}};
            debounced <= pulse;
        end else begin
            count <= count + 1'b1;
        end
    end

    pulse_edge_align u_pulse_edge_align_0 (
        .clk(clk),
        .rst_n(rst_n),
        .pulse(debounced),
        .level(level),
        .rise(rise),
        .fall(fall)
    );
endmodule
