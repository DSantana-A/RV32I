`timescale 1ns/1ps

module ALU #(
    parameter WIDTH = 32
) (
    input logic [WIDTH-1:0] inputA, inputB,
    input logic [3:0] aluOp,
    output logic [WIDTH-1:0] result,
    output logic zero
);
always_comb begin : ALU
    case (aluOp)
       4'b0000 : result = inputA + inputB;     //ADD
       4'b0001 : result = inputA - inputB;     //SUB

       4'b0010 : result = inputA & inputB;   //AND
       4'b0011 : result = inputA | inputB;     //OR
       4'b0100 : result = inputA ^ inputB;   //XOR

       4'b0101: result = inputA << inputB[$clog2(WIDTH)-1:0];   //SHIFT LEFT LOGIC
       4'b0110: result = inputA>> inputB[$clog2(WIDTH)-1:0];   //SHIFT RIGHT LOGIC
       4'b0111: result = $signed(inputA) >>> inputB[$clog2(WIDTH)-1:0];  //SHIFT RIGHT ARITHMETIC

       4'b1000: result = ($signed(inputA) < $signed(inputB))? 1 : 0;    // SLT:  SET LESS THAN (SIGN)
        4'b1001: result = (inputA<inputB) ? 1 : 0;                                     //SLTU: SET LESS THAN (NO SIGN)

        default: result = '0; 
    endcase
end

    assign zero = (result == '0);
endmodule