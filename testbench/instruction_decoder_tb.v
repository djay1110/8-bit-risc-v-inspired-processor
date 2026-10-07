`timescale 1ns/1ps

module instruction_decoder_tb;

    reg [15:0] instruction;
    wire [3:0] opcode;
    wire [2:0] rd;
    wire [2:0] rs1;
    wire [2:0] rs2;
    wire [2:0] funct3;
    wire illegal_instr;
    integer errors;
    integer i;

    instruction_decoder dut (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .illegal_instr(illegal_instr)
    );

    task check_decode;
        input [15:0] test_instruction;
        input [3:0] expected_opcode;
        input [2:0] expected_rd;
        input [2:0] expected_rs1;
        input [2:0] expected_rs2;
        input [2:0] expected_funct3;
        input expected_illegal;
        input [511:0] label_text;
        begin
            instruction = test_instruction;
            #1;

            if ((opcode !== expected_opcode) ||
                (rd !== expected_rd) ||
                (rs1 !== expected_rs1) ||
                (rs2 !== expected_rs2) ||
                (funct3 !== expected_funct3) ||
                (illegal_instr !== expected_illegal)) begin
                $display("FAIL: %0s instr=%04h expected op=%h rd=%h rs1=%h rs2=%h f3=%h illegal=%b",
                         label_text, test_instruction, expected_opcode, expected_rd,
                         expected_rs1, expected_rs2, expected_funct3, expected_illegal);
                $display("      got op=%h rd=%h rs1=%h rs2=%h f3=%h illegal=%b",
                         opcode, rd, rs1, rs2, funct3, illegal_instr);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s op=%h rd=%h rs1=%h rs2=%h f3=%h illegal=%b",
                         label_text, opcode, rd, rs1, rs2, funct3, illegal_instr);
            end
        end
    endtask

    initial begin
        instruction = 16'h0000;
        errors = 0;

        // All seven assigned R-format funct3 values are legal.
        for (i = 0; i <= 6; i = i + 1) begin
            check_decode({4'b0000, 3'd3, 3'd2, 3'd5, i[2:0]},
                         4'b0000, 3'd3, 3'd2, 3'd5, i[2:0], 1'b0,
                         "valid R-format funct3");
        end

        // I format: rd and rs1 are decoded; rs2/funct3 are unused defaults.
        check_decode(16'b0001_001_111_111111,
                     4'b0001, 3'd1, 3'd7, 3'd0, 3'd0, 1'b0, "ADDI fields");
        check_decode(16'b0010_100_010_000001,
                     4'b0010, 3'd4, 3'd2, 3'd0, 3'd0, 1'b0, "LOAD fields");

        // S format maps the base to rs1 and store data to the RF's rs2 port.
        check_decode(16'b0011_101_011_000001,
                     4'b0011, 3'd0, 3'd3, 3'd5, 3'd0, 1'b0, "STORE fields");

        // B and J formats have their own register-field positions.
        check_decode(16'b0100_110_010_111111,
                     4'b0100, 3'd0, 3'd6, 3'd2, 3'd0, 1'b0, "BEQ fields");
        check_decode(16'b0101_111_000_101010,
                     4'b0101, 3'd7, 3'd0, 3'd0, 3'd0, 1'b0, "JAL fields");

        // R-format funct3=111 is reserved and illegal.
        check_decode(16'b0000_111_010_101_111,
                     4'b0000, 3'd0, 3'd0, 3'd0, 3'b111, 1'b1,
                     "reserved R-format funct3");

        // Every opcode from 6 through F is unassigned and therefore illegal.
        for (i = 6; i <= 15; i = i + 1) begin
            check_decode({i[3:0], 12'hABC}, i[3:0],
                         3'd0, 3'd0, 3'd0, 3'd0, 1'b1,
                         "unassigned opcode");
        end

        if (errors == 0) begin
            $display("\nINSTRUCTION DECODER TEST PASSED");
            $finish;
        end else begin
            $display("\nINSTRUCTION DECODER TEST FAILED: %0d error(s)", errors);
            $fatal(1);
        end
    end

endmodule
