`timescale 1ns/1ps

module tbControlUnit ();

    logic [6:0] opcode;
    logic [3:0] aluOp;
    logic [2:0] funct3, immSrc;
    logic [1:0] resultSrc;
    logic funct7b5, regWrite, aluSrc, memWrite, branch, jump, aluSrcA, jalr;

    int errors = 0;

    ControlUnit dut(.*);

    //  regWrite immSrc aluSrc aluOp memWrite resultSrc branch jump aluSrcA jalr
    //     1                 3          1         4             1               2           1          1         1         1       = 16 bits
    logic [15:0] ctrl;
    assign ctrl = {regWrite, immSrc, aluSrc, aluOp, memWrite, resultSrc, branch, jump, aluSrcA, jalr};

    task automatic check (
        input logic [6:0] op,
        input logic [2:0] f3,
        input logic f7,
        input logic [15:0] exp,
        input string name
    );
        
        opcode = op;
        funct3 = f3;
        funct7b5 = f7;
        #1;
        if (ctrl !== exp) begin
            errors++;
            $error("%s:\n  got %b\n  exp %b", name, ctrl, exp);
        end

    endtask //automatic

    initial begin
        $dumpfile("tbControlUnit.vcd");
        $dumpvars(0, tbControlUnit);

        check(7'b0110011, 3'b000, 1'b0, 16'b1_000_0_0000_0_00_0_0_0_0, "add");
        check(7'b0110011, 3'b000, 1'b1, 16'b1_000_0_0001_0_00_0_0_0_0, "sub");
        check(7'b0110011, 3'b111, 1'b0, 16'b1_000_0_0010_0_00_0_0_0_0, "and");
        check(7'b0110011, 3'b101, 1'b0, 16'b1_000_0_0110_0_00_0_0_0_0, "srl");
        check(7'b0110011, 3'b101, 1'b1, 16'b1_000_0_0111_0_00_0_0_0_0, "sra");

        check(7'b0010011, 3'b000, 1'b1, 16'b1_000_1_0000_0_00_0_0_0_0, "addi ignores funct7b5");
        check(7'b0010011, 3'b101, 1'b1, 16'b1_000_1_0111_0_00_0_0_0_0, "srai uses funct7b5");

        check(7'b0000011, 3'b010, 1'b0, 16'b1_000_1_0000_0_01_0_0_0_0, "lw");
        check(7'b0100011, 3'b010, 1'b0, 16'b0_001_1_0000_1_00_0_0_0_0, "sw");

        check(7'b1100011, 3'b000, 1'b0, 16'b0_010_0_0001_0_00_1_0_0_0, "beq");
        check(7'b1100011, 3'b110, 1'b0, 16'b0_010_0_1001_0_00_1_0_0_0, "bltu");

        check(7'b0110111, 3'b000, 1'b0, 16'b1_011_1_1010_0_00_0_0_0_0, "lui");
        check(7'b0010111, 3'b000, 1'b0, 16'b1_011_1_0000_0_00_0_0_1_0, "auipc");
        check(7'b1101111, 3'b000, 1'b0, 16'b1_100_0_0000_0_10_0_1_0_0, "jal");
        check(7'b1100111, 3'b000, 1'b0, 16'b1_000_1_0000_0_10_0_1_0_1, "jalr");

        check(7'b1111111, 3'b000, 1'b0, 16'b0_000_0_0000_0_00_0_0_0_0, "invalid opcode is safe");

        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

endmodule