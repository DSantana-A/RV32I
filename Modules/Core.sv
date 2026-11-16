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
    // ----- IF -----
    logic [31:0] pcF, pcPlus4F, instrF;

  // ----- ID -----
    logic [31:0] instrD, pcD, pcPlus4D;
    logic [31:0] immExtD, rdData1D, rdData2D;
    logic [4:0]  rdD;
    logic [3:0]  aluOpD;
    logic [2:0]  immSrcD, funct3D;
    logic [1:0]  resultSrcD;
    logic regWriteD, aluSrcD, branchD, jumpD, aluSrcAD, jalrD, memWriteD;
    logic stallD, flushD;

    // ----- EX -----
    logic [31:0] pcE, pcPlus4E, immExtE, rdData1E, rdData2E;
    logic [31:0] srcA, srcB, aluResult, pcSum, pcTargetE;
    logic [4:0]  rdE;
    logic [3:0]  aluOpE;
    logic [2:0]  funct3E;
    logic [1:0]  resultSrcE;
    logic regWriteE, aluSrcE, aluSrcAE, branchE, jumpE, jalrE, memWriteE;
    logic zero, condition, pcSrcE, flushE;

    // ----- MEM -----
    logic [31:0] aluResultM, writeDataM, pcPlus4M, readDataM;
    logic [4:0]  rdM;
    logic [2:0]  funct3M;
    logic [1:0]  resultSrcM;
    logic memWriteM, regWriteM;

    // ----- WB -----
    logic [31:0] aluResultW, readDataW, pcPlus4W, resultW;
    logic [4:0]  rdW;
    logic [1:0]  resultSrcW;
    logic regWriteW;

    // ===== IF =====
    ProgramCounter pcReg (
        .clk(clk), .reset(reset), .pcSrc(pcSrcE),
        .pcTarget(pcTargetE), .pc(pcF), .pcPlus4(pcPlus4F)
    );
    assign imemAddr  = pcF;
    assign instrF = instr;

    // ===== IF/ID =====
    assign stallD = 1'b0;
    assign flushD = 1'b0;

    always_ff @( posedge clk ) begin : RegisterIFID
        if (reset || flushD) begin
            instrD <= 32'h0000_0013;
            pcD <= '0;
            pcPlus4D <= '0; 
        end else if (!stallD) begin
            instrD <= instrF;
            pcD <= pcF;
            pcPlus4D <= pcPlus4F;
        end
    end

    // ===== ID =====
    assign funct3D = instrD[14:12];
    assign rdD = instrD[11:7];

    ControlUnit ctrl (
        .opcode(instrD[6:0]), .funct3(instrD[14:12]), .funct7b5(instrD[30]), 
        .aluOp(aluOpD), .immSrc(immSrcD), .resultSrc(resultSrcD),
        .regWrite(regWriteD), .aluSrc(aluSrcD), .memWrite(memWriteD),
        .branch(branchD), .jump(jumpD), .aluSrcA(aluSrcAD), .jalr(jalrD)
    );

    ImmediateGenerator immgen (.instr(instrD), .immSrc(immSrcD), .immExt(immExtD));

    RegisterFile rf (
        .clk(clk), .reset(reset), .wEn(regWriteW),
        .rs1(instrD[19:15]), .rs2(instrD[24:20]), .rd(rdW),
        .wd(resultW), .rdData1(rdData1D), .rdData2(rdData2D)
    );

    // ===== ID/EX =====
    assign flushE = 1'b0;

    always_ff @( posedge clk ) begin : RegisterIDEX
        if (reset || flushE) begin
            aluSrcAE <= '0;
            aluSrcE <= '0;
            aluOpE <= '0;
            rdData1E <= '0;
            rdData2E <= '0;
            immExtE <= '0;
            pcE <= '0;
            jalrE <= '0;
            branchE <= '0;
            jumpE <= '0;
            funct3E <= '0;
            memWriteE <= '0;
            resultSrcE <= '0;
            regWriteE <= '0;
            pcPlus4E  <= '0;
            rdE <= '0;

        end else begin
            aluSrcAE <= aluSrcAD;
            aluSrcE <= aluSrcD;
            aluOpE <= aluOpD;
            rdData1E <= rdData1D;
            rdData2E <= rdData2D;
            immExtE <= immExtD;
            pcE <= pcD;
            jalrE <= jalrD;
            branchE <= branchD;
            jumpE <= jumpD;
            funct3E <= funct3D;
            memWriteE <= memWriteD;
            resultSrcE <= resultSrcD;
            regWriteE <= regWriteD;
            pcPlus4E  <= pcPlus4D;
            rdE <= rdD;
        end
    end

    // ===== EX =====
    assign srcA = aluSrcAE ? pcE     : rdData1E;
    assign srcB = aluSrcE  ? immExtE : rdData2E;

    ALU alu (.inputA(srcA), .inputB(srcB), .aluOp(aluOpE), .result(aluResult), .zero(zero));

    assign pcSum    = pcE + immExtE;
    assign pcTargetE = jalrE ? {aluResult[31:1], 1'b0} : pcSum;

    always_comb begin : BranchCondition
        case (funct3E)
            3'b000 : condition =  zero;
            3'b001 : condition = ~zero;
            3'b100 : condition =  aluResult[0];
            3'b101 : condition = ~aluResult[0];
            3'b110 : condition =  aluResult[0];
            3'b111 : condition = ~aluResult[0];
            default: condition = 1'b0;
        endcase
    end

    assign pcSrcE = jumpE | (branchE & condition);

    // ===== EX/MEM =====
    always_ff @( posedge clk ) begin : registerEXMEM
        if (reset) begin
            aluResultM <= '0;
            writeDataM <= '0;
            funct3M <= '0;
            memWriteM <= '0;
            regWriteM <= '0;
            resultSrcM <= '0;
            rdM <= '0;
            pcPlus4M <= '0;
        end else begin
            aluResultM <= aluResult;
            writeDataM <= rdData2E;
            funct3M <= funct3E;
            memWriteM <= memWriteE;
            regWriteM <= regWriteE;
            resultSrcM <= resultSrcE;
            rdM <= rdE;
            pcPlus4M <= pcPlus4E;
        end
    end

    // ===== MEM =====
    assign memWrite = memWriteM;
    assign dmemAddr  = aluResultM;
    assign dmemWData = writeDataM;
    assign memFunct3 = funct3M;
    assign readDataM = dmemRData;

    // ===== MEM/WB =====
    

    always_ff @( posedge clk ) begin : registerMEMWB
        if (reset) begin
            aluResultW <= '0;
            readDataW <= '0;
            regWriteW <= '0;
            resultSrcW <= '0;
            rdW <= '0;
            pcPlus4W <= '0;
        end else begin
            aluResultW <= aluResultM;
            readDataW <= readDataM;
            regWriteW <= regWriteM;
            resultSrcW <= resultSrcM;
            rdW <= rdM;
            pcPlus4W <= pcPlus4M;
        end
    end

    // ===== WB =====

    always_comb begin : Writeback
        case (resultSrcW)
            2'b00  : resultW = aluResultW;
            2'b01  : resultW = readDataW;
            2'b10  : resultW = pcPlus4W;
            default: resultW = aluResultW;
        endcase
    end
    
endmodule