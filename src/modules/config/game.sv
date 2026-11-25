package game;
    // 每个格子宽度为 4 位
    localparam int GRID_WIDTH = 4;
    // 棋盘上有 9 个格子, 3x3 排列
    localparam int LAYOUT_GRIDS = 9;
    localparam int LAYOUT_WIDTH = 3;
    localparam int LAYOUT_HEIGHT = 3;
    // 布局类型
    typedef logic [GRID_WIDTH - 1:0] layout_t [LAYOUT_GRIDS - 1:0];
endpackage