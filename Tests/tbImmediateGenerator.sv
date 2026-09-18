`timescale 1ns/1ps

module tbImmediateGenerator ();

    logic [31:0] instr, immExt;
    logic [2:0] immSrc;

    int errors = 0;
    
    localparam  logic [2:0] I_TYPE = 3'b000;
    localparam  logic [2:0] S_TYPE = 3'b001;
    localparam  logic [2:0] B_TYPE = 3'b010;
    localparam  logic [2:0] U_TYPE = 3'b011;
    localparam  logic [2:0] J_TYPE = 3'b100;

    ImmediateGenerator dut(.*);

    task automatic check(
        input logic [31:0] ins, exp,
        input logic [2:0] src,
        input string name
    );
        instr = ins;
        immSrc = src;
        #1;
        if (immExt !== exp) begin
            errors++;
            $error("%s: got 0x%08h, expected 0x%08h", name, immExt, exp);
        end
    endtask //automatic

    initial begin
        $dumpfile("tbImmediateGenerator.vcd");
        $dumpvars(0, tbImmediateGenerator);

        check(32'h0083_2283, 32'h0000_0008, I_TYPE, "lw   x5, 8(x6)");
        check(32'hFF63_0293, 32'hFFFF_FFF6, I_TYPE, "addi x5, x6, -10");
        check(32'h7FF0_0013, 32'h0000_07FF, I_TYPE, "addi x0, x0, 2047");
        check(32'h8000_0013, 32'hFFFF_F800, I_TYPE, "addi x0, x0, -2048");

        check(32'h0073_2423, 32'h0000_0008, S_TYPE, "sw   x7, 8(x6)");
        check(32'hFE73_2E23, 32'hFFFF_FFFC, S_TYPE, "sw   x7, -4(x6)");

        check(32'h0073_0863, 32'h0000_0010, B_TYPE, "beq  x6, x7, +16");
        check(32'hFE73_08E3, 32'hFFFF_FFF0, B_TYPE, "beq  x6, x7, -16");

        check(32'h1234_52B7, 32'h1234_5000, U_TYPE, "lui  x5, 0x12345");
        check(32'hFFFF_F2B7, 32'hFFFF_F000, U_TYPE, "lui  x5, 0xFFFFF");

        check(32'h0010_02EF, 32'h0000_0800, J_TYPE, "jal  x5, +2048");
        check(32'hFFDF_F2EF, 32'hFFFF_FFFC, J_TYPE, "jal  x5, -4");

        check(32'hFFFF_FFFF, 32'h0000_0000, 3'b111, "invalid immSrc");

        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

endmodule