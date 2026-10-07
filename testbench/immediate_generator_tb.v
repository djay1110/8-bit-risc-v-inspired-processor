`timescale 1ns/1ps

module immediate_generator_tb;

    reg [15:0] instruction;
    wire signed [7:0] imm6_ext;
    wire signed [8:0] offset9;
    integer errors;

    immediate_generator dut (
        .instruction(instruction),
        .imm6_ext(imm6_ext),
        .offset9(offset9)
    );

    task check_fields;
        input [15:0] test_instruction;
        input [7:0] expected_imm6_ext;
        input [8:0] expected_offset9;
        input [511:0] label_text;
        begin
            instruction = test_instruction;
            #1;

            if ((imm6_ext !== expected_imm6_ext) ||
                (offset9 !== expected_offset9)) begin
                $display("FAIL: %0s expected imm6=%02h offset9=%03h, got imm6=%02h offset9=%03h at %0t",
                         label_text, expected_imm6_ext, expected_offset9,
                         imm6_ext, offset9, $time);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s imm6=%02h offset9=%03h",
                         label_text, imm6_ext, offset9);
            end
        end
    endtask

    initial begin
        instruction = 16'h0000;
        errors = 0;

        // Check the signed 6-bit endpoints and representative values.
        check_fields(16'b0000_000_000_000000, 8'h00, 9'b000000000,
                     "zero fields");
        check_fields(16'b1010_110_011_011111, 8'h1F, 9'b011011111,
                     "imm6 maximum +31");
        check_fields(16'b1010_111_010_100000, 8'hE0, 9'b010100000,
                     "imm6 minimum -32");
        check_fields(16'b0110_001_101_111111, 8'hFF, 9'b101111111,
                     "imm6 negative one");

        // Check the signed 9-bit JAL endpoints and sign-bit preservation.
        check_fields(16'b0101_111_100_000000, 8'h00, 9'b100000000,
                     "offset9 minimum -256");
        check_fields(16'b0101_000_011_111111, 8'hFF, 9'b011111111,
                     "offset9 maximum +255");
        check_fields(16'b0101_000_111_111111, 8'hFF, 9'b111111111,
                     "offset9 negative one");

        if (errors == 0) begin
            $display("\nIMMEDIATE GENERATOR TEST PASSED");
            $finish;
        end else begin
            $display("\nIMMEDIATE GENERATOR TEST FAILED: %0d error(s)", errors);
            $fatal(1);
        end
    end

endmodule
