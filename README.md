# AIPS-SoC

**AMBA Image Processing System-on-Chip**

AIPS-SoC is an RTL-focused SoC project built in **SystemVerilog** and verified in **QuestaSim**. The system uses a custom CPU to control image movement between **UART** and **memory** through **AHB-Lite** and **APB**, while measuring the effective bandwidth and utilization of each interface.

A later version adds a hardware **Sobel image-processing accelerator** and optional **DMA/AXI** support.

---

## 1. Project Goals

### AIPS-SoC V1

Implement a CPU-controlled image transfer system with two main commands:

| Command | Operation |
|---|---|
| `0x01` | UART Image2 -> CPU -> SRAM |
| `0x02` | SRAM Image1 -> CPU -> UART |

The project will also measure:

- AHB-Lite read/write bandwidth
- APB read/write bandwidth
- UART RX/TX bandwidth
- Bus utilization
- Total image-transfer time
- CPU cycles used for data movement

### AIPS-SoC V2

Add hardware image processing:

| Command | Operation |
|---|---|
| `0x03` | SRAM Image2 -> Sobel Accelerator -> SRAM -> UART |

The Sobel RTL result will be compared against a MATLAB golden model.

### Future Version

Optional extensions:

- Interrupts
- FIFO buffering
- DMA
- AXI / AXI burst transfers
- Performance comparison between CPU-driven and DMA-driven transfers
- SVA and functional coverage

---

## 2. System Architecture

```text
                         +------------------+
                         |   RV32I CPU      |
                         |  SystemVerilog   |
                         +---------+--------+
                                   |
                                AHB-Lite
                                   |
                  +----------------+----------------+
                  |                                 |
                  v                                 v
              AHB SRAM                       AHB -> APB
                  |                                 |
          +-------+--------+                        |
          |                |                        v
       Image1           Image2                    UART
                                                      |
                                               External/Testbench
```

V2 adds:

```text
SRAM Image2
    |
    v
Sobel Accelerator
    |
    v
Processed Image SRAM
    |
    v
CPU -> UART
```

---

## 3. Image Format

```text
Resolution  : 64 x 64
Format      : Grayscale
Pixel width : 8 bits
Image size  : 4096 bytes
```

Each MATLAB-generated HEX file contains one pixel per line.

Example:

```text
00
1A
7F
C4
FF
```

---

## 4. Initial Memory Map

| Address | Function |
|---|---|
| `0x0000_0000` | Instruction ROM |
| `0x1000_0000` | Image1 SRAM |
| `0x1000_1000` | Image2 SRAM |
| `0x1000_2000` | Processed image SRAM / reserved for V2 |
| `0x4000_0000` | UART_DATA |
| `0x4000_0004` | UART_STATUS |
| `0x4000_0008` | UART_CONTROL |

Each 64x64 grayscale image occupies:

```text
4096 bytes = 0x1000 bytes
```

---

## 5. Suggested Repository Structure

```text
AIPS-SoC/
|
+-- README.md
|
+-- rtl/
|   +-- cpu/
|   |   +-- rv32_core.sv
|   |   +-- decoder.sv
|   |   +-- control_unit.sv
|   |   +-- alu.sv
|   |   +-- regfile.sv
|   |   +-- immediate_gen.sv
|   |   +-- instruction_rom.sv
|   |
|   +-- ahb/
|   +-- apb/
|   +-- uart/
|   +-- memory/
|   +-- image/
|   +-- top/
|
+-- tb/
|   +-- cpu/
|   +-- ahb/
|   +-- apb/
|   +-- uart/
|   +-- image/
|   +-- performance/
|   |   +-- ahb_bw_monitor.sv
|   |   +-- apb_bw_monitor.sv
|   |   +-- uart_bw_monitor.sv
|   +-- soc/
|
+-- firmware/
|   +-- asm/
|   +-- hex/
|
+-- matlab/
|   +-- images/
|   +-- output/
|   +-- prepare_image.m
|   +-- rebuild_image.m
|   +-- sobel_golden.m
|
+-- memory/
|   +-- image1.hex
|   +-- image2_received.hex
|
+-- uart/
|   +-- image2.hex
|   +-- image1_received.hex
|
+-- sim/
|   +-- scripts/
|   +-- waves/
|
+-- docs/
```

---

# 6. Development Plan

## Phase 1 - Freeze the Specification

Define:

- CPU architecture
- Image size and format
- UART command protocol
- Memory map
- AHB/APB data width
- Clock frequencies
- Bandwidth measurement rules

### Exit Criteria

- Architecture diagram complete
- Memory map fixed
- Commands `0x01` and `0x02` fixed
- Image format fixed

---

## Phase 2 - MATLAB Image Preparation

Prepare two source images:

```text
Image1 -> memory/image1.hex
Image2 -> uart/image2.hex
```

MATLAB processing:

```text
JPEG/PNG
   |
   v
Grayscale
   |
   v
Resize 64x64
   |
   v
4096-byte HEX
```

Also create a MATLAB script to rebuild HEX data into an image.

### Exit Criteria

- `image1.hex` contains 4096 pixels
- `image2.hex` contains 4096 pixels
- Both reconstructed images match the expected source images

---

## Phase 3 - RV32I CPU in SystemVerilog

Implement a simple multi-cycle RV32I CPU.

Initial instructions:

```text
ADD
ADDI
SUB
```

Then add:

```text
LW
SW
LB
SB
BEQ
BNE
JAL
LUI
```

Initial CPU test:

```asm
addi x1, x0, 10
addi x2, x0, 20
add  x3, x1, x2
```

Expected:

```text
x1 = 10
x2 = 20
x3 = 30
```

### Exit Criteria

- CPU executes simple Assembly correctly in QuestaSim
- Register file contents match expected results

---

## Phase 4 - CPU + SRAM

Connect the CPU directly to SRAM before AMBA integration.

Verify:

```text
CPU -> SRAM write
CPU <- SRAM read
```

Test:

```asm
sw
lw
sb
lb
```

Preload `image1.hex` into SRAM and verify the CPU can read image bytes.

### Exit Criteria

- CPU load/store instructions work correctly
- CPU reads Image1 correctly from memory

---

## Phase 5 - AHB-Lite Integration

Insert AHB-Lite between the CPU and SRAM.

```text
CPU
 |
 v
AHB Master
 |
 v
AHB Interconnect
 |
 v
SRAM
```

Tests:

- Word read/write
- Byte read/write
- Back-to-back transfers
- HREADY wait states
- Invalid-address response
- Address boundary tests

### Exit Criteria

```text
CPU <-> AHB-Lite <-> SRAM
```

works correctly.

---

## Phase 6 - AHB Bandwidth Measurement

Add an AHB performance monitor.

Count a successful AHB transfer when:

```systemverilog
HREADY && HTRANS[1]
```

Transferred bytes depend on `HSIZE`.

Measure:

```text
AHB Read Bandwidth
AHB Write Bandwidth
AHB Utilization
Elapsed Cycles
```

Basic bandwidth formula:

```text
Bandwidth = Transferred Payload Bytes / Elapsed Time
```

Bus utilization:

```text
Utilization = Active Transfer Cycles / Total Measured Cycles * 100%
```

### Exit Criteria

QuestaSim reports values such as:

```text
AHB READ BW   : xx MB/s
AHB WRITE BW  : xx MB/s
AHB UTIL      : xx %
```

---

## Phase 7 - APB + UART Integration

Add the AHB-to-APB bridge and UART peripheral.

```text
CPU
 |
 v
AHB-Lite
 |
 v
AHB -> APB Bridge
 |
 v
UART
```

First verify individual bytes:

```text
CPU -> UART TX -> Testbench
Testbench -> UART RX -> CPU
```

Example test values:

```text
0x41
0x55
0xAA
```

### Exit Criteria

- CPU can transmit through UART
- CPU can receive through UART
- UART registers are accessible through APB

---

## Phase 8 - APB and UART Bandwidth Measurement

Add performance monitors for:

- APB read
- APB write
- UART RX
- UART TX

Use the same 4096-byte payload for comparison.

Example final table:

| Interface | Direction | Bytes | Time | Bandwidth | Utilization |
|---|---|---:|---:|---:|---:|
| UART | RX | 4096 | - | - | - |
| UART | TX | 4096 | - | - | - |
| APB | Read | 4096 | - | - | - |
| APB | Write | 4096 | - | - | - |
| AHB | Read | 4096 | - | - | - |
| AHB | Write | 4096 | - | - | - |

### Exit Criteria

- Bandwidth values are automatically reported by the testbench
- AHB, APB, and UART performance can be directly compared

---

## Phase 9 - Command 0x01: UART -> Memory

UART stimulus:

```text
0x01
Image2 byte 0
Image2 byte 1
...
Image2 byte 4095
```

CPU firmware:

```text
Receive command
      |
      v
Command == 0x01
      |
      v
Read UART_DATA
      |
      v
Store byte into Image2 SRAM
      |
      v
Repeat 4096 times
```

Data path:

```text
uart/image2.hex
      |
      v
UART RX
      |
      v
CPU
      |
      v
AHB-Lite
      |
      v
SRAM Image2
```

### Verification

Compare:

```text
uart/image2.hex == Image2 region in SRAM
```

### Exit Criteria

```text
4096 / 4096 bytes match
0 errors
```

---

## Phase 10 - Command 0x02: Memory -> UART

UART sends:

```text
0x02
```

CPU firmware:

```text
Read Image1 SRAM
      |
      v
Write UART_DATA
      |
      v
Repeat 4096 times
```

Data path:

```text
SRAM Image1
    |
    v
AHB-Lite
    |
    v
CPU
    |
    v
APB
    |
    v
UART TX
    |
    v
uart/image1_received.hex
```

### Verification

Compare:

```text
memory/image1.hex == uart/image1_received.hex
```

### Exit Criteria

```text
4096 / 4096 bytes match
0 errors
```

---

## Phase 11 - Full-System Bandwidth Study

Run both real application flows:

```text
UART -> CPU -> AHB -> SRAM
```

and:

```text
SRAM -> AHB -> CPU -> APB -> UART
```

Measure:

- Total transfer time
- CPU cycles
- AHB bandwidth
- APB bandwidth
- UART bandwidth
- AHB utilization
- APB utilization

Goal:

> Identify the actual performance bottleneck from measured simulation data.

---

## Phase 12 - AIPS-SoC V1 Full Verification

Full test sequence:

```text
RESET
  |
  v
CPU boots
  |
  v
UART sends 0x01
  |
  v
Image2 transferred to SRAM
  |
  v
Verify Image2
  |
  v
UART sends 0x02
  |
  v
Image1 transferred through UART
  |
  v
Verify Image1
  |
  v
Print performance report
```

Target QuestaSim result:

```text
====================================
          AIPS-SoC V1
====================================

UART -> MEMORY
Bytes  : 4096
Errors : 0
PASS

MEMORY -> UART
Bytes  : 4096
Errors : 0
PASS

AHB Read BW    : ...
AHB Write BW   : ...
APB Read BW    : ...
APB Write BW   : ...
UART RX BW     : ...
UART TX BW     : ...

AIPS-SoC V1 PASSED
====================================
```

---

# 7. AIPS-SoC V2 - Sobel Accelerator

The Sobel arithmetic core has already been prototyped using:

```text
G = abs(Gx) + abs(Gy)
```

with binary thresholding.

Add command:

```text
0x03 = Process Image2
```

V2 data path:

```text
Image2 SRAM
    |
    v
Sobel Accelerator
    |
    v
Processed Image SRAM
    |
    v
CPU
    |
    v
UART
```

MATLAB acts as the golden model.

### Verification Goal

```text
RTL Sobel output == MATLAB golden output
```

for the full image.

---

# 8. Future Extensions

After V1 and V2 are stable:

## Interrupts

Replace polling where appropriate:

```text
UART RX interrupt
UART TX interrupt
Accelerator DONE interrupt
```

## FIFO

Add buffering between UART and CPU.

## DMA

Move image blocks without the CPU copying every byte.

Compare:

```text
CPU-controlled transfer
vs
DMA-controlled transfer
```

## AXI

Use AXI for high-bandwidth image-memory transfers.

Possible path:

```text
UART
 |
 v
FIFO
 |
 v
DMA
 |
 v
AXI
 |
 v
Memory / Sobel Accelerator
```

## Verification Improvements

Add:

- SystemVerilog Assertions
- Functional coverage
- Code coverage
- Random wait states
- Error injection
- Protocol corner cases

---

# 9. Main Tools

| Tool | Purpose |
|---|---|
| SystemVerilog | CPU, buses, UART, memory, accelerator, monitors |
| QuestaSim | RTL simulation, waveform debug, verification |
| RISC-V Assembly | CPU firmware |
| MATLAB | Image preparation, reconstruction, Sobel golden model |
| Git | Version control |

---

# 10. Main Technical Objectives

AIPS-SoC should demonstrate:

- RTL CPU design
- Assembly execution
- AHB-Lite protocol
- APB protocol
- AHB-to-APB bridging
- UART communication
- Memory-mapped I/O
- Image data transfer
- Bandwidth measurement
- Bus-utilization analysis
- End-to-end verification
- Hardware image acceleration in V2

---

# 11. Project Milestones

```text
Phase 1   Specification
Phase 2   MATLAB Images
Phase 3   RV32I CPU
Phase 4   CPU + SRAM
Phase 5   AHB-Lite
Phase 6   AHB Bandwidth
Phase 7   APB + UART
Phase 8   APB/UART Bandwidth
Phase 9   UART -> Memory
Phase 10  Memory -> UART
Phase 11  Full Performance Study
Phase 12  AIPS-SoC V1 Complete
Phase 13  Sobel Accelerator / V2
Phase 14  DMA + AXI + Advanced Verification
```

---

## Current Focus

The current priority is:

```text
1. Finalize MATLAB image preparation
2. Build the RV32I CPU in SystemVerilog
3. Verify CPU + SRAM
4. Integrate AHB-Lite
```

Do not integrate every subsystem at once. Each phase should end with an independently passing QuestaSim test before moving to the next phase.
