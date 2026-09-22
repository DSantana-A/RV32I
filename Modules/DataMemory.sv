`timescale 1ns/1ps

module DataMemory #(
    parameter int DEPTH = 64,
    parameter int WIDTH = 32
) (
    input logic clk, memWrite,
    input logic [WIDTH-1:0] addr, writeData,
    output logic [WIDTH-1:0] readData
);

    localparam int SHIFT = $clog2(WIDTH/8);
    logic [WIDTH-1:0] mem [DEPTH];
    logic [$clog2(DEPTH)-1:0] index;

    assign index = addr[$clog2(DEPTH)+SHIFT-1:SHIFT];

    always_ff @( posedge clk ) begin : Write
        if (memWrite) begin
            mem[index] <= writeData;
        end
    end

    assign readData = mem[index];

    initial begin
        foreach (mem[i]) mem[i] = '0;
    end
    
endmodule