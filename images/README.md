# Simulation Waveforms and Results

This directory contains captured simulation and synthesis results.

---

## `simulation/` — Vivado Behavioural Simulation Waveforms

All waveforms were captured using Vivado Behavioural Simulation (`tb_top_behav.wcfg`).
The instrumentation signals visible in every waveform are:

| Signal | Description |
|--------|-------------|
| `clk`, `reset` | System clock and reset |
| `led[15:0]` | Live `mem_addr[15:0]` — shows active memory bus activity |
| `bfpu_count[31:0]` | Running count of all BFPU instructions executed |
| `getfu_count[31:0]` | GETFU instructions executed |
| `getfxu_count[31:0]` | GETFXU instructions executed |
| `fdseti_count[31:0]` | FDSETI instructions executed |
| `putf_count[31:0]` | PUTF instructions executed |
| `pcpi_valid/insn/rs1/rs2` | PCPI request bus |
| `pcpi_ready/wait/wr` | PCPI response handshake |
| `reg_pc[31:0]` | PicoRV32 program counter |

### Waveform Files

| File | Firmware | Key Observations |
|------|----------|-----------------|
| `waveform_adcbench_counts.png` | ADC BFPU | `bfpu_count=0x33` (51), `getfu_count=0x18` (24), `fdseti_count=3`, `putf_count=0x18` (24) — matches 3 FDSETIs + 8×3 GETFUs + 8×3 PUTFs |
| `waveform_adcbench_final.png` | ADC BFPU (2 ms window) | Programme settled; `bfpu_count=0x1803`, instruction counts stable |
| `waveform_rgbbench_fullrun.png` | RGB BFPU (99 µs) | `bfpu_count=0x030f` (783 = 3×1024 ops = 1024 pixels × 3 GETFU + 3 PUTF / pixel, with 3 FDSETIs at start) |
| `waveform_rgbbench_detail.png` | RGB BFPU (99 µs alt) | Shows `getfu_count=0x0186` (390 ≈ 3×130 — mid-loop snapshot), `putf_count=0x0183` |
| `waveform_packet_benchmark.jpeg` | Packet BFPU (1 µs) | Early FDSETI phase visible; PCPI transactions shown at fine timescale |
| `waveform_adcbench_early.jpeg` | Pre-BFPU debug run | `bfpu_count=0` — BFPU not yet connected; demonstrates baseline RV32I-only execution |
| `waveform_adcbench_early_b.jpeg` | Pre-BFPU debug run B | As above, different time window |
| `waveform_rgbbench_early.jpeg` | Early RGB run | First version of system integration; `bfpu_count` incrementing |

---

## `evaluation/` — Synthesis and Performance Results

| File | Content |
|------|---------|
| `fpga_resource_comparison.jpeg` | Vivado post-implementation resource utilisation table: LUT/FF/LUTRAM/IO/WNS/Fmax for baseline and BFPU |
| `benchmark_performance_table.jpeg` | Simulation-derived performance table: completion cycles, dynamic instructions, CPI, speedup (ADC benchmark) |
| `performance_fingerprint.jpeg` | Line chart across all 3 benchmarks: dynamic instructions, execution cycles, CPI — BFPU as % of RV32I |
| `energy_efficiency.jpeg` | Bar chart: energy per completed workload for all 3 benchmarks (BFPU vs RV32I baseline) |

### Key Numbers At a Glance

#### Resource Utilisation

| Metric | RV32I Baseline | BFPU System | Δ |
|--------|---------------|-------------|---|
| LUT | 3,262 | 3,557 | +9.04% |
| FF | 675 | 722 | +6.96% |
| LUTRAM | 2,092 | 2,092 | 0% |
| IO | 18 | 18 | 0% |
| WNS | +0.705 ns | +0.402 ns | −0.303 ns |
| Fmax (approx) | 107.6 MHz | 104.2 MHz | −3.2% |
| Timing @ 100 MHz | **PASS** | **PASS** | — |

#### Execution Performance

| Benchmark | Speedup | Cycle Reduction | Energy Reduction |
|-----------|---------|----------------|-----------------|
| ADC Config (Embedded) | **1.99×** | 49.7% | 35.1% |
| Packet Header (Network) | **1.53×** | 34.5% | 14.4% |
| RGB888→RGB565 (Graphics) | **1.34×** | 25.5% | 32.0% |
