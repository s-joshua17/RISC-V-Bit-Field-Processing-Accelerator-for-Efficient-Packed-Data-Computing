# Architecture Documentation

This directory contains system-level and block-level architecture diagrams.

---

## Files

| File | Description |
|------|-------------|
| `system_block_diagram.jpeg` | Full SoC block diagram: PicoRV32 internals (PC/Fetch, Instruction Decode, Control FSM, Register File, ALU, PCPI Interface), BFPU peripheral, Simple RAM, and Firmware HEX load path |
| `bfpu_internal_pipeline.jpeg` | BFPU internal data-flow: Instruction Decoder → Descriptor File / Mask Generator / Control Logic → Barrel Shifter → Insert Logic → BFPU Result → PCPI RD |
| `getfxu_control_word_format.jpeg` | Bit-field layout of the GETFXU/FDSETI control word: bits [31:16]=FIELD EXTRACT, [15:5]=FIELD WIDTH, [4:0]=CONTROL BFPU MODE |

---

## System Integration Summary

```
┌──────────────────────────────────────────────────────────────┐
│                     PicoRV32 Core (picorv32.v)               │
│  PC/FETCH → INSTRUCTION DECODE → CONTROL / CPU FSM           │
│                       │                │                     │
│              ALU ←── REGISTER FILE     │                     │
│                                        ▼                     │
│                               PCPI INTERFACE ──pcpi_valid──► picorv32_pcpi_bfpu
│                                                              │ (BFPU peripheral)
│                               MEMORY INTERFACE ────────────► simple_ram
└──────────────────────────────────────────────────────────────┘
                                                              ▲
                                                        FIRMWARE.HEX
```

### PCPI Signal Directions

| Signal | Direction | Description |
|--------|-----------|-------------|
| `pcpi_valid` | CPU → BFPU | High when CPU has a custom instruction to dispatch |
| `pcpi_insn[31:0]` | CPU → BFPU | Full 32-bit instruction word |
| `pcpi_rs1[31:0]` | CPU → BFPU | Value of source register rs1 |
| `pcpi_rs2[31:0]` | CPU → BFPU | Value of source register rs2 |
| `pcpi_wait` | BFPU → CPU | Stall signal (tied 0 — all BFPU instructions are single-cycle) |
| `pcpi_ready` | BFPU → CPU | High when BFPU result is valid |
| `pcpi_wr` | BFPU → CPU | High when BFPU wants to write-back to rd |
| `pcpi_rd[31:0]` | BFPU → CPU | Result value to write to rd |

### Key Design Decisions

1. **Non-invasive attachment**: PicoRV32 source is not modified. The BFPU hooks
   in entirely through the documented PCPI port.

2. **Single-cycle execution**: All four BFPU instructions are purely
   combinational. `pcpi_wait` is permanently tied low.

3. **Single shared shifter + mask generator**: The PUTF reordered-arithmetic
   trick (shift-then-mask using the positioned mask for both clear and merge)
   means every instruction needs exactly one shifter evaluation and one
   mask-generator evaluation per cycle — no hardware duplication.

4. **Width-1 encoding**: Widths are encoded as `width - 1` throughout
   (instruction fields, descriptor file, mask generator inputs). This avoids
   ever needing to represent the value `32` in a 5-bit field and prevents
   a 33-bit intermediate in the mask computation.
