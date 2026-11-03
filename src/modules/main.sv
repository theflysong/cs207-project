module main #(
    parameter integer DEBOUNCE_TIME = 20_000_000,
    parameter integer SEG7_SCAN_FREQ = 4000
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  sw,
    input  wire [4:0]  btn,
    output wire [7:0]  seg7_ss0,
    output wire [7:0]  seg7_ss1,
    output wire [7:0]  seg7_cs
);
    // 对 btn[2] 进行消抖
    wire btn2_debpos;

    pulse_debounce #(
        .CLK_FREQ       (board::CLK_FREQ),
        .DEBOUNCE_TIME  (DEBOUNCE_TIME)
    ) u_btn2_deb (
        .clk            (clk),
        .rst_n          (rst_n),
        .pulse          (btn[2]),
        .deb_pulse      (),
        .deb_posedge    (btn2_debpos),
        .deb_negedge    ()
    );

    logic [31:0] __cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            __cnt <= 32'd0;
        else if (btn2_debpos)
            __cnt <= __cnt + 32'd1;
    end

    // 将 __cnt 转换为 BCD 码, 再转换为 7 段数码管的段选信号

    // 32 位无符号数最大为 4294967295，需要完整的 10 位 BCD。
    // 板上只有 8 位数码管，显示十进制低 8 位。
    localparam integer BCD_DIGITS = 10;
    localparam integer BCD_WIDTH = 4 * BCD_DIGITS;

    wire [BCD_DIGITS-1:0][3:0] __bcd_code;
    wire [7:0] __seg_sels [0:1][0:3];

    bin2bcd_u #(
        .BIN_WIDTH  (32),
        .BCD_WIDTH  (BCD_WIDTH)
    ) u_bin2bcd (
        .bin_in  (__cnt),
        .bcd_out (__bcd_code)
    );

    for (genvar bank = 0; bank < 2; bank++) begin : gen_bank
        for (genvar digit = 0; digit < 4; digit++) begin : gen_digit
            bcd2seg7_u #(.polarity(SEG7_CATHODE)) u_seg7 (
                .bcd_in   (__bcd_code[bank*4 + digit]),
                .seg7_out (__seg_sels[bank][digit])
            );
        end
    end

    // 将段选信号送入 7 段数码管驱动模块

    wire baselib::clk_rst_t __clk_rst;
    driver::seg7_input_t __seg_in;
    wire driver::seg7_output_t __seg_out;

    assign __clk_rst = '{clk: clk, rst_n: rst_n};
    always_comb begin
        for (int bank = 0; bank < 2; bank++)
            for (int digit = 0; digit < 4; digit++)
                __seg_in.seg_sels[bank][digit] = __seg_sels[bank][digit];
    end

    assign seg7_ss0 = __seg_out.seg7_ss[1];
    assign seg7_ss1 = __seg_out.seg7_ss[0];
    assign seg7_cs[3:0] = __seg_out.seg7_cs[0];
    assign seg7_cs[7:4] = __seg_out.seg7_cs[1];

    drv_seg7 #(
        .SEG7_SCAN_FREQ (SEG7_SCAN_FREQ)
    ) u_driver (
        .clk_rst (__clk_rst),
        .seg_in  (__seg_in),
        .seg_out (__seg_out)
    );
endmodule
