# AIPS-SoC — Pre-Phase 5: RTL Error Detection

**Project:** AMBA Image Processing System-on-Chip (AIPS-SoC)  
**Checkpoint:** After Phase 4 (CPU + SRAM), before Phase 5 (AHB-Lite integration)  
**Status:** **IN PROGRESS — not yet verified**  
**Baseline:** Phase 4 regression **9 PASS / 0 FAIL** (QuestaSim, 726 ns)

## 1. Objective

Add **optional simulation-time error detection** to each existing SystemVerilog RTL module **without changing its normal functionality**. Detect unexpected conditions early, report the module, simulation time, and relevant signal values, and re-run the original 9 regression tests before moving to AHB-Lite integration.

These checks are **simulation diagnostics** (`$error`, `$warning`, `$fatal`), **not synthesizable fault-handling hardware**. Keep them gated behind a compilation macro.

## 2. Standard coding convention

Use `ifdef` and `endif` (not `def` / `enddef`):

```systemverilog
`timescale 1ns/1ps

module example (...);
    // Existing functional RTL — unchanged.

`ifdef ERROR_DETEC
    // Checks relevant to this module only.
`endif

endmodule
```

The project uses the macro name **`ERROR_DETEC`** consistently. This spelling is intentional for compatibility with existing requests; do not silently mix it with `ERROR_DETECT`.

**Reporting policy:**

- **`$error`** — unexpected illegal or unknown condition during a valid operation.
- **`$warning`** — suspicious but permitted condition, or an expected negative-test condition.
- **`$fatal`** — only when the testbench cannot continue or when the final regression summary fails.
- Include `[%0t]`, the module name, and the relevant address/opcode/value.
- Guard reset-sensitive checks with `rst_n === 1'b1` where that signal exists.
- Avoid reporting unknown/unused signals when an operation is inactive.

## 3. Module-by-module checklist

| File | Suggested simulation checks | Caveat |
|---|---|---|
| `pc.sv` | PC unknown; PC not 4-byte aligned when running | Check after sequential updates settle; JALR clears bit 0, but bit 1 may still cause misalignment |
| `alu.sv` | Unsupported `alu_op`; X/Z operands when ALU result is relevant | Current supported operations: `000` ADD, `001` SUB |
| `regfile.sv` | X/Z write address/data when `reg_write=1`; attempted writes to `x0` (optional warning); `x0` reads remain zero | Writing `x0` is legal and should be ignored, not treated as an ISA error |
| `decoder.sv` | X/Z instruction; unsupported opcode or invalid `funct3`/`funct7` combinations | Accept instructions supported by *this CPU subset*; distinguish unsupported from malformed |
| `immediate_gen.sv` | Unknown instruction on valid decode; unexpected format selection | R-type need not produce a meaningful immediate |
| `control_unit.sv` | Unsupported instruction; conflicting enables; illegal branch or load/store function | Avoid warnings for intentional idle/default control outputs |
| `instruction_rom.sv` | X/Z PC; PC outside ROM capacity; fetched X/Z word | ROM is 256 × 32-bit instructions = **1 KiB**, mapped here at PC `0x0000_0000`–`0x0000_03FC` |
| `sram.sv` | X/Z on active write; invalid store `funct3`; misaligned `SW`; write outside SRAM | **TC9 deliberately writes outside SRAM**; use a warning or explicitly classify it as expected |
| `rv32_core.sv` | Unknown/misaligned PC; unknown fetched instruction; invalid branch/jump selections | Prefer checks on `negedge clk` or assertions with correct sampled timing |
| `rv32_core_tb.sv` | PASS/FAIL assertions, test isolation, summary, optional negative-check cases | Preserve all nine existing functional tests |

**Important:** The SRAM currently exposes `mem_write` but no separate `mem_read` enable. Do not infer a real load operation from `funct3` alone. If read-error diagnostics are needed later, consider adding an explicit read-enable interface during the bus-integration design.

## 4. Reference checks (adapt signal names to the module)

### CPU: unknown or misaligned PC

```systemverilog
`ifdef ERROR_DETEC
always @(negedge clk) begin
    if (rst_n === 1'b1) begin
        if ($isunknown(pc_out))
            $error("[%0t] CPU: PC contains X/Z", $time);
        else if (pc_out[1:0] !== 2'b00)
            $error("[%0t] CPU: misaligned PC=%08h", $time, pc_out);

        if ($isunknown(instruction))
            $error("[%0t] CPU: instruction X/Z at PC=%08h", $time, pc_out);
    end
end
`endif
```

### SRAM: invalid or misaligned store

```systemverilog
`ifdef ERROR_DETEC
always @(posedge clk) begin
    if (mem_write === 1'b1) begin
        if ($isunknown({address, write_data, funct3}))
            $error("[%0t] SRAM: X/Z in store request", $time);
        else begin
            if ((funct3 !== 3'b000) && (funct3 !== 3'b010))
                $error("[%0t] SRAM: unsupported store funct3=%03b", $time, funct3);
            if ((funct3 === 3'b010) && (address[1:0] !== 2'b00))
                $error("[%0t] SRAM: misaligned SW at %08h", $time, address);
            if (!valid_addr)
                $warning("[%0t] SRAM: out-of-range store %08h (TC9 may expect this)",
                         $time, address);
        end
    end
end
`endif
```

These snippets illustrate the convention; apply checks **one file at a time** and adapt to the module's actual ports and existing signal names. Never duplicate a module declaration or change datapath/control logic merely to add diagnostics.

## 5. Compile and run in QuestaSim (PowerShell)

From the AIPS-SoC project root, compile the RTL with the macro **enabled**:

```powershell
$src = @(Get-ChildItem .\rtl\cpu\*.sv | ForEach-Object { $_.FullName })
$src += @(Get-ChildItem .\rtl\memory\*.sv | ForEach-Object { $_.FullName })
vlog +define+ERROR_DETEC $src
vlog +define+ERROR_DETEC .\tb\cpu\rv32_core_tb.sv
vsim -c -voptargs=+acc rv32_core_tb -do "run -all; quit -f"
```

*If a file lives in another folder, include its path in `$src`. Compile dependent packages before modules if applicable.* PowerShell wildcard arguments passed directly to `vlog` may not expand as expected; using `Get-ChildItem` avoids that issue.

To **disable** diagnostics, recompile the same files **without** `+define+ERROR_DETEC`, then rerun the simulation.

## 6. Verification procedure

1. **Baseline:** All nine existing TC1–TC9 tests must still pass with diagnostics disabled.
2. **Enabled regression:** Recompile *all* relevant RTL with `+define+ERROR_DETEC`. Rerun TC1–TC9: target **9 PASS / 0 FAIL**, with no unexpected `$error`.
3. **Directed negative checks:** Deliberately stimulate one bad condition at a time in a separate debug test (e.g., misaligned word store, unsupported ALU opcode, unknown PC), and verify the correct message appears. Restore the original test after each injection.
4. **Expected invalid access:** TC9 exercises `0x1000_3000` (outside the 12 KB SRAM); this must remain an intentional boundary test, not an unexpected regression failure.
5. **Review:** Ensure all guards are under `ERROR_DETEC`, all messages identify their source, and normal behavior remains unchanged when the macro is off.

### Acceptance criteria

- [ ] Error guards added to all applicable CPU/ROM/SRAM RTL files.
- [ ] Each added guard has an understandable, actionable diagnostic message.
- [ ] No unwanted diagnostic during reset, NOP, legal `x0` operations, or intentional TC9 boundary behavior.
- [ ] Complete regression passes **9/9** with the macro enabled.
- [ ] At least representative invalid-condition tests prove error messages trigger.
- [ ] Recompile without the macro; baseline **9/9** still passes.

## 7. Workflow and completion gate

We will review **one `.sv` file per message**: user sends the current module → add a small `ERROR_DETEC` block → explain what it catches → test → move to the next file.

**Phase 4:** COMPLETE (9/9 passed before instrumentation).  
**Pre-Phase 5 Error Detection:** **IN PROGRESS** until the criteria above pass.  
**Phase 5 — AHB-Lite Integration:** **NOT STARTED**.

When the checks and regression are complete, explicitly announce **“PRE-PHASE 5 ERROR DETECTION COMPLETE”** before moving on to Phase 5.
