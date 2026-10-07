`timescale 1ns/1ps

module control_unit_tb;

    reg [3:0] opcode;
    reg [2:0] funct3;
    reg decoder_illegal;
    wire reg_write;
    wire mem_write;
    wire alu_src;
    wire [2:0] alu_control;
    wire [1:0] result_src;
    wire [1:0] pc_src;
    wire illegal_instr;
    integer errors;
    integer i;

    control_unit dut (
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

    task check_controls;
        input [3:0] test_opcode;
        input [2:0] test_funct3;
        input test_decoder_illegal;
        input expected_reg_write;
        input expected_mem_write;
        input expected_alu_src;
        input [2:0] expected_alu_control;
        input [1:0] expected_result_src;
        input [1:0] expected_pc_src;
        input expected_illegal;
        input [511:0] label_text;
        begin
            opcode = test_opcode;
            funct3 = test_funct3;
            decoder_illegal = test_decoder_illegal;
            #1;

            if ((reg_write !== expected_reg_write) ||
                (mem_write !== expected_mem_write) ||
                (alu_src !== expected_alu_src) ||
                (alu_control !== expected_alu_control) ||
                (result_src !== expected_result_src) ||
                (pc_src !== expected_pc_src) ||
                (illegal_instr !== expected_illegal)) begin
                $display("FAIL: %0s op=%h f3=%h decoder_illegal=%b", label_text,
                         test_opcode, test_funct3, test_decoder_illegal);
                $display("      expected RW=%b MW=%b AS=%b ALU=%b WB=%b PC=%b ill=%b",
                         expected_reg_write, expected_mem_write, expected_alu_src,
                         expected_alu_control, expected_result_src,
                         expected_pc_src, expected_illegal);
                $display("      got      RW=%b MW=%b AS=%b ALU=%b WB=%b PC=%b ill=%b",
                         reg_write, mem_write, alu_src, alu_control,
                         result_src, pc_src, illegal_instr);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s RW=%b MW=%b AS=%b ALU=%b WB=%b PC=%b ill=%b",
                         label_text, reg_write, mem_write, alu_src, alu_control,
                         result_src, pc_src, illegal_instr);
            end
        end
    endtask

    initial begin
        opcode = 4'b0000;
        funct3 = 3'b000;
        decoder_illegal = 1'b0;
        errors = 0;

        // Each assigned R-format operation writes its ALU result to rd.
        for (i = 0; i <= 6; i = i + 1) begin
            check_controls(4'b0000, i[2:0], 1'b0,
                           1'b1, 1'b0, 1'b0, i[2:0],
                           2'b00, 2'b00, 1'b0, "R-format operation");
        end

        check_controls(4'b0001, 3'b000, 1'b0,
                       1'b1, 1'b0, 1'b1, 3'b000,
                       2'b00, 2'b00, 1'b0, "ADDI controls");
        check_controls(4'b0010, 3'b000, 1'b0,
                       1'b1, 1'b0, 1'b1, 3'b000,
                       2'b01, 2'b00, 1'b0, "LOAD controls");
        check_controls(4'b0011, 3'b000, 1'b0,
                       1'b0, 1'b1, 1'b1, 3'b000,
                       2'b00, 2'b00, 1'b0, "STORE controls");
        check_controls(4'b0100, 3'b000, 1'b0,
                       1'b0, 1'b0, 1'b0, 3'b001,
                       2'b00, 2'b01, 1'b0, "BEQ controls");
        check_controls(4'b0101, 3'b000, 1'b0,
                       1'b1, 1'b0, 1'b0, 3'b000,
                       2'b10, 2'b10, 1'b0, "JAL controls");

        // Illegal inputs retain safe defaults and suppress every write.
        check_controls(4'b0000, 3'b111, 1'b0,
                       1'b0, 1'b0, 1'b0, 3'b000,
                       2'b00, 2'b00, 1'b1, "reserved R funct3");
        check_controls(4'b1000, 3'b000, 1'b0,
                       1'b0, 1'b0, 1'b0, 3'b000,
                       2'b00, 2'b00, 1'b1, "unassigned opcode");
        check_controls(4'b0001, 3'b000, 1'b1,
                       1'b0, 1'b0, 1'b0, 3'b000,
                       2'b00, 2'b00, 1'b1, "decoder illegal propagation");

        if (errors == 0) begin
            $display("\nCONTROL UNIT TEST PASSED");
            $finish;
        end else begin
            $display("\nCONTROL UNIT TEST FAILED: %0d error(s)", errors);
            $fatal(1);
        end
    end

endmodule
