`timescale 1ns/1ps

module RV32I_asic (
    input  logic        clk, reset,
    input  logic        imemWe,       // carga del programa con reset en 1
    input  logic [31:0] imemWAddr,
    input  logic [31:0] imemWData,
    output logic [31:1] dbgPC,        // salidas para que DC no elimine la lógica
    output logic [31:0] dbgDmemAddr
);
    logic [31:0] pc, instr, dmemAddr, dmemWData, dmemRData;
    logic        memWrite;
    logic [2:0]  memFunct3;

    RV32I_core core (
        .clk(clk), .reset(reset),
        .imemAddr(pc), .instr(instr),
        .memWrite(memWrite), .memFunct3(memFunct3),
        .dmemAddr(dmemAddr), .dmemWData(dmemWData), .dmemRData(dmemRData)
    );

    InstructionMemory imem (
        .clk(clk), .we(imemWe), .waddr(imemWAddr), .wdata(imemWData),
        .addr(pc), .instr(instr)
    );

    DataMemory dmem (
        .clk(clk), .memWrite(memWrite), .funct3(memFunct3),
        .addr(dmemAddr), .writeData(dmemWData), .readData(dmemRData)
    );

    assign dbgPC       = pc[31:1];
    assign dbgDmemAddr = dmemAddr;
endmodule