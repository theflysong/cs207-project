//! 基础信号类型，供模块接口复用。
package baselib;
    typedef struct packed {
        logic sig;
        // positive edge
        logic pos;
        // negative edge
        logic neg;
    } sig_t;

    typedef enum logic {
        SEG7_CATHODE = 1'b0,
        SEG7_ANODE   = 1'b1
    } seg7_polarity_e;

    function automatic int s_clog2(int n);
        return (n > 1) ? $clog2(n) : 1;
    endfunction
endpackage
