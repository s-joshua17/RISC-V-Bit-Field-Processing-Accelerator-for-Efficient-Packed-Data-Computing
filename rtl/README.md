# RTL Source Files

This directory contains all synthesisable Verilog RTL for the BFPU SoC.

---

## Module Hierarchy

```
top
├── picorv32          (unmodified PicoRV32 RV32I CPU)
├── picorv32_pcpi_bfpu  (BFPU PCPI peripheral)
│   ├── bfpu_decoder
│   ├── bfpu_descriptor_file
│   ├── bfpu_barrel_shifter
│   ├── bfpu_mask_generator
│   └── bfpu_insert_logic
└── simple_ram
```

---

## File Descriptions

| File | Type | Lines | Description |
|------|------|-------|-------------|
| `top.v` | Mixed | 103 | SoC top: wires PicoRV32 + BFPU + RAM. `led[15:0] = mem_addr[15:0]`. See note below. |
| `picorv32.v` | Sequential | 3072 | Unmodified PicoRV32 RV32I core (Claire Wolf / YosysHQ, ISC). `ENABLE_PCPI=1`. |
| `picorv32_pcpi_bfpu.v` | Combinational | 170 | BFPU PCPI peripheral: decoder + mux + submodule instantiation + handshake |
| `bfpu_decoder.v` | Combinational | 74 | Pure combinational; extracts opcode/funct3/funct7/immediates |
| `bfpu_descriptor_file.v` | Sequential | 60 | 4×10-bit descriptor registers; synchronous write, asynchronous read |
| `bfpu_barrel_shifter.v` | Combinational | 25 | Shared bidirectional 32-bit logical barrel shifter |
| `bfpu_mask_generator.v` | Combinational | 40 | Contiguous bit-field mask: `raw_mask >> (31-w) << offset` |
| `bfpu_insert_logic.v` | Combinational | 38 | PUTF merge: `(dest & ~pmask) \| (shifted_val & pmask)` |
| `simple_ram.v` | Mixed | 99 | 16 KB (4096×32-bit) RAM; combinational read; synchronous byte-lane write |

---

## Open Item — `top.v` PCPI Wiring

Lines 83–86 of `top.v` currently **hardwire** the PCPI output signals to zero:

```verilog
assign pcpi_wr    = 1'b0;
assign pcpi_rd    = 32'b0;
assign pcpi_wait  = 1'b0;
assign pcpi_ready = 1'b0;
```

The `picorv32_pcpi_bfpu` module is **not instantiated** in `top.v` in its current
state. The BFPU has been fully verified in isolation via `testbench/tb_picorv32_pcpi_bfpu.v`
and in a separate system-level simulation. Connecting it in `top.v` requires
replacing those four `assign` statements with:

```verilog
picorv32_pcpi_bfpu u_bfpu (
    .clk        (clk),
    .resetn     (~reset),
    .pcpi_valid (pcpi_valid),
    .pcpi_insn  (pcpi_insn),
    .pcpi_rs1   (pcpi_rs1),
    .pcpi_rs2   (pcpi_rs2),
    .pcpi_wr    (pcpi_wr),
    .pcpi_rd    (pcpi_rd),
    .pcpi_wait  (pcpi_wait),
    .pcpi_ready (pcpi_ready)
);
```

---

## Synthesis Notes

- Target: Xilinx 7-series device (synthesised with Vivado)
- Clock: 100 MHz target — timing **PASS** for both baseline and BFPU configurations
- BFPU adds ~295 LUTs (+9%) and ~47 FFs (+7%) over the plain RV32I+RAM baseline
- PicoRV32 itself (`picorv32.v`) is included verbatim and is **not modified**
