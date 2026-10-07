`timescale 1ns/1ps

// Integrates decode, register reads, ALU, writeback, and PC selection.
// Instruction and data memories remain outside this module for Phase 10.
module datapath (
    input        clk,
    input        rst,
    input  [15:0] instruction,
    input  [7:0] data_read_data,
    output [7:0] pc,
    output [7:0] data_address,
    output [7:0] data_write_data,
    output       data_write_enable,
    output       illegal_instr
);

    wire [3:0] opcode;
    wire [2:0] rd;
    wire [2:0] rs1;
    wire [2:0] rs2;
    wire [2:0] funct3;
    wire decoder_illegal;

    wire reg_write;
    wire mem_write;
    wire alu_src;
    wire [2:0] alu_control;
    wire [1:0] result_src;
    wire [1:0] pc_src;

    wire [7:0] rs1_data;
    wire [7:0] rs2_data;
    wire signed [7:0] imm6_ext;
    wire signed [8:0] offset9;
    wire [7:0] alu_b;
    wire [7:0] alu_result;
    wire alu_zero;
    wire [7:0] pc_plus_1;
    wire [7:0] branch_target;
    wire [7:0] jump_target;
    wire [7:0] pc_next;
    reg  [7:0] writeback_data;

    instruction_decoder decoder (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .illegal_instr(decoder_illegal)
    );

    control_unit control (
        .opcode(opcode),
        .funct3(funct3),
        .decoder_illegal(decoder_illegal),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .alu_control(alu_control),
        .result_src(result_src),
        .pc_src(pc_src),
        .illegal_instr(illegal_instr)
    );

    register_file registers (
        .clk(clk),
        .rst(rst),
        .we(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(writeback_data),
        .rd1(rs1_data),
        .rd2(rs2_data)
    );

    immediate_generator immediates (
        .instruction(instruction),
        .imm6_ext(imm6_ext),
        .offset9(offset9)
    );

    assign alu_b = alu_src ? imm6_ext : rs2_data;

    alu main_alu (
        .a(rs1_data),
        .b(alu_b),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(alu_zero)
    );

    // Select the architectural register writeback source.
    always @* begin
        case (result_src)
            2'b00: writeback_data = alu_result;
            2'b01: writeback_data = data_read_data;
            2'b10: writeback_data = pc_plus_1;
            default: writeback_data = 8'h00;
        endcase
    end

    assign data_address = alu_result;
    assign data_write_data = rs2_data;
    // Reset takes priority over state updates; suppress external RAM writes
    // on a reset edge as well because the data memory itself has no reset.
    assign data_write_enable = mem_write && !rst;

    next_pc_logic next_pc (
        .pc(pc),
        .branch_offset(imm6_ext),
        .jump_offset(offset9),
        .pc_src(pc_src),
        .zero(alu_zero),
        .pc_plus_1(pc_plus_1),
        .branch_target(branch_target),
        .jump_target(jump_target),
        .pc_next(pc_next)
    );

    program_counter pc_register (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc(pc)
    );

endmodule
