//! EGO1 seven-segment scan driver; digit patterns are supplied by display logic.
//! seg_sels[0:7] is ordered from the rightmost to the leftmost digit.
//! The mapping to the two physical segment buses is private to this driver.
//! Each scan phase lasts floor(board::CLK_FREQ / SEG7_SCAN_FREQ) clock cycles.
//! Reset is asynchronous and active low; it selects digits 0 and 4.
//! The registered divider enable adds one clock cycle before the first advance.
module drv_seg7 #(
    parameter int unsigned SEG7_SCAN_FREQ = 4_000
) (
    clk_if.sink cr,
    seg7_if.drv seg
);
    // Assertions to check parameter validity
    initial begin
        if (board::CLK_FREQ == 0)
            $fatal(1, "drv_seg7: INVALID board::CLK_FREQ");

        if (SEG7_SCAN_FREQ == 0 ||
            SEG7_SCAN_FREQ > board::CLK_FREQ)
            $fatal(1, "drv_seg7: SEG7_SCAN_FREQ must wihin (0, board::CLK_FREQ], but got %0d", SEG7_SCAN_FREQ);
    end

    // 每个数位持续的周期数
    localparam int unsigned CYCLES_PER_DIGIT = board::CLK_FREQ / SEG7_SCAN_FREQ;

    logic scan_en;
    logic [1:0] scan_digit;

    // 分频
    clk_div #(.DIVISOR(CYCLES_PER_DIGIT)) u_scan_div (
        .cr(cr),
        .en(scan_en)
    );

    // 推进 scan_digit
    step_cnt #(.CNT_STATES(4)) u_scan_cnt (
        .cr(cr),
        .en(scan_en),
        .step(scan_digit)
    );

    // EGO1 routes digits 0..3 to ss1, and digits 4..7 to ss0.
    assign seg.seg7_ss1 = seg.seg_sels[{1'b0, scan_digit}];
    assign seg.seg7_ss0 = seg.seg_sels[{1'b1, scan_digit}];
    assign seg.seg7_cs = 8'h11 << scan_digit;
endmodule
