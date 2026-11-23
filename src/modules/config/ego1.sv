// EGO1 板级时钟与数码管常量.
package board;
    parameter int CLK_FREQ = 100_000_000;

    // 两组物理段选总线各连接 4 位数码管.
    localparam int SEG7_DIGITS_PER_BANK = 4;
    localparam int SEG7_DIGIT_COUNT = 2 * SEG7_DIGITS_PER_BANK;
endpackage
