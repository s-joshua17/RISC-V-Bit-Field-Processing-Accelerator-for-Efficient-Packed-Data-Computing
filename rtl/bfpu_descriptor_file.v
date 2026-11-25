// -----------------------------------------------------------------------------
// bfpu_descriptor_file.v
//
// Purpose:
//   Stores 4 field descriptors (FD0-FD3), each holding an {offset, width-1}
//   pair (10 bits total per entry). FDSETI writes an entry; PUTF reads one.
//   Write port is synchronous (registered on clk); read port is
//   combinational (asynchronous).
//
// Why a combinational read is safe here:
//   PicoRV32 is a single-issue, non-pipelined core -- it never overlaps the
//   execution of two instructions. An FDSETI immediately followed by a PUTF
//   referencing the same descriptor therefore sees the fully updated value
//   with zero extra latency: the write completes on the clock edge that ends
//   FDSETI's (single) cycle, and the combinational read reflects that value
//   for the entirety of PUTF's own (later) cycle. No forwarding/bypass logic
//   is required.
//
// Reset behavior:
//   All four descriptors reset to {offset=0, width_m1=0} (i.e. width=1), a
//   well-defined single-bit-at-LSB field, rather than an undefined ('X')
//   value if PUTF is ever issued against a descriptor software never
//   configured.
// -----------------------------------------------------------------------------
module bfpu_descriptor_file (
    input  wire        clk,
    input  wire        resetn,

    input  wire        write_en,
    input  wire [1:0]  write_addr,
    input  wire [4:0]  write_offset,
    input  wire [4:0]  write_width_m1,

    input  wire [1:0]  read_addr,
    output wire [4:0]  read_offset,
    output wire [4:0]  read_width_m1
);

    reg [4:0] fd_offset   [0:3];
    reg [4:0] fd_width_m1 [0:3];

    integer i;
    always @(posedge clk) begin
        if (!resetn) begin
            for (i = 0; i < 4; i = i + 1) begin
                fd_offset[i]   <= 5'd0;
                fd_width_m1[i] <= 5'd0;
            end
        end else if (write_en) begin
            fd_offset[write_addr]   <= write_offset;
            fd_width_m1[write_addr] <= write_width_m1;
        end
    end

    // Combinational (asynchronous) read port -- see reasoning above.
    assign read_offset   = fd_offset[read_addr];
    assign read_width_m1 = fd_width_m1[read_addr];

endmodule
