// 模块 clk_div 生成周期性时钟使能. 从复位释放后的第 DIVISOR 个上升沿起输出.
// 参数:
// - DIVISOR: 两次使能之间的 clk 周期数, 默认 2, 范围 1..2^31-1.
// 端口:
// - clk: 输入, 1 位工作时钟, 上升沿更新计数和使能.
// - rst_n: 输入, 1 位低有效异步复位, 释放需与 clk 同步.
// - en: 输出, 1 位高有效使能, 每次保持一个周期. DIVISOR 为 1 时持续使能.
module clk_div #(
    parameter int DIVISOR = 2
) (
    input wire clk,
    input wire rst_n,
    output logic en
);
    // 计数从 0 到 DIVISOR-1, 位宽至少为 1.
    localparam int CNT_WIDTH = baselib::count_width((DIVISOR > 0) ? DIVISOR : 1);
    localparam int LAST_COUNT_VALUE = (DIVISOR > 0) ? DIVISOR - 1 : 0;
    localparam [CNT_WIDTH-1:0] LAST_COUNT = LAST_COUNT_VALUE[CNT_WIDTH-1:0];

    logic [CNT_WIDTH-1:0] count;

    // synthesis translate_off
    initial begin
        if (DIVISOR < 1) begin
            $display("ERROR: clk_div requires DIVISOR >= 1");
            $finish;
        end
    end
    // synthesis translate_on

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= {CNT_WIDTH{1'b0}};
            en <= 1'b0;
        end else if (count == LAST_COUNT) begin
            count <= {CNT_WIDTH{1'b0}};
            en <= 1'b1;
        end else begin
            count <= count + 1'b1;
            en <= 1'b0;
        end
    end
endmodule
