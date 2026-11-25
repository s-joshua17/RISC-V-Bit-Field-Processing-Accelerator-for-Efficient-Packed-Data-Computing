// -----------------------------------------------------------------------------
// bfpu_insert_logic.v
//
// Purpose:
//   Final combinational merge for PUTF. Clears the target field in the
//   destination operand and ORs in the pre-shifted value, masked by the same
//   positioned_mask signal used to clear the destination (one mask value,
//   fanned out to two AND gates -- not two separate mask computations).
//
// Reordered-arithmetic datapath (approved):
//   The reference behavior is
//       destination = (destination & ~mask) | ((source & fieldmask) << offset)
//   This module instead computes
//       destination = (destination & ~positioned_mask)
//                     | ((source << offset) & positioned_mask)
//   i.e. it shifts first and masks after, using the *positioned* mask for
//   both the clear and the final merge. The two orderings are numerically
//   identical for every offset/width combination (masking after a left shift
//   with the correspondingly-positioned mask always isolates the same bit
//   window as masking before the shift). This ordering is what lets PUTF
//   need only ONE bfpu_mask_generator evaluation and ONE bfpu_barrel_shifter
//   evaluation per cycle instead of two of each, which is what makes a
//   single shared instance of each block sufficient for every v1
//   instruction while staying fully single-cycle. Verified against a
//   software golden model, including an explicit oversized-source-value
//   corner case, in the accompanying testbench.
// -----------------------------------------------------------------------------
module bfpu_insert_logic (
    input  wire [31:0] destination,      // pcpi_rs1 (current target value)
    input  wire [31:0] positioned_mask,  // ((1<<width)-1) << offset
    input  wire [31:0] shifted_value,    // rs2 << offset (unmasked)
    output wire [31:0] result
);

    assign result = (destination & ~positioned_mask) | (shifted_value & positioned_mask);

endmodule
