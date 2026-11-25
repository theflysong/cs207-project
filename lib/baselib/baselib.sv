// 公共常量和纯函数. 段码位序为 {dp, g, f, e, d, c, b, a}.
package baselib;
    localparam int SEG7_WIDTH = 8;
    localparam int HEX_DIGIT_WIDTH = 4;
    localparam [HEX_DIGIT_WIDTH - 1:0] BCD_MAX_DIGIT = 4'd9;
    localparam SEG7_CATHODE = 1'b0;
    localparam SEG7_ANODE = 1'b1;

    // 统一保存高有效段码, 小数点默认关闭.
    localparam [SEG7_WIDTH - 1:0] SEG7_BLANK = 8'h00;
    localparam [SEG7_WIDTH - 1:0] SEG7_0 = 8'h3f;
    localparam [SEG7_WIDTH - 1:0] SEG7_1 = 8'h06;
    localparam [SEG7_WIDTH - 1:0] SEG7_2 = 8'h5b;
    localparam [SEG7_WIDTH - 1:0] SEG7_3 = 8'h4f;
    localparam [SEG7_WIDTH - 1:0] SEG7_4 = 8'h66;
    localparam [SEG7_WIDTH - 1:0] SEG7_5 = 8'h6d;
    localparam [SEG7_WIDTH - 1:0] SEG7_6 = 8'h7d;
    localparam [SEG7_WIDTH - 1:0] SEG7_7 = 8'h07;
    localparam [SEG7_WIDTH - 1:0] SEG7_8 = 8'h7f;
    localparam [SEG7_WIDTH - 1:0] SEG7_9 = 8'h6f;
    localparam [SEG7_WIDTH - 1:0] SEG7_A = 8'h77;
    localparam [SEG7_WIDTH - 1:0] SEG7_B = 8'h7c;
    localparam [SEG7_WIDTH - 1:0] SEG7_C = 8'h39;
    localparam [SEG7_WIDTH - 1:0] SEG7_D = 8'h5e;
    localparam [SEG7_WIDTH - 1:0] SEG7_E = 8'h79;
    localparam [SEG7_WIDTH - 1:0] SEG7_F = 8'h71;

    // 计数器至少需要 1 位, 包括只有一个计数值的情况.
    function automatic int count_width(input [63:0] states);
        count_width = (states > 1) ? $clog2(states) : 1;
    endfunction

    // 十六进制数字转高有效段码, 未知输入显示为空白.
    function automatic [SEG7_WIDTH - 1:0] hex_to_seg7(input [HEX_DIGIT_WIDTH - 1:0] digit);
        case (digit)
            4'h0: hex_to_seg7 = SEG7_0;
            4'h1: hex_to_seg7 = SEG7_1;
            4'h2: hex_to_seg7 = SEG7_2;
            4'h3: hex_to_seg7 = SEG7_3;
            4'h4: hex_to_seg7 = SEG7_4;
            4'h5: hex_to_seg7 = SEG7_5;
            4'h6: hex_to_seg7 = SEG7_6;
            4'h7: hex_to_seg7 = SEG7_7;
            4'h8: hex_to_seg7 = SEG7_8;
            4'h9: hex_to_seg7 = SEG7_9;
            4'ha: hex_to_seg7 = SEG7_A;
            4'hb: hex_to_seg7 = SEG7_B;
            4'hc: hex_to_seg7 = SEG7_C;
            4'hd: hex_to_seg7 = SEG7_D;
            4'he: hex_to_seg7 = SEG7_E;
            4'hf: hex_to_seg7 = SEG7_F;
            default: hex_to_seg7 = SEG7_BLANK;
        endcase
    endfunction
endpackage
