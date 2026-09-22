`timescale 1ns/1ps

module tbDataMemory ();
    
    logic clk, memWrite;
    logic [31:0] addr, writeData, readData;
    int errors = 0;

    DataMemory dut (.*);

    task automatic writeMem (
        input logic [31:0] a, data,
        input logic en
    );

        @(negedge clk);
        addr = a;
        writeData = data;
        memWrite = en;

        @(posedge clk);
        @(negedge clk);
        memWrite = 1'b0;
    endtask //automatic

    task automatic checkMem (
        input logic [31:0] a, exp,
        input string name
    );

        addr = a;
        #1;
        if (readData !== exp) begin
            errors++;
            $error("%s: got 0x%08h, expected 0x%08h", name, readData, exp);
        end
    endtask //automatic

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tbDataMemory.vcd");
        $dumpvars(0, tbDataMemory);

        memWrite = 1'b0;
        addr = '0;
        writeData = '0;

        checkMem(32'h0000_0000, 32'h0000_0000, "starts at zero");

        writeMem(32'h0000_0000, 32'hDEAD_BEEF, 1'b1);
        checkMem(32'h0000_0000, 32'hDEAD_BEEF, "wrote 0x00");

        writeMem(32'h0000_0004, 32'hCAFE_BABE, 1'b1);
        checkMem(32'h0000_0004, 32'hCAFE_BABE, "wrote 0x04");
        checkMem(32'h0000_0000, 32'hDEAD_BEEF, "0x00 untouched by 0x04 write");

        writeMem(32'h0000_0000, 32'h1111_1111, 1'b0);
        checkMem(32'h0000_0000, 32'hDEAD_BEEF, "no write when memWrite=0");

        checkMem(32'h0000_0020, 32'h0000_0000, "never written stays zero");


        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

endmodule