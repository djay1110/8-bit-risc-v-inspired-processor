`timescale 1ns/1ps

module instruction_memory_tb;

    reg [7:0] address;
    wire [15:0] instruction;
    integer errors;

    instruction_memory dut (
        .address(address),
        .instruction(instruction)
    );

    task check_read;
        input [7:0] test_address;
        input [15:0] expected_instruction;
        input [511:0] label_text;
        begin
            address = test_address;
            #1;

            if (instruction !== expected_instruction) begin
                $display("FAIL: %0s at address %02h expected %04h, got %04h at %0t",
                         label_text, test_address, expected_instruction,
                         instruction, $time);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s address=%02h instruction=%04h",
                         label_text, test_address, instruction);
            end
        end
    endtask

    initial begin
        address = 8'h00;
        errors = 0;

        // Reads at multiple addresses update without a clock.
        check_read(8'h00, 16'h0000, "first ROM word");
        check_read(8'h01, 16'h1234, "second ROM word");
        check_read(8'h02, 16'hABCD, "third ROM word");

        // Check the last two locations in the 256-word address space.
        check_read(8'hFE, 16'h55AA, "address FE");
        check_read(8'hFF, 16'hC33C, "address FF");

        if (errors == 0) begin
            $display("\nINSTRUCTION MEMORY TEST PASSED");
            $finish;
        end else begin
            $display("\nINSTRUCTION MEMORY TEST FAILED: %0d error(s)", errors);
            $fatal(1);
        end
    end

endmodule
