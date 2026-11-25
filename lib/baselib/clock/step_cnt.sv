// 模块 step_cnt 在使能时循环计数, 每个 clk 上升沿最多推进一次.
// 参数:
// - CNT_STATES: 计数状态数, 默认 4, 范围 1..2^31-1.
// 端口:
// - clk: 输入, 1 位工作时钟, 上升沿采样.
// - rst_n: 输入, 1 位低有效异步复位, 释放需与 clk 同步.
// - en: 输入, 1 位高有效计数使能, 为低时保持当前值.
// - step: 输出, 当前计数值, 位宽至少为 1, 从 0 到 CNT_STATES-1.
module step_cnt #(
    parameter int CNT_STATES = 4
) (
    input logic clk,
    input logic rst_n,
    input logic en,
    output logic [baselib::count_width((CNT_STATES > 0) ? CNT_STATES : 1) - 1:0] step
);
    // 位宽与端口一致, 终值由状态数推导.
    localparam int CNT_WIDTH = baselib::count_width((CNT_STATES > 0) ? CNT_STATES : 1);
    localparam int LAST_STEP_VALUE = (CNT_STATES > 0) ? CNT_STATES - 1 : 0;
    localparam [CNT_WIDTH - 1:0] LAST_STEP = LAST_STEP_VALUE[CNT_WIDTH - 1:0];

    // synthesis translate_off
    initial begin
        if (CNT_STATES < 1) begin
            $display("ERROR: step_cnt requires CNT_STATES >= 1");
            $finish;
        end
    end
    // synthesis translate_on

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step <= {CNT_WIDTH{1'b0}};
        end else if (en) begin
            if (step == LAST_STEP) begin
                step <= {CNT_WIDTH{1'b0}};
            end else begin
                step <= step + 1'b1;
            end
        end
    end
endmodule
