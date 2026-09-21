`timescale 1ns/1ps

module tbInstructionMemory ();
    
    logic  [31:0] addr, instr;
    int errors = 0;

    InstructionMemory #(.HEXFILE("Src/program.hex")) dut (.*);

    task automatic check (
        input logic [31:0] a, exp,
        input string name
    );
        addr = a;
        #1;
        if (instr !== exp) begin
            errors++;
            $error("%s: got 0x%08h, expected 0x%08h", name, instr, exp);
        end    
    endtask //automatic

    initial begin
         $dumpfile("tbInstructionMemory.vcd");
        $dumpvars(0, tbInstructionMemory);

        check(32'h0000_0000, 32'h0083_2283, "addr 0x00");
        check(32'h0000_0004, 32'hFF63_0293, "addr 0x04");
        check(32'h0000_0008, 32'h0073_0863, "addr 0x08");
        check(32'h0000_000C, 32'h1234_52B7, "addr 0x0C");
        check(32'h0000_0100, 32'h0083_2283, "addr 0x100 wraps to 0");

        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;

    end

endmodule
