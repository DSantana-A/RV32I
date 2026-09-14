`timescale 1ns/1ps

module RegisterFile #(
    parameter WIDTH = 32,
    parameter REGS = 32
) (
    input logic clk, reset, wEn,
    input logic [$clog2(REGS)-1:0] rs1, rs2, rd,
    input logic [WIDTH-1:0] wd,
    output logic [WIDTH-1:0] rdData1,rdData2
);

    logic [WIDTH-1:0] registers [REGS];

    always_ff @( posedge clk ) begin : WRITE
        if (reset) begin
            for (int i = 0; i<REGS; i++ ) begin
                registers[i] <= '0;
            end
        end else if (wEn && rd != '0)
            registers[rd] <= wd;
    end

    assign rdData1 = (rs1 == '0) ? '0 : registers[rs1];
    assign rdData2 = (rs2 == '0) ? '0 : registers[rs2];

endmodule