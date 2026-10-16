# FPGA Implementation Progress

This note records the implementation and verification evidence currently available for the custom 8-bit RISC-V-inspired processor. It distinguishes source inspection, saved Vivado reports, previously recorded simulations, and owner-reported board observations.

## Milestones

- The architectural baseline defines an 8-bit datapath, 16-bit fixed instructions, eight registers, and a single-cycle CPU with the twelve instructions listed in the root README. This is not a standards-compliant RISC-V implementation.
- Git history shows RTL milestones for instruction/data memories, control, datapath integration, CPU top, and expanded CPU integration coverage on 2026-10-07.
- The current local PYNQ-Z2 wrapper exports `debug_x3[3:0]` to the four LEDs. The current local demo image computes `x3=15`, performs a store/load, and loops at word address 5.
- Saved Vivado synthesis/implementation artifacts and a generated bitstream are present in the local working directory. The Vivado project, wrapper, and XDC are untracked; generated reports and the bitstream are ignored and uncommitted. None are included in the documentation-only Git changes.

## Architecture and demonstration behavior

`pynq_z2_top` instantiates the CPU with `programs/cpu_top_test.mem`. The first five instruction words are `1205`, `140A`, `0650`, `3614`, and `2814`: they initialize `x1=5`, `x2=10`, compute `x3=15`, store 15 at data-memory address 20, and load that value into `x4`. Subsequent `51FF` words execute `JAL x0,-1`, keeping the PC at address 5 without changing `x3`.

CPU reset is active-high and synchronous. On a rising edge with reset asserted, PC and `x1`–`x7` clear. `x0` remains hardwired to zero. Instruction ROM and data RAM are not reset; data RAM contents persist through CPU reset.

## Simulation evidence

Previously recorded project results report passing unit testbenches for the register file, ALU, immediate generator, instruction decoder, program counter, instruction memory, data memory, and control unit. Recorded integration results are datapath: 46 checks; CPU: 83 checks; CPU top: 22 checks. The FPGA wrapper was also previously reported to compile with Icarus Verilog.

These are historical results supplied in the project handoff. No per-run simulation log was found in the repository. During this documentation task, I attempted to rerun the suite: the invocation printed a pass for the immediate-generator test, but the complete sweep did not finish. Direct Icarus compile attempts exited with Windows status `-1073741819` (`0xC0000005`, access violation). Therefore this documentation update does not claim a fresh full-suite pass; rerun the tests in the user's VS Code terminal after resolving or restarting the local Icarus process/tool installation.

To rerun the CPU-top test from the repository root:

```powershell
iverilog -g2005 -Wall -s cpu_top_tb -o cpu_top_tb.out rtl/cpu.v rtl/instruction_memory.v rtl/datapath.v rtl/instruction_decoder.v rtl/control_unit.v rtl/register_file.v rtl/immediate_generator.v rtl/alu.v rtl/program_counter.v rtl/data_memory.v testbench/cpu_top_tb.v
vvp .\cpu_top_tb.out
```

The expected testbench completion line from the previously recorded run is `CPU TOP TEST PASSED: 22 checks`.

## Vivado reports

The local Vivado project is `fpga/pynq z2/pynq_z2_cpu/pynq_z2_cpu.xpr`. Its configuration names `pynq_z2_top` as the synthesis top and targets `xc7z020clg400-1`. The saved reports identify Vivado 2026.1.

Saved synthesis utilization (`pynq_z2_top_utilization_synth.rpt`):

| Resource | Reported use |
|---|---:|
| Slice LUTs | 108 (76 logic, 32 memory) |
| LUTs used as distributed RAM | 32 |
| Slice registers / flip-flops | 32 |
| Block RAM tiles | 0 |
| DSPs | 0 |
| Bonded I/Os | 6 |

Saved routed timing summary (`pynq_z2_top_timing_summary_routed.rpt`): 8.00 ns clock period (125 MHz), WNS 0.200 ns, TNS 0, WHS 0.265 ns, THS 0, and no setup or hold failing endpoints. This is evidence from the saved report dated 2026-10-14, not a new Vivado run performed for this documentation task.

The existing bitstream is `fpga/pynq z2/pynq_z2_cpu/pynq_z2_cpu.runs/impl_1/pynq_z2_top.bit`. Vivado's implementation log records successful routing and bitstream generation. The bitstream and generated run directory should not be committed as source.

## Board mapping and physical observation

The local XDC assigns `sysclk` to H16 with an 8.00 ns clock constraint, `btn_reset` (BTN0) to D19, and `led[0]` through `led[3]` to R14, P14, N16, and M14 respectively. No XDC edits were made as part of this documentation update.

The project owner reports that on 2026-10-16 the bitstream was programmed onto the PYNQ-Z2: the DONE LED illuminated, all four user LEDs displayed `1111` during the demo self-loop, holding BTN0 turned them off, and releasing BTN0 restarted execution and restored `1111`. These are owner-reported physical observations. They are distinct from the Icarus tests and Vivado reports, and do not establish independent hardware verification of every instruction or internal state transition.

## Current limitations and follow-up

- The wrapper's `INIT_FILE` currently uses an absolute Windows path (`D:/8 Bit Risc V PC Project/programs/cpu_top_test.mem`), which is not portable to another checkout location or machine.
- The saved timing report has 0.200 ns positive worst setup slack at 125 MHz; timing should be checked again after any RTL or constraint change.
- The arrays use LUT resources and the saved synthesis report shows no block RAM inference. This is consistent with the current implementation and does not by itself indicate a failure.
- The FPGA source and project files are not committed. Review and commit the project source files separately if the repository is expected to reproduce the FPGA build. Keep generated runs, reports, and bitstreams out unless there is a specific release/evidence requirement.
- Resolve the local Icarus compiler crash and rerun all unit and integration testbenches. Keep simulation, synthesis-report, and physical-board evidence labeled separately in future updates.
