`timescale 1ns/1ps

module alu_tb;

    reg [7:0] a;
    reg [7:0] b;
    reg [2:0] alu_control;
    wire [7:0] result;
    wire zero;
    integer errors;

    alu dut (
        .a(a),
        .b(b),
        .alu_control(alu_control),
        .result(result),
        .zero(zero)
    );

    task check_alu;
        input [2:0] test_control;
        input [7:0] test_a;
        input [7:0] test_b;
        input [7:0] expected_result;
        input expected_zero;
        input [511:0] label_text;
        begin
            alu_control = test_control;
            a = test_a;
            b = test_b;
            #1;

            if ((result !== expected_result) || (zero !== expected_zero)) begin
                $display("FAIL: %0s expected result=%02h zero=%b, got result=%02h zero=%b at %0t",
                         label_text, expected_result, expected_zero, result, zero, $time);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s result=%02h zero=%b",
                         label_text, result, zero);
            end
        end
    endtask

    initial begin
        a = 8'h00;
        b = 8'h00;
        alu_control = 3'b000;
        errors = 0;

        // ADD: ordinary addition and modulo-256 wraparound.
        check_alu(3'b000, 8'h12, 8'h23, 8'h35, 1'b0, "ADD ordinary");
        check_alu(3'b000, 8'hFF, 8'h02, 8'h01, 1'b0, "ADD wraps to low 8 bits");

        // SUB: result and equality/zero flag used by BEQ.
        check_alu(3'b001, 8'h55, 8'h55, 8'h00, 1'b1, "SUB equal operands");
        check_alu(3'b001, 8'h55, 8'h54, 8'h01, 1'b0, "SUB unequal operands");
        check_alu(3'b001, 8'h00, 8'h01, 8'hFF, 1'b0, "SUB underflow wraps");

        // Bitwise logical operations.
        check_alu(3'b010, 8'hF0, 8'h3C, 8'h30, 1'b0, "AND");
        check_alu(3'b011, 8'hF0, 8'h0F, 8'hFF, 1'b0, "OR");
        check_alu(3'b100, 8'hAA, 8'hFF, 8'h55, 1'b0, "XOR");

        // Shifts use only b[2:0]; exercise shift amounts 0 and 7.
        check_alu(3'b101, 8'h81, 8'h08, 8'h81, 1'b0, "SLL by 0 (low shift bits)");
        check_alu(3'b101, 8'h01, 8'h0F, 8'h80, 1'b0, "SLL by 7 (low shift bits)");
        check_alu(3'b110, 8'h81, 8'h08, 8'h81, 1'b0, "SRL by 0 (low shift bits)");
        check_alu(3'b110, 8'h81, 8'h0F, 8'h01, 1'b0, "SRL by 7 (logical)");

        // The reserved ALU control encoding has a deterministic safe default.
        check_alu(3'b111, 8'hA5, 8'h5A, 8'h00, 1'b0, "reserved ALU control");

        if (errors == 0) begin
            $display("\nALU TEST PASSED");
            $finish;
        end else begin
            $display("\nALU TEST FAILED: %0d error(s)", errors);
            $fatal(1);
        end
    end

endmodule
