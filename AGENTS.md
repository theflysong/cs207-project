# CS207 FPGA 项目开发指南

## 重要要求: 只使用半角标点

- 所有标点必须使用 ASCII 半角形式. 中文内容也必须遵守.
- 适用于新增或修改的代码, 注释, 文档, 提交说明, 日志, 错误消息及智能体回复.
- 使用 `, . : ; ! ? ( ) [ ] " '` 等半角标点, 不使用中文顿号, 中文句号, 弯引号或全角括号.
- 完成修改前检查并清除本次新增或修改文本中的非 ASCII 标点. 历史文件的标点习惯不能作为例外.

本文适用于当前仓库. 工作流程, 项目结构和验证要求集中于本文件. 命名, HDL 语法及模块注释规范见 [STYLE.md](STYLE.md).

## 工作原则

- 修改前阅读本文件, STYLE.md, 目标目录内适用的 AGENTS.md, 相邻源码及相关配置. 子目录指南仅适用于其子树.
- 以当前源码, `configuration.toml` 和构建工具实际支持的命令为准. `.vscode/AGENTS.md` 与 `.vscode/STYLE.md` 是文档组织参考, 其中 Rust 项目的目录和规则不适用于本项目.
- 新增说明和代码注释使用中文, 保留必要的英文术语及标识符, 标点一律半角.
- HDL 源码, 头文件, testbench 和 XDC 约束统一使用 GBK 读写. AGENTS.md 和 STYLE.md 也使用 GBK 编码. 修改前确认目标文件的编码, 保存后检查中文注释是否可正常读取.
- 只修改任务涉及的文件, 保留用户和其他人的未提交改动. 未经请求, 不提交, 回退或覆盖无关修改.
- 修改源文件, 配置或生成器, 不手工修补 `build/` 下的生成产物或生成的构建入口.
- 修改模块接口, 参数或信号极性时, 同时更新实例化位置, 模块头注释, 相关仿真及约束. 顶层端口与 XDC 必须一致.
- 优先复用 `lib/baselib/` 中职责合适的实现. 复用前检查其语法是否符合 STYLE.md, 不能因历史实现存在就继续扩散不允许的语法.

## 当前目录与职责

| 路径 | 职责 |
| --- | --- |
| `configuration.toml` | 公共项目配置, 源码目录, FPGA 器件与构建目标 |
| `src/modules/main.sv` | 当前顶层模块 `main`, 连接板级输入输出与功能模块 |
| `src/modules/config/ego1.sv` | EGO1 的 `board` package, 提供 `board::CLK_FREQ` 等板级常量 |
| `src/modules/driver/` | 数码管等板级外设驱动 |
| `src/modules/traffic_light.sv` 和 `src/modules/traffic_light_2_seg7.sv` | 交通灯示例状态机和显示译码 |
| `sim/` | 独立的 Vivado 回归仿真, 包含计数及消抖边界和转换测试 |
| `src/constraints/xilinx.xdc` | EGO1 引脚和电气约束, 修改前核对顶层端口与开发板资料 |
| `lib/baselib/` | 计数, 分频, 消抖, 边沿检测及编码转换等公共 HDL |
| `FPGA-Buildsys/` | 独立 Git 子模块, 提供 Python 构建入口和工具链任务 |
| `.buildsys/` | 本地工具链选择及本机设置, 不是公共源码 |
| `build/` | 源码清单, Vivado 工程, 中间文件和构建产物 |
| `.vscode/` | 编辑器配置, 参考文档及历史实验, 不属于当前配置的源码目录 |

当前配置的根 id 为 `cs207`, FPGA id 为 `ego1`, 器件为 `xc7a35tcsg324-1`, project id 为 `huarongdao`, 顶层符号为 `main`. 目标命令使用 `huarongdao`, 不能把 FPGA id 或顶层名称当作 project id.

## 必须保持的 HDL 约束

- 有业务含义的常量尽可能定义为 `parameter` 后引用. 内部派生值使用 `localparam`, 不重复散落魔数.
- 状态机使用 `enum logic` 定义状态. 需要命名状态类型时使用 `typedef enum logic`, 不用独立整数参数代替状态枚举.
- 采用 C 风格命名: 普通标识符为 `snake_case`, 参数和枚举值为 `UPPER_SNAKE_CASE`. 模块实例按 `u_<type>_<cnt>` 命名, 如 `u_step_cnt_0`.
- 每个模块在声明前写中文说明, 逐项解释所有端口和 parameter 的用途. 同一文件有多个模块时分别书写, 没有参数时明确写 `参数: 无.`.
- EGO1 时钟频率统一读取 `board::CLK_FREQ`. 不在其他模块重复写入板载时钟频率数值.
- 以 Verilog-2005 为基础, SystemVerilog 扩展仅允许 `logic`, `enum`, `int`, 固定大小的多维数组, 以及枚举和固定大小数组的 `typedef`. package 可承载常量, 函数和固定大小数组的类型别名. 具体允许范围与替代写法见 STYLE.md.
- `interface`, `modport`, `struct`, `always_ff`, `always_comb` 等历史写法不属于允许范围. 本次任务未涉及的历史代码不要求机械重写, 新增及主动改写的实现必须遵守规则. 若模块迁移需要调整调用方, 应将相关接口一起迁移, 不能留下不兼容的连接.

## 构建与源码收集

构建入口是 `FPGA-Buildsys/main.py`, 要求 Python 3.11+. Windows 通常使用根目录的 `buildsys.bat`, Bash 使用 `./buildsys`. Vivado 需安装并加入 PATH, Python 依赖由子模块的 `requirements.txt` 管理.

以下命令均在项目根目录执行:

| PowerShell 命令 | 行为 |
| --- | --- |
| `git submodule update --init --recursive` | 首次检出时初始化子模块, 已有本地修改时先检查状态 |
| `python FPGA-Buildsys/main.py install .` | 安装或刷新根目录的快捷入口 |
| `.\buildsys.bat init-venv` | 在构建子模块中初始化 Python 虚拟环境并安装依赖 |
| `.\buildsys.bat toolchain` | 查询本项目选择的工具链 |
| `.\buildsys.bat toolchain vivado` | 选择 Vivado, 结果保存在本地设置中 |
| `.\buildsys.bat model` | 扫描源码目录并生成路径清单, 不检查 HDL 语法或依赖 |
| `.\buildsys.bat xpr` | 导出包含全部已配置目标的共享 Vivado 工程, 不接收目标 id |
| `.\buildsys.bat xpr-synthesis huarongdao` | 对当前 project 执行 Vivado 综合 |
| `.\buildsys.bat xpr-implementation huarongdao` | 执行 Vivado 实现 |
| `.\buildsys.bat xpr-bitstream huarongdao` | 生成当前 project 的比特流 |

- 当前构建子模块使用 `nopyslang` 分支. 修改子模块前检查其分支和工作区状态, 不擅自覆盖本地修改或切换回旧实现.
- `directories.sources` 当前为 `src/modules/` 和 `lib/`. 构建系统递归收集其中全部 `.sv` 与 `.v` 文件, 按相对路径排序并去重, 不建立符号索引或依赖图, 不按顶层可达性筛选源码.
- 不把临时模块, 重复定义, 旧版本源码或测试替身放进上述目录. 不依赖未被实例化来避开编译问题.
- 新增 package 时必须验证工具实际采用的编译顺序. Vivado 会更新编译顺序, 其他前端不能假定存在自动依赖排序.
- `configuration.toml` 将 `sim/` 配置为仿真目录, 仿真目标 id 为 `step_cnt` 和 `bin2bcd`. 使用 `xpr-simulation <simulation-id>` 运行对应回归.
- `build` 始终使用 Icarus, `simulate` 按所选工具链路由. 不使用当前 CLI 不支持的 `simulation` 或 `vivado-simulation` 命令名.
- 通用 `synthesis`, `implementation`, `bitstream`, `program` 按所选工具链路由. 修改源码后的综合或仿真不等于已经完成硬件烧录和板上验证.
- Vivado 阶段会检查源码清单及配置快照, 必要时重新导出共享工程. 生成工程位于 `build/vivado/cs207/`, 不直接编辑其中的 XPR 或生成 Tcl.
- `clean` 和 `cleandist` 仅用于明确需要的产物清理, 不作为修复源码或诊断失败的默认步骤.

## 验证要求

按修改范围选择验证. `model` 成功只能证明文件路径收集成功, 不能证明语法, 状态机行为, 时序或引脚正确.

| 修改范围 | 应执行的验证 |
| --- | --- |
| Markdown 文档 | 检查半角标点, 相对链接, 示例语法, 命令与当前实现的一致性, 执行 `git diff --check`, 无需构建 |
| 普通 HDL 逻辑 | 检查 GBK 编码, 受限语法, 模块头注释和命名, 对受影响目标执行编译或综合, 按行为变化运行仿真 |
| 状态机, 计数, 分频或消抖 | 验证复位, 状态转换, 使能, 计数边界及参数边界, 检查周期数与实际频率 |
| 顶层连接或 XDC | 检查 GBK 编码, 核对端口方向, 位宽, 引脚与有效电平, 执行相关综合和实现检查 |
| 时钟或跨时钟域逻辑 | 检查时钟来源, 同步链, 复位释放和时序约束, 不能仅凭功能仿真判断安全 |
| FPGA-Buildsys 子模块 | 在子模块内执行与修改相称的 Python 测试, 检查源码清单及生成任务, 使用其虚拟环境 |

- 测试验证可观察行为和边界, 避免照抄实现. testbench 同样遵守受限 SystemVerilog 语法和半角标点要求.
- 新增时序逻辑说明所属时钟域, 复位方式与输出延迟. 状态机说明非法状态恢复策略.
- 失败时区分代码错误, 工具缺失, 不支持的语法及硬件环境限制. 不删除检查或放宽语法规则来获得通过.
- 最终说明包含修改内容, 已完成验证及未验证的关键部分. 子模块改动与主仓库改动分别说明.

## 文档索引

- [STYLE.md](STYLE.md): 命名, 常量, 受限语法, 状态机和模块注释规范.
- [configuration.toml](configuration.toml): 当前源码目录, 器件和构建目标.
- [FPGA-Buildsys/README.md](FPGA-Buildsys/README.md): 构建系统和工具链说明, 命令以当前 CLI 为准.
- 项目环境, 仿真与构建命令见 [README.md](README.md).
