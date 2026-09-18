`timescale 1ns/1ps

module InstructionMemory #(
    parameter int DEPTH = 64,
    parameter string HEXFILE = "program.hex"
) (
    input logic [31:0] addr,
    output logic [31:0] instr
);
    
    logic [31:0] mem [DEPTH];

    initial $readmemh(HEXFILE, mem);
    assign instr = mem[addr[$clog2(DEPTH)+1:2]];

endmodule