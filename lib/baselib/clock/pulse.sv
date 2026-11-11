//!pulse.v
//!
//!Author: theflysong (song_of_the_fly@163.com)
//!
//!# 脉冲源相关
//!

//!## 脉冲边沿对齐模块
//!
//!### Parameters
//!
//!### Ports
//!
//! - `input wire clk` : 时钟信号
//! - `input wire rst_n` : 低有效复位信号
//! - `input wire pulse` : 脉冲信号
//! - `output wire posedge_pulse` : 上升沿脉冲信号
//! - `output wire negedge_pulse` : 下降沿脉冲信号
//!
//!### Description
//!
//!对脉冲信号进行边缘检测, 使其与时钟信号对齐, 生成上升沿和下降沿脉冲信号.
//!
module pulse_edge_align (
    clk_if.sink cr,
    input logic pulse,
    output baselib::sig_t sig
);
    // 上一个时钟周期的脉冲信号
    logic pulse_d;

    always_ff @(posedge cr.clk or negedge cr.rst_n) begin
        if (!cr.rst_n)
            pulse_d <= 1'b0;
        else
            pulse_d <= pulse;
    end

    logic pulse_pos, pulse_neg;
    assign pulse_pos = pulse & ~pulse_d; // 上升沿检测
    assign pulse_neg = ~pulse & pulse_d; // 下降沿检测
    assign sig = '{sig: pulse, pos : pulse_pos, neg : pulse_neg};
endmodule

//!## 脉冲边沿消抖模块
//!
//!### Parameters
//!
//! - `parameter integer CLK_FREQ`: clk 信号的频率(Hz)
//! - `parameter integer DEBOUNCE_TIME`: 消抖时长(ns)
//!
//!### Ports
//!
//! - `input wire clk` : 时钟信号
//! - `input wire rst_n` : 低有效复位信号
//! - `input wire pulse` : 脉冲信号
//! - `output wire deb_pulse` :   消抖后脉冲信号
//! - `output wire deb_posedge` : 上升沿脉冲信号
//! - `output wire deb_negedge` : 下降沿脉冲信号
//!
//!### Description
//!
//!对脉冲信号进行消抖与边缘检测, 使其与时钟信号对齐.
//!
module pulse_debounce#(
    parameter int CLK_FREQ,
    parameter int DEBOUNCE_TIME
) (
    clk_if.sink cr,
    input logic pulse,
    output baselib::sig_t debsig
);
    localparam int DEBOUNCE_CYCLES = (DEBOUNCE_TIME / 1_000) * (CLK_FREQ / 1_000) / 1_000;
    // 用 $clog2 自动推导计数器位宽，避免固定 32 位浪费资源
    localparam int CNT_WIDTH       = $clog2(DEBOUNCE_CYCLES + 1);

    //--- 电平型消抖 ---
    logic deb_pulse;
    logic [CNT_WIDTH-1:0] cnt;

    always_ff @(posedge cr.clk or negedge cr.rst_n) begin
        if (!cr.rst_n) begin
            cnt       <= 31'd0;
            deb_pulse <= 1'b0;
        end
        else if (pulse == deb_pulse)
            cnt <= 31'd0;
        else if (cnt == DEBOUNCE_CYCLES - 1) begin
            deb_pulse <= pulse;
            cnt       <= 31'd0;
        end
        else
            cnt <= cnt + 1'b1;
    end

    // 脉冲对齐
    pulse_edge_align u_edge(
        .cr(cr),
        .pulse(deb_pulse),
        .sig(debsig)
    );

endmodule