`timescale 1ns/1ps

module InstructionMemory #(
    parameter int DEPTH = 64
) (
    input  logic        clk,
    input  logic        we, 
    input  logic [31:0] waddr,
    input  logic [31:0] wdata,
    input logic [31:0] addr,
    output logic [31:0] instr
);
    
    logic [31:0] mem [DEPTH];

    initial begin
        foreach (mem[i]) mem[i] = '0;
        $readmemh("Src/test_basic.hex", mem);
    end

    always @( posedge clk ) begin : blockName
        if (we) begin
            mem[waddr[$clog2(DEPTH)+1:2]] <= wdata;
        end
    end

    assign instr = mem[addr[$clog2(DEPTH)+1:2]];

endmodule