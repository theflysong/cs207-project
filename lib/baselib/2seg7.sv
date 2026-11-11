//! 7 段译码. seg7_out[7:0] = {dp, g, f, e, d, c, b, a}, 小数点关闭.
// 共阴极高电平点亮, 共阳极低电平点亮.

//! BCD 单位译码, 非 BCD 输入全灭.
module bcd2seg7_u #(
    parameter baselib::seg7_polarity_e polarity = baselib::SEG7_ANODE
)(
    input  logic [3:0] bcd_in,
    output logic [7:0] seg7_out
);

    function automatic logic [7:0] encode(input logic [3:0] bcd);
        case (bcd)
            4'd0: return 8'b0011_1111;
            4'd1: return 8'b0000_0110;
            4'd2: return 8'b0101_1011;
            4'd3: return 8'b0100_1111;
            4'd4: return 8'b0110_0110;
            4'd5: return 8'b0110_1101;
            4'd6: return 8'b0111_1101;
            4'd7: return 8'b0000_0111;
            4'd8: return 8'b0111_1111;
            4'd9: return 8'b0110_1111;
            default: return 8'b0000_0000;
        endcase
    endfunction

    always_comb begin
        seg7_out = encode(bcd_in);
        if (polarity == baselib::SEG7_ANODE) seg7_out = ~seg7_out;
    end

endmodule

//! N 位 BCD 译码, 下标 0 为最低位.
module bcd2seg7 #(
    parameter int N = 4,
    parameter baselib::seg7_polarity_e polarity = baselib::SEG7_ANODE
)(
    input  logic [N-1:0][3:0] bcd_in,
    output logic [N-1:0][7:0] seg7_out
);

    for (genvar i = 0; i < N; i++) begin : gen_seg
        bcd2seg7_u #(
            .polarity(polarity)
        ) u_seg (
            .bcd_in  (bcd_in[i]),
            .seg7_out(seg7_out[i])
        );
    end

endmodule

//! 十六进制单位译码.
module hex2seg7_u #(
    parameter baselib::seg7_polarity_e polarity = baselib::SEG7_ANODE
) (
    input  logic [3:0] hex_in,
    output logic [7:0] seg7_out
);
    function automatic logic [7:0] encode(input logic [3:0] hex_digit);
        case (hex_digit)
            4'h0: return 8'h3f;
            4'h1: return 8'h06;
            4'h2: return 8'h5b;
            4'h3: return 8'h4f;
            4'h4: return 8'h66;
            4'h5: return 8'h6d;
            4'h6: return 8'h7d;
            4'h7: return 8'h07;
            4'h8: return 8'h7f;
            4'h9: return 8'h6f;
            4'ha: return 8'h77;
            4'hb: return 8'h7c;
            4'hc: return 8'h39;
            4'hd: return 8'h5e;
            4'he: return 8'h79;
            4'hf: return 8'h71;
            default: return 8'h00;
        endcase
    endfunction

    always_comb begin
        seg7_out = encode(hex_in);
        if (polarity == baselib::SEG7_ANODE) seg7_out = ~seg7_out;
    end
endmodule

//! N 位十六进制译码, 下标 0 为最低位.
module hex2seg7 #(
    parameter int N = 4,
    parameter baselib::seg7_polarity_e polarity = baselib::SEG7_ANODE
) (
    input  logic [N-1:0][3:0] hex_in,
    output logic [N-1:0][7:0] seg7_out
);
    for (genvar i = 0; i < N; i++) begin : gen_seg
        hex2seg7_u #(.polarity(polarity)) u_seg (
            .hex_in(hex_in[i]),
            .seg7_out(seg7_out[i])
        );
    end
endmodule
