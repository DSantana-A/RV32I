`timescale 1ns/1ps

module InstructionMemory #(
    parameter int DEPTH = 64
) (
    input logic [31:0] addr,
    output logic [31:0] instr
);
    
    logic [31:0] mem [DEPTH];

    // synopsys translate_off
    initial begin
        foreach (mem[i]) mem[i] = '0;
        $readmemh("program.hex", mem);
    end
    // synopsys translate_on

    assign instr = mem[addr[$clog2(DEPTH)+1:2]];

endmodule