//!bin2bcd.sv
//!
//!Author: theflysong (song_of_the_fly@163.com)
//!
//!# BCD 相关模块
//!
//!本文件包含两个模块:
//!

//!## 二进制转 BCD 单元模块
//!
//!### Parameters
//!
//! - `parameter int BIN_WIDTH` : 输入位宽, 默认 8 (范围 0..255)
//! - `parameter int BCD_WIDTH` : 输出位宽, 默认 12 (3 位 BCD)
//!
//! Static Assertion: 2^BIN_WIDTH <= 10^ceil(BCD_WIDTH/4)
//!
//!### Ports
//!
//! - `input  logic [BIN_WIDTH-1:0] bin_in` : 二进制输入
//! - `output logic [BCD_WIDTH-1:0] bcd_out`: BCD 输出
//!
module bin2bcd_u #(
    parameter int BIN_WIDTH = 8,
    parameter int BCD_WIDTH = 12
)(
    input  logic [BIN_WIDTH-1:0] bin_in,
    output logic [BCD_WIDTH-1:0] bcd_out
);

    // Static Assertion: 2^BIN_WIDTH <= 10^ceil(BCD_WIDTH/4)
    initial begin
        if ($pow(2, BIN_WIDTH) > $pow(10, (BCD_WIDTH + 3) / 4))
            $fatal(1, "bin2bcd_u: BIN_WIDTH=%0d too large for BCD_WIDTH=%0d",
                   BIN_WIDTH, BCD_WIDTH);
    end

    always_comb begin
        logic [BCD_WIDTH-1:0] bcd;
        logic [BIN_WIDTH-1:0] bin;

        bcd = '0;
        bin = bin_in;

        for (int i = 0; i < BIN_WIDTH; i++) begin
            // 对每个 BCD 位判断是否 >=5, 是则加 3
            for (int k = 0; k < BCD_WIDTH/4; k++) begin
                if (bcd[k*4 +: 4] >= 4'd5)
                    bcd[k*4 +: 4] += 4'd3;
            end
            // 整体左移 1 位, bin 的最高位进入 bcd 的最低位
            bcd = (bcd << 1) | bin[BIN_WIDTH-1];
            bin = bin << 1;
        end

        bcd_out = bcd;
    end
endmodule


//!## N 路二进制转 BCD 模块
//!
//!### Parameters
//!
//! - `parameter int N`         : 路数, 默认 4
//! - `parameter int BIN_WIDTH` : 每路输入位宽, 默认 8
//! - `parameter int BCD_WIDTH` : 每路输出位宽, 默认 12
//!
//!### Ports
//!
//! - `input  logic [N-1:0][BIN_WIDTH-1:0] bin_in` : N 路二进制输入
//! - `output logic [N-1:0][BCD_WIDTH-1:0] bcd_out`: N 路 BCD 输出, 与 bin_in 一一对应
//!
//!### Description
//!
//!例化 N 个 bin2bcd_u
//!
module bin2bcd #(
    parameter int N         = 4,
    parameter int BIN_WIDTH = 8,
    parameter int BCD_WIDTH = 12
)(
    input  logic [N-1:0][BIN_WIDTH-1:0] bin_in,
    output logic [N-1:0][BCD_WIDTH-1:0] bcd_out
);

    for (genvar i = 0; i < N; i++) begin : gen_bcd
        bin2bcd_u #(
            .BIN_WIDTH(BIN_WIDTH),
            .BCD_WIDTH(BCD_WIDTH)
        ) u_bin2bcd (
            .bin_in  (bin_in[i]),
            .bcd_out (bcd_out[i])
        );
    end

endmodule
