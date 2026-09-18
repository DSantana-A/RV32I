`timescale 1ns/1ps

module tbProgramCounter ();
    
    logic clk, reset, pcSrc;
    logic [31:0] pcTarget;
    logic [31:0] pc, pcPlus4;

    int errors = 0;

    ProgramCounter dut(.*);

    task automatic check (
        input logic [31:0] got, exp,
        input string name
    );
        if (got !== exp) begin
            errors ++;
            $error("%s: got 0x%08h, expected 0x%08h", name, got, exp);
        end
    endtask //automatic

    initial clk = 1'b0;
    always #5 clk = ~clk;

        initial begin
        $dumpfile("tbProgramCounter.vcd");
        $dumpvars(0, tbProgramCounter);

        reset    = 1'b1;
        pcSrc    = 1'b0;
        pcTarget = 32'h0000_0000;
        @(negedge clk);
        @(negedge clk);
        check(pc, 32'h0000_0000, "after reset");

        reset = 1'b0;

        @(negedge clk);
        check(pc,      32'h0000_0004, "first step");
        check(pcPlus4, 32'h0000_0008, "pcPlus4 follows pc");

        @(negedge clk);
        check(pc, 32'h0000_0008, "second step");

        @(negedge clk);
        check(pc, 32'h0000_000C, "third step");

        pcTarget = 32'h0000_0100;
        pcSrc    = 1'b1;
        @(negedge clk);
        check(pc, 32'h0000_0100, "jump to 0x100");

        pcSrc = 1'b0;
        @(negedge clk);
        check(pc, 32'h0000_0104, "keeps going after jump");

        pcTarget = 32'hFFFF_FFFC;
        pcSrc    = 1'b1;
        @(negedge clk);
        check(pc, 32'hFFFF_FFFC, "jump to end of memory");

        pcSrc = 1'b0;
        @(negedge clk);
        check(pc, 32'h0000_0000, "wraps around to zero");

        @(negedge clk);
        check(pc, 32'h0000_0004, "steps again");

        reset = 1'b1;
        @(negedge clk);
        check(pc, 32'h0000_0000, "reset returns to start");

        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

    
endmodule