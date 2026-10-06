`timescale 1ns/1ps

// Eight-entry, 8-bit register file for the custom processor.
// x0 is architecturally hardwired to zero and is not stored or written.
module register_file (
    input        clk,
    input        rst,
    input        we,
    input  [2:0] rs1,
    input  [2:0] rs2,
    input  [2:0] rd,
    input  [7:0] wd,
    output [7:0] rd1,
    output [7:0] rd2
);

    reg [7:0] registers [1:7];

    // Synchronous active-high reset. x0 has no storage element.
    always @(posedge clk) begin
        if (rst) begin
            registers[1] <= 8'h00;
            registers[2] <= 8'h00;
            registers[3] <= 8'h00;
            registers[4] <= 8'h00;
            registers[5] <= 8'h00;
            registers[6] <= 8'h00;
            registers[7] <= 8'h00;
        end else if (we && (rd != 3'b000)) begin
            registers[rd] <= wd;
        end
    end

    // Asynchronous read ports. Reads of x0 always return zero.
    assign rd1 = (rs1 == 3'b000) ? 8'h00 : registers[rs1];
    assign rd2 = (rs2 == 3'b000) ? 8'h00 : registers[rs2];

endmodule
