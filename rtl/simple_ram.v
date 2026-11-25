//`timescale 1ns / 1ps

module simple_ram (
    input  wire        clk,
    input  wire        mem_valid,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,

    output reg  [31:0] mem_rdata,
    output wire        mem_ready
);

    // ============================================================
    // 16 KB RAM
    // 4096 x 32-bit words
    // Address range:
    // 0x00000000 - 0x00003FFF
    // ============================================================

    reg [31:0] memory [0:4095];


    // ============================================================
    // Firmware loading
    // ============================================================

    initial begin

        $readmemh(
        "C:/Users/Joshua Selvaraj S/Desktop/PicoRV32_lastrywithbfpu/PicoRV32_Project/PicoRV32_Project.srcs/sources_1/new/rgbbfpu (1).hex",memory);

        $display("==============================================");
        $display("simple_ram: firmware loaded");
        $display("RAM[0]  = %08h", memory[0]);
        $display("RAM[1]  = %08h", memory[1]);
        $display("RAM[2]  = %08h", memory[2]);
        $display("RAM[3]  = %08h", memory[3]);
        $display("RAM[4]  = %08h", memory[4]);
        $display("RAM[5]  = %08h", memory[5]);
        $display("RAM[6]  = %08h", memory[6]);
        $display("RAM[7]  = %08h", memory[7]);
        $display("RAM[8]  = %08h", memory[8]);
        $display("RAM[9]  = %08h", memory[9]);
        $display("RAM[10] = %08h", memory[10]);
        $display("RAM[11] = %08h", memory[11]);
        $display("==============================================");

    end


    // ============================================================
    // Memory response
    //
    // PicoRV32 expects mem_rdata to correspond to the request
    // while mem_valid && mem_ready are asserted.
    //
    // Therefore the READ must be combinational.
    // ============================================================

    assign mem_ready = mem_valid;


    always @(*) begin

        mem_rdata = 32'h00000000;

        if (mem_valid) begin
            mem_rdata = memory[mem_addr[13:2]];
        end

    end


    // ============================================================
    // Synchronous writes
    // ============================================================

    always @(posedge clk) begin

        if (mem_valid && mem_ready) begin

            if (mem_wstrb[0])
                memory[mem_addr[13:2]][7:0] <= mem_wdata[7:0];

            if (mem_wstrb[1])
                memory[mem_addr[13:2]][15:8] <= mem_wdata[15:8];

            if (mem_wstrb[2])
                memory[mem_addr[13:2]][23:16] <= mem_wdata[23:16];

            if (mem_wstrb[3])
                memory[mem_addr[13:2]][31:24] <= mem_wdata[31:24];

        end

    end

endmodule