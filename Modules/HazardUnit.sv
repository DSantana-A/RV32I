`timescale 1ns/1ps

module HazardUnit (
    input logic [4:0] rs1E, rs2E, rdM, rdW, rs1D, rs2D, rdE,
    input logic [1:0] resultSrcE,
    input logic regWriteW, regWriteM, pcSrcE,
    output logic [1:0] forwardAE, forwardBE,
    output logic  stallF, stallD, flushE, flushD
);
    logic lwStall;

    always_comb begin : BlockA
        if (regWriteM && (rdM != '0) && (rdM == rs1E)) begin
            forwardAE = 2'b10;
        end else if (regWriteW && (rdW != 0) && (rdW == rs1E)) begin
            forwardAE = 2'b01;
        end else begin
            forwardAE = 2'b00;
        end
    end

    always_comb begin : BlockB
        if (regWriteM && (rdM != '0) && (rdM == rs2E)) begin
            forwardBE = 2'b10;
        end else if (regWriteW && (rdW != 0) && (rdW == rs2E)) begin
            forwardBE = 2'b01;
        end else begin
            forwardBE = 2'b00;
        end
    end

    assign lwStall = (resultSrcE == 2'b01) && (rdE != 0) && ((rdE == rs1D) || (rdE == rs2D));

    assign stallF = lwStall;
    assign stallD = lwStall;
    assign flushD = pcSrcE;
    assign flushE = lwStall || pcSrcE; 
endmodule