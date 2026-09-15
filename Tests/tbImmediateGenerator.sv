`timescale 1ns/1ps

module tbImmediateGenerator ();

    localparam logic [2:0] I_TYPE = 3'b000;
    localparam logic [2:0] S_TYPE = 3'b001;
    localparam logic [2:0] B_TYPE = 3'b010;
    localparam logic [2:0] U_TYPE = 3'b011;
    localparam logic [2:0] J_TYPE = 3'b100;

    logic [31:0] instr, immExt;
    logic [2:0]  immSrc;

    int unsigned errors = 0;
    int unsigned checks = 0;

    ImmediateGenerator dut (.*);

    task automatic check (
        input logic [31:0] ins,
        input logic [2:0]  src,
        input logic [31:0] exp,
        input string       nombre
    );
        instr  = ins;
        immSrc = src;
        #1;
        checks++;
        if (immExt !== exp) begin
            errors++;
            $error("%s | instr=0x%08h src=%b -> immExt=0x%08h (esp 0x%08h)",
                   nombre, ins, src, immExt, exp);
        end
    endtask

    function automatic logic [31:0] makeI (input logic [11:0] imm);
        logic [4:0] rs1, rd;
        logic [2:0] f3;
        rs1 = $urandom; rd = $urandom; f3 = $urandom;
        return {imm, rs1, f3, rd, 7'b0010011};
    endfunction

    function automatic logic [31:0] makeS (input logic [11:0] imm);
        logic [4:0] rs1, rs2;
        logic [2:0] f3;
        rs1 = $urandom; rs2 = $urandom; f3 = $urandom;
        return {imm[11:5], rs2, rs1, f3, imm[4:0], 7'b0100011};
    endfunction

    function automatic logic [31:0] makeB (input logic [12:0] imm);
        logic [4:0] rs1, rs2;
        logic [2:0] f3;
        rs1 = $urandom; rs2 = $urandom; f3 = $urandom;
        return {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], 7'b1100011};
    endfunction

    function automatic logic [31:0] makeU (input logic [19:0] imm);
        logic [4:0] rd;
        rd = $urandom;
        return {imm, rd, 7'b0110111};
    endfunction

    function automatic logic [31:0] makeJ (input logic [20:0] imm);
        logic [4:0] rd;
        rd = $urandom;
        return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'b1101111};
    endfunction

    task automatic checkI (input logic [11:0] imm);
        check(makeI(imm), I_TYPE, {{20{imm[11]}}, imm},
              $sformatf("I-type imm=0x%03h", imm));
    endtask

    task automatic checkS (input logic [11:0] imm);
        check(makeS(imm), S_TYPE, {{20{imm[11]}}, imm},
              $sformatf("S-type imm=0x%03h", imm));
    endtask

    task automatic checkB (input logic [12:0] semilla);
        logic [12:0] imm;
        imm = {semilla[12:1], 1'b0};        // el bit 0 siempre es cero
        check(makeB(imm), B_TYPE, {{19{imm[12]}}, imm},
              $sformatf("B-type imm=0x%04h", imm));
    endtask

    task automatic checkU (input logic [19:0] imm);
        check(makeU(imm), U_TYPE, {imm, 12'b0},
              $sformatf("U-type imm=0x%05h", imm));
    endtask

    task automatic checkJ (input logic [20:0] semilla);
        logic [20:0] imm;
        imm = {semilla[20:1], 1'b0};        // el bit 0 siempre es cero
        check(makeJ(imm), J_TYPE, {{11{imm[20]}}, imm},
              $sformatf("J-type imm=0x%06h", imm));
    endtask

    logic [11:0] CORNERS_I [6] = '{12'h000, 12'h001, 12'hFFF, 12'h7FF, 12'h800, 12'h5A5};
    logic [12:0] CORNERS_B [6] = '{13'h0000, 13'h0002, 13'h1FFE, 13'h0FFE, 13'h1000, 13'h0AAA};
    logic [19:0] CORNERS_U [5] = '{20'h00000, 20'h00001, 20'hFFFFF, 20'h7FFFF, 20'h80000};
    logic [20:0] CORNERS_J [6] = '{21'h000000, 21'h000002, 21'h1FFFFE, 21'h0FFFFE,
                                   21'h100000, 21'h0AAAAA};

    initial begin : PRUEBAS
        $dumpfile("tbImmediateGenerator.vcd");
        $dumpvars(0, tbImmediateGenerator);

        check(32'hFF63_0293, I_TYPE, 32'hFFFF_FFF6, "addi x5, x6, -10");
        check(32'h0083_2283, I_TYPE, 32'h0000_0008, "lw   x5, 8(x6)");
        check(32'h0073_2423, S_TYPE, 32'h0000_0008, "sw   x7, 8(x6)");
        check(32'h0073_0863, B_TYPE, 32'h0000_0010, "beq  x6, x7, +16");
        check(32'hFE73_08E3, B_TYPE, 32'hFFFF_FFF0, "beq  x6, x7, -16");
        check(32'h1234_52B7, U_TYPE, 32'h1234_5000, "lui  x5, 0x12345");
        check(32'h0010_02EF, J_TYPE, 32'h0000_0800, "jal  x5, +2048");
        check(32'hFFDF_F2EF, J_TYPE, 32'hFFFF_FFFC, "jal  x5, -4");

        foreach (CORNERS_I[i]) begin checkI(CORNERS_I[i]); checkS(CORNERS_I[i]); end
        foreach (CORNERS_B[i]) checkB(CORNERS_B[i]);
        foreach (CORNERS_U[i]) checkU(CORNERS_U[i]);
        foreach (CORNERS_J[i]) checkJ(CORNERS_J[i]);

        repeat (300) checkI($urandom);
        repeat (300) checkS($urandom);
        repeat (300) checkB($urandom);
        repeat (300) checkU($urandom);
        repeat (300) checkJ($urandom);

        check(32'hFFFF_FFFF, 3'b101, '0, "immSrc invalido 101");
        check(32'hFFFF_FFFF, 3'b110, '0, "immSrc invalido 110");
        check(32'hFFFF_FFFF, 3'b111, '0, "immSrc invalido 111");

        if (errors == 0) $display("TEST PASSED: %0d chequeos", checks);
        else             $display("TEST FAILED: %0d chequeos, %0d errores", checks, errors);
        $finish;
    end

endmodule
