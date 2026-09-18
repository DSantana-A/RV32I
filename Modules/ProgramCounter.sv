`timescale 1ns/1ps

module ProgramCounter #(
    parameter logic [31:0] RESETADDR = 32'h0000_0000
) (
    input logic clk, reset, pcSrc,
    input logic [31:0] pcTarget,
    output logic [31:0] pc, pcPlus4
);
    logic [31:0] pcNext;

    assign pcPlus4 = pc + 32'd4;
    assign pcNext = pcSrc ? pcTarget : pcPlus4;

    always_ff @( posedge clk ) begin : Register
        if (reset) begin
            pc <= RESETADDR;
        end else begin
            pc <= pcNext;
        end
    end

endmodule