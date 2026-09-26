`timescale 1ns/1ps

module DataMemory #(
    parameter int DEPTH = 64
) (
    input logic clk, memWrite,
    input logic [2:0] funct3,
    input logic [31:0] addr, writeData,
    output logic [31:0] readData
);

    localparam int SHIFT = 2;
    logic [31:0] mem [DEPTH];
    logic [$clog2(DEPTH)-1:0] index;

    logic [31:0] word;
    logic [7:0] byteSel;
    logic [15:0] halfSel;

    assign index = addr[$clog2(DEPTH)+SHIFT-1:SHIFT];

    assign word = mem[index];
    assign byteSel = word[8*addr[1:0]+: 8];
    assign halfSel = word[16*addr[1] +: 16];

    always @( posedge clk ) begin : Write
        if (memWrite) begin
            case (funct3[1:0])
                2'b00 : mem[index][8*addr[1:0] +: 8] <= writeData[7:0];
                2'b01 :  mem[index][16*addr[1] +: 16] <= writeData[15:0];
                default: mem[index] <= writeData;
            endcase
        end
    end

    always_comb begin : Read
        case (funct3)
            3'b000 : readData = {{24{byteSel[7]}}, byteSel};
            3'b001 :  readData = {{16{halfSel[15]}}, halfSel};
            3'b010 : readData = word;
            3'b100 : readData = {24'b0, byteSel};
            3'b101 : readData = {16'b0, halfSel};
            default:  readData = word;
        endcase
    end

    initial begin
        foreach (mem[i]) mem[i] = '0;
    end
    
endmodule