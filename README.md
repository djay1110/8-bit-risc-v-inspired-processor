# 8-bit RISC-V-Inspired Processor

An educational custom 8-bit processor inspired by RISC-V concepts. It is **not standard RISC-V compliant**. The approved architecture baseline is documented in the [Architecture Specification v1.0](docs/Architecture_Specification_v1.0.md).

## Project navigation

- [Architecture Specification](docs/Architecture_Specification_v1.0.md)
- [Instruction Set](docs/Architecture_Specification_v1.0.md#b-final-instruction-encoding-table)
- [Processor Block Diagram](docs/Architecture_Specification_v1.0.md#d-final-datapath-description)
- [RTL Modules](#rtl-modules)
- [Testbenches](#testbenches)
- [Demonstration Programs](docs/Architecture_Specification_v1.0.md#demonstration-program-expectations) (assembly examples; `.mem` images not created yet)
- [Verification Results](#verification-status)
- [FPGA Implementation](#fpga-implementation)

## RTL modules

| Module | Description | RTL | Testbench | Status |
|---|---|---|---|---|
| Register File | 8 × 8-bit registers, two combinational read ports, one synchronous write port, hardwired-zero `x0` | [register_file.v](rtl/register_file.v) | [register_file_tb.v](testbench/register_file_tb.v) | **Verified** |
| ALU | 8-bit arithmetic and logic unit | Not started | Not started | Not Started |
| Immediate Generator | Extracts and extends instruction immediates | Not started | Not started | Not Started |
| Instruction Decoder | Decodes instruction fields | Not started | Not started | Not Started |
| Program Counter / Next-PC Logic | PC state and sequential/branch/jump selection | Not started | Not started | Not Started |
| Instruction Memory | 256 × 16-bit instruction words | Not started | Not started | Not Started |
| Data Memory | 256 × 8-bit data bytes | Not started | Not started | Not Started |
| Control Unit | Generates architectural control signals | Not started | Not started | Not Started |
| Datapath / CPU | Integration stages | Not started | Not started | Not Started |

## Testbenches

| Testbench | Module under test | Status |
|---|---|---|
| [register_file_tb.v](testbench/register_file_tb.v) | [register_file.v](rtl/register_file.v) | **Verified** |

Run the register-file simulation from the project root in a PowerShell terminal:

```powershell
iverilog -g2005 -Wall -s register_file_tb -o register_file_tb.out rtl/register_file.v testbench/register_file_tb.v
vvp .\register_file_tb.out
```

Expected final message: `REGISTER FILE TEST PASSED`.

## Verification status

| Module | Simulation result | Evidence |
|---|---|---|
| Register File | **PASS** — all testbench checks passed with Icarus Verilog; no compiler warnings or errors | [testbench](testbench/register_file_tb.v), [RTL](rtl/register_file.v) |
| Other modules | Not started | — |

## Demonstration programs

The approved architecture document contains the arithmetic/memory and loop assembly examples. Program image files under `programs/` will be added in the demonstration-program phase.

## FPGA implementation

**Not Started.** FPGA-specific files and timing evaluation are deferred until the processor passes functional simulation.

## Repository structure

```text
README.md
rtl/register_file.v
testbench/register_file_tb.v
docs/Architecture_Specification_v1.0.md
.gitignore
```

The architecture specification is authoritative for processor behavior. Update this page whenever modules or verification status change. Do not claim a module is Verified based only on successful compilation; its testbench must demonstrate the specified behavior.
