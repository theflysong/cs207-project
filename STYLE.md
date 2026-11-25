# CS207 FPGA 代码风格与模块接口规范

## 重要要求: 只使用半角标点

- 所有标点必须使用 ASCII 半角形式. 中文内容也必须遵守.
- 适用于代码, 注释, 文档, 提交说明, 日志, 错误消息和智能体回复.
- 使用 `, . : ; ! ? ( ) [ ] " '` 等半角标点, 不使用中文顿号, 中文句号, 弯引号或全角括号.
- 新增和修改文本必须在完成前检查. 不沿用历史文件中的全角标点.

本文与 [AGENTS.md](AGENTS.md) 配合使用. 规则适用于新增和主动改写的代码. 历史文件不是语法许可清单, 无关代码不做机械重写.

## 格式与组织

- HDL 源码 (`.v`, `.sv`), 头文件 (`.vh`, `.svh`), testbench 和 XDC 约束 (`.xdc`) 使用 GBK 编码. 以 GBK 打开和保存这些文件, 确认中文注释可正常读取.
- AGENTS.md 和 STYLE.md 也使用 GBK 编码. 新增文件使用 LF 行尾, 末尾保留换行, 不留行尾空白. 修改旧文件时避免无关的全文件编码和排版变动.
- HDL 使用 4 空格缩进, 不使用 Tab. `begin` 与控制语句同一行, `end` 与所属块对齐, 多行分支显式使用 `begin` 和 `end`.
- 二元运算符与左右操作数之间各留一个空格, 位宽和下标表达式也遵守此规则. 例如 `a + b`, `a == b` 和 `[WIDTH - 1:0]`.
- 新增 HDL 使用 `.sv` 后缀, 但只使用本文允许的语言范围. 不能以文件后缀或工具支持为由扩大语法范围.
- 模块围绕单一职责组织. 板级连接留在顶层或驱动, 通用计数与转换逻辑放在职责匹配的公共模块中.
- 优先每个文件一个主要模块. 同一文件声明多个模块时, 每个模块都必须有独立的模块头注释.
- 参数覆盖与端口连接使用显式命名, 不使用位置连接, `.*` 或 `.port` 隐式连接.

## 命名规范

采用 C 风格命名, 普通名称小写加下划线, 常量大写加下划线.

| 对象 | 规则 | 示例 |
| --- | --- | --- |
| 源文件, 目录, 模块, package | `snake_case` | `pulse_debounce.sv`, `step_cnt`, `board` |
| 端口, 信号, 变量, 函数 | `snake_case` | `rst_n`, `scan_digit`, `cycles_from_ns` |
| `parameter`, `localparam`, package 常量 | `UPPER_SNAKE_CASE` | `DEBOUNCE_TIME_NS`, `CNT_WIDTH`, `CLK_FREQ` |
| 枚举和数组类型别名 | `snake_case` 加 `_t` | `state_t`, `layout_t` |
| 枚举值 | `UPPER_SNAKE_CASE`, 带含义前缀 | `STATE_IDLE`, `STATE_RUN`, `LIGHT_RED` |
| 模块实例 | `u_<type>_<cnt>` | `u_step_cnt_0`, `u_pulse_debounce_0`, `u_drv_seg7_1` |
| generate 块 | `gen_<purpose>` | `gen_digit`, `gen_channel` |
| testbench 模块与文件 | `tb_<module>` | `tb_step_cnt.sv`, `tb_step_cnt` |

- 实例名中的 `type` 为被实例化模块的完整名称, `cnt` 为当前作用域内同类型实例从 `0` 开始的十进制序号. 即使只有一个实例也保留 `_0`.
- generate 循环中可以重复使用 `u_step_cnt_0`, 由 `gen_channel[i].u_step_cnt_0` 区分层级, 不要求把运行时或展开索引拼入标识符.
- 低有效信号使用 `_n`, 如 `rst_n`, `button_n`. 时钟频率, 时间和计数参数应说明单位, 优先使用 `_HZ`, `_NS`, `_CYCLES` 等后缀. 既有公共名称 `board::CLK_FREQ` 保持不变, 单位为 Hz.
- 当前状态和下一状态分别命名为 `state` 和 `next_state`. 名称反映用途, 避免 `tmp1`, `data2` 等缺少语义的名称.
- 已有外部端口和约束不能只为命名统一而单独改名. 必须调整时同步修改所有调用方和 XDC.

实例化写法:

```verilog
step_cnt #(
    .CNT_STATES(DIGIT_COUNT)
) u_step_cnt_0 (
    .clk(clk),
    .rst_n(rst_n),
    .en(scan_en),
    .step(scan_digit)
);
```

`step_cnt` 通过显式端口接收时钟, 复位和使能.

## 常量与参数

- 有业务含义或重复使用的常量尽可能定义为 `parameter`, 并在声明, 比较, 运算及实例参数中引用. 位宽, 通道数, 扫描频率, 消抖时间, 编码表和协议常量不能散落为魔数.
- 允许外部覆盖的配置放入模块参数列表. 仅供内部使用的固定值和派生值使用 `localparam`, 不把内部位宽或计数终值暴露成可随意覆盖的配置.
- 明确参数类型, 位宽, 单位, 默认值和有效范围. 整数配置可使用 `parameter int`; 位模式使用明确宽度的 `parameter` 或 `localparam`.
- 表示复位清零, 单比特真假或加一操作的 `1'b0`, `1'b1` 等基础字面量可以直接使用. 具有协议或硬件含义的值仍应命名. 枚举值直接在 enum 中定义, 不再维护一组重复的状态 parameter.
- 数值常量的位宽和进制应与用途一致. 不依赖隐式截断, 符号扩展或无尺寸常量碰巧得到正确结果.
- `int` 为 32 位有符号类型. 频率与时间换算应检查中间乘法是否溢出, 必要时使用明确宽度的向量和常量, 不引入语法白名单之外的整数类型.
- 参数允许值为 `1` 时, 派生计数位宽至少为 `1`. 明确除法取整规则, 计数起止值及实际输出周期, 避免除零, 负位宽和计数差一.

例如:

```verilog
parameter int SCAN_FREQ_HZ = 4_000;
localparam int SCAN_CYCLES = board::CLK_FREQ / SCAN_FREQ_HZ;
localparam int CNT_WIDTH = (SCAN_CYCLES > 1) ? $clog2(SCAN_CYCLES) : 1;
localparam [CNT_WIDTH - 1:0] LAST_CYCLE = SCAN_CYCLES - 1;
```

这些派生值的前置条件为 `1 <= SCAN_FREQ_HZ <= board::CLK_FREQ`. 定义常量后, 实际逻辑也应引用这些名称, 不能只声明而继续使用原始数值.

## 板级时钟与时序

- EGO1 的板载时钟频率只在 [src/modules/config/ego1.sv](src/modules/config/ego1.sv) 的 `board` package 中定义. 其他模块通过 `board::CLK_FREQ` 读取, 当前单位为 Hz.
- 板级扫描, 延时, 消抖和计数周期由该常量推导, 不在其他源码中重复写入 `100_000_000` 或等价的板载频率字面量.
- 通用模块确需可配置时钟频率时, 可以保留 `CLK_FREQ` 参数. EGO1 的实例化必须使用 `.CLK_FREQ(board::CLK_FREQ)`, 或以 `board::CLK_FREQ` 作为板级默认值.
- 分频后或来自独立时钟源的逻辑按实际时钟频率计算, 不把 `board::CLK_FREQ` 当成所有时钟域的频率.
- 优先以主时钟加时钟使能控制低速行为. 需要新时钟域时明确时钟资源, 跨域同步和时序约束, 不能直接把普通计数位当作任意可用的时钟.
- 外部按键和开关进入同步逻辑前处理跨域采样. 消抖不能替代同步链. 注释说明复位极性, 同步或异步方式, 以及复位释放要求.
- XDC 中的时钟约束必须与板级频率一致. XDC 是 Tcl, 不假定其能够直接求值 HDL 的 `board::CLK_FREQ`.

## 允许的语言范围

以 Verilog-2005 为基础, 仅允许以下 SystemVerilog 扩展. 此规则同时适用于设计源码和 testbench.

| 允许项 | 范围 |
| --- | --- |
| `logic` | 普通变量, 单驱动信号, 端口和 enum 底层向量. 需要 net 语义时使用 `wire` |
| `enum` | 使用 `enum logic` 声明枚举, 可用 `typedef` 命名枚举类型 |
| `int` | 参数, 局部整数及循环变量, 注意其宽度和有符号语义 |
| `package` | 承载常量, 函数和固定大小的数组类型别名, 通过 `package_name::member` 显式访问 |
| 固定大小的多维数组 | 允许 packed 和 unpacked 维度, 可用于模块内部和端口, 可用 `typedef` 命名数组类型 |

- `typedef` 用于命名 `enum logic` 或固定大小的数组类型. 数组的元素类型和维度遵守上述规则.
- package 中不放共享可变变量. 普通纯函数使用 Verilog 风格函数返回值赋值, 不使用 SystemVerilog 的 `return`.
- 禁止 `interface`, `modport`, `struct`, `union`, `class`, `program`, clocking block, 动态数组, 队列, 关联数组, mailbox, semaphore, 约束随机化及 SVA.
- 禁止 `always_ff`, `always_comb`, `always_latch`, `unique`, `priority`, `foreach`, `inside`, `ref`, `const` 等额外语法. 时序使用 `always @(posedge clk ...)`, 组合使用 `always @*`.
- 禁止 `bit`, `byte`, `shortint`, `longint`, `string` 等额外类型. 模块内部可使用 Verilog 已支持的固定大小 memory.
- 固定大小的多维数组声明可写成 `logic [3:0][7:0] channel_data;` 或 `logic [7:0] pixel_data [0:1][0:3];`.
- 禁止赋值模式 `'{...}`, 类型或尺寸转换 `type'(expr)` 和 `WIDTH'(expr)`, 无尺寸单比特填充值 `'0` 与 `'1`, 自增自减 `++` 与 `--`, 复合赋值 `+=` 等额外操作符.
- 使用普通拼接和重复拼接, 如 `{WIDTH{1'b0}}`; 使用 `i = i + 1` 和 `value = value + delta`. 宽度转换通过明确位宽的声明, 位选或拼接实现.
- 使用显式端口传递数据, 按数据布局选择打平向量或固定大小的数组. 不通过 `include`, 宏或 package 包装来隐藏被禁止的语法.
- Verilog 已有的 `wire`, `reg`, `integer`, `parameter`, `localparam`, `generate`, `genvar`, `function`, `task`, `assign`, `always` 等可以继续使用. `logic` 或 `int` 合适时优先使用, 不能把普通 Verilog 结构误判为新增许可.
- 仿真诊断使用 Verilog 已有的 `$display` 和 `$finish` 等设施, 不新增 `$fatal`, `$error` 或 SystemVerilog assertion. 工具能够编译某种语法不代表本项目允许使用.

package 中的数组类型可用于信号和端口声明. 例如 `game::layout_t layout;` 和 `input game::layout_t layout`.

```systemverilog
package game;
    localparam int GRID_WIDTH = 4;
    localparam int LAYOUT_GRIDS = 9;

    typedef logic [GRID_WIDTH - 1:0] layout_t [LAYOUT_GRIDS - 1:0];
endpackage
```

## 状态机与组合逻辑

- 所有状态机使用 `enum logic` 声明状态, 指明足以表达全部状态的位宽. 状态名称和编码保持一致, 不用普通 logic 总线加 parameter 状态码代替枚举.
- 状态类型通常在所属模块内定义. 跨模块传递状态时通过明确宽度的普通端口和具名编码约定连接.
- 状态寄存器使用时序 `always` 和非阻塞赋值 `<=`, 下一状态及组合输出使用 `always @*` 和阻塞赋值 `=`.
- 组合块先给默认值, 再按条件覆盖. `case` 保留 `default`, 明确非法状态恢复目标, 防止锁存器和无意保持.
- 复位直接赋枚举成员. 状态转换只赋合法枚举成员, 不依赖类型强制转换, 数值加一或未定义编码切换.
- 同一寄存器只由一个时序块驱动. 不对同一信号混用连续赋值与过程赋值.

状态声明和更新示例, 位于模块内部:

```verilog
typedef enum logic [1:0] {
    STATE_IDLE = 2'd0,
    STATE_RUN = 2'd1,
    STATE_DONE = 2'd2
} state_t;

state_t state;
state_t next_state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= STATE_IDLE;
    end else begin
        state <= next_state;
    end
end

always @* begin
    next_state = state;
    case (state)
        STATE_IDLE: begin
            if (start) begin
                next_state = STATE_RUN;
            end
        end
        STATE_RUN: begin
            if (done) begin
                next_state = STATE_DONE;
            end
        end
        STATE_DONE: begin
            next_state = STATE_IDLE;
        end
        default: begin
            next_state = STATE_IDLE;
        end
    endcase
end
```

## 每个模块必须具备的注释

- 每个模块声明前必须有中文模块头注释, 包括同一文件中的辅助模块和 testbench. 标点只能为 ASCII 半角形式.
- 说明模块职责, 所属时钟域, 复位方式, 关键行为和输出延迟.
- 逐项写出全部 parameter 的名称, 用途, 默认值, 单位或编码及有效范围. 内部 localparam 在定义附近说明派生关系及用途.
- 逐项写出全部端口的名称, 输入或输出方向, 位宽含义, 有效电平, 采样时机及协议语义. 对无关项目明确说明, 不用空泛的 "输入信号" 代替实际用途.
- 没有参数时明确写 `参数: 无.`. 没有端口的 testbench 写 `端口: 无.`.
- 注释与当前声明保持一致, 不保留已经移除的端口名或过时的位宽. 不添加虚构作者, 日期或变更记录.

注释模板示例:

```verilog
// 模块: tick_counter.
// 功能: en 为高时递增, 达到周期终值时回到零.
// 时钟与复位: clk 上升沿采样, rst_n 为异步低有效复位.
// 参数:
// - PERIOD_CYCLES: 计数周期数, 单位为 clk 周期, 默认 4, 有效范围为 1..2^30.
// 端口:
// - clk: 输入, 1 位工作时钟.
// - rst_n: 输入, 1 位异步低有效复位, 拉低时清零计数值.
// - en: 输入, 1 位高有效计数使能, 在 clk 上升沿采样, 为低时保持.
// - count: 输出, 计数值, 位宽为 max(1, ceil(log2(PERIOD_CYCLES))).
//   取值从 0 到 PERIOD_CYCLES - 1, 在 clk 上升沿更新, 复位后为零.
module tick_counter #(
    parameter int PERIOD_CYCLES = 4
) (
    input wire clk,
    input wire rst_n,
    input wire en,
    output logic [((PERIOD_CYCLES > 1) ? $clog2(PERIOD_CYCLES) : 1) - 1:0] count
);
    // 计数终值, 从 PERIOD_CYCLES 推导, 不允许单独覆盖.
    localparam int LAST_COUNT = PERIOD_CYCLES - 1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 1'b0;
        end else if (en) begin
            if (count == LAST_COUNT) begin
                count <= 1'b0;
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule
```

## 文档与验证风格

- Markdown 使用有效的相对链接, 带语言标记的代码块和符合当前 CLI 的命令. 文档示例也遵守语法与标点规则.
- 仿真覆盖复位, 使能暂停, 边界回绕, 状态转换和有意义的参数边界, 观察输出行为与时序.
- 内部实现细节变化不应导致无关测试失效. 不为简单文档或排版修改新增行为测试.
- 修改注释时检查其参数和端口清单与声明逐项对应. 修改常量或时钟计算时检查位宽, 单位, 中间溢出及取整误差.
