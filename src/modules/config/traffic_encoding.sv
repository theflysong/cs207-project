// 交通灯状态在状态机和段码译码模块之间的传递编码.
package traffic_encoding;
    localparam int LIGHT_WIDTH = 2;
    localparam [LIGHT_WIDTH-1:0] LIGHT_RED_CODE = 2'd0;
    localparam [LIGHT_WIDTH-1:0] LIGHT_YELLOW_CODE = 2'd1;
    localparam [LIGHT_WIDTH-1:0] LIGHT_GREEN_CODE = 2'd2;
endpackage
