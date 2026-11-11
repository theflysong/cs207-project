module main #(
    parameter int DEBOUNCE_TIME = 20_000_000,
    parameter int SEG7_SCAN_FREQ = 4_000
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] sw,
    input  wire [4:0] btn,
    output wire [7:0] seg7_ss0,
    output wire [7:0] seg7_ss1,
    output wire [7:0] seg7_cs
);
    // 时钟接口
    clk_if cr (
        .clk(clk),
        .rst_n(rst_n)
    );

    // 按键消抖 + 边沿检测
    baselib::sig_t btn_sig;
    pulse_debounce #(
        .CLK_FREQ(board::CLK_FREQ),
        .DEBOUNCE_TIME(DEBOUNCE_TIME)
    ) u_debounce (
        .cr(cr),
        .pulse(btn[0]),
        .debsig(btn_sig)
    );

    // 七段数码管接口与驱动
    seg7_if seg (
        .seg7_cs(seg7_cs),
        .seg7_ss0(seg7_ss0),
        .seg7_ss1(seg7_ss1)
    );

    drv_seg7 #(.SEG7_SCAN_FREQ(SEG7_SCAN_FREQ)) u_drv_seg7 (
        .cr(cr),
        .seg(seg)
    );

    traffic_light_e light;

    traffic_light u_traffic_light (
        .cr(cr),
        .sig(btn_sig),
        .light(light)
    );

    traffic_light_2_seg7 #(.polarity(baselib::SEG7_CATHODE)) u_light2seg7 (
        .light(light),
        .seg7_out(seg.seg_sels[0])
    );

    always_comb begin
        // 清空 1~7 数位
        for (int digit = 1; digit < 8; digit++)
            seg.seg_sels[digit] = 8'h00;
    end
endmodule
