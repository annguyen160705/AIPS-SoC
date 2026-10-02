# AIPS-SoC — Phase 3: RV32I CPU Subset

**Status:** ✅ COMPLETE (agreed Phase 3 scope)  
**Verified on:** 2 October 2026 (QuestaSim simulation log provided by project owner)  
**Next phase:** Phase 4 — CPU + SRAM Integration

## 1. Goal

Build and verify a small **32-bit RISC-V CPU** that can later control image transfers through the AIPS-SoC memory and peripheral interfaces. Phase 3 establishes a working **12-instruction RV32I subset**; it is **not** a complete RV32I implementation.

## 2. Implemented design

| Module | Purpose |
|---|---|
| `pc.sv` | 32-bit program counter; reset to zero; write `pc_next` when enabled. |
| `decoder.sv` | Extract opcode, `rd`, `rs1`, `rs2`, `funct3` and `funct7`. |
| `immediate_gen.sv` | Generate signed/immediate fields for I, S, B, U and J encodings. |
| `control_unit.sv` | Decode supported instructions into register write, ALU, memory, branch, jump and writeback controls. |
| `regfile.sv` | 32 × 32-bit registers; two combinational read ports and one clocked write port; `x0` remains zero. |
| `alu.sv` | Combinational addition/subtraction and zero flag. |
| `rv32_core.sv` | Single-cycle datapath, branch/jump PC selection and register writeback. |
| `instruction_rom.sv` | Simulation instruction storage: 256 × 32-bit words, indexed by `pc[9:2]`. |
| `data_memory.sv` | Temporary internal data memory: 256 × 32-bit words, supporting LW/SW and signed LB/SB with byte lanes. |
| `rv32_core_tb.sv` | Self-checking tests that reset the CPU and load a separate HEX image per test case. |

**Execution model:** one instruction per rising clock edge in the current RTL, assuming combinational instruction and load data reads. No bus wait states or ready/valid handshakes yet. This is a **functional simulation milestone**, not a synthesis timing or maximum-frequency result.

## 3. Supported instructions

| Group | Instructions | Main behavior |
|---|---|---|
| Arithmetic | `ADD`, `ADDI`, `SUB` | Register/immediate arithmetic. |
| Word memory | `LW`, `SW` | Load/store 32-bit words. |
| Byte memory | `LB`, `SB` | Signed byte load; low-byte store to addressed lane. |
| Branch | `BEQ`, `BNE` | PC-relative conditional branches. |
| Upper immediate | `LUI` | Write upper 20-bit immediate shifted left by 12. |
| Jump | `JAL`, `JALR` | Jump and write return address (`PC + 4`) to `rd`; JALR clears target bit 0. |

**Not yet covered:** the rest of RV32I (including AUIPC, SLT/SLTU, logic/shift instructions, other branches, unsigned loads, halfword loads/stores, system instructions), traps/interrupts, misalignment handling and complete ISA compliance. AUIPC was proposed as an optional extension, but was **not** part of the six confirmed passing tests.

## 4. Memory model and addressing

- Instruction ROM: 256 words = **1 KiB**, with 32-bit instructions addressed at `PC = 0, 4, 8, ...`.
- Temporary data RAM: 256 words = **1 KiB**; effective word index uses address bits `[9:2]`.
- `SB` chooses a byte lane through address bits `[1:0]`.
- `LB` sign-extends the selected byte to 32 bits.
- Register `x0` is always read as zero.
- The testbench uses hierarchical access to clear ROM/RAM and inspect registers; that mechanism is **simulation-only**.

**Integration limitation:** Phase 3 uses a toy, directly attached memory model. It does not implement the mapped AIPS-SoC SRAM address range or the AHB-Lite interface.

### Planned AIPS-SoC address map

| Region | Base address | Intended contents |
|---|---|---|
| SRAM image 1 | `0x1000_0000` | Preloaded 64 × 64, 8-bit grayscale image (4,096 bytes). |
| SRAM image 2 | `0x1000_1000` | UART-received 64 × 64 image (4,096 bytes). |
| SRAM output | `0x1000_2000` | Sobel result for later V2 (4,096 bytes). |
| UART DATA | `0x4000_0000` | UART data register (future peripheral integration). |
| UART STATUS | `0x4000_0004` | Status register (future peripheral integration). |
| UART CONTROL | `0x4000_0008` | Control register (future peripheral integration). |

The three image buffers require **at least 12 KiB** of usable storage, so the Phase 3 1 KiB data RAM is insufficient for the final system.

## 5. Verification

Six independent program-level cases ran in QuestaSim. Each case starts from `PC = 0`, with a reset register file and an appropriate test program; the testbench clears the temporary data memory between cases.

| Test | HEX file | Instructions checked | Observed result |
|---|---|---|---|
| TC1 | `tc1_alu.hex` | ADD, ADDI, SUB | PASS at 66 ns |
| TC2 | `tc2_lw_sw.hex` | LW, SW | PASS at 116 ns |
| TC3 | `tc3_lb_sb.hex` | LB, SB | PASS at 196 ns |
| TC4 | `tc4_branch.hex` | BEQ, BNE | PASS at 276 ns |
| TC5 | `tc5_lui.hex` | LUI | PASS at 306 ns |
| TC6 | `jump_test.hex` | JAL, JALR | PASS at 376 ns |

Reported summary:

```text
[66 ns]  TC1 ALU PASSED
[116 ns] TC2 LW/SW PASSED
[196 ns] TC3 LB/SB PASSED
[276 ns] TC4 BRANCH PASSED
[306 ns] TC5 LUI PASSED
[376 ns] TC6 JAL/JALR PASSED
================================
        CPU TEST SUMMARY
================================
PASS : 6
FAIL : 0
TIME : 376 ns
================================
```

### Representative expected register values

- TC1: `x1 = 10`, `x2 = 20`, `x3 = 30`, `x4 = 20`.
- TC2: `x5 = 99`, `x6 = 99`.
- TC3: `x8 = 127`, `x10 = 0xFFFF_FFFF` (signed -1).
- TC4: `x3 = 20`, `x4 = 7` (both skips taken).
- TC5: `x11 = 0x1000_0000`.
- TC6: `x1 = 8`, `x2 = 20`, `x7 = 7`, `x9 = 9`; skipped destinations `x6`, `x8` remain zero.

**Interpretation:** The user-provided log confirms these six directed tests passed. It does not establish exhaustive instruction verification, full RV32I compliance or hardware timing closure.

## 6. Suggested project layout

```text
AIPS-SoC/
├── rtl/
│   └── cpu/
│       ├── alu.sv
│       ├── control_unit.sv
│       ├── data_memory.sv
│       ├── decoder.sv
│       ├── immediate_gen.sv
│       ├── instruction_rom.sv
│       ├── pc.sv
│       ├── regfile.sv
│       └── rv32_core.sv
├── tb/
│   └── cpu/
│       └── rv32_core_tb.sv
└── firmware/
    └── hex/
        ├── tc1_alu.hex
        ├── tc2_lw_sw.hex
        ├── tc3_lb_sb.hex
        ├── tc4_branch.hex
        ├── tc5_lui.hex
        └── jump_test.hex
```

File names and hierarchical instance names must match the actual repository.

## 7. Run regression in QuestaSim (Windows PowerShell)

From the **project root** (`AIPS-SoC`), where relative HEX paths resolve:

```powershell
vlib work
Get-ChildItem .\rtl\cpu\*.sv | ForEach-Object { vlog $_.FullName }
vlog .\tb\cpu\rv32_core_tb.sv
vsim -c -voptargs=+acc work.rv32_core_tb -do "run -all; quit -f"
```

> PowerShell may not expand `*.sv` in a native `vlog` command: enumerate the files as shown. The `instruction_rom.sv` version used for independent tests should **not** automatically preload `cpu_test.hex`; the testbench loads the selected file with `$readmemh`.

## 8. Phase 3 completion criteria

- [x] CPU datapath and 32-register file implemented.
- [x] 12-instruction RV32I subset integrated.
- [x] Signed byte load and byte store supported in temporary RAM.
- [x] Branch and jump targets/return-address paths tested.
- [x] Independent HEX-based test cases.
- [x] QuestaSim regression: **6 PASS, 0 FAIL**.

**PHASE 3 COMPLETE** — for the explicitly scoped CPU subset and directed tests.

## 9. Next: Phase 4 — CPU + SRAM Integration

1. Replace the temporary 1 KiB RAM assumptions with a correctly decoded SRAM address space large enough for the image buffers.
2. Define CPU memory request/address/write-data/read-data behavior and support byte vs word accesses without losing the tested CPU semantics.
3. Verify reads/writes across the planned image memory regions, including boundaries and byte lanes.
4. Prepare for the following phase's AHB-Lite interconnect; add handshaking/stalls when integrating a bus with wait states.

**Phase 4 is not yet complete.**
