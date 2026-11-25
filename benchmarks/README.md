# Benchmarks

This directory contains all benchmark programs used to evaluate the BFPU against
a plain RV32I baseline. Each benchmark is provided in both BFPU-accelerated and
RV32I-only variants so the comparison is exact and fair.

---

## Directory Layout

```
benchmarks/
├── assembly/
│   ├── adc/          ADC register configuration benchmark (assembly source)
│   ├── packet/       Packet-header field-processing benchmark (assembly source)
│   └── rgb/          RGB888→RGB565 pixel-format conversion (assembly source)
│
└── firmware/
    ├── adc/          Compiled hex images for ADC benchmark
    ├── packet/       Compiled hex images for packet benchmark
    ├── rgb/          Compiled hex images for RGB benchmark
    └── misc/         General-purpose and smoke-test firmware images
```

---

## Benchmark Descriptions

### 1. ADC Register Configuration (`adc/`)

**Domain:** Embedded / IoT  
**Files:** `bfpu.s` / `rv32i.s` → `bfpu.hex` / `rv32i.hex`

Simulates configuring three STM32-style ADC control registers (CR1, CR2, SQR3)
across 8 successive configurations. Each configuration writes three fields and
reads them back to accumulate a checksum.

| Field  | Register | Bit Position | Width |
|--------|----------|-------------|-------|
| RES    | CR1      | [25:24]     | 2 bits |
| CH     | SQR3     | [4:0]       | 5 bits |
| TRIG   | CR2      | [27:24]     | 4 bits |

**RV32I approach:** Requires pre-computed clear-masks, 3–5 instructions per field.  
**BFPU approach:** Three `FDSETI` instructions once at startup; then one `PUTF` / `GETFU` per field operation.

**Results:** 1.99× speedup, 49.7% cycle reduction, 35.1% energy reduction.

---

### 2. Packet Header Field Processing (`packet/`)

**Domain:** Networking / Protocol Processing  
**Files:** `packet_header_benchmark_v2_bfpu.S` / `packet_header_benchmark_v2_rv32i.S`  
→ `packet_header_benchmark_v2_bfpu.hex` / `packet_header_benchmark_v2_rv32i.hex`

Processes 4 IPv4 packet headers. For each packet:
- Extracts: DSCP[23:18], TTL[15:8], Protocol[7:0] from two 32-bit header words
- Updates: DSCP=42, TTL=64, Protocol=17 (all packets normalised)
- Accumulates a checksum; validates against expected value at the end
- Writes PASS=1 or FAIL=0 to RAM[0x404]

**Results:** 1.53× speedup, 34.5% cycle reduction, 14.4% energy reduction.

---

### 3. RGB888 → RGB565 Pixel Format Conversion (`rgb/`)

**Domain:** Graphics / Display Processing  
**Files:** `rgbbfpu.s` / `rgbrv32i.s` → `rgbbfpu.hex` / `rgbrv32i.hex`

Converts 1024 deterministically-generated RGB888 pixels to 16-bit RGB565 format.

| Channel | RGB888 bits | RGB565 target bits | Width |
|---------|------------|-------------------|-------|
| R       | [23:19]    | [15:11]           | 5 bits |
| G       | [15:10]    | [10:5]            | 6 bits |
| B       | [7:3]      | [4:0]             | 5 bits |

Pixel stream is generated with a deterministic linear recurrence (no external memory required).
Checksum and last pixel value compared against software golden model.

**Results:** 1.34× speedup, 25.5% cycle reduction, 32.0% energy reduction.

---

### 4. Misc Firmware (`misc/`)

| File              | Description |
|-------------------|-------------|
| `firmwarebfpu.hex` | General BFPU firmware image |
| `firmware.hex`     | General RV32I firmware image |
| `firmwaretest.hex` | Minimal smoke-test: single GETFXU + PUTF, checks result, writes PASS/FAIL |
| `bitmapbfpu.hex`   | Bitmap processing workload (BFPU version) |
| `bitmaprv32i.hex`  | Bitmap processing workload (RV32I baseline) |

---

## Assembling from Source

The assembly sources use standard RISC-V assembly syntax with custom BFPU
instructions encoded as `.word` directives (since the assembler does not natively
know the custom-0 opcode).

```bash
# Example: assemble ADC BFPU benchmark
riscv32-unknown-elf-as -march=rv32i -mabi=ilp32 \
    benchmarks/assembly/adc/bfpu.s \
    -o bfpu_adc.o

riscv32-unknown-elf-objcopy -O verilog bfpu_adc.o bfpu.hex
```

> **Note:** Pre-assembled `.hex` files are provided in `benchmarks/firmware/`
> for immediate use in simulation without requiring a RISC-V toolchain.
