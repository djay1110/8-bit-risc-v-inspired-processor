`timescale 1ns/1ps

module cpu_top_tb;

    reg clk;
    reg rst;
    wire illegal_instr;
    integer errors;
    integer checks;

    cpu #(
        .INIT_FILE("programs/cpu_top_test.mem")
    ) dut (
        .clk(clk),
        .rst(rst),
        .illegal_instr(illegal_instr)
    );

    always #5 clk = ~clk;

    task check_value;
        input condition;
        input [511:0] label_text;
        begin
            checks = checks + 1;
            if (condition !== 1'b1) begin
                $display("FAIL: %0s at %0t", label_text, $time);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", label_text);
            end
        end
    endtask

    task execute_instruction;
        input [7:0] expected_pc;
        input [511:0] label_text;
        begin
            @(posedge clk);
            #1;
            check_value(dut.pc === expected_pc, label_text);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        errors = 0;
        checks = 0;

        // The ROM is initialized from the .mem file; reset only affects CPU state.
        @(posedge clk);
        #1;
        check_value(dut.pc === 8'h00, "CPU reset sets PC to zero");
        check_value(dut.data_ram.memory[20] === 8'hxx,
                    "data memory is not initialized by CPU reset");
        rst = 1'b0;

        execute_instruction(8'h01, "ADDI x1 executes through CPU top");
        check_value(dut.core.registers.registers[1] === 8'd5, "x1 contains 5");
        execute_instruction(8'h02, "second ADDI advances the PC");
        check_value(dut.core.registers.registers[2] === 8'd10, "x2 contains 10");
        execute_instruction(8'h03, "ADD advances the PC");
        check_value(dut.core.registers.registers[3] === 8'd15, "x3 contains 15");
        execute_instruction(8'h04, "STORE advances the PC");
        check_value(dut.data_ram.memory[20] === 8'd15, "STORE writes 15 to memory[20]");
        execute_instruction(8'h05, "LOAD advances the PC");
        check_value(dut.core.registers.registers[4] === 8'd15, "LOAD writes 15 to x4");

        #1;
        check_value(illegal_instr === 1'b1, "ROM illegal instruction is reported");
        execute_instruction(8'h06, "illegal instruction advances PC normally");
        check_value(dut.core.registers.registers[4] === 8'd15,
                    "illegal instruction does not alter x4");

        rst = 1'b1;
        @(posedge clk);
        #1;
        check_value(dut.pc === 8'h00, "CPU reset returns PC to zero");
        check_value(dut.core.registers.registers[1] === 8'h00,
                    "CPU reset clears general-purpose registers");
        check_value(dut.data_ram.memory[20] === 8'd15,
                    "CPU reset preserves data memory contents");

        if (errors == 0) begin
            $display("\nCPU TOP TEST PASSED: %0d checks", checks);
            $finish;
        end else begin
            $display("\nCPU TOP TEST FAILED: %0d error(s) across %0d checks", errors, checks);
            $fatal(1);
        end
    end

endmodule
