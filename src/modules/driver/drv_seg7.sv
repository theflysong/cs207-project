//!drv_seg7.sv
//!
//! 两组四位数码管的扫描驱动，段码由上游模块提供。

//! 时钟频率直接使用 board::CLK_FREQ，扫描频率使用独立参数。
//! 每位持续 floor(board::CLK_FREQ / SEG7_SCAN_FREQ) 个时钟。
//! seg_in.seg_sels[0][0..3] 为低四位，[1][0..3] 为高四位。
//! seg_out.seg7_ss[bank] 为段码，seg_out.seg7_cs[bank] 为高有效独热片选。
//! clk_rst.rst_n 异步低有效，复位后两组都选择第 0 位。
module drv_seg7 #(
    parameter int unsigned SEG7_SCAN_FREQ = 4_000
) (
    input  baselib::clk_rst_t                 clk_rst,
    input  driver::seg7_input_t     seg_in,
    output driver::seg7_output_t    seg_out
);
    localparam int unsigned CYCLES_PER_DIGIT =
        (SEG7_SCAN_FREQ > 0) ? board::CLK_FREQ / SEG7_SCAN_FREQ : 1;
    localparam int unsigned DIV_WIDTH =
        (CYCLES_PER_DIGIT > 1) ? $clog2(CYCLES_PER_DIGIT) : 1;
    localparam logic [DIV_WIDTH-1:0] DIV_LAST = DIV_WIDTH'(CYCLES_PER_DIGIT - 1);

    initial begin
        if (board::CLK_FREQ == 0 || SEG7_SCAN_FREQ == 0 ||
            SEG7_SCAN_FREQ > board::CLK_FREQ)
            $fatal(1, "drv_seg7: require 0 < SEG7_SCAN_FREQ <= board::CLK_FREQ, got clk_freq=%0d scan_freq=%0d",
                   board::CLK_FREQ, SEG7_SCAN_FREQ);
    end

    logic [DIV_WIDTH-1:0] div_count;
    logic [1:0] scan_digit;

    always_ff @(posedge clk_rst.clk or negedge clk_rst.rst_n) begin
        if (!clk_rst.rst_n) begin
            div_count <= '0;
            scan_digit <= '0;
        end else if (div_count == DIV_LAST) begin
            div_count <= '0;
            scan_digit <= scan_digit + 2'd1;
        end else begin
            div_count <= div_count + 1'b1;
        end
    end

    always_comb begin
        for (int bank = 0; bank < 2; bank++) begin
            seg_out.seg7_ss[bank] = seg_in.seg_sels[bank][scan_digit];
            seg_out.seg7_cs[bank] = 4'b0001 << scan_digit;
        end
    end
endmodule
