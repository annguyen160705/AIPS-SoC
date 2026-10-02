# AIPS-SoC — Phase 4: CPU + SRAM Integration

**Status:** ✅ COMPLETE  
**Verification:** 9 PASS / 0 FAIL, QuestaSim simulation time **726 ns**  
**Next:** Pre-Phase-5 RTL Error Detection, then Phase 5 — AHB-Lite Integration

## 1. Objective

Connect the custom single-cycle, 32-bit RISC-V CPU (supported RV32I subset) to a **12 KiB byte-addressable SRAM** that can hold three independent 64×64 grayscale images. Validate byte/word loads and stores, image address mapping, and memory boundaries before adding a bus interface.

> **Scope:** This is a direct CPU-to-SRAM behavioral RTL integration, **not yet AHB-Lite**. This CPU implements a tested RV32I subset rather than the entire RV32I ISA.

## 2. Architecture

```text
                  +------------------------+
Instruction ROM ->|     RV32 CPU Core      |
                  |  ALU + Regfile + PC    |
                  +-----------+------------+
                              |
                   address = alu_result
                   data    = rs2_data
                   control = mem_write, funct3
                              |
                              v
                  +------------------------+
                  |   SRAM (12 KiB)        |
                  |   byte-addressable     |
                  |   synchronous writes   |
                  |   combinational reads  |
                  +------------------------+
                              |
                      read_data (32-bit)
                              |
                      CPU register writeback
```

### SRAM interface

| Port | Width | Meaning |
|---|---:|---|
| `clk` | 1 | Clock; write at positive edge |
| `address` | 32 | CPU byte address |
| `write_data` | 32 | Store data from `rs2` |
| `mem_write` | 1 | Enables a store operation |
| `funct3` | 3 | `000` = LB/SB; `010` = LW/SW |
| `read_data` | 32 | Read value returned to CPU |

**Implemented behavior:**
- `SB`: writes `write_data[7:0]` to one addressed byte.
- `SW`: writes four bytes in **little-endian** order; writes are guarded against crossing the SRAM upper boundary.
- `LB`: reads one byte with **sign extension** from 8 to 32 bits.
- `LW`: concatenates four bytes in little-endian order into a 32-bit word.
- Out-of-range reads return `0`; out-of-range writes are ignored (behavior of this simplified model).
- **Assumption:** Word accesses are 4-byte aligned. Misaligned accesses are not architecturally handled by this basic SRAM model; add explicit checks in the pre-Phase-5 error-detection pass.

## 3. Address map

The SRAM base is `32'h1000_0000`; total size is **12,288 bytes** (`0x3000`), with address range `0x1000_0000` through `0x1000_2FFF` inclusive.

| Region | Start address | End address | Byte offsets | Capacity |
|---|---|---|---|---:|
| Image 1 | `0x1000_0000` | `0x1000_0FFF` | 0–4095 | 4096 B |
| Image 2 | `0x1000_1000` | `0x1000_1FFF` | 4096–8191 | 4096 B |
| Sobel output (reserved for V2) | `0x1000_2000` | `0x1000_2FFF` | 8192–12287 | 4096 B |
| First invalid address | `0x1000_3000` | — | 12288 (out of range) | — |

Each image has `64 × 64 × 1 byte = 4096 bytes`.

SRAM indexing uses:

```systemverilog
localparam logic [31:0] BASE_ADDR = 32'h1000_0000;
localparam int MEM_SIZE = 12288;
logic [7:0] mem [0:MEM_SIZE-1];
logic [31:0] offset;
logic valid_addr;

assign offset = address - BASE_ADDR;
assign valid_addr = (address >= BASE_ADDR) &&
                    (address < BASE_ADDR + MEM_SIZE);
```

Thus `0x1000_1000 -> mem[4096]` and `0x1000_2000 -> mem[8192]`.

## 4. RTL integration

### Files

- `rtl/memory/sram.sv` — 12 KiB, 8-bit-wide storage elements; CPU-facing 32-bit access.
- `rtl/cpu/rv32_core.sv` — instantiates `sram u_sram` instead of the former `data_memory` module.
- `rtl/cpu/instruction_rom.sv` — instruction fetch at `mem[pc[9:2]]`; the testbench manages test-program loading.
- `tb/cpu/rv32_core_tb.sv` — resets the CPU, clears SRAM/ROM, loads each test program, and checks architectural results.
- `firmware/hex/` — separately stored machine-code tests.

### SRAM instance

```systemverilog
sram u_sram (
    .clk        (clk),
    .address    (alu_result),
    .write_data (rs2_data),
    .mem_write  (mem_write),
    .funct3     (funct3),
    .read_data  (mem_read_data)
);
```

### Test program setup

Each test must **restart from `PC = 0`** and use the correct SRAM base address. In the testbench `load_program(filename)`:

1. Assert `rst_n = 0` on a safe clock edge.
2. Initialize unused instruction ROM entries to `32'h00000013` (`ADDI x0, x0, 0` / NOP).
3. Clear all 12,288 SRAM bytes.
4. Load the selected HEX program into instruction ROM using `$readmemh(filename, u_rom.mem)`.
5. Hold reset for sufficient clock edges and deassert it on a falling edge.
6. Run exactly the number of instruction cycles required and check results **after `#1`** to allow nonblocking assignments to settle.

For the SRAM initializer:

```systemverilog
for (int i = 0; i < 12288; i++)
    dut.u_sram.mem[i] = 8'h00;
```

**Why TC2/TC3 changed:** Old test programs referenced addresses near `0x00000000`; they were updated with a leading `LUI x1, 0x10000` to form the mapped SRAM base `0x1000_0000`. As a result, their execution counts became **4 cycles for TC2** and **7 cycles for TC3**.

## 5. Directed verification

| Case | Description | What is checked | Result |
|---|---|---|---|
| TC1 | ADD / ADDI / SUB | ALU computation and register writes | PASS |
| TC2 | LW / SW | Word write and read at SRAM base | PASS |
| TC3 | LB / SB | Byte write and signed byte read | PASS |
| TC4 | BEQ / BNE | Conditional branch control | PASS |
| TC5 | LUI | `x11 = 0x1000_0000` | PASS |
| TC6 | JAL / JALR | Jump targets, saved `PC + 4` | PASS |
| TC7 | SRAM write/read | `SB/LB` and `SW/LW` at mapped offsets | PASS |
| TC8 | SRAM region map | Image 1 = 17, Image 2 = 34, Sobel = 51 | PASS |
| TC9 | SRAM upper bound | Valid `0x1000_2FFF` works; invalid `0x1000_3000` reads zero in the model | PASS |

**Observed QuestaSim transcript (provided by project owner):**

```text
# [66 ns] TC1 ALU PASSED
# [126 ns] TC2 LW/SW PASSED
# [216 ns] TC3 LB/SB PASSED
# [296 ns] TC4 BRANCH PASSED
# [326 ns] TC5 LUI PASSED
# [396 ns] TC6 JAL/JALR PASSED
# [476 ns] TC7 SRAM PASSED
# [616 ns] Image 1 = 17
# [616 ns] Image 2 = 34
# [616 ns] Sobel   = 51
# [616 ns] TC8 SRAM MAP PASSED
# [726 ns] TC9 SRAM BOUNDARY PASSED
# ================================
#         CPU TEST SUMMARY
# ================================
# PASS : 9
# FAIL : 0
# TIME : 726 ns
# ================================
```

## 6. Running QuestaSim (Windows PowerShell)

Run from your AIPS-SoC repository root so paths inside `$readmemh` resolve correctly. A typical rebuild is:

```powershell
vlib work
Get-ChildItem .\rtl\cpu\*.sv, .\rtl\memory\*.sv | ForEach-Object { vlog $_.FullName }
vlog .\tb\cpu\rv32_core_tb.sv
vsim -c -voptargs=+acc rv32_core_tb -do "run -all; quit"
```

**Check your repository paths/module names** if they differ. In particular, be sure the old `data_memory.sv` is not instantiated alongside `sram.sv`. If you later enable error diagnostics, compile with `vlog +define+ERROR_DETEC` consistently.

## 7. Limitations and next steps

- SRAM is a basic behavioral memory model, with **zero-wait-state combinational reads**, not a timed AHB-Lite SRAM slave.
- Only `LB`, `LW`, `SB`, `SW` are implemented on the memory interface; unaligned accesses and unsupported access types need explicit handling.
- Current tests cover representative locations and boundaries, **not exhaustive 12 KiB data-pattern verification**.
- Out-of-range transactions do not raise a CPU exception in this implementation; the pre-Phase-5 checkers should detect/report them in simulation, with expected-negative-test controls for TC9.
- System target clock in the architecture is **50 MHz**; the existing CPU testbench's `always #5 clk = ~clk` corresponds to a **100 MHz** testbench clock. This does not affect instruction-level regression conclusions but should be aligned/verified in system integration.
- **Before Phase 5:** Add `ifdef ERROR_DETEC` / `endif` guarded simulation diagnostics to RTL modules (PC, ALU, regfile, instruction ROM, decoder, immediate generator, control, CPU, SRAM); run the full regression with and without checks enabled.
- **Phase 5:** Introduce CPU-to-AHB-Lite transaction adaptation, bus address/control/data phases, `HREADY`/`HRESP` handling, and an AHB-compatible SRAM slave; verify stalled transfers and timing.

## 8. Completion criteria

- [x] CPU connected to SRAM through direct address/data/control signals.
- [x] 12 KiB capacity and three separate 4 KiB address regions defined.
- [x] `LB/LW/SB/SW` exercised at mapped addresses.
- [x] Top-of-memory boundary behavior checked.
- [x] Full Phase 4 regression: **9 PASS, 0 FAIL**.

**Phase 4: COMPLETE.**  
**Next checkpoint:** Pre-Phase-5 error detection, then Phase 5 AHB-Lite integration.
