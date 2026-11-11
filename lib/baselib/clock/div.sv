//! 周期使能分频器: 每 DIVISOR 个输入周期, en 拉高一个周期.
//! 要求 DIVISOR >= 1; 为 1 时每个周期均使能.
//! cr.rst_n 为低有效异步复位, 清零计数和 en.
module clk_div #(
    parameter int DIVISOR = 2
) (
    clk_if.sink cr,
    output logic en
);
    localparam int COUNT_WIDTH = baselib::s_clog2(DIVISOR);
    localparam logic [COUNT_WIDTH-1:0] LAST = COUNT_WIDTH'(DIVISOR - 1);

    initial begin
        if (DIVISOR < 1)
            $fatal(1, "clk_div: require DIVISOR >= 1, got %0d", DIVISOR);
    end

    logic [COUNT_WIDTH-1:0] count;

    always_ff @(posedge cr.clk or negedge cr.rst_n) begin
        if (!cr.rst_n) begin
            count <= '0;
            en <= 1'b0;
        end else if (count == LAST) begin
            count <= '0;
            en <= 1'b1;
        end else begin
            count <= count + 1'b1;
            en <= 1'b0;
        end
    end
endmodule
