`timescale 1ns/1ps

module tbRV32I;
    logic clk = 0, reset = 1;

    RV32I dut (.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    initial begin
        #12 reset = 0;           // suelta reset después del primer flanco
        #100;                    // 10 ciclos, sobra para 5 instrucciones
                $display("x1=%0d x2=%0d x3=%0d x4=%0d x5=%0d",
                 dut.core.rf.registers[1], dut.core.rf.registers[2],
                 dut.core.rf.registers[3], dut.core.rf.registers[4],
                 dut.core.rf.registers[5]);
        if (dut.core.rf.registers[3] == 8 && dut.core.rf.registers[4] == 2 &&
            dut.core.rf.registers[5] == 8)
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end
endmodule
