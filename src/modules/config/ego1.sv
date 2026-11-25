// EGO1 板级时钟与数码管常量.
package board;
    localparam int CLK_FREQ = 100_000_000;

    // 两组物理段选总线各连接 4 位数码管.
    localparam int SEG7_DIGITS_PER_BANK = 4;
    localparam int SEG7_DIGIT_COUNT = 2 * SEG7_DIGITS_PER_BANK;

    // 按数码管编号索引一组段码, 每位数码管的段码位宽由 baselib 定义.
    localparam int SEG7_WIDTH = baselib::SEG7_WIDTH;
    typedef logic [SEG7_DIGIT_COUNT - 1:0][SEG7_WIDTH - 1:0] seg7_patterns_t;

    localparam int LED_COUNT = 8;
    localparam int SW_COUNT  = 8;
    localparam int BTN_COUNT = 5;
endpackage
