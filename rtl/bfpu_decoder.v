// -----------------------------------------------------------------------------
// bfpu_decoder.v
//
// Purpose:
//   Combinational instruction decoder for the BFPU PCPI peripheral. Inspects
//   the raw instruction word forwarded by PicoRV32's PCPI interface and
//   produces one-hot operation-select signals plus GETFU's immediate
//   sub-fields. Performs no arithmetic -- purely field extraction and
//   opcode/funct3 comparison.
//
// Encoding (custom-0 major opcode, RISC-V 7'b0001011):
//   funct3 = 3'b000 : GETFU   I-type-shaped, finalized layout:
//                        pcpi_insn[24:20] = offset
//                        pcpi_insn[30:26] = width_m1 (width-1)
//                        pcpi_insn[31] and pcpi_insn[25] are reserved (0)
//   funct3 = 3'b010 : GETFXU  R-type. offset/width-1 come from the VALUE in
//                              rs2 (pcpi_rs2[4:0]/pcpi_rs2[9:5]) -- unpacked
//                              at the top level, not here.
//   funct3 = 3'b100 : FDSETI  R-type-shaped. rd[1:0] (inst[8:7]) selects the
//                              descriptor register FD0..FD3. offset/width-1
//                              come from the VALUE in rs1
//                              (pcpi_rs1[4:0]/pcpi_rs1[9:5]) -- also
//                              unpacked at the top level, not here. FDSETI
//                              carries no instruction-encoded immediate.
//   funct3 = 3'b110 : PUTF    R-type. funct7[1:0] (inst[26:25]) selects which
//                              descriptor register to read.
//   funct3 = 3'b001/011/101/111 : reserved for GETFS/GETFXS/future work --
//                              decoded as "not a v1 BFPU op" here.
//
// Width is always encoded/carried as width-1 (5 bits, range 0..31 => width
// 1..32) so no field in this design ever needs to represent "32" as a raw
// value -- see bfpu_mask_generator.v for why that matters.
// -----------------------------------------------------------------------------
module bfpu_decoder (
    input  wire [31:0] pcpi_insn,

    output wire         is_bfpu_op,
    output wire         is_getfu,
    output wire         is_getfxu,
    output wire         is_fdseti,
    output wire         is_putf,

    output wire [4:0]   getfu_offset,
    output wire [4:0]   getfu_width_m1,

    output wire [1:0]   fdsel_write,
    output wire [1:0]   fdsel_read
);

    localparam [6:0] OPCODE_CUSTOM0 = 7'b0001011;

    wire [6:0] opcode = pcpi_insn[6:0];
    wire [2:0] funct3 = pcpi_insn[14:12];
    wire [6:0] funct7 = pcpi_insn[31:25];
    wire [4:0] rd     = pcpi_insn[11:7];

    assign is_bfpu_op = (opcode == OPCODE_CUSTOM0);

    assign is_getfu   = is_bfpu_op && (funct3 == 3'b000);
    assign is_getfxu  = is_bfpu_op && (funct3 == 3'b010);
    assign is_fdseti  = is_bfpu_op && (funct3 == 3'b100);
    assign is_putf    = is_bfpu_op && (funct3 == 3'b110);

    // GETFU immediate fields only. pcpi_insn[31] and pcpi_insn[25] are the
    // two reserved bits in the finalized layout and are simply not read.
    assign getfu_offset   = pcpi_insn[24:20];
    assign getfu_width_m1 = pcpi_insn[30:26];

    // Descriptor index fields (used by FDSETI and PUTF respectively).
    assign fdsel_write = rd[1:0];       // FDSETI writes FD[rd[1:0]]
    assign fdsel_read  = funct7[1:0];   // PUTF reads FD[funct7[1:0]]

endmodule
