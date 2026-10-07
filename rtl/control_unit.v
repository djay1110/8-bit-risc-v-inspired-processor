`timescale 1ns/1ps

// Maps decoded opcode/function fields to the processor control signals.
module control_unit (
    input  [3:0] opcode,
    input  [2:0] funct3,
    input        decoder_illegal,
    output reg       reg_write,
    output reg       mem_write,
    output reg       alu_src,
    output reg [2:0] alu_control,
    output reg [1:0] result_src,
    output reg [1:0] pc_src,
    output reg       illegal_instr
);

    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;

    localparam RESULT_ALU  = 2'b00;
    localparam RESULT_MEM  = 2'b01;
    localparam RESULT_LINK = 2'b10;

    localparam PC_SEQUENTIAL = 2'b00;
    localparam PC_BRANCH     = 2'b01;
    localparam PC_JUMP       = 2'b10;

    always @* begin
        // Safe defaults: no writes, ALU result path, and sequential PC.
        reg_write = 1'b0;
        mem_write = 1'b0;
        alu_src = 1'b0;
        alu_control = ALU_ADD;
        result_src = RESULT_ALU;
        pc_src = PC_SEQUENTIAL;
        illegal_instr = decoder_illegal;

        // A decoder-reported illegal instruction keeps all side effects off.
        if (!decoder_illegal) begin
            case (opcode)
                4'b0000: begin // R-format ALU operation
                    case (funct3)
                        3'b000, 3'b001, 3'b010, 3'b011,
                        3'b100, 3'b101, 3'b110: begin
                            reg_write = 1'b1;
                            alu_control = funct3;
                        end
                        default: illegal_instr = 1'b1;
                    endcase
                end

                4'b0001: begin // ADDI
                    reg_write = 1'b1;
                    alu_src = 1'b1;
                    alu_control = ALU_ADD;
                end

                4'b0010: begin // LOAD
                    reg_write = 1'b1;
                    alu_src = 1'b1;
                    alu_control = ALU_ADD;
                    result_src = RESULT_MEM;
                end

                4'b0011: begin // STORE
                    mem_write = 1'b1;
                    alu_src = 1'b1;
                    alu_control = ALU_ADD;
                end

                4'b0100: begin // BEQ
                    alu_control = ALU_SUB;
                    pc_src = PC_BRANCH;
                end

                4'b0101: begin // JAL
                    reg_write = 1'b1;
                    result_src = RESULT_LINK;
                    pc_src = PC_JUMP;
                end

                default: illegal_instr = 1'b1;
            endcase
        end
    end

endmodule
