`timescale 1ns/1ps

module RV32I (
    input  logic clk, reset,
    output logic [31:0] pc, instr
);
    logic        memWrite;
    logic [2:0]  memFunct3;
    logic [31:0] dmemAddr, dmemWData, dmemRData;

    RV32I_core core (
        .clk(clk), .reset(reset),
        .imemAddr(pc), .instr(instr),
        .memWrite(memWrite), .memFunct3(memFunct3),
        .dmemAddr(dmemAddr), .dmemWData(dmemWData), .dmemRData(dmemRData)
    );

    InstructionMemory imem (.addr(pc), .instr(instr));

    DataMemory dmem (
        .clk(clk), .memWrite(memWrite), .funct3(memFunct3),
        .addr(dmemAddr), .writeData(dmemWData), .readData(dmemRData)
    );
endmodule