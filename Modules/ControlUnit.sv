`timescale 1ns/1ps

module ControlUnit(
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic funct7b5,
    output logic [3:0] aluOp,
    output logic [2:0] immSrc,
    output logic [1:0] resultSrc,
    output logic regWrite, aluSrc, memWrite, branch, jump, aluSrcA, jalr
);

    always_comb begin : OPCODE
        //Secure Values
        regWrite = 1'b0;
        immSrc = 3'b000;
        aluSrc = 1'b0;
        aluOp = 4'b0000;
        memWrite = 1'b0;
        resultSrc = 2'b00;
        branch = 1'b0;
        jump = 1'b0;
        aluSrcA = 1'b0;
        jalr = 1'b0;

        case (opcode)
           // R-type: add, sub. Both operands are registers, no immediate.
           // funct7b5 (instr[30]) picks sub over add.
           7'b0110011: begin
            regWrite = 1'b1;
            case (funct3)
               3'b000 : aluOp = funct7b5 ? 4'b0001 : 4'b0000;   // sub : add
                3'b001 : aluOp = 4'b0101;                        // sll
                3'b010 : aluOp = 4'b1000;                        // slt
                3'b011 : aluOp = 4'b1001;                        // sltu
                3'b100 : aluOp = 4'b0100;                        // xor
                3'b101 : aluOp = funct7b5 ? 4'b0111 : 4'b0110;   // sra : srl
                3'b110 : aluOp = 4'b0011;                        // or
                3'b111 : aluOp = 4'b0010;                        // and
                default: aluOp = 4'b0000;
            endcase
           end

           7'b0010011: begin
            regWrite = 1'b1;
            aluSrc = 1'b1;
            case (funct3)
               3'b000 : aluOp = 4'b0000;                        // addi
                3'b001 : aluOp = 4'b0101;                        // slli
                3'b010 : aluOp = 4'b1000;                        // slti
                3'b011 : aluOp = 4'b1001;                        // sltiu
                3'b100 : aluOp = 4'b0100;                        // xori
                3'b101 : aluOp = funct7b5 ? 4'b0111 : 4'b0110;   // srai : srli
                3'b110 : aluOp = 4'b0011;                        // ori
                3'b111 : aluOp = 4'b0010;                        // andi
                default: aluOp = 4'b0000;
            endcase
           end

    
           7'b0000011: begin
                regWrite = 1'b1;
                aluSrc = 1'b1;
                resultSrc = 2'b01;
           end

           7'b0100011: begin
                immSrc = 3'b001;
                aluSrc = 1'b1;
                memWrite = 1'b1;
           end

           7'b1100011: begin
                immSrc = 3'b010;
                branch = 1'b1;
                case (funct3)
                    3'b000, 3'b001 : aluOp = 4'b0001;   // beq,  bne   → resta
                    3'b100, 3'b101 : aluOp = 4'b1000;   // blt,  bge   → slt
                    3'b110, 3'b111 : aluOp = 4'b1001;   // bltu, bgeu  → sltu: 
                    default: aluOp = 4'b0001;
                endcase
           end

           7'b0110111: begin
                regWrite = 1'b1;
                immSrc = 3'b011;
                aluSrc = 1'b1;
                aluOp = 4'b1010; 
           end

           7'b0010111: begin
                regWrite = 1'b1;
                immSrc = 3'b011;
                aluSrc = 1'b1;
                aluSrcA = 1'b1;
           end

           7'b1101111: begin
                regWrite = 1'b1;
                immSrc = 3'b100;
                resultSrc = 2'b10;
                jump = 1'b1;
           end

           7'b1100111: begin
                regWrite = 1'b1;
                aluSrc = 1'b1;
                resultSrc = 2'b10;
                jump = 1'b1;
                jalr = 1'b1;
           end

            default: ;
        endcase

    end

endmodule
