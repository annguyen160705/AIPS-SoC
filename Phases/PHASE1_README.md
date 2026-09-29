# AIPS-SoC — Phase 1 Specification

## 1. Phase Goal

Freeze the AIPS-SoC V1 architecture before RTL integration.

AIPS-SoC V1 supports two CPU-controlled image transfer commands:

```text
0x01 : UART -> CPU -> SRAM
       Receive Image2 from UART and store it in memory

0x02 : SRAM -> CPU -> UART
       Read Image1 from memory and transmit it through UART
```

A later V2 command will add Sobel image processing.

---

## 2. Image Specification

```text
Resolution  : 64 x 64
Format      : 8-bit grayscale
Pixel size  : 1 byte
Image size  : 4096 bytes
```

Since:

```text
64 x 64 = 4096 bytes = 0x1000 bytes
```

each image occupies one `0x1000` memory region.

---

## 3. System Architecture

```text
                +------------------+
                |   RV32I CPU      |
                |  SystemVerilog   |
                +--------+---------+
                         |
                      AHB-Lite
                         |
              +----------+----------+
              |                     |
              v                     v
            SRAM               AHB -> APB
                                      |
                                      v
                                    UART
                                      |
                                      v
                                Testbench / PC
```

### V1 Rules

- CPU is the only AHB master.
- SRAM stores Image1 and Image2.
- UART is accessed through APB.
- HCLK and PCLK use the same clock in V1.
- No DMA or AXI in V1.

---

## 4. Memory Map

```text
0x0000_0000 - 0x0000_0FFF
Instruction ROM

0x1000_0000 - 0x1000_0FFF
Image1

0x1000_1000 - 0x1000_1FFF
Image2

0x1000_2000 - 0x1000_2FFF
Processed Image / reserved for V2

0x4000_0000
UART_DATA

0x4000_0004
UART_STATUS

0x4000_0008
UART_CONTROL
```

### Initial State

```text
Image1 : preloaded into SRAM
Image2 : empty, later received from UART
```

---

## 5. Bus Configuration

```text
CPU data width  : 32-bit
AHB address     : 32-bit
AHB data        : 32-bit

APB address     : 32-bit
APB data        : 32-bit

UART data       : 8-bit
```

### Main AHB-Lite Signals

```text
HADDR
HTRANS
HWRITE
HSIZE
HWDATA
HRDATA
HREADY
HRESP
```

Because the project uses AHB-Lite, arbitration signals such as `HBUSREQ` and `HGRANT` are not required.

---

## 6. Clock and UART Configuration

```text
HCLK : 50 MHz
PCLK : 50 MHz
CPU  : 50 MHz
```

UART configuration:

```text
Baud rate : 115200
Data bits : 8
Parity    : None
Stop bits : 1

Format    : 8-N-1
```

The UART baud rate may initially be a compile-time parameter.

---

## 7. UART Register Map

### UART_DATA — `0x4000_0000`

Read:

```text
CPU read -> UART RX byte
```

Write:

```text
CPU write -> UART TX byte
```

Data field:

```text
bits [7:0] = UART data
```

### UART_STATUS — `0x4000_0004`

```text
bit 0 : RX_VALID
bit 1 : TX_READY
bit 2 : RX_ERROR
bits 31:3 : Reserved
```

### UART_CONTROL — `0x4000_0008`

```text
bit 0 : UART enable
bits 31:1 : Reserved
```

---

## 8. UART Command Protocol

### Command `0x01` — UART to Memory

UART stream:

```text
Byte 0       : 0x01
Bytes 1-4096 : Image2 data
```

CPU behavior:

```text
Read command
     |
     v
Command == 0x01
     |
     v
Receive 4096 bytes
     |
     v
Store at 0x1000_1000
```

### Command `0x02` — Memory to UART

UART stream:

```text
Byte 0 : 0x02
```

CPU behavior:

```text
Read command
     |
     v
Command == 0x02
     |
     v
Read 4096 bytes from 0x1000_0000
     |
     v
Transmit through UART
```

Because image size is fixed in V1, the image dimensions do not need to be sent over UART.

---

## 9. Minimum RV32I Instruction Set

The custom multi-cycle RV32I CPU only needs the instructions required by the firmware.

### Arithmetic

```text
ADD
ADDI
SUB
```

### Memory

```text
LW
SW
LB
SB
```

### Branch

```text
BEQ
BNE
```

### Address / Control Flow

```text
LUI
JAL
JALR
```

---

## 10. Bandwidth Measurement

AIPS-SoC V1 will compare UART, APB, and AHB-Lite performance using the same payload:

```text
4096 bytes
```

### AHB-Lite Transfer

A successful transfer is counted when:

```systemverilog
HREADY && HTRANS[1]
```

Payload size is determined by `HSIZE`:

```text
HSIZE = 000 -> 1 byte
HSIZE = 001 -> 2 bytes
HSIZE = 010 -> 4 bytes
```

Measure:

```text
AHB read bytes
AHB write bytes
AHB active cycles
AHB total cycles
```

### APB Transfer

A completed APB transfer is counted when:

```systemverilog
PSEL && PENABLE && PREADY
```

Direction:

```text
PWRITE = 0 -> Read
PWRITE = 1 -> Write
```

### UART Transfer

Count one byte when a UART RX or TX transaction completes.

### Bandwidth Formula

```text
Bandwidth = Transferred Payload Bytes / Elapsed Time
```

### Bus Utilization

```text
Utilization =
    Active Transfer Cycles
    ----------------------
    Total Measured Cycles
    x 100%
```

---

## 11. Frozen AIPS-SoC V1 Specification

```text
CPU:
Custom multi-cycle RV32I
32-bit

Bus:
AHB-Lite 32-bit
APB 32-bit

Clock:
50 MHz

UART:
115200 baud
8-N-1

Image:
64 x 64
8-bit grayscale
4096 bytes

Commands:
0x01 = UART -> Memory
0x02 = Memory -> UART

Memory:
Image1 @ 0x1000_0000
Image2 @ 0x1000_1000

Performance:
Measure UART, APB, and AHB bandwidth/utilization
```

---

## 12. Phase 1 Completion Checklist

- [x] Project purpose defined
- [x] System architecture defined
- [x] Image format defined
- [x] Memory map defined
- [x] UART commands defined
- [x] Bus widths defined
- [x] Clock configuration defined
- [x] UART register map defined
- [x] CPU minimum ISA defined
- [x] Bandwidth measurement rules defined

---

## Next Phase

**Phase 2 — MATLAB Image Preparation**

Prepare:

```text
memory/image1.hex
uart/image2.hex
```

and verify that each HEX file reconstructs correctly into a 64x64 grayscale image.
