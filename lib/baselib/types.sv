//! 基础信号类型，供模块接口复用。
package baselib;
    typedef struct packed {
        logic clk;
        logic rst_n;
    } clk_rst_t;
endpackage
