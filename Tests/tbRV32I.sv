`timescale 1ns/1ps

module tbRV32I;
    logic clk = 0, reset = 1;
    int errors = 0;
    RV32I #(.HEXFILE("Src/testHazards.hex")) dut (.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    task automatic check(
        input int r,
        input logic [31:0] value,
        input string name
    );

        if (dut.core.rf.registers[r] !== value) begin
            $display("FAIL %s: esperado %h, obtenido %h", name, value, dut.core.rf.registers[r]);
            errors++;
        end else begin
            $display("OK   %s = %h", name, value);
        end
        
    endtask //automatic

    initial begin
        #12 reset = 0;           // suelta reset después del primer flanco
            repeat (80) @(posedge clk);                // 10 ciclos, sobra para 5 instrucciones
            check(1,  32'd5,         "x1");
        check(2,  32'd3,         "x2");
        check(3,  32'd8,         "x3");
        check(4,  32'd3,         "x4");
        check(5,  32'd11,        "x5");
        check(6,  32'd11,        "x6");
        check(7,  32'd5,         "x7");
        check(8,  32'd4,         "x8");
        check(9,  32'd4,         "x9");
        check(10, 32'd8,         "x10");
        check(11, 32'd0,         "x11");   // flush tras beq
        check(12, 32'd9,         "x12");
        check(13, 32'h48,        "x13");   // link de jal
        check(14, 32'd0,         "x14");   // flush tras jal
        check(15, 32'h54,        "x15");   // link de jalr
        check(16, 32'd0,         "x16");   // flush tras jalr
        check(17, 32'h12345000,  "x17");   // lui
        check(18, 32'h5C,        "x18");   // auipc
        if (dut.dmem.mem[1] !== 32'd4) begin
            $display("FAIL mem[1]: esperado 00000004, obtenido %h", dut.dmem.mem[1]);
            errors++;
        end else begin
            $display("OK   mem[1] = 00000004");
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d errores", errors);
        $finish;
    end
endmodule
