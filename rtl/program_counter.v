`timescale 1ns/1ps

// 8-bit PC state element with active-high synchronous reset.
module program_counter (
    input        clk,
    input        rst,
    input  [7:0] pc_next,
    output reg [7:0] pc
);

    always @(posedge clk) begin
        if (rst)
            pc <= 8'h00;
        else
            pc <= pc_next;
    end

endmodule

// Combinational PC arithmetic and next-PC selection.
module next_pc_logic (
    input  [7:0] pc,
    input  signed [7:0] branch_offset,
    input  signed [8:0] jump_offset,
    input  [1:0] pc_src,
    input        zero,
    output wire [7:0] pc_plus_1,
    output wire [7:0] branch_target,
    output wire [7:0] jump_target,
    output reg  [7:0] pc_next
);

    // Extend operands to 10 signed bits before target addition. The final
    // target is reduced modulo 256 by retaining its low 8 bits.
    wire signed [9:0] pc_plus_1_ext;
    wire signed [9:0] branch_offset_ext;
    wire signed [9:0] jump_offset_ext;
    wire signed [9:0] branch_sum;
    wire signed [9:0] jump_sum;

    assign pc_plus_1 = pc + 8'd1;
    assign pc_plus_1_ext = {2'b00, pc_plus_1};
    assign branch_offset_ext = {{2{branch_offset[7]}}, branch_offset};
    assign jump_offset_ext = {{1{jump_offset[8]}}, jump_offset};
    assign branch_sum = pc_plus_1_ext + branch_offset_ext;
    assign jump_sum = pc_plus_1_ext + jump_offset_ext;
    assign branch_target = branch_sum[7:0];
    assign jump_target = jump_sum[7:0];

    // PCSrc: 00 sequential, 01 conditional BEQ, 10 JAL, 11 safe sequential.
    always @* begin
        case (pc_src)
            2'b00: pc_next = pc_plus_1;
            2'b01: pc_next = zero ? branch_target : pc_plus_1;
            2'b10: pc_next = jump_target;
            default: pc_next = pc_plus_1;
        endcase
    end

endmodule
