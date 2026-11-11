//! 模 N 计数器, step 在 0..CNT_STATES-1 之间循环.
//! en 在 cr.clk 上升沿采样; 异步低有效复位清零 step.
module step_cnt #(
    parameter int CNT_STATES = 4,
    parameter int CNT_WIDTH = baselib::s_clog2(CNT_STATES)
) (
    clk_if.sink cr,
    input logic en,
    output logic [CNT_WIDTH-1:0] step
);
    localparam logic [CNT_WIDTH-1:0] LAST = CNT_WIDTH'(CNT_STATES - 1);

    initial begin
        if (CNT_STATES < 1)
            $fatal(1, "step_cnt: require CNT_STATES >= 1, got %0d", CNT_STATES);
        if (CNT_WIDTH < baselib::s_clog2(CNT_STATES))
            $fatal(1, "step_cnt: CNT_WIDTH=%0d cannot represent %0d states", CNT_WIDTH, CNT_STATES);
    end

    always_ff @(posedge cr.clk or negedge cr.rst_n) begin
        if (!cr.rst_n)
            step <= '0;
        else if (en) begin
            if (step == LAST)
                step <= '0;
            else
                step <= step + 1'b1;
        end
    end
endmodule
