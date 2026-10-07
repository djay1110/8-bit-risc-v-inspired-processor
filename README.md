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
| ALU | 8-bit arithmetic and logic unit | [alu.v](rtl/alu.v) | [alu_tb.v](testbench/alu_tb.v) | **Verified** |
| Immediate Generator | Sign-extends the shared 6-bit immediate/branch offset and exposes the signed 9-bit JAL offset | [immediate_generator.v](rtl/immediate_generator.v) | [immediate_generator_tb.v](testbench/immediate_generator_tb.v) | **Verified** |
| Instruction Decoder | Extracts opcode/register fields and flags reserved encodings | [instruction_decoder.v](rtl/instruction_decoder.v) | [instruction_decoder_tb.v](testbench/instruction_decoder_tb.v) | **Verified** |
| Program Counter / Next-PC Logic | Synchronous PC register plus 10-bit signed target arithmetic and PC selection | [program_counter.v](rtl/program_counter.v) | [program_counter_tb.v](testbench/program_counter_tb.v) | **Verified** |
| Instruction Memory | 256 × 16-bit ROM, combinational read, `.mem` initialization | [instruction_memory.v](rtl/instruction_memory.v) | [instruction_memory_tb.v](testbench/instruction_memory_tb.v) | **Verified** |
| Data Memory | 256 × 8-bit array, combinational read, synchronous write, no reset | [data_memory.v](rtl/data_memory.v) | [data_memory_tb.v](testbench/data_memory_tb.v) | **Verified** |
| Control Unit | Maps opcode/funct3 to ALU, writeback, memory, and PC controls; suppresses illegal side effects | [control_unit.v](rtl/control_unit.v) | [control_unit_tb.v](testbench/control_unit_tb.v) | **Verified** |
| Datapath | Integrates decoder, control, register file, immediate generator, ALU, writeback, and PC logic; memories connect through ports | [datapath.v](rtl/datapath.v) | [datapath_tb.v](testbench/datapath_tb.v) | **Verified** |
| CPU Top | Connects datapath with instruction and data memories | Not started | Not started | Not Started |

## Testbenches

| Testbench | Module under test | Status |
|---|---|---|
| [register_file_tb.v](testbench/register_file_tb.v) | [register_file.v](rtl/register_file.v) | **Verified** |
| [alu_tb.v](testbench/alu_tb.v) | [alu.v](rtl/alu.v) | **Verified** |
| [immediate_generator_tb.v](testbench/immediate_generator_tb.v) | [immediate_generator.v](rtl/immediate_generator.v) | **Verified** |
| [instruction_decoder_tb.v](testbench/instruction_decoder_tb.v) | [instruction_decoder.v](rtl/instruction_decoder.v) | **Verified** |
| [program_counter_tb.v](testbench/program_counter_tb.v) | [program_counter.v](rtl/program_counter.v) | **Verified** |
| [instruction_memory_tb.v](testbench/instruction_memory_tb.v) | [instruction_memory.v](rtl/instruction_memory.v) | **Verified** |
| [data_memory_tb.v](testbench/data_memory_tb.v) | [data_memory.v](rtl/data_memory.v) | **Verified** |
| [control_unit_tb.v](testbench/control_unit_tb.v) | [control_unit.v](rtl/control_unit.v) | **Verified** |
| [datapath_tb.v](testbench/datapath_tb.v) | [datapath.v](rtl/datapath.v), with [data_memory.v](rtl/data_memory.v) | **Verified** |

Run the register-file simulation from the project root in a PowerShell terminal:

```powershell
iverilog -g2005 -Wall -s register_file_tb -o register_file_tb.out rtl/register_file.v testbench/register_file_tb.v
vvp .\register_file_tb.out
```

Expected final message: `REGISTER FILE TEST PASSED`.

Run the ALU simulation from the project root:

```powershell
iverilog -g2005 -Wall -s alu_tb -o alu_tb.out rtl/alu.v testbench/alu_tb.v
vvp .\alu_tb.out
```

Expected final message: `ALU TEST PASSED`.

Run the immediate-generator simulation from the project root:

```powershell
iverilog -g2005 -Wall -s immediate_generator_tb -o immediate_generator_tb.out rtl/immediate_generator.v testbench/immediate_generator_tb.v
vvp .\immediate_generator_tb.out
```

Expected final message: `IMMEDIATE GENERATOR TEST PASSED`.

Run the instruction-decoder simulation from the project root:

```powershell
iverilog -g2005 -Wall -s instruction_decoder_tb -o instruction_decoder_tb.out rtl/instruction_decoder.v testbench/instruction_decoder_tb.v
vvp .\instruction_decoder_tb.out
```

Expected final message: `INSTRUCTION DECODER TEST PASSED`.

Run the program-counter/next-PC simulation from the project root:

```powershell
iverilog -g2005 -Wall -s program_counter_tb -o program_counter_tb.out rtl/program_counter.v testbench/program_counter_tb.v
vvp .\program_counter_tb.out
```

Expected final message: `PROGRAM COUNTER TEST PASSED`.

Run the instruction-memory simulation from the project root:

```powershell
iverilog -g2005 -Wall -s instruction_memory_tb -o instruction_memory_tb.out rtl/instruction_memory.v testbench/instruction_memory_tb.v
vvp .\instruction_memory_tb.out
```

Expected final message: `INSTRUCTION MEMORY TEST PASSED`.

Run the data-memory simulation from the project root:

```powershell
iverilog -g2005 -Wall -s data_memory_tb -o data_memory_tb.out rtl/data_memory.v testbench/data_memory_tb.v
vvp .\data_memory_tb.out
```

Expected final message: `DATA MEMORY TEST PASSED`.

Run the control-unit simulation from the project root:

```powershell
iverilog -g2005 -Wall -s control_unit_tb -o control_unit_tb.out rtl/control_unit.v testbench/control_unit_tb.v
vvp .\control_unit_tb.out
```

Expected final message: `CONTROL UNIT TEST PASSED`.

Run the datapath-integration simulation from the project root:

```powershell
iverilog -g2005 -Wall -s datapath_tb -o datapath_tb.out rtl/datapath.v rtl/instruction_decoder.v rtl/control_unit.v rtl/register_file.v rtl/immediate_generator.v rtl/alu.v rtl/program_counter.v rtl/data_memory.v testbench/datapath_tb.v
vvp .\datapath_tb.out
```

Expected final message: `DATAPATH TEST PASSED: 45 checks`.

## Verification status

| Module | Simulation result | Evidence |
|---|---|---|
| Register File | **PASS** — all testbench checks passed with Icarus Verilog; no compiler warnings or errors | [testbench](testbench/register_file_tb.v), [RTL](rtl/register_file.v) |
| ALU | **PASS** — all 13 test cases passed with Icarus Verilog; no compiler warnings or errors | [testbench](testbench/alu_tb.v), [RTL](rtl/alu.v) |
| Immediate Generator | **PASS** — all 7 field extraction/sign-extension cases passed with Icarus Verilog; no compiler warnings or errors | [testbench](testbench/immediate_generator_tb.v), [RTL](rtl/immediate_generator.v) |
| Instruction Decoder | **PASS** — all 23 field/validity cases passed with Icarus Verilog; no compiler warnings or errors | [testbench](testbench/instruction_decoder_tb.v), [RTL](rtl/instruction_decoder.v) |
| Program Counter / Next-PC Logic | **PASS** — all 14 sequential and combinational PC checks passed with Icarus Verilog; no compiler warnings or errors | [testbench](testbench/program_counter_tb.v), [RTL](rtl/program_counter.v) |
| Instruction Memory | **PASS** — all 5 combinational ROM reads passed with Icarus Verilog; no compiler warnings or errors | [testbench](testbench/instruction_memory_tb.v), [RTL](rtl/instruction_memory.v), [test image](programs/instruction_memory_test.mem) |
| Data Memory | **PASS** — all 12 write-timing, combinational-read, address, and persistence checks passed with Icarus Verilog; no compiler warnings or errors | [testbench](testbench/data_memory_tb.v), [RTL](rtl/data_memory.v) |
| Control Unit | **PASS** — all 15 instruction/control and illegal-suppression cases passed with Icarus Verilog; no compiler warnings or errors | [testbench](testbench/control_unit_tb.v), [RTL](rtl/control_unit.v) |
| Datapath | **PASS** — all 45 integration checks passed with Icarus Verilog; no compiler warnings or errors | [testbench](testbench/datapath_tb.v), [RTL](rtl/datapath.v) |
| Other modules | Not started | — |

## Demonstration programs

The approved architecture document contains the arithmetic/memory and loop assembly examples. [instruction_memory_test.mem](programs/instruction_memory_test.mem) is a unit-test ROM image; demonstration program images will be added in the demonstration-program phase.

## FPGA implementation

**Not Started.** FPGA-specific files and timing evaluation are deferred until the processor passes functional simulation.

## Repository structure

```text
README.md
rtl/register_file.v
rtl/alu.v
rtl/immediate_generator.v
rtl/instruction_decoder.v
rtl/program_counter.v
rtl/instruction_memory.v
rtl/data_memory.v
rtl/control_unit.v
rtl/datapath.v
testbench/register_file_tb.v
testbench/alu_tb.v
testbench/immediate_generator_tb.v
testbench/instruction_decoder_tb.v
testbench/program_counter_tb.v
testbench/instruction_memory_tb.v
testbench/data_memory_tb.v
testbench/control_unit_tb.v
testbench/datapath_tb.v
docs/Architecture_Specification_v1.0.md
.gitignore
```

The architecture specification is authoritative for processor behavior. Update this page whenever modules or verification status change. Do not claim a module is Verified based only on successful compilation; its testbench must demonstrate the specified behavior.
