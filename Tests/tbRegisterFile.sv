`timescale 1ns/1ps

module tbRegisterFile();
    
    localparam int WIDTH = 32;
    localparam int REGS = 32 ;

    logic clk, reset, wEn;
    logic [$clog2(REGS)-1:0] rs1, rs2, rd;
    logic [WIDTH-1:0] wd;
    logic [WIDTH-1:0] rdData1,rdData2;

    int errors;
    
    RegisterFile dut(.*);
    
    task automatic writeReg (
        input logic [4:0] addr, input logic [31:0] data, input logic en
    );

        @(negedge clk);
        rd = addr;
        wd = data;
        wEn = en;
        @(posedge clk);
        @(negedge clk);
        wEn = 1'b0;
    endtask //automatic

    task automatic checkReg (
        input logic [4:0] addr,
        input logic [31:0] exp,
        input string name
    );
        rs1 = addr;
        #1;
        if (rdData1 !== exp) begin
            errors++;
            $error("%s: got 0x%08h, expected 0x%08h", name, rdData1, exp);
        end
    endtask //automatic

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tbRegisterFile.vcd");
        $dumpvars(0, tbRegisterFile);

        reset = 1'b1;
        wEn = 1'b0;
        rs1 = '0; rs2='0; rd='0; wd='0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        checkReg(5'd1, 32'h0000_0000, "x1 after reset");
        checkReg(5'd5, 32'h0000_0000, "x5 after reset");

        writeReg(5'd1, 32'hAAAA_AAAA, 1'b1);
        checkReg(5'd1, 32'hAAAA_AAAA, "x1 written");

        writeReg(5'd2, 32'hBBBB_BBBB, 1'b1);
        checkReg(5'd2, 32'hBBBB_BBBB, "x2 written");
        checkReg(5'd1, 32'hAAAA_AAAA, "x1 untouched by x2 write");

        writeReg(5'd0, 32'hFFFF_FFFF, 1'b1);
        checkReg(5'd0, 32'h0000_0000, "x0 stays zero");

        writeReg(5'd1, 32'hDEAD_DEAD, 1'b0);
        checkReg(5'd1, 32'hAAAA_AAAA, "no write when wEn=0");

        rs1 = 5'd1;
        rs2 = 5'd2;
        #1;
        if (rdData1 !== 32'hAAAA_AAAA || rdData2 !== 32'hBBBB_BBBB) begin
            errors++;
            $error("two ports: rdData1=0x%08h rdData2=0x%08h", rdData1, rdData2);
        end

        reset = 1'b1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        checkReg(5'd1, 32'h0000_0000, "x1 after second reset");
        checkReg(5'd2, 32'h0000_0000, "x2 after second reset");

        if (errors == 0) $display("TEST PASSED");
        else $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

    
endmodule