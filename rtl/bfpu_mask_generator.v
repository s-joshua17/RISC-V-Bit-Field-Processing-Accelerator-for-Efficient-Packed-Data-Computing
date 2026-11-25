// -----------------------------------------------------------------------------
// bfpu_mask_generator.v
//
// Purpose:
//   Computes a contiguous bit-field mask of the given width, positioned at
//   the given bit offset:
//
//       positioned_mask = ((1 << (width_m1+1)) - 1) << offset
//
//   Implemented as a right-shift-then-left-shift so it never needs a 33-bit
//   intermediate value or a special case in the arithmetic for width==32 --
//   this is the reason width is carried as width-1 (range 0..31) throughout
//   the whole ISA, both in instruction encodings and in the descriptor file.
//
// Single shared instance, two call patterns (see picorv32_pcpi_bfpu.v):
//   - GETFU / GETFXU tie `offset` to 0, obtaining the plain (unpositioned)
//     field mask, applied to the operand after it has already been shifted
//     right into place by bfpu_barrel_shifter.
//   - PUTF supplies the descriptor's real `offset`, obtaining the positioned
//     clear-mask, reused (fanned out, not recomputed) as the final merge
//     mask in bfpu_insert_logic.
// -----------------------------------------------------------------------------
module bfpu_mask_generator (
    input  wire [4:0]  width_m1,
    input  wire [4:0]  offset,
    output wire [31:0] positioned_mask
);

    // raw_mask has the low (width_m1+1) bits set, all others clear.
    //   width_m1 = 5'd31 -> shift amount 0  -> all 32 bits set (width==32)
    //   width_m1 = 5'd0  -> shift amount 31 -> only bit 0 set   (width==1)
    // Never evaluates (1 << 32): the widest left shift ever computed here is
    // by at most 31, and the widest value shifted is a 32-bit constant, so
    // no intermediate value needs more than 32 bits.
    wire [31:0] raw_mask = 32'hFFFFFFFF >> (5'd31 - width_m1);

    assign positioned_mask = raw_mask << offset;

endmodule
