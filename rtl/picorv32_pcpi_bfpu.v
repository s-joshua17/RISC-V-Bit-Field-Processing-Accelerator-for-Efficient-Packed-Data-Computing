// -----------------------------------------------------------------------------
// picorv32_pcpi_bfpu.v
//
// Purpose:
//   Top-level BFPU PCPI peripheral for PicoRV32. Implements GETFU, GETFXU,
//   FDSETI, PUTF entirely through PicoRV32's existing, unmodified PCPI port
//   (requires ENABLE_PCPI=1 on the picorv32 instance) -- no changes to
//   picorv32.v's decoder, ALU, register file, pipeline, or control FSM are
//   required or made anywhere in this design.
//
//   The operand-select "mux" logic (which value/shift-amount/direction the
//   shared shifter and mask generator receive, per instruction) is
//   implemented directly in this module as plain continuous assignments
//   rather than as a separate bfpu_mux.v file, per the finalized module
//   list for this build.
//
// Design decision (flagged previously, approved, implemented here):
//   PUTF's reference behavior needs, in principle, two masked/positioned
//   quantities per cycle -- a clear-mask for the destination and a
//   masked-and-shifted value to merge in. Computing both the direct way
//   would need two shifter uses and two mask-generator uses in the same
//   cycle: either duplicated hardware, or two cycles. Instead, PUTF shifts
//   the (bit-0-aligned) value left by the descriptor's offset FIRST, then
//   masks the shifted result with the descriptor's positioned_mask -- the
//   same positioned_mask signal also used to clear the destination. This is
//   numerically identical to the reference "mask first, then shift" order
//   for every offset/width combination, and it means every one of the four
//   v1 instructions needs exactly one shifter evaluation and one
//   mask-generator evaluation per cycle, so one shared instance of each
//   suffices with zero duplicated hardware and full single-cycle timing.
//   This is a microarchitectural decision only -- no encoding or
//   instruction semantics changed.
// -----------------------------------------------------------------------------
module picorv32_pcpi_bfpu (
    input  wire        clk,
    input  wire        resetn,

    input  wire        pcpi_valid,
    input  wire [31:0] pcpi_insn,
    input  wire [31:0] pcpi_rs1,
    input  wire [31:0] pcpi_rs2,

    output wire        pcpi_wr,
    output wire [31:0] pcpi_rd,
    output wire        pcpi_wait,
    output wire        pcpi_ready
);

    // ---- Decode ---------------------------------------------------------------
    wire is_bfpu_op, is_getfu, is_getfxu, is_fdseti, is_putf;
    wire [4:0] getfu_offset, getfu_width_m1;
    wire [1:0] fdsel_write, fdsel_read;

    bfpu_decoder u_decoder (
        .pcpi_insn      (pcpi_insn),
        .is_bfpu_op     (is_bfpu_op),
        .is_getfu       (is_getfu),
        .is_getfxu      (is_getfxu),
        .is_fdseti      (is_fdseti),
        .is_putf        (is_putf),
        .getfu_offset   (getfu_offset),
        .getfu_width_m1 (getfu_width_m1),
        .fdsel_write    (fdsel_write),
        .fdsel_read     (fdsel_read)
    );

    // ---- GETFXU control-word unpack --------------------------------------------
    // GETFXU's offset/width live in the VALUE of rs2 (pcpi_rs2), not in the
    // instruction word -- plain wiring, not decoder logic.
    wire [4:0] getfxu_offset   = pcpi_rs2[4:0];
    wire [4:0] getfxu_width_m1 = pcpi_rs2[9:5];

    // ---- FDSETI control-word unpack --------------------------------------------
    // FDSETI's offset/width live in the VALUE of rs1 (pcpi_rs1), not in the
    // instruction word -- exactly parallel to GETFXU's rs2 unpack above.
    // FDSETI carries no instruction-encoded immediate in this finalized
    // architecture.
    wire [4:0] fdseti_offset   = pcpi_rs1[4:0];
    wire [4:0] fdseti_width_m1 = pcpi_rs1[9:5];

    // ---- Descriptor file --------------------------------------------------------
    wire [4:0] fd_offset, fd_width_m1;

    bfpu_descriptor_file u_fdfile (
        .clk            (clk),
        .resetn         (resetn),
        .write_en       (pcpi_valid && is_fdseti),
        .write_addr     (fdsel_write),
        .write_offset   (fdseti_offset),
        .write_width_m1 (fdseti_width_m1),
        .read_addr      (fdsel_read),
        .read_offset    (fd_offset),
        .read_width_m1  (fd_width_m1)
    );

    // ---- Shared shifter / mask-generator operand select (inlined mux) ----------
    // Shift direction: PUTF shifts left (moving the value into position);
    // GETFU/GETFXU shift right (bringing the field down to bit 0).
    wire shifter_dir = is_putf;

    // Shift operand: PUTF shifts rs2 (the value); GETFU/GETFXU shift rs1
    // (the source word being extracted from).
    wire [31:0] shifter_data_in = is_putf ? pcpi_rs2 : pcpi_rs1;

    wire [4:0] shifter_shamt =
        is_getfu  ? getfu_offset   :
        is_getfxu ? getfxu_offset  :
        is_putf   ? fd_offset      :
                    5'd0;

    // Mask offset: GETFU/GETFXU need the plain (unpositioned) field mask,
    // applied *after* the shift, so offset is tied to 0 for them. PUTF needs
    // the mask positioned at the descriptor's real offset.
    wire [4:0] mask_offset = is_putf ? fd_offset : 5'd0;

    wire [4:0] mask_width_m1 =
        is_getfu  ? getfu_width_m1  :
        is_getfxu ? getfxu_width_m1 :
        is_putf   ? fd_width_m1     :
                    5'd0;

    // ---- Shared barrel shifter (single instance) --------------------------------
    wire [31:0] shifter_data_out;

    bfpu_barrel_shifter u_shifter (
        .data_in    (shifter_data_in),
        .shamt      (shifter_shamt),
        .shift_left (shifter_dir),
        .data_out   (shifter_data_out)
    );

    // ---- Shared mask generator (single instance) --------------------------------
    wire [31:0] positioned_mask;

    bfpu_mask_generator u_maskgen (
        .width_m1        (mask_width_m1),
        .offset          (mask_offset),
        .positioned_mask (positioned_mask)
    );

    // ---- Extract result (GETFU / GETFXU) -----------------------------------------
    // Shift already brought the field to bit 0; positioned_mask (offset==0
    // in this case) is exactly the plain field mask.
    wire [31:0] extract_result = shifter_data_out & positioned_mask;

    // ---- Insert result (PUTF) -----------------------------------------------------
    wire [31:0] insert_result;

    bfpu_insert_logic u_insert (
        .destination     (pcpi_rs1),
        .positioned_mask (positioned_mask),
        .shifted_value   (shifter_data_out),
        .result          (insert_result)
    );

    // ---- Final write-back value ------------------------------------------------------
    assign pcpi_rd = is_putf ? insert_result : extract_result;

    // ---- PCPI handshake -------------------------------------------------------------------
    // All four v1 instructions resolve combinationally in the same cycle
    // pcpi_valid is asserted, so pcpi_wait is permanently tied low.
    // FDSETI updates only the descriptor file (synchronously, on this same
    // clock edge) and produces no register result, so it is excluded from
    // pcpi_wr; pcpi_ready is still asserted for it so the core does not stall.
    assign pcpi_wait  = 1'b0;
    assign pcpi_ready = pcpi_valid && is_bfpu_op;
    assign pcpi_wr    = pcpi_valid && is_bfpu_op && !is_fdseti;

endmodule
