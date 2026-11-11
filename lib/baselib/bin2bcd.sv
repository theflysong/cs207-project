//! 二进制转 BCD. BIN_WIDTH 为输入位宽, BCD_DIGITS 为 BCD 数位数.
module bin2bcd_u #(
    parameter int BIN_WIDTH = 8,
    parameter int BCD_DIGITS = 3
)(
    input  logic [BIN_WIDTH-1:0] bin_in,
    output logic [4 * BCD_DIGITS - 1 : 0] bcd_out
);

    initial begin
        if ($pow(2, BIN_WIDTH) > $pow(10, BCD_DIGITS))
            $fatal(1, "bin2bcd_u: BIN_WIDTH=%0d too large for BCD_DIGITS=%0d",
                   BIN_WIDTH, BCD_DIGITS);
    end

    always_comb begin
        logic [4 * BCD_DIGITS - 1 : 0] bcd;
        logic [BIN_WIDTH-1:0] bin;

        bcd = '0;
        bin = bin_in;

        // Double dabble: 每位 >= 5 时加 3, 然后左移 1 bit.
        for (int i = 0; i < BIN_WIDTH; i++) begin
            for (int k = 0; k < BCD_DIGITS; k++) begin
                if (bcd[k*4 +: 4] >= 4'd5)
                    bcd[k*4 +: 4] += 4'd3;
            end
            bcd = (bcd << 1) | bin[BIN_WIDTH-1];
            bin = bin << 1;
        end

        bcd_out = bcd;
    end
endmodule

//! N 路独立转换, 每路输出 BCD_DIGITS 位 BCD.
module bin2bcd #(
    parameter int N         = 4,
    parameter int BIN_WIDTH = 8,
    parameter int BCD_DIGITS = 3
)(
    input  logic [N-1:0][BIN_WIDTH-1:0] bin_in,
    output logic [N-1:0][4 * BCD_DIGITS - 1 : 0] bcd_out
);

    for (genvar i = 0; i < N; i++) begin : gen_bcd
        bin2bcd_u #(
            .BIN_WIDTH(BIN_WIDTH),
            .BCD_DIGITS(BCD_DIGITS)
        ) u_bin2bcd (
            .bin_in  (bin_in[i]),
            .bcd_out (bcd_out[i])
        );
    end

endmodule
