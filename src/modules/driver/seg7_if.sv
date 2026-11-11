//! 八位数码管的段选和片选接口.
//! seg_sels[i] 为第 i 个数码管的段选信号
//! seg_cs[i] 为第 i 个数码管的片选信号
//! 数码管编号从右到左为 0-7
//! ss0 和 ss1 分别连接到 EGO1 的两个物理数码管总线
//! 分别负责第 0-3 位和第 4-7 位数码管的段选信号
interface seg7_if (
    output logic [7:0] seg7_cs,
    output logic [7:0] seg7_ss0,
    output logic [7:0] seg7_ss1
);
    logic [7:0] seg_sels [0:7];

    // Display logic only supplies the eight digit patterns.
    modport source (
        output seg_sels
    );

    modport drv (
        input  seg_sels,
        output seg7_cs, seg7_ss0, seg7_ss1
    );
endinterface
