`timescale 1ns/1ps

module tbALU ();

    localparam int WIDTH = 32;

    logic [WIDTH-1:0] inputA, inputB, result;
    logic [3:0]       aluOp;
    logic             zero;

    int unsigned errors = 0;
    int unsigned checks = 0;

    ALU #(.WIDTH(WIDTH)) dut (.*);

    function automatic logic [WIDTH-1:0] aluModel (
        input logic [WIDTH-1:0] a, b,
        input logic [3:0]       op
    );
        case (op)
            4'b0000 : return a + b;
            4'b0001 : return a - b;
            4'b0010 : return a & b;
            4'b0011 : return a | b;
            4'b0100 : return a ^ b;
            4'b0101 : return a << b[$clog2(WIDTH)-1:0];
            4'b0110 : return a >> b[$clog2(WIDTH)-1:0];
            4'b0111 : return $signed(a) >>> b[$clog2(WIDTH)-1:0];
            4'b1000 : return ($signed(a) < $signed(b)) ? 1 : 0;
            4'b1001 : return (a < b) ? 1 : 0;
            default : return '0;
        endcase
    endfunction

    task automatic check (
        input logic [WIDTH-1:0] a, b,
        input logic [3:0]       op
    );
        logic [WIDTH-1:0] exp;

        inputA = a;
        inputB = b;
        aluOp  = op;
        #1;

        exp = aluModel(a, b, op);
        checks++;

        if (result !== exp || zero !== (exp == '0)) begin
            errors++;
            $error("op=%b A=0x%08h B=0x%08h | result=0x%08h (esp 0x%08h) zero=%0b (esp %0b)",
                   op, a, b, result, exp, zero, (exp == '0));
        end
    endtask

    logic [WIDTH-1:0] CORNERS [5] = '{
        32'h0000_0000, 32'h0000_0001, 32'hFFFF_FFFF, 32'h7FFF_FFFF, 32'h8000_0000
    };

    initial begin
        $dumpfile("tbALU.vcd");
        $dumpvars(0, tbALU);

        for (int op = 0; op < 16; op++) begin
            foreach (CORNERS[i])
                foreach (CORNERS[j])
                    check(CORNERS[i], CORNERS[j], op[3:0]);

            repeat (200) check({$urandom, $urandom}, {$urandom, $urandom}, op[3:0]);
            repeat (100) check({$urandom, $urandom}, $urandom_range(0, 2*WIDTH), op[3:0]);
        end

        if (errors == 0) $display("TEST PASSED: %0d chequeos", checks);
        else             $display("TEST FAILED: %0d chequeos, %0d errores", checks, errors);
        $finish;
    end

endmodule
