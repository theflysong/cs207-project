package driver;
    // 非打包的组、位维度，避免与 64 位向量隐式互连。
    typedef struct {
        logic [7:0] seg_sels [0:1][0:3];
    } seg7_input_t;

    typedef struct packed {
        logic [1:0][7:0] seg7_ss;
        logic [1:0][3:0] seg7_cs;
    } seg7_output_t;
endpackage
