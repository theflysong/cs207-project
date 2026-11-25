# CS207 FPGA 项目

当前顶层根据 EGO1 第 0 个按键的消抖电平选择数值, 从数码管的个位开始显示十进制数, 高位空白. Vivado 的构建目标名为 `huarongdao`, HDL 顶层为 `main`.

## 构建环境

安装 Python 3.11+ 和 Vivado, 将 Vivado 的 `bin` 目录加入 PATH. 以下命令在项目根目录的 PowerShell 中运行.

```powershell
git submodule update --init --recursive
python FPGA-Buildsys/main.py install .
.\buildsys.bat init-venv
.\buildsys.bat toolchain vivado
```

Bash 用户可用 `python3` 和 `./buildsys` 运行相同命令.

## 仿真与构建

```powershell
.\buildsys.bat xpr-simulation step_cnt
.\buildsys.bat xpr-simulation bin2bcd
.\buildsys.bat xpr-synthesis huarongdao
.\buildsys.bat xpr-implementation huarongdao
.\buildsys.bat xpr-bitstream huarongdao
```

仿真检查计数及消抖边界, 以及 BCD 转换和段码极性. 通过的仿真会输出对应的 `PASS` 标记, 生成工程和日志位于 `build/vivado/cs207/`.

开发流程和 HDL 规范见 [AGENTS.md](AGENTS.md) 和 [STYLE.md](STYLE.md). 两份指南, HDL 文件和 XDC 约束使用 GBK 编码.
