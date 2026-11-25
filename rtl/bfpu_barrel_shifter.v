// -----------------------------------------------------------------------------
// bfpu_barrel_shifter.v
//
// Purpose:
//   Single shared, bidirectional logical barrel shifter.
//     - GETFU/GETFXU use it to shift the source operand (rs1) RIGHT by
//       `offset`, bringing the target field down to bit 0.
//     - PUTF uses the SAME instance to shift the value operand (rs2, already
//       bit-0-aligned) LEFT by the descriptor's offset, moving it into
//       position before the merge.
//   Exactly one shift is required per instruction (see picorv32_pcpi_bfpu.v
//   for the derivation), so one instance covers all four v1 instructions
//   with no duplicated shifter hardware.
// -----------------------------------------------------------------------------
module bfpu_barrel_shifter (
    input  wire [31:0] data_in,
    input  wire [4:0]  shamt,
    input  wire        shift_left,   // 0 = logical right, 1 = logical left
    output wire [31:0] data_out
);

    assign data_out = shift_left ? (data_in << shamt) : (data_in >> shamt);

endmodule
