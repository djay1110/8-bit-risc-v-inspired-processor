`timescale 1ns/1ps

// Combinational 8-bit ALU for the custom RISC-V-inspired processor.
module alu (
    input  [7:0] a,
    input  [7:0] b,
    input  [2:0] alu_control,
    output reg [7:0] result,
    output reg       zero
);

    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;
    localparam ALU_XOR = 3'b100;
    localparam ALU_SLL = 3'b101;
    localparam ALU_SRL = 3'b110;

    always @* begin
        // Safe defaults for the reserved control encoding and full assignment
        // of combinational outputs (no inferred latches).
        result = 8'h00;
        zero = 1'b0;

        case (alu_control)
            ALU_ADD: result = a + b;

            ALU_SUB: begin
                result = a - b;
                zero = (result == 8'h00);
            end

            ALU_AND: result = a & b;
            ALU_OR:  result = a | b;
            ALU_XOR: result = a ^ b;
            ALU_SLL: result = a << b[2:0];
            ALU_SRL: result = a >> b[2:0];

            default: begin
                result = 8'h00;
                zero = 1'b0;
            end
        endcase
    end

endmodule
