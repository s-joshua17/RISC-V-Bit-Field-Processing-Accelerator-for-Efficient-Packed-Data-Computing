// -----------------------------------------------------------------------------
// tb_picorv32_pcpi_bfpu.v
//
// Self-checking testbench for picorv32_pcpi_bfpu. Drives the PCPI ports
// directly (no full PicoRV32 core instantiated) -- this validates the
// peripheral's own decode, datapath, and handshake behavior in isolation,
// against a software golden model, as the first level of verification
// before hand-assembled full-core FPGA validation.
//
// Run with, e.g.:
//   iverilog -o bfpu_tb.out tb_picorv32_pcpi_bfpu.v picorv32_pcpi_bfpu.v \
//       bfpu_decoder.v bfpu_descriptor_file.v bfpu_barrel_shifter.v \
//       bfpu_mask_generator.v bfpu_insert_logic.v
//   vvp bfpu_tb.out
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_picorv32_pcpi_bfpu;

    reg clk = 0;
    reg resetn = 0;

    reg         pcpi_valid;
    reg  [31:0] pcpi_insn;
    reg  [31:0] pcpi_rs1;
    reg  [31:0] pcpi_rs2;

    wire        pcpi_wr;
    wire [31:0] pcpi_rd;
    wire        pcpi_wait;
    wire        pcpi_ready;

    integer pass_count = 0;
    integer fail_count = 0;

    picorv32_pcpi_bfpu dut (
        .clk        (clk),
        .resetn     (resetn),
        .pcpi_valid (pcpi_valid),
        .pcpi_insn  (pcpi_insn),
        .pcpi_rs1   (pcpi_rs1),
        .pcpi_rs2   (pcpi_rs2),
        .pcpi_wr    (pcpi_wr),
        .pcpi_rd    (pcpi_rd),
        .pcpi_wait  (pcpi_wait),
        .pcpi_ready (pcpi_ready)
    );

    always #5 clk = ~clk; // 100 MHz test clock

    // ---- Instruction encoders (must match bfpu_decoder.v exactly) -------------
    localparam [6:0] OPC = 7'b0001011;

    // GETFU: insn[31]=0, insn[30:26]=width_m1, insn[25]=0, insn[24:20]=offset
    function [31:0] enc_getfu(input [4:0] offset, input [4:0] width_m1);
        enc_getfu = {1'b0, width_m1, 1'b0, offset, 5'd1, 3'b000, 5'd3, OPC};
    endfunction

    // GETFXU: offset/width come from pcpi_rs2's contents, not this encoding.
    // `dummy` exists only because Verilog-2001 requires >=1 function argument.
    function [31:0] enc_getfxu(input dummy);
        enc_getfxu = {7'd0, 5'd2, 5'd1, 3'b010, 5'd3, OPC};
    endfunction

    // FDSETI: offset/width come from pcpi_rs1's contents, not this encoding.
    // Only the descriptor select (rd[1:0]) and funct3 matter here.
    function [31:0] enc_fdseti(input [1:0] fdsel);
        enc_fdseti = {7'd0, 5'd0, 5'd1, 3'b100, 3'b000, fdsel, OPC};
    endfunction

    function [31:0] enc_putf(input [1:0] fdsel);
        enc_putf = {5'b00000, fdsel, 5'd2, 5'd1, 3'b110, 5'd3, OPC};
    endfunction

    // ---- Golden model -----------------------------------------------------------
    function [31:0] golden_extract(input [31:0] val, input [4:0] offset, input [4:0] width_m1);
        reg [31:0] mask;
        begin
            mask = (width_m1 == 5'd31) ? 32'hFFFFFFFF : ((32'h1 << (width_m1 + 1)) - 1);
            golden_extract = (val >> offset) & mask;
        end
    endfunction

    function [31:0] golden_insert(input [31:0] dest, input [31:0] src, input [4:0] offset, input [4:0] width_m1);
        reg [31:0] mask, pmask;
        begin
            mask  = (width_m1 == 5'd31) ? 32'hFFFFFFFF : ((32'h1 << (width_m1 + 1)) - 1);
            pmask = mask << offset;
            golden_insert = (dest & ~pmask) | ((src & mask) << offset);
        end
    endfunction

    // ---- Directed test task -------------------------------------------------------
    task run_check(input [31:0] expected, input check_wr, input [127:0] name);
        begin
            @(posedge clk);
            #1;
            if (pcpi_ready !== 1'b1) begin
                $display("FAIL [%0s]: pcpi_ready not asserted", name);
                fail_count = fail_count + 1;
            end else if (check_wr && pcpi_wr !== 1'b1) begin
                $display("FAIL [%0s]: pcpi_wr not asserted when expected", name);
                fail_count = fail_count + 1;
            end else if (check_wr && pcpi_rd !== expected) begin
                $display("FAIL [%0s]: got %h expected %h", name, pcpi_rd, expected);
                fail_count = fail_count + 1;
            end else if (!check_wr && pcpi_wr !== 1'b0) begin
                $display("FAIL [%0s]: pcpi_wr asserted when it should not be (FDSETI)", name);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [%0s]", name);
                pass_count = pass_count + 1;
            end
            pcpi_valid = 0;
            @(posedge clk);
        end
    endtask

    integer i;
    reg [31:0] rand_val, rand_val2;
    reg [4:0] rand_off, rand_w;

    initial begin
        pcpi_valid = 0;
        pcpi_insn  = 32'd0;
        pcpi_rs1   = 32'd0;
        pcpi_rs2   = 32'd0;

        repeat (3) @(posedge clk);
        resetn = 1;
        @(posedge clk);

        // --- Directed GETFU corner cases, exercising the corrected bit layout ---
        pcpi_rs1 = 32'hDEADBEEF;
        pcpi_insn = enc_getfu(5'd0, 5'd7);   // offset=0, width=8
        pcpi_valid = 1;
        run_check(golden_extract(32'hDEADBEEF, 5'd0, 5'd7), 1, "GETFU offset0 width8");

        pcpi_rs1 = 32'hDEADBEEF;
        pcpi_insn = enc_getfu(5'd24, 5'd7);  // offset=24, width=8
        pcpi_valid = 1;
        run_check(golden_extract(32'hDEADBEEF, 5'd24, 5'd7), 1, "GETFU offset24 width8");

        pcpi_rs1 = 32'hFFFFFFFF;
        pcpi_insn = enc_getfu(5'd0, 5'd31);  // width=32, exercises width_m1 top bit at insn[30]
        pcpi_valid = 1;
        run_check(golden_extract(32'hFFFFFFFF, 5'd0, 5'd31), 1, "GETFU width32");

        pcpi_rs1 = 32'h00000001;
        pcpi_insn = enc_getfu(5'd0, 5'd0);   // width=1
        pcpi_valid = 1;
        run_check(golden_extract(32'h00000001, 5'd0, 5'd0), 1, "GETFU width1");

        pcpi_rs1 = 32'hA5A5A5A5;
        pcpi_insn = enc_getfu(5'd20, 5'd15); // width_m1=15 (0b01111) exercises the
                                              // insn[30:26] field's mid bits distinctly
                                              // from the old insn[29:25] layout
        pcpi_valid = 1;
        run_check(golden_extract(32'hA5A5A5A5, 5'd20, 5'd15), 1, "GETFU width_m1 mid-value regression check");

        // --- Directed GETFXU: offset/width from pcpi_rs2 ----------------------
        pcpi_rs1 = 32'h12345678;
        pcpi_rs2 = {22'd0, 5'd3 /*width_m1*/, 5'd4 /*offset*/};
        pcpi_insn = enc_getfxu(1'b0);
        pcpi_valid = 1;
        run_check(golden_extract(32'h12345678, 5'd4, 5'd3), 1, "GETFXU offset4 width4");

        // --- FDSETI (offset/width now supplied via pcpi_rs1) then PUTF ----------
        pcpi_rs1 = {22'd0, 5'd7 /*width_m1*/, 5'd24 /*offset*/}; // control word in rs1
        pcpi_insn = enc_fdseti(2'd0); // FD0
        pcpi_valid = 1;
        run_check(32'd0, 0, "FDSETI FD0 (rs1-sourced)");

        pcpi_rs1 = 32'h00000000; // destination (rs1 reused: FDSETI's control word
                                  // has already been consumed and stored)
        pcpi_rs2 = 32'h000000A5; // source value, bit-0 aligned
        pcpi_insn = enc_putf(2'd0);
        pcpi_valid = 1;
        run_check(golden_insert(32'h00000000, 32'h000000A5, 5'd24, 5'd7), 1, "PUTF FD0 into zero dest");

        pcpi_rs1 = 32'hFFFFFFFF; // destination all-ones: verify surrounding bits preserved
        pcpi_rs2 = 32'h00000000; // insert all-zero field
        pcpi_insn = enc_putf(2'd0);
        pcpi_valid = 1;
        run_check(golden_insert(32'hFFFFFFFF, 32'h00000000, 5'd24, 5'd7), 1, "PUTF clears field, preserves rest");

        pcpi_rs1 = 32'hFFFFFFFF;
        pcpi_rs2 = 32'hFFFFFFFF; // oversized value: only low `width` bits of the
                                  // field should land, upper garbage must be dropped
        pcpi_insn = enc_putf(2'd0);
        pcpi_valid = 1;
        run_check(golden_insert(32'hFFFFFFFF, 32'hFFFFFFFF, 5'd24, 5'd7), 1, "PUTF oversized value masked correctly");

        // --- Multiple descriptors: confirm FD0..FD3 are independent -------------
        pcpi_rs1 = {22'd0, 5'd0 /*width_m1*/, 5'd0 /*offset*/};
        pcpi_insn = enc_fdseti(2'd3); // FD3 = {offset=0,width=1}
        pcpi_valid = 1;
        run_check(32'd0, 0, "FDSETI FD3");

        pcpi_rs1 = 32'hFFFFFFFE;
        pcpi_rs2 = 32'h00000001;
        pcpi_insn = enc_putf(2'd3);
        pcpi_valid = 1;
        run_check(golden_insert(32'hFFFFFFFE, 32'h00000001, 5'd0, 5'd0), 1, "PUTF FD3 independent of FD0");

        // --- Randomized regression across all four instructions ----------------
        for (i = 0; i < 200; i = i + 1) begin
            rand_val  = $random;
            rand_val2 = $random;
            rand_off  = $random % 32;
            rand_w    = $random % 32;

            // GETFU
            pcpi_rs1  = rand_val;
            pcpi_insn = enc_getfu(rand_off, rand_w);
            pcpi_valid = 1;
            run_check(golden_extract(rand_val, rand_off, rand_w), 1, "RAND GETFU");

            // GETFXU
            pcpi_rs1  = rand_val;
            pcpi_rs2  = {22'd0, rand_w, rand_off};
            pcpi_insn = enc_getfxu(1'b0);
            pcpi_valid = 1;
            run_check(golden_extract(rand_val, rand_off, rand_w), 1, "RAND GETFXU");

            // FDSETI FD1 <= {rand_off, rand_w} via rs1
            pcpi_rs1  = {22'd0, rand_w, rand_off};
            pcpi_insn = enc_fdseti(2'd1);
            pcpi_valid = 1;
            run_check(32'd0, 0, "RAND FDSETI FD1");

            // PUTF using FD1
            pcpi_rs1  = rand_val;
            pcpi_rs2  = rand_val2;
            pcpi_insn = enc_putf(2'd1);
            pcpi_valid = 1;
            run_check(golden_insert(rand_val, rand_val2, rand_off, rand_w), 1, "RAND PUTF FD1");
        end

        $display("---------------------------------------------");
        $display("PASS: %0d   FAIL: %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED");
        $finish;
    end

endmodule
