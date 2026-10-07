`timescale 1ns/1ps

// Extracts instruction fields and identifies reserved encodings.
// Control-signal generation is handled by the later control-unit phase.
module instruction_decoder (
    input  [15:0] instruction,
    output reg [3:0] opcode,
    output reg [2:0] rd,
    output reg [2:0] rs1,
    output reg [2:0] rs2,
    output reg [2:0] funct3,
    output reg       illegal_instr
);

    always @* begin
        // Defaults keep unused fields deterministic and avoid inferred latches.
        opcode = instruction[15:12];
        rd = 3'b000;
        rs1 = 3'b000;
        rs2 = 3'b000;
        funct3 = 3'b000;
        illegal_instr = 1'b0;

        case (instruction[15:12])
            4'b0000: begin // R format
                funct3 = instruction[2:0];
                if (instruction[2:0] == 3'b111) begin
                    illegal_instr = 1'b1;
                end else begin
                    rd = instruction[11:9];
                    rs1 = instruction[8:6];
                    rs2 = instruction[5:3];
                end
            end

            4'b0001, // ADDI (I format)
            4'b0010: begin // LOAD (I format)
                rd = instruction[11:9];
                rs1 = instruction[8:6];
            end

            4'b0011: begin // STORE (S format): rs1=base, rs2=store data
                rs1 = instruction[8:6];
                rs2 = instruction[11:9];
            end

            4'b0100: begin // BEQ (B format)
                rs1 = instruction[11:9];
                rs2 = instruction[8:6];
            end

            4'b0101: begin // JAL (J format)
                rd = instruction[11:9];
            end

            default: illegal_instr = 1'b1;
        endcase
    end

endmodule
