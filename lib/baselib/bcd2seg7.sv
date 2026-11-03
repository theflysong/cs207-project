//!bcd2seg7.sv
//!
//!Author: theflysong (song_of_the_fly@163.com)
//!
//!# BCD 转 7-Segment 模块
//!

// 数码管极性: 共阴极=0, 共阳极=1
typedef enum bit {
    SEG7_CATHODE = 1'b0,
    SEG7_ANODE   = 1'b1
} seg7_polarity_e;

//!## BCD 转 7-Segment 单元模块
//!
//!### Parameters
//!
//! - `parameter seg7_polarity_e polarity` : 极性, 默认 SEG7_ANODE
//!
//!### Ports
//!
//! - `input  logic [3:0] bcd_in`  : 1 位 BCD 数
//! - `output logic [7:0] seg7_out`: 1 组段选信号
//!
module bcd2seg7_u #(
    parameter seg7_polarity_e polarity = SEG7_ANODE
)(
    input  logic [3:0] bcd_in,
    output logic [7:0] seg7_out
);

    // 共阴极编码: 1=点亮, 0=熄灭. 位序: abcdefg_dp
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
            default: return 8'b0000_0000; // 非 BCD 输入, 全部熄灭
        endcase
    endfunction

    always_comb begin
        seg7_out = encode(bcd_in);
        if (polarity == SEG7_ANODE) seg7_out = ~seg7_out;
    end

endmodule


//!## N 位 BCD 转 7-Segment 模块
//!
//!### Parameters
//!
//! - `parameter int N`                    : 数码管位数, 默认 4
//! - `parameter seg7_polarity_e polarity` : 极性, 默认 SEG7_ANODE
//!
//!### Ports
//!
//! - `input  logic [N-1:0][3:0] bcd_in`  : N 路 BCD, 索引 0 为最低位
//! - `output logic [N-1:0][7:0] seg7_out`: N 组段选, 与 bcd_in 一一对应
//!
module bcd2seg7 #(
    parameter int N = 4,
    parameter seg7_polarity_e polarity = SEG7_ANODE
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
