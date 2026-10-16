# 8-bit RISC-V-Inspired Processor

An educational custom 8-bit processor implemented in Verilog and demonstrated on a Digilent PYNQ-Z2 FPGA. The design borrows RISC-V ideas but uses a project-specific 16-bit instruction format; it is **not a standards-compliant RISC-V core**.

## Architecture

- 8-bit datapath and 8-bit, word-addressed PC; sequential execution advances by one 16-bit instruction word.
- Eight 8-bit registers (`x0`–`x7`); `x0` reads as zero and ignores writes.
- Fixed 16-bit instructions. Supported operations: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `ADDI`, `LOAD`, `STORE`, `BEQ`, and `JAL`.
- Single-cycle, unpipelined execution.
- 256 × 16-bit combinational instruction ROM and 256 × 8-bit data RAM. Data RAM read is combinational and writes occur on a clock edge.
- Active-high synchronous reset clears the PC and `x1`–`x7`. Neither memory is reset by CPU reset.

The frozen architecture and instruction encodings are described in [Architecture Specification v1.0](docs/Architecture_Specification_v1.0.md).

## Repository layout

```text
rtl/                 Verilog processor modules
testbench/           Unit and CPU integration testbenches
programs/             Instruction-memory .mem images
docs/                 Architecture and implementation notes
fpga/pynq z2/         Local Vivado project, wrapper, and board constraints
```

The current checkout contains the Vivado project at `fpga/pynq z2/pynq_z2_cpu/pynq_z2_cpu.xpr`. The FPGA project sources are local and untracked; generated outputs are ignored. This documentation commit does not add those design or build files to Git. The generated bitstream is also local and is not included in the repository commit.

## Demonstration program

`programs/cpu_top_test.mem` initializes `x1=5`, `x2=10`, calculates `x3=15`, stores the value at data-memory address 20, and loads it into `x4`. At word address 5, `51FF` executes `JAL x0,-1`, a self-loop. The FPGA wrapper exposes `debug_x3[3:0]` on the four user LEDs, so the expected display after the first three instructions is `1111`.

## Running simulations

Run commands from the repository root in PowerShell. Icarus Verilog and `vvp` must be on `PATH`. For example, to run the full CPU-top testbench:

```powershell
iverilog -g2005 -Wall -s cpu_top_tb -o cpu_top_tb.out rtl/cpu.v rtl/instruction_memory.v rtl/datapath.v rtl/instruction_decoder.v rtl/control_unit.v rtl/register_file.v rtl/immediate_generator.v rtl/alu.v rtl/program_counter.v rtl/data_memory.v testbench/cpu_top_tb.v
vvp .\cpu_top_tb.out
```

The testbench loads `programs/cpu_top_test.mem` through the CPU's `INIT_FILE` parameter. The repository also has focused testbenches for each RTL block and `testbench/cpu_tb.v` for CPU program integration.

Previously recorded results include 46 datapath checks, 83 CPU integration checks, and 22 CPU-top checks, plus passing unit testbenches and a successful Icarus compile of `pynq_z2_top`. These are historical results; see [implementation progress](docs/implementation-progress.md) for this documentation pass's rerun status.

## FPGA implementation

The Vivado project targets the Zynq-7000 `xc7z020clg400-1`, with top module `pynq_z2_top`. In Vivado 2026.1, open `fpga/pynq z2/pynq_z2_cpu/pynq_z2_cpu.xpr`; the existing local bitstream is `fpga/pynq z2/pynq_z2_cpu/pynq_z2_cpu.runs/impl_1/pynq_z2_top.bit`.

PYNQ-Z2 pin assignments in `fpga/pynq z2/pynq_z2_master.xdc`:

| Port | Board signal | FPGA package pin |
|---|---|---:|
| `sysclk` | 125 MHz clock | H16 |
| `btn_reset` | BTN0, active high | D19 |
| `led[0]` | User LED 0 | R14 |
| `led[1]` | User LED 1 | P14 |
| `led[2]` | User LED 2 | N16 |
| `led[3]` | User LED 3 | M14 |

The recorded routed timing report uses an 8.00 ns (125 MHz) clock and reports WNS 0.200 ns, WHS 0.265 ns, and zero setup/hold failing endpoints. The synthesis utilization report lists 108 slice LUTs (76 logic, 32 memory), 32 slice registers, 32 LUTs as distributed RAM, zero block RAM tiles, zero DSPs, and 6 bonded I/Os. These figures describe the saved Vivado reports, not a fresh run performed for this documentation update.

## Hardware demonstration

The project owner reports programming the PYNQ-Z2 and observing the DONE LED illuminate, the four user LEDs display `1111` during the self-loop, and BTN0 turn them off while held. Releasing BTN0 causes the program to restart and the LEDs to return to `1111`. These are direct physical observations reported by the owner, not automated or independently observed tests; they do not independently verify every internal processor operation.

## Limitations and next work

- This is a small custom educational ISA, not binary-compatible or standards-compliant RISC-V.
- The processor is single-cycle. The saved routed timing result has only 0.200 ns of positive worst setup slack at 125 MHz; further timing margin should be assessed before adding logic or raising clock frequency.
- Memory inference and mapping are tool-dependent. The saved synthesis report maps memory to LUT resources and uses no block RAM.
- The wrapper currently names the instruction image with an absolute Windows path. Make that initialization path portable before building from another directory or machine.
- The Vivado project, wrapper, and XDC are untracked in the current working tree; generated reports and the bitstream are ignored and uncommitted. Review the source files separately before deciding which should belong in Git; generated build products should remain excluded.
- Future work can improve portability and repeatability, add board-level automated checks, and evaluate timing/resource changes as the design evolves.
