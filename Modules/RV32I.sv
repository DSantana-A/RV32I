`timescale 1ns/1ps

module RV32I (
    input  logic clk, reset,
    output logic [31:0] pc, instr
);

    logic [3:0] aluOp;
    logic [2:0] immSrc;
    logic [1:0] resultSrc;
    logic       regWrite, aluSrc, memWrite, branch, jump, aluSrcA, jalr;

    logic [31:0] pcPlus4, pcTarget, pcSum;
    logic [31:0] immExt, rdData1, rdData2;
    logic [31:0] srcA, srcB, aluResult;
    logic [31:0] memData, result;
    logic        zero, pcSrc, condition;

    ProgramCounter pcReg (
        .clk(clk),
        .reset(reset),
        .pcSrc(pcSrc),
        .pcTarget(pcTarget),
        .pc(pc),
        .pcPlus4(pcPlus4)
    );

    InstructionMemory #(.HEXFILE("Src/test_basic.hex")) imem (
        .addr(pc),
        .instr(instr)
    );

    ControlUnit ctrl (
        .opcode(instr[6:0]),
        .funct3(instr[14:12]),
        .funct7b5(instr[30]),
        .aluOp(aluOp),
        .immSrc(immSrc),
        .resultSrc(resultSrc),
        .regWrite(regWrite),
        .aluSrc(aluSrc),
        .memWrite(memWrite),
        .branch(branch),
        .jump(jump),
        .aluSrcA(aluSrcA),
        .jalr(jalr)
    );

    ImmediateGenerator immgen (
        .instr(instr),
        .immSrc(immSrc),
        .immExt(immExt)
    );

    RegisterFile rf (
        .clk(clk),
        .reset(reset),
        .wEn(regWrite),
        .rs1(instr[19:15]),
        .rs2(instr[24:20]),
        .rd(instr[11:7]),
        .wd(result),
        .rdData1(rdData1),
        .rdData2(rdData2)
    );

    assign srcA = aluSrcA ? pc     : rdData1;
    assign srcB = aluSrc  ? immExt : rdData2;

    ALU alu (
        .inputA(srcA),
        .inputB(srcB),
        .aluOp(aluOp),
        .result(aluResult),
        .zero(zero)
    );

    DataMemory dmem (
        .clk(clk),
        .memWrite(memWrite),
        .funct3(instr[14:12]),
        .addr(aluResult),
        .writeData(rdData2),
        .readData(memData)
    );

    always_comb begin : Writeback
        case (resultSrc)
            2'b00  : result = aluResult;
            2'b01  : result = memData;
            2'b10  : result = pcPlus4;
            default: result = aluResult;
        endcase
    end

    assign pcSum    = pc + immExt;
    assign pcTarget = jalr ? {aluResult[31:1], 1'b0} : pcSum;

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

    assign pcSrc = jump | (branch & condition);

endmodule
