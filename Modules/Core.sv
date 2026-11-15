`timescale 1ns/1ps

module RV32I_core (
    input  logic clk, reset,
    output logic [31:0] imemAddr,
    input  logic [31:0] instr,
    output logic memWrite,
    output logic [2:0]  memFunct3,
    output logic [31:0] dmemAddr, dmemWData,
    input  logic [31:0] dmemRData
);

    logic [3:0] aluOpD;
    logic [2:0] immSrcD;
    logic [1:0] resultSrcD;
    logic regWriteD, aluSrcD, branchD, jumpD, aluSrcAD, jalrD, memWriteD;

    logic [31:0] pcF, pcPlus4F, pcTargetE, instrF, pcSum;
    logic [31:0] immExt, rdData1, rdData2;
    logic [31:0] srcA, srcB, aluResult, result;
    logic [31:0] instrD;
    logic zero, pcSrcE, condition;

    // ===== IF =====
    ProgramCounter pcReg (
        .clk(clk), .reset(reset), .pcSrc(pcSrcE),
        .pcTarget(pcTargetE), .pc(pcF), .pcPlus4(pcPlus4F)
    );
    assign imemAddr  = pcF;
    assign instrF = instr;

    // ===== IF/ID =====
    assign instrD = instrF;

    // ===== ID =====


    ControlUnit ctrl (
        .opcode(instrD[6:0]), .funct3(instrD[14:12]), .funct7b5(instrD[30]), 
        .aluOp(aluOpD), .immSrc(immSrcD), .resultSrc(resultSrcD),
        .regWrite(regWriteD), .aluSrc(aluSrcD), .memWrite(memWriteD),
        .branch(branchD), .jump(jumpD), .aluSrcA(aluSrcAD), .jalr(jalrD)
);

    ImmediateGenerator immgen (.instr(instr), .immSrc(immSrcD), .immExt(immExt));

    RegisterFile rf (
        .clk(clk), .reset(reset), .wEn(regWriteD),
        .rs1(instr[19:15]), .rs2(instr[24:20]), .rd(instr[11:7]),
        .wd(result), .rdData1(rdData1), .rdData2(rdData2)
    );

    assign srcA = aluSrcAD ? pcF     : rdData1;
    assign srcB = aluSrcD  ? immExt : rdData2;

    ALU alu (.inputA(srcA), .inputB(srcB), .aluOp(aluOpD), .result(aluResult), .zero(zero));

    // Memory interfaces
    assign memWrite = memWriteD;
    assign dmemAddr  = aluResult;
    assign dmemWData = rdData2;
    assign memFunct3 = instr[14:12];

    always_comb begin : Writeback
        case (resultSrcD)
            2'b00  : result = aluResult;
            2'b01  : result = dmemRData;
            2'b10  : result = pcPlus4F;
            default: result = aluResult;
        endcase
    end

    assign pcSum    = pcF + immExt;
    assign pcTargetE = jalrD ? {aluResult[31:1], 1'b0} : pcSum;

    always_comb begin : BranchCondition
        case (instr[14:12])
            3'b000 : condition =  zero;
            3'b001 : condition = ~zero;
            3'b100 : condition =  aluResult[0];
            3'b101 : condition = ~aluResult[0];
            3'b110 : condition =  aluResult[0];
            3'b111 : condition = ~aluResult[0];
            default: condition = 1'b0;
        endcase
    end

    assign pcSrcE = jumpD | (branchD & condition);

    

endmodule


// ===== ID/EX =====
// ===== EX =====
// ===== EX/MEM =====
// ===== MEM =====
// ===== MEM/WB =====
// ===== WB =====


