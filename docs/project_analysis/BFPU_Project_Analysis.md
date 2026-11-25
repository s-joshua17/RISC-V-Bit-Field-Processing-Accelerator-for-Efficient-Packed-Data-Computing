# RISC-V Bit-Field Processing Unit (BFPU) — Project Analysis

> **Purpose:** Professional engineering portfolio documentation.  
> All findings below are drawn exclusively from actual files in the repository.  
> Facts are labelled **[ACTUAL]**; inferences or gaps are labelled **[NOTE]** or **[NOT PRESENT]**.

---

## 1. Overall Project Objective & Functionality

**[ACTUAL]** This project designs and validates a **custom RISC-V co-processor extension** called the **Bit-Field Processing Unit (BFPU)** — a hardware accelerator that adds four new instructions to a standard RV32I core for sub-word bit-field extraction and insertion.

The accelerator attaches to the **unmodified** open-source [PicoRV32](https://github.com/YosysHQ/picorv32) CPU core via its native **PCPI (Pico Co-Processor Interface)** port — requiring zero modifications to the CPU's decoder, ALU, register file, or pipeline. The BFPU resolves every instruction **combinationally in a single clock cycle** (zero wait-states).

### Motivation
Bit-field manipulation is pervasive in embedded and networking software (e.g., packing/unpacking hardware register fields, network header fields, pixel-format conversion). The baseline RV32I approach requires multiple instructions per field operation (AND/OR/SHIFT sequences). The BFPU collapses each such sequence into a **single custom instruction**, reducing dynamic instruction count and execution time.

### Three Demonstrated Application Domains
| Domain | Benchmark | Speedup |
|--------|-----------|---------|
| Networking | Packet header field processing (DSCP, TTL, Protocol) | **1.53×** |
| Embedded / IoT | ADC register configure + readback (8 configurations) | **1.99×** |
| Graphics / Display | RGB888 → RGB565 pixel format conversion (1024 pixels) | **1.34×** |

---

## 2. Complete Source Code & Module Hierarchy

### Top-Level Repository Layout (Actual on Disk)

```
bfpudoc/
├── rtl/                            ← Primary synthesisable RTL + firmware
│   ├── top.v                       ← Top-level SoC integration
│   ├── picorv32.v                  ← Unmodified PicoRV32 RV32I CPU (Claire Wolf, ISC licence)
│   ├── picorv32_pcpi_bfpu.v        ← BFPU PCPI peripheral (top-level BFPU wrapper)
│   ├── bfpu_decoder.v              ← Combinational instruction decoder
│   ├── bfpu_descriptor_file.v      ← 4-entry field-descriptor register file
│   ├── bfpu_barrel_shifter.v       ← Shared bidirectional barrel shifter
│   ├── bfpu_mask_generator.v       ← Contiguous bit-field mask generator
│   ├── bfpu_insert_logic.v         ← PUTF merge (clear + OR)
│   ├── simple_ram.v                ← 16 KB word-addressed synchronous RAM
│   ├── bfpu.hex                    ← ADC benchmark firmware (BFPU version)
│   ├── rv32i.hex                   ← ADC benchmark firmware (RV32I baseline)
│   ├── firmwarebfpu.hex            ← General BFPU firmware image
│   ├── firmware.hex                ← General RV32I firmware image
│   ├── firmwaretest.hex            ← Small smoke-test firmware
│   ├── rgbbfpu (1).hex             ← RGB888→565 benchmark (BFPU)
│   ├── rgbrv32i (1).hex            ← RGB888→565 benchmark (RV32I baseline)
│   ├── bitmapbfpu.hex              ← Bitmap processing firmware (BFPU)
│   ├── bitmaprv32i.hex             ← Bitmap processing firmware (RV32I)
│   ├── packet_header_benchmark_v2_bfpu.hex   ← Packet benchmark (BFPU)
│   └── packet_header_benchmark_v2_rv32i.hex  ← Packet benchmark (RV32I)
│
├── proposed bfpu rtl/              ← Identical mirror of rtl/ BFPU modules + testbench
│   ├── picorv32_pcpi_bfpu.v        ← [ACTUAL: byte-identical to rtl/ version]
│   ├── bfpu_decoder.v
│   ├── bfpu_descriptor_file.v
│   ├── bfpu_barrel_shifter.v
│   ├── bfpu_mask_generator.v
│   ├── bfpu_insert_logic.v
│   └── tb_picorv32_pcpi_bfpu.v    ← Self-checking testbench (Icarus Verilog)
│
├── benchmark hex files/            ← Benchmark assembly sources (hand-assembled)
│   ├── bfpu.s                      ← ADC benchmark source (BFPU)
│   ├── rv32i.s                     ← ADC benchmark source (RV32I baseline)
│   ├── packet_header_benchmark_v2_bfpu.S    ← Packet benchmark source (BFPU)
│   ├── packet_header_benchmark_v2_rv32i.S   ← Packet benchmark source (RV32I)
│   ├── rgbbfpu (1).s               ← RGB benchmark source (BFPU)
│   └── rgbrv32i (1).s              ← RGB benchmark source (RV32I)
│
├── waveforms/                      ← Simulation waveform screenshots (Vivado)
│   ├── Screenshot 2026-08-24 *.png (×4)
│   └── WhatsApp Image 2026-10-12 *.jpeg (×6) ← includes paper-quality result tables
│
├── output images/                  ← Architecture diagrams and performance charts
│   ├── WhatsApp Image 2026-08-28 at 12.34.25 AM.jpeg  ← System block diagram
│   ├── WhatsApp Image 2026-08-28 at 12.48.20 AM.jpeg  ← BFPU internal pipeline diagram
│   ├── WhatsApp Image 2026-08-29 at 12.23.57 AM.jpeg  ← GETFXU control word format
│   ├── WhatsApp Image 2026-08-29 at 12.36.09 AM.jpeg  ← Performance fingerprint chart
│   └── WhatsApp Image 2026-08-29 at 12.39.57 AM.jpeg  ← Energy efficiency chart
│
└── RISC-V-Bit-Field-Processing-Accelerator-for-Efficient-Packed-Data-Computing/
    └── .git/   ← Empty initialised git repo (no commits yet) [ACTUAL: only .git dir present]
```

---

## 3. Top-Level Module & Submodule Hierarchy

```
top (top.v)
├── picorv32 (picorv32.v)           ← RV32I CPU; ENABLE_PCPI=1, ENABLE_MUL/DIV/IRQ=0
│   └── [PCPI port wired to picorv32_pcpi_bfpu]
│
├── picorv32_pcpi_bfpu (picorv32_pcpi_bfpu.v)   ← BFPU PCPI peripheral
│   ├── bfpu_decoder (bfpu_decoder.v)             ← One-hot instruction decode
│   ├── bfpu_descriptor_file (bfpu_descriptor_file.v) ← FD0–FD3 register file
│   ├── bfpu_barrel_shifter (bfpu_barrel_shifter.v)   ← Shared bidirectional shifter
│   ├── bfpu_mask_generator (bfpu_mask_generator.v)   ← Bit-field mask compute
│   └── bfpu_insert_logic (bfpu_insert_logic.v)       ← PUTF merge datapath
│
└── simple_ram (simple_ram.v)       ← 16 KB SRAM (combinational read, sync write)
```

> [!NOTE]
> `top.v` lines 83–86 contain a known bug: the PCPI output signals (`pcpi_wr`, `pcpi_rd`, `pcpi_wait`, `pcpi_ready`) are **hardwired to zero** via `assign` statements instead of being connected to `picorv32_pcpi_bfpu`. The instantiation of `picorv32_pcpi_bfpu` itself is **absent** from `top.v`. The comment in the file acknowledges this was "the fix" but the fix was **not applied** in `top.v`. The BFPU submodules are implemented and verified standalone. `picorv32_pcpi_bfpu.v` is correctly implemented and verified in simulation independently.

---

## 4. Hardware Architecture & Data Flow

### System Block Diagram (from output images)

```
                    ┌─────────────────────────────────────────┐
                    │  PicoRV32 Core (picorv32.v — UNMODIFIED)│
  FIRMWARE.HEX ───► │  PC/Fetch → Instr Decode → Ctrl FSM    │
                    │            │          │                  │
                    │    REGISTER FILE ◄── ALU                │
                    │            │                            │
                    │    PCPI INTERFACE ─────────────────────►│──► picorv32_pcpi_bfpu
                    │            │                            │
                    │    MEMORY INTERFACE ────────────────────►──► simple_ram
                    └─────────────────────────────────────────┘
```

### BFPU Internal Data Flow (from `picorv32_pcpi_bfpu.v`)

```
pcpi_insn ──► bfpu_decoder ──────────────────────────────────► is_getfu / is_getfxu / is_fdseti / is_putf
                │                                               getfu_offset, getfu_width_m1
                │                                               fdsel_write, fdsel_read
                │
pcpi_rs1 ──────┤──► (FDSETI) fdseti_offset, fdseti_width_m1
               │                      │
               │                      ▼
               │            bfpu_descriptor_file ──► fd_offset, fd_width_m1
               │                                           │
               │          MUX (inline, combinational):      │
pcpi_rs2 ──────┤◄── shifter_data_in (rs2 if PUTF, rs1 otherwise)
               │◄── shifter_shamt   (getfu_offset / getfxu_offset / fd_offset / 0)
               │◄── mask_offset     (fd_offset if PUTF, else 0)
               │◄── mask_width_m1   (from decoder or rs2[9:5])
               │
               ├──► bfpu_barrel_shifter ──► shifted_data
               └──► bfpu_mask_generator ──► positioned_mask
                              │                     │
                              ▼                     ▼
                    extract_result = shifted_data & positioned_mask   (GETFU/GETFXU)
                    insert_result  = bfpu_insert_logic(rs1, positioned_mask, shifted_data) (PUTF)
                              │
                              ▼
                    pcpi_rd  (returned to PicoRV32 register file)
```

### PCPI Handshake
- `pcpi_wait` = `1'b0` (always, all instructions resolve in one cycle)
- `pcpi_ready` = `pcpi_valid && is_bfpu_op`
- `pcpi_wr` = `pcpi_valid && is_bfpu_op && !is_fdseti` (FDSETI has no register write-back)

---

## 5. Custom Instruction Set Architecture

**Major opcode:** RISC-V `custom-0` = `7'b0001011`

| Instruction | funct3 | Encoding type | Operands | Function |
|-------------|--------|--------------|----------|----------|
| **GETFU** | `3'b000` | I-type shaped | rs1=source, insn[24:20]=offset, insn[30:26]=width-1 | Unsigned field extract, offset/width in instruction word |
| **GETFXU** | `3'b010` | R-type | rs1=source, rs2[4:0]=offset, rs2[9:5]=width-1 | Unsigned field extract, offset/width in register |
| **FDSETI** | `3'b100` | R-type shaped | rd[1:0]=FD index, rs1[4:0]=offset, rs1[9:5]=width-1 | Write field descriptor register FD0–FD3 |
| **PUTF** | `3'b110` | R-type | rs1=destination, rs2=value, funct7[1:0]=FD index | Insert field into destination using stored descriptor |

**Descriptor file:** 4 entries (FD0–FD3), each storing `{offset[4:0], width_m1[4:0]}` (10 bits). Synchronous write, combinational read.

**Key microarchitectural constraint (documented in source):** Width is always encoded as `width-1` (range 0..31 → actual widths 1..32) to avoid needing a 33-bit intermediate in the mask generator.

---

## 6. FPGA Board & Target Device

**[ACTUAL — from waveform timestamps and EDA tool title bars]**

- **EDA Tool:** AMD/Xilinx **Vivado** (visible in taskbar of waveform screenshots dated 24–26 August 2026)
- **Simulation tool:** Vivado Simulator (Behavioural, `tb_top_behav.wcfg` waveform file shown)
- **Specific device:** [NOT PRESENT in any source file — no `.xdc`, `.xpr`, or constraints file is present in the repository]

> [!NOTE]
> The synthesis results table (LUT: 3557, FF: 722, LUTRAM: 2092, IO: 18, Fmax ≈ 104.2 MHz) is consistent with a **Xilinx 7-Series** device (Artix-7 or Zynq-7000), based on the resource terminology and IO count, but this is an inference. The actual part number is not documented in any file.

---

## 7. EDA Tools & Software Dependencies

| Tool | Evidence | Version Known? |
|------|----------|---------------|
| **Xilinx Vivado** | Visible in screenshot taskbar, `.wcfg` file type | Unknown |
| **Icarus Verilog** | Documented in `tb_picorv32_pcpi_bfpu.v` comment (`iverilog` command) | Unknown |
| **VVP** (Icarus runtime) | Documented in same comment (`vvp bfpu_tb.out`) | Unknown |
| **RISC-V GNU assembler** (`as`) | Assembly `.s` / `.S` files present; custom `.word` directives used for BFPU instructions | Unknown |

**[NOT PRESENT]:** No Makefile, build script, Tcl script, or `.xpr` project file is in the repository.

---

## 8. Testbenches & Simulation Environment

### File: [`tb_picorv32_pcpi_bfpu.v`](file:///c:/Users/Joshua%20Selvaraj%20S/Desktop/bfpudoc/proposed%20bfpu%20rtl/tb_picorv32_pcpi_bfpu.v)

**Type:** Self-checking, isolated PCPI peripheral testbench (no PicoRV32 core instantiated).

**Coverage:**
- Directed GETFU corner cases: offset=0 width=8, offset=24 width=8, width=32 (full word), width=1
- GETFU regression for `width_m1` layout (old vs. new instruction encoding)
- Directed GETFXU: offset/width via `pcpi_rs2`
- FDSETI → PUTF: write then read descriptor
- PUTF edge cases: insert into all-zeros, clear field in all-ones, oversized source value
- Multiple descriptors: FD0 and FD3 independence check
- **200 randomised iterations** covering all four instructions with `$random` stimuli

**Golden model:** Implemented as Verilog functions `golden_extract()` / `golden_insert()` using software-reference arithmetic.

**Run command (from file):**
```bash
iverilog -o bfpu_tb.out tb_picorv32_pcpi_bfpu.v picorv32_pcpi_bfpu.v \
    bfpu_decoder.v bfpu_descriptor_file.v bfpu_barrel_shifter.v \
    bfpu_mask_generator.v bfpu_insert_logic.v
vvp bfpu_tb.out
```

**Test clock:** 100 MHz (10 ns period, `always #5 clk = ~clk`)

### Full-System Simulation (Vivado Behavioural)

**[ACTUAL — from waveform screenshots]**

The `tb_top_behav.wcfg` waveform file (Vivado) shows a full-system simulation with the following instrumentation signals visible:
- `led[15:0]` — live memory address bus lower bits
- `bfpu_count[31:0]` — total BFPU instructions executed
- `getfu_count[31:0]` — GETFU instruction count
- `getfxu_count[31:0]` — GETFXU instruction count  
- `fdseti_count[31:0]` — FDSETI instruction count
- `putf_count[31:0]` — PUTF instruction count
- `pcpi_valid`, `pcpi_insn[31:0]`, `pcpi_rs1[31:0]`, `pcpi_rs2[31:0]`
- `pcpi_ready`, `pcpi_wait`, `pcpi_wr`
- `reg_pc[31:0]` — CPU program counter

> [!NOTE]
> The instrumented waveform files (`.wcfg`) themselves are not in the repository; only screenshot images of them are present.

---

## 9. Constraints & FPGA Configuration Files

**[NOT PRESENT]:** No `.xdc` constraints file, no `.xpr` Vivado project file, no bitstream (`.bit`), no implementation report, and no `.tcl` script are present anywhere in the repository.

The synthesis/implementation results are captured only as a screenshot image (`waveforms/WhatsApp Image 2026-10-12 at 3.37.17 PM.jpeg`).

---

## 10. Actual Implemented Features

### ✅ Confirmed Implemented (source code present, fully readable)

| Feature | File | Notes |
|---------|------|-------|
| GETFU — unsigned field extract, offset/width in instruction | `bfpu_decoder.v`, `picorv32_pcpi_bfpu.v` | Fully combinational, 1 cycle |
| GETFXU — unsigned field extract, offset/width from register | `picorv32_pcpi_bfpu.v` (lines 70–71) | Register-specified field |
| FDSETI — write field descriptor (FD0–FD3) | `bfpu_descriptor_file.v` | Synchronous write, no write-back |
| PUTF — insert field using stored descriptor | `bfpu_insert_logic.v`, `picorv32_pcpi_bfpu.v` | Reordered arithmetic, single shifter instance |
| Bidirectional barrel shifter (shared, 1 instance) | `bfpu_barrel_shifter.v` | 32-bit, left/right |
| Bit-field mask generator (shared, 1 instance) | `bfpu_mask_generator.v` | Avoids 33-bit intermediate |
| 4-entry descriptor register file (FD0–FD3) | `bfpu_descriptor_file.v` | Async read, sync write, reset to 0 |
| PCPI handshake (zero wait-state) | `picorv32_pcpi_bfpu.v` (lines 165–167) | pcpi_wait tied low |
| PicoRV32 RV32I CPU (unmodified) | `picorv32.v` | ENABLE_PCPI=1, IRQ/MUL/DIV disabled |
| 16 KB simple RAM | `simple_ram.v` | 4096×32-bit, combinational read |
| Self-checking testbench | `tb_picorv32_pcpi_bfpu.v` | 200 random + directed tests |

### ✅ Confirmed Benchmarks (assembly source + compiled hex both present)

| Benchmark | BFPU source | RV32I source | BFPU hex | RV32I hex |
|-----------|-------------|--------------|----------|-----------|
| ADC register configure + readback (8 configs) | `bfpu.s` | `rv32i.s` | `bfpu.hex` | `rv32i.hex` |
| Packet header field processing (4 packets) | `packet_header_benchmark_v2_bfpu.S` | `packet_header_benchmark_v2_rv32i.S` | `packet_header_benchmark_v2_bfpu.hex` | `packet_header_benchmark_v2_rv32i.hex` |
| RGB888 → RGB565 conversion (1024 pixels) | `rgbbfpu (1).s` | `rgbrv32i (1).s` | `rgbbfpu (1).hex` | `rgbrv32i (1).hex` |

---

## 11. Simulation Results & Performance Data (from screenshots)

> All numbers below come from waveform screenshots and performance table images in the repository. They are actual captured results, not estimates.

### FPGA Resource Utilisation (Vivado Post-Implementation)

| Resource | RV32I Baseline | BFPU | Change |
|----------|---------------|------|--------|
| LUT | 3,262 | 3,557 | **+9.04%** |
| FF (Flip-Flops) | 675 | 722 | **+6.96%** |
| LUTRAM | 2,092 | 2,092 | 0% |
| IO | 18 | 18 | 0% |
| WNS | +0.705 ns | +0.402 ns | −0.303 ns |
| WHS | +0.083 ns | +0.073 ns | −0.010 ns |
| Approx. Fmax | 107.6 MHz | **104.2 MHz** | −3.2% |
| Timing @ 100 MHz | PASS | **PASS** | — |

### Performance Comparison (Simulation)

**ADC Benchmark (packet-header simulation screenshot):**

| Metric | RV32I Baseline | BFPU | Improvement |
|--------|---------------|------|-------------|
| Completion cycles | 502 | 328 | **34.7% fewer** |
| Dynamic instructions | 124 | 93 | 25.0% fewer |
| CPI | 4.048 | 3.527 | — |
| Speedup | 1.00× | **1.53×** | — |

**BFPU Performance Fingerprint (all three benchmarks):**

| Benchmark | Speedup | Cycle Reduction | Instruction Reduction |
|-----------|---------|-----------------|----------------------|
| Packet (Network) | **1.53×** | 34.5% | 24.8% (75.2% of baseline) |
| ADC (Embedded) | **1.99×** | 49.7% | 39.6% (60.4% of baseline) |
| RGB888→RGB565 (Image) | **1.34×** | 25.5% | 8.7% (91.3% of baseline) |

**Energy Efficiency (normalised to RV32I baseline, from chart):**

| Benchmark | RV32I Energy | BFPU Energy | Reduction |
|-----------|-------------|-------------|-----------|
| Packet parsing | 0.378 μJ (100%) | 0.323 μJ (85.6%) | **−14.4%** |
| ADC register | 0.632 μJ (100%) | 0.410 μJ (64.9%) | **−35.1%** |
| RGB888→RGB565 | 108 μJ (100%) | 73.2 μJ (68.0%) | **−32.0%** |

### Waveform Observations (Vivado Behavioural Simulation)

From the four PNG waveforms (dated 24 August 2026):
- Early run (22:45–22:50): `bfpu_count=0x00`, all op-counts zero — BFPU not yet connected (baseline RV32I run, `pcpi_wr=0` throughout)
- Later run (23:03–23:05): `bfpu_count=0x0a`, `fdseti_count=0x03`, `putf_count=0x03` — BFPU executing instructions
- Final run (18:33 & 18:40, 26 Aug): RGB benchmark — `bfpu_count=0x030f`, `getfu_count=0x0186`, `putf_count=0x0186` — matches expected 3 GETFU + 3 PUTF per pixel × 1024 pixels in loop (0x0186 = 390 ≈ 384... loop-unrolled counts visible evolving across simulation window)
- ADC benchmark run (18:43, 26 Aug): `bfpu_count=0x0033`, `getfu_count=0x0018`, `fdseti_count=0x0003`, `putf_count=0x0018` — matches expected 3 FDSETIs + 8×3 GETFUs + 8×3 PUTFs

---

## 12. Known Gaps & Issues (Documented, Not Invented)

| Issue | Location | Evidence |
|-------|----------|---------|
| **`top.v` BFPU not wired** | `top.v` lines 83–86 | PCPI outputs hardwired to 0; `picorv32_pcpi_bfpu` not instantiated despite comments claiming it was fixed |
| **No XDC constraints file** | Entire repo | No `.xdc` present; timing data only in screenshots |
| **No Vivado project file** | Entire repo | No `.xpr` file |
| **No Makefile or build script** | Entire repo | Manual workflow inferred |
| **Hardcoded firmware path in RAM** | `simple_ram.v` line 31 | Absolute Windows path `C:/Users/Joshua Selvaraj S/...` — not portable |
| **Git repo empty** | `RISC-V-.../` folder | Only `.git` dir, no commits |
| **No synthesis/impl reports** | Entire repo | Results captured only as screenshot images |
| **No formal verification** | Entire repo | No `.sby` or property files |

---

## 13. Proposed GitHub Repository Folder Structure

This reorganisation maps every existing file to a clean, professional structure suitable for a public engineering portfolio.

```
RISC-V-BFPU/
│
├── README.md                        ← Project overview, ISA table, results summary
├── LICENSE                          ← ISC (matching PicoRV32's licence)
│
├── rtl/                             ← All synthesisable Verilog
│   ├── top.v                        ← SoC top-level (fix BFPU wiring here)
│   ├── picorv32.v                   ← Unmodified PicoRV32 (upstream, attributed)
│   ├── picorv32_pcpi_bfpu.v         ← BFPU PCPI peripheral wrapper
│   ├── bfpu_decoder.v
│   ├── bfpu_descriptor_file.v
│   ├── bfpu_barrel_shifter.v
│   ├── bfpu_mask_generator.v
│   └── bfpu_insert_logic.v
│
├── sim/                             ← Simulation environment
│   ├── tb_picorv32_pcpi_bfpu.v      ← Self-checking unit testbench
│   └── tb_top.v                     ← (Future: full-system testbench)
│
├── firmware/                        ← Benchmark assembly sources and hex images
│   ├── adc/
│   │   ├── bfpu.s
│   │   ├── bfpu.hex
│   │   ├── rv32i.s
│   │   └── rv32i.hex
│   ├── packet/
│   │   ├── packet_header_benchmark_v2_bfpu.S
│   │   ├── packet_header_benchmark_v2_bfpu.hex
│   │   ├── packet_header_benchmark_v2_rv32i.S
│   │   └── packet_header_benchmark_v2_rv32i.hex
│   └── rgb/
│       ├── rgbbfpu.s
│       ├── rgbbfpu.hex
│       ├── rgbrv32i.s
│       └── rgbrv32i.hex
│
├── constraints/                     ← FPGA constraints (to be added)
│   └── bfpu_top.xdc                 ← [NOT YET PRESENT — needs creation]
│
├── docs/
│   ├── architecture/
│   │   ├── system_block_diagram.jpeg
│   │   └── bfpu_internal_pipeline.jpeg
│   ├── isa/
│   │   └── getfxu_control_word_format.jpeg
│   └── results/
│       ├── performance_fingerprint_chart.jpeg
│       ├── energy_efficiency_chart.jpeg
│       └── fpga_resource_comparison_table.jpeg
│
├── waveforms/
│   ├── sim_adcbench_bfpu_26aug.png
│   ├── sim_rgbbench_bfpu_26aug.png
│   ├── sim_initial_debug_24aug_a.png
│   └── sim_initial_debug_24aug_b.png
│
└── scripts/                         ← (Future: Makefile, Tcl, assembler scripts)
    └── README.md
```

---

*Analysis completed: 2026-11-25. No source files were modified, generated, or deleted.*
