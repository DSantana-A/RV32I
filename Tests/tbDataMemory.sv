`timescale 1ns/1ps

module tbDataMemory ();
    
    logic clk, memWrite;
    logic [2:0] funct3;
    logic [31:0] addr, writeData, readData;
    int errors = 0;

    DataMemory dut (.*);

    localparam logic [2:0] F3B = 3'b000;     // lb & sb
    localparam logic [2:0] F3H = 3'b001;     // lh & sh
    localparam logic [2:0] F3W = 3'b010;    // lw & sw
    localparam logic [2:0] F3BU = 3'b100;   // lbu
    localparam logic [2:0] F3HU = 3'b101;   // lhu

    task automatic writeMem (
        input logic [31:0] a, data,
        input logic [2:0] f3,
        input logic en
    );

        @(negedge clk);
        addr = a;
        writeData = data;
        funct3 = f3;
        memWrite = en;

        @(posedge clk);
        @(negedge clk);
        memWrite = 1'b0;
    endtask //automatic

    task automatic checkMem (
        input logic [31:0] a, exp,
        input logic [2:0] f3,
        input string name
    );

        addr = a;
        funct3 = f3;
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
        funct3 = F3W;

        checkMem(32'h0000_0000, 32'h0000_0000, F3W, "starts at zero");

        writeMem(32'h0000_0000, 32'hDEAD_BEEF, F3W, 1'b1);
        checkMem(32'h0000_0000, 32'hDEAD_BEEF, F3W, "wrote 0x00");

        writeMem(32'h0000_0004, 32'hCAFE_BABE, F3W, 1'b1);
        checkMem(32'h0000_0004, 32'hCAFE_BABE, F3W, "wrote 0x04");
        checkMem(32'h0000_0000, 32'hDEAD_BEEF, F3W, "0x00 untouched by 0x04 write");

        writeMem(32'h0000_0000, 32'h1111_1111, F3W, 1'b0);
        checkMem(32'h0000_0000, 32'hDEAD_BEEF, F3W, "no write when memWrite=0");

        checkMem(32'h0000_0020, 32'h0000_0000, F3W, "never written stays zero");

        writeMem(32'h0000_0008, 32'h1122_3344, F3W, 1'b1);
        writeMem(32'h0000_000A, 32'h0000_00AB, F3B, 1'b1);
        checkMem(32'h0000_0008, 32'h11AB_3344, F3W, "sb only touched byte 2");

        checkMem(32'h0000_0008, 32'h0000_0044, F3BU, "lbu byte 0");
        checkMem(32'h0000_0009, 32'h0000_0033, F3BU, "lbu byte 1");
        checkMem(32'h0000_000A, 32'h0000_00AB, F3BU, "lbu byte 2");
        checkMem(32'h0000_000B, 32'h0000_0011, F3BU, "lbu byte 3");

        checkMem(32'h0000_000A, 32'hFFFF_FFAB, F3B,  "lb sign-extends 0xAB");
        checkMem(32'h0000_0008, 32'h0000_0044, F3B,  "lb keeps 0x44 positive");

        writeMem(32'h0000_000C, 32'h9999_8888, F3W, 1'b1);
        writeMem(32'h0000_000C, 32'h0000_CAFE, F3H, 1'b1);
        checkMem(32'h0000_000C, 32'h9999_CAFE, F3W, "sh wrote lower half");

        writeMem(32'h0000_000E, 32'h0000_1234, F3H, 1'b1);
        checkMem(32'h0000_000C, 32'h1234_CAFE, F3W, "sh wrote upper half");

        checkMem(32'h0000_000C, 32'hFFFF_CAFE, F3H,  "lh sign-extends 0xCAFE");
        checkMem(32'h0000_000C, 32'h0000_CAFE, F3HU, "lhu zero-extends 0xCAFE");
        checkMem(32'h0000_000E, 32'h0000_1234, F3H,  "lh keeps 0x1234 positive");



        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

endmodule