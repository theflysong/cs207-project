// 模块 pulse_edge_align 将同一时钟域内的电平变化转换为边沿脉冲.
// 参数: 无.
// 端口:
// - clk: 输入, 1 位工作时钟, 上升沿保存当前电平.
// - rst_n: 输入, 1 位低有效异步复位, 清除历史电平, 释放需与 clk 同步.
// - pulse: 输入, 1 位已同步电平, 复位期间应为低.
// - level: 输出, 1 位当前电平, 与 pulse 一致.
// - rise: 输出, 1 位高有效上升沿, 从电平上升持续到下次 clk 采样.
// - fall: 输出, 1 位高有效下降沿, 从电平下降持续到下次 clk 采样.
module pulse_edge_align (
    input logic clk,
    input logic rst_n,
    input logic pulse,
    output logic level,
    output logic rise,
    output logic fall
);
    logic previous_pulse;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            previous_pulse <= 1'b0;
        end else begin
            previous_pulse <= pulse;
        end
    end

    assign level = pulse;
    assign rise = pulse & ~previous_pulse;
    assign fall = ~pulse & previous_pulse;
endmodule
