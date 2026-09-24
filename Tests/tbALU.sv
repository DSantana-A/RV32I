`timescale 1ns/1ps

module tbALU ();
    
    logic [31:0] inputA, inputB, result;
    logic [3:0] aluOp;
    logic zero;

    int errors = 0;

    ALU dut (.*);

    task automatic check (
        input logic [31:0] a,b, 
        input logic [3:0] op,
        input logic [31:0] exp,
        input string name
        );
        
        inputA = a;
        inputB = b;
        aluOp = op;

        #1;

        if (result !== exp || zero !== (exp == '0)) begin
            errors++;
            $error("%s: result=0x%08h (exp 0x%08h) zero=%0b (exp %0b)", name, result, exp, zero, (exp=='0));
        end
    endtask

    initial begin
        $dumpfile("tbALU.vcd");
        $dumpvars(0, tbALU);

        check(32'd5,         32'd3,         4'b0000, 32'd8,         "ADD  5+3");
        check(32'hFFFF_FFFF, 32'd1,         4'b0000, 32'h0000_0000, "ADD  overflow to 0");

        check(32'd10,        32'd3,         4'b0001, 32'd7,         "SUB  10-3");
        check(32'd7,         32'd7,         4'b0001, 32'h0000_0000, "SUB  7-7 (zero)");

        check(32'hF0F0_F0F0, 32'h0FF0_0FF0, 4'b0010, 32'h00F0_00F0, "AND  pattern");
        check(32'hF0F0_F0F0, 32'h0FF0_0FF0, 4'b0011, 32'hFFF0_FFF0, "OR   pattern");
        check(32'hF0F0_F0F0, 32'h0FF0_0FF0, 4'b0100, 32'hFF00_FF00, "XOR  pattern");

        check(32'd1,         32'd4,         4'b0101, 32'd16,        "SLL  1<<4");
        check(32'd1,         32'd33,        4'b0101, 32'd2,         "SLL  shift 33 -> uses 1");
        check(32'h8000_0000, 32'd4,         4'b0110, 32'h0800_0000, "SRL  fills with zeros");
        check(32'h8000_0000, 32'd4,         4'b0111, 32'hF800_0000, "SRA  fills with sign");

        check(32'hFFFF_FFFF, 32'd1,         4'b1000, 32'd1,         "SLT  -1 < 1 (signed)");
        check(32'hFFFF_FFFF, 32'd1,         4'b1001, 32'd0,         "SLTU -1 < 1 (unsigned)");

        check(32'hDEAD_BEEF, 32'h1234_5000, 4'b1010, 32'h1234_5000, "PASS  lets B through");


        check(32'hDEAD_BEEF, 32'hCAFE_BABE, 4'b1111, 32'h0000_0000, "default");

        if (errors == 0) $display("TEST PASSED");
        else $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

endmodule