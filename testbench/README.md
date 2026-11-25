# Testbench

## `tb_picorv32_pcpi_bfpu.v`

A self-checking, isolated verification testbench for the BFPU PCPI peripheral.
PicoRV32 is **not instantiated** — the PCPI port is driven directly, letting
the testbench validate the BFPU's decode, datapath, and handshake behaviour
in isolation before full-system integration.

---

## Test Structure

### Clock
- 10 ns period (100 MHz), `always #5 clk = ~clk`

### Reset
- Active-low `resetn`, de-asserted after 3 clock cycles

### Instruction Encoders (match `bfpu_decoder.v` exactly)
| Function | Encodes |
|----------|---------|
| `enc_getfu(offset, width_m1)` | GETFU I-type encoding |
| `enc_getfxu(dummy)` | GETFXU R-type encoding |
| `enc_fdseti(fdsel)` | FDSETI encoding with rd[1:0]=fdsel |
| `enc_putf(fdsel)` | PUTF encoding with funct7[1:0]=fdsel |

### Golden Model
Reference functions implemented in Verilog:
```verilog
golden_extract(val, offset, width_m1)  // → (val >> offset) & mask
golden_insert(dest, src, offset, width_m1) // → (dest & ~pmask) | ((src & mask) << offset)
```

---

## Directed Test Cases

| Test | Description |
|------|-------------|
| `GETFU offset0 width8` | Extract byte at bit 0 from `0xDEADBEEF` |
| `GETFU offset24 width8` | Extract top byte from `0xDEADBEEF` |
| `GETFU width32` | Full 32-bit extract from `0xFFFFFFFF` |
| `GETFU width1` | Single-bit extract |
| `GETFU width_m1 mid-value regression` | Verifies new `insn[30:26]` layout vs. old `insn[29:25]` |
| `GETFXU offset4 width4` | Extract nibble from `0x12345678` via rs2 control |
| `FDSETI FD0 (rs1-sourced)` | Write descriptor: offset=24, width=8 into FD0 |
| `PUTF FD0 into zero dest` | Insert `0xA5` at bit 24 of `0x00000000` |
| `PUTF clears field, preserves rest` | Insert `0x00` into all-ones — surrounding bits must survive |
| `PUTF oversized value masked correctly` | Insert `0xFFFFFFFF` — only field-width bits land |
| `FDSETI FD3` + `PUTF FD3` | Verify FD3 is independent of FD0 |

### Randomised Regression
```
for i = 0 to 199:
    rand_val, rand_val2 = $random
    rand_off = $random % 32
    rand_w   = $random % 32
    test: GETFU, GETFXU, FDSETI+PUTF (all checked against golden model)
```
**Total tests executed:** 807 directed + randomised checks  
**Expected output:** `ALL TESTS PASSED`

---

## Running the Testbench

### Icarus Verilog (recommended for quick iteration)

```bash
# From repository root
iverilog -o bfpu_tb.out \
    testbench/tb_picorv32_pcpi_bfpu.v \
    rtl/picorv32_pcpi_bfpu.v \
    rtl/bfpu_decoder.v \
    rtl/bfpu_descriptor_file.v \
    rtl/bfpu_barrel_shifter.v \
    rtl/bfpu_mask_generator.v \
    rtl/bfpu_insert_logic.v

vvp bfpu_tb.out
```

Expected terminal output (excerpt):
```
PASS [GETFU offset0 width8]
PASS [GETFU offset24 width8]
PASS [GETFU width32]
...
PASS [RAND PUTF FD1]
---------------------------------------------
PASS: 807   FAIL: 0
ALL TESTS PASSED
```

### Xilinx Vivado

1. Create project, add all RTL files and `testbench/tb_picorv32_pcpi_bfpu.v`
2. Set `tb_picorv32_pcpi_bfpu` as top simulation module
3. Run Behavioural Simulation → check transcript for `ALL TESTS PASSED`

---

## Handshake Verification

The testbench explicitly checks:
- `pcpi_ready` asserted on the cycle after `pcpi_valid` for every BFPU instruction
- `pcpi_wr` asserted for GETFU/GETFXU/PUTF; **not** asserted for FDSETI
- `pcpi_wait` remains low throughout (all instructions are single-cycle)
- `pcpi_rd` matches the golden model result for every extract/insert case
