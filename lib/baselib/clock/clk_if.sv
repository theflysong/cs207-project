//! Shared clock and active-low reset, supplied by the enclosing module.
interface clk_if (
    input logic clk,
    input logic rst_n
);
    modport sink (
        input clk, rst_n
    );
endinterface
