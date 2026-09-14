`timescale 1ns/1ps

module tbRegisterFile ();

    localparam int WIDTH = 32;
    localparam int REGS  = 32;
    localparam int ADDR  = $clog2(REGS);
    localparam int CLK   = 10;

    logic                  clk, reset, wEn;
    logic [ADDR-1:0]       rs1, rs2, rd;
    logic [WIDTH-1:0]      wd, rdData1, rdData2;

    int unsigned errors = 0;
    int unsigned checks = 0;

    logic [WIDTH-1:0] model [REGS];

    RegisterFile #(.WIDTH(WIDTH), .REGS(REGS)) dut (.*);


    initial clk = 1'b0;
    always #(CLK/2) clk = ~clk;

    task automatic doReset ();
        reset = 1'b1;
        wEn   = 1'b0;
        rd    = '0;
        wd    = '0;
        rs1   = '0;
        rs2   = '0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;
        foreach (model[i]) model[i] = '0;
    endtask

    task automatic writeReg (
        input logic [ADDR-1:0]  addr,
        input logic [WIDTH-1:0] data,
        input logic             en
    );
        @(negedge clk);
        rd  = addr;
        wd  = data;
        wEn = en;

        @(posedge clk);             
        if (en && addr != '0)       
            model[addr] = data;

        @(negedge clk);
        wEn = 1'b0;
    endtask

    task automatic checkRead (
        input logic [ADDR-1:0] a1,
        input logic [ADDR-1:0] a2
    );
        logic [WIDTH-1:0] exp1, exp2;

        rs1 = a1;
        rs2 = a2;
        #1;                        

        exp1 = (a1 == '0) ? '0 : model[a1];
        exp2 = (a2 == '0) ? '0 : model[a2];
        checks++;

        if (rdData1 !== exp1 || rdData2 !== exp2) begin
            errors++;
            $error("rs1=%0d rs2=%0d | rdData1=0x%08h (esp 0x%08h) rdData2=0x%08h (esp 0x%08h)",
                   a1, a2, rdData1, exp1, rdData2, exp2);
        end
    endtask

    task automatic expect1 (
        input logic [WIDTH-1:0] got,
        input logic [WIDTH-1:0] exp,
        input string            nombre
    );
        checks++;
        if (got !== exp) begin
            errors++;
            $error("%s: obtuve 0x%08h, esperaba 0x%08h", nombre, got, exp);
        end
    endtask

    initial begin : PRUEBAS
        logic [WIDTH-1:0] viejo;

        $dumpfile("tbRegisterFile.vcd");
        $dumpvars(0, tbRegisterFile);


        doReset();
        for (int i = 0; i < REGS; i++)
            checkRead(i[ADDR-1:0], i[ADDR-1:0]);

        for (int i = 1; i < REGS; i++)
            writeReg(i[ADDR-1:0], 32'hA5A5_0000 + i, 1'b1);

        for (int i = 0; i < REGS; i++)
            checkRead(i[ADDR-1:0], (REGS-1-i));

        writeReg('0, 32'hFFFF_FFFF, 1'b1);
        checkRead('0, '0);
        expect1(rdData1, '0, "x0 quedo escrito");

        viejo = model[3];
        writeReg(5'd3, 32'hDEAD_DEAD, 1'b0);
        checkRead(5'd3, 5'd3);
        expect1(rdData1, viejo, "escribio con wEn=0");

        checkRead(5'd9, 5'd9);
        expect1(rdData2, model[9], "los dos puertos no coinciden");

        @(negedge clk);
        rd  = 5'd7;
        wd  = 32'hDEAD_BEEF;
        wEn = 1'b1;
        rs1 = 5'd7;
        rs2 = '0;
        #1;
        expect1(rdData1, model[7], "antes del flanco ya cambio");

        @(posedge clk);
        model[7] = 32'hDEAD_BEEF;
        #1;
        expect1(rdData1, 32'hDEAD_BEEF, "despues del flanco no cambio");

        @(negedge clk);
        wEn = 1'b0;

        repeat (500) begin
            writeReg($urandom_range(0, REGS-1), $urandom, 1'b1);
            checkRead($urandom_range(0, REGS-1), $urandom_range(0, REGS-1));
        end

        doReset();
        for (int i = 0; i < REGS; i++)
            checkRead(i[ADDR-1:0], i[ADDR-1:0]);

        if (errors == 0) $display("TEST PASSED: %0d chequeos", checks);
        else             $display("TEST FAILED: %0d chequeos, %0d errores", checks, errors);
        $finish;
    end

endmodule
