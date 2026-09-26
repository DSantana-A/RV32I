`timescale 1ns/1ps

module tbRV32I ();

    logic clk, reset;
    logic [31:0] pc, instr;

    int errors = 0;

    RV32I dut (.*);

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check (input logic [31:0] got, exp, input string name);
        if (got !== exp) begin
            errors++;
            $error("%s: got 0x%08h, expected 0x%08h", name, got, exp);
        end
    endtask

    initial begin
        $dumpfile("tbRV32I.vcd");
        $dumpvars(0, tbRV32I);

        reset = 1'b1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        repeat (12) begin
            @(negedge clk);
            $display("pc = 0x%08h   instr = 0x%08h", pc, instr);
        end

        check(dut.rf.registers[1], 32'd5,    "x1 = 5");
        check(dut.rf.registers[2], 32'd3,    "x2 = 3");
        check(dut.rf.registers[3], 32'd8,    "x3 = x1 + x2");
        check(dut.rf.registers[4], 32'd2,    "x4 = x1 - x2");
        check(dut.dmem.mem[0],     32'd8,    "mem[0] = x3");
        check(dut.rf.registers[5], 32'd8,    "x5 = loaded back from mem[0]");
        check(pc,                  32'h0018, "pc parked in the final loop");

        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

endmodule
