`timescale 1ns/1ps

module tbRV32IIsa;
    logic clk = 0, reset = 1, done = 0;
    int errors = 0, cycles = 0, instret = 0;
    RV32I #(.HEXFILE("Src/testISA.hex")) dut (.clk(clk), .reset(reset));

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

    always @(posedge clk) begin
        if (!reset && !done) begin
            cycles++;
            if (dut.core.validE) begin
                instret++;
                if (dut.core.pcE == 32'hB0) begin
                    done <= 1;
                end
            end
        end
    end

    initial begin
        #12 reset = 0; 
        repeat (100) @(posedge clk);
        check(1,  32'hFFFFFFFF, "x1");
        check(2,  32'h00000001, "x2");
        check(3,  32'h000000F0, "x3");
        check(4,  32'h000000FF, "x4");
        check(5,  32'h000000F0, "x5   and");
        check(6,  32'h0000000F, "x6   xor");
        check(7,  32'h00000001, "x7   slt");
        check(8,  32'h00000000, "x8   sltu");
        check(9,  32'h80000000, "x9   sll");
        check(10, 32'h00000001, "x10  srl");
        check(11, 32'hFFFFFFFF, "x11  sra");
        check(12, 32'h0000000F, "x12  andi");
        check(13, 32'hFFFFFF0F, "x13  xori");
        check(14, 32'h000000FF, "x14  ori");
        check(15, 32'h00000001, "x15  slti");
        check(16, 32'h00000001, "x16  sltiu");
        check(17, 32'h00000010, "x17  slli");
        check(18, 32'h0000000F, "x18  srli");
        check(19, 32'hF8000000, "x19  srai");
        check(20, 32'h00000040, "x20");
        check(21, 32'h81828384, "x21");
        check(22, 32'hFFFFFF84, "x22  lb");
        check(23, 32'h00000084, "x23  lbu");
        check(24, 32'hFFFF8182, "x24  lh");
        check(25, 32'h00008182, "x25  lhu");
        check(26, 32'hFFFFFF83, "x26  lb +1");
        check(27, 32'h01828384, "x27  lw tras sb");
        check(28, 32'h83840000, "x28  lw tras sh");
        check(29, 32'h00000002, "x29  branches no tomados OK");
        check(31, 32'h00000000, "x31  errores de branch");

        if (dut.dmem.mem[16] !== 32'h01828384) begin
            $display("FAIL mem[16]: esperado 01828384, obtenido %h", dut.dmem.mem[16]);
            errors++;
        end else begin
            $display("OK   mem[16] = 01828384");
        end

        if (dut.dmem.mem[17] !== 32'h83840000) begin
            $display("FAIL mem[17]: esperado 83840000, obtenido %h", dut.dmem.mem[17]);
            errors++;
        end else begin
            $display("OK   mem[17] = 83840000");
        end

        $display("cycles=%0d  instret=%0d  CPI=%0.2f", cycles, instret, real'(cycles)/instret);
        if (errors == 0) $display("PASS");
        else  $display("FAIL: %0d errores", errors);
        $finish;
    end
endmodule
