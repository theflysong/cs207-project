// 模块 traffic_light 在每个有效按键脉冲时按红, 绿, 黄的顺序循环.
// 参数: 无.
// 端口:
// - clk: 输入, 1 位工作时钟, 上升沿采样 advance.
// - rst_n: 输入, 1 位低有效异步复位, 释放需与 clk 同步. 复位时回到红灯.
// - advance: 输入, 1 位高有效单周期脉冲, 相应 clk 上升沿推进一次.
// - light: 输出, 2 位灯色编码, 随状态寄存器更新, 定义见 traffic_encoding.
module traffic_light (
    input wire clk,
    input wire rst_n,
    input wire advance,
    output wire [traffic_encoding::LIGHT_WIDTH-1:0] light
);
    // 与段码译码模块共用边界编码, 状态类型留在状态机内部.
    typedef enum logic [traffic_encoding::LIGHT_WIDTH-1:0] {
        LIGHT_RED = traffic_encoding::LIGHT_RED_CODE,
        LIGHT_YELLOW = traffic_encoding::LIGHT_YELLOW_CODE,
        LIGHT_GREEN = traffic_encoding::LIGHT_GREEN_CODE
    } state_t;

    state_t state;
    state_t next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= LIGHT_RED;
        end else begin
            state <= next_state;
        end
    end

    always @* begin
        next_state = state;
        case (state)
            LIGHT_RED: begin
                if (advance) begin
                    next_state = LIGHT_GREEN;
                end
            end
            LIGHT_GREEN: begin
                if (advance) begin
                    next_state = LIGHT_YELLOW;
                end
            end
            LIGHT_YELLOW: begin
                if (advance) begin
                    next_state = LIGHT_RED;
                end
            end
            default: begin
                // 非法状态在下一个时钟上升沿恢复为红灯.
                next_state = LIGHT_RED;
            end
        endcase
    end

    assign light = state;
endmodule
