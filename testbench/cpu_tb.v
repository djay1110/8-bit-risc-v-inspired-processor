`timescale 1ns/1ps

module cpu_tb;

    reg clk;
    reg arithmetic_rst;
    reg loop_rst;
    wire arithmetic_illegal;
    wire loop_illegal;

    integer errors;
    integer checks;
    integer starting_errors;
    integer loop_cycles;
    integer taken_branch_count;
    integer backward_jump_count;
    reg [7:0] loop_pc_before;
    reg [55:0] arithmetic_register_snapshot;
    reg [15:0] arithmetic_memory_snapshot;

    cpu #(
        .INIT_FILE("programs/arithmetic.mem")
    ) arithmetic_cpu (
        .clk(clk),
        .rst(arithmetic_rst),
        .illegal_instr(arithmetic_illegal)
    );

    cpu #(
        .INIT_FILE("programs/loop_test.mem")
    ) loop_cpu (
        .clk(clk),
        .rst(loop_rst),
        .illegal_instr(loop_illegal)
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

    task report_group;
        input integer errors_before_group;
        input [511:0] group_name;
        begin
            if (errors == errors_before_group)
                $display("%0s: PASS", group_name);
            else
                $display("%0s: FAIL", group_name);
        end
    endtask

    task arithmetic_step;
        input [7:0] expected_pc;
        input [511:0] label_text;
        begin
            @(posedge clk);
            #1;
            check_value(arithmetic_cpu.pc === expected_pc, label_text);
        end
    endtask

    task capture_arithmetic_state;
        begin
            arithmetic_register_snapshot = {
                arithmetic_cpu.core.registers.registers[1],
                arithmetic_cpu.core.registers.registers[2],
                arithmetic_cpu.core.registers.registers[3],
                arithmetic_cpu.core.registers.registers[4],
                arithmetic_cpu.core.registers.registers[5],
                arithmetic_cpu.core.registers.registers[6],
                arithmetic_cpu.core.registers.registers[7]
            };
            arithmetic_memory_snapshot = {
                arithmetic_cpu.data_ram.memory[0],
                arithmetic_cpu.data_ram.memory[20]
            };
        end
    endtask

    task check_arithmetic_state_unchanged;
        begin
            check_value(({
                arithmetic_cpu.core.registers.registers[1],
                arithmetic_cpu.core.registers.registers[2],
                arithmetic_cpu.core.registers.registers[3],
                arithmetic_cpu.core.registers.registers[4],
                arithmetic_cpu.core.registers.registers[5],
                arithmetic_cpu.core.registers.registers[6],
                arithmetic_cpu.core.registers.registers[7]
            } === arithmetic_register_snapshot),
            "illegal instruction preserves x1-x7");
            check_value(({
                arithmetic_cpu.data_ram.memory[0],
                arithmetic_cpu.data_ram.memory[20]
            } === arithmetic_memory_snapshot),
            "illegal instruction preserves tested data-memory locations");
        end
    endtask

    initial begin
        clk = 1'b0;
        arithmetic_rst = 1'b1;
        loop_rst = 1'b1;
        errors = 0;
        checks = 0;
        loop_cycles = 0;
        taken_branch_count = 0;
        backward_jump_count = 0;

        // Both complete CPUs receive synchronous reset; neither memory is reset.
        @(posedge clk);
        #1;
        check_value(arithmetic_cpu.pc === 8'h00, "arithmetic CPU reset sets PC to zero");
        check_value(loop_cpu.pc === 8'h00, "loop CPU reset sets PC to zero");
        arithmetic_rst = 1'b0;

        $display("\n========================================");
        $display("CPU INTEGRATION TEST");
        $display("========================================");

        // Program 1: arithmetic and memory instructions from Architecture v1.0.
        starting_errors = errors;
        arithmetic_step(8'h01, "ADDI x1 advances PC");
        check_value(arithmetic_cpu.core.registers.registers[1] === 8'd5,
                    "arithmetic program x1 expected 5, actual value checked");
        arithmetic_step(8'h02, "ADDI x2 advances PC");
        check_value(arithmetic_cpu.core.registers.registers[2] === 8'd10,
                    "arithmetic program x2 expected 10, actual value checked");
        arithmetic_step(8'h03, "ADD advances PC");
        check_value(arithmetic_cpu.core.registers.registers[3] === 8'd15,
                    "arithmetic program x3 expected 15, actual value checked");
        report_group(starting_errors, "Arithmetic test");

        starting_errors = errors;
        arithmetic_step(8'h04, "STORE advances PC");
        check_value(arithmetic_cpu.data_ram.memory[20] === 8'd15,
                    "memory[20] after STORE expected 15");
        arithmetic_step(8'h05, "LOAD advances PC");
        check_value(arithmetic_cpu.core.registers.registers[4] === 8'd15,
                    "LOAD result x4 expected 15");
        report_group(starting_errors, "Memory test");

        // x0 write is attempted by the ROM program; the following x1 read
        // uses x0 as its source and verifies that x0 still supplies zero.
        starting_errors = errors;
        arithmetic_step(8'h06, "ADDI x0,x0,31 advances PC");
        check_value(arithmetic_cpu.core.rs1_data === 8'h00,
                    "x0 read port remains zero after attempted write");
        report_group(starting_errors, "x0 protection test");

        starting_errors = errors;
        arithmetic_step(8'h07, "negative-immediate ADDI advances PC");
        check_value(arithmetic_cpu.core.registers.registers[1] === 8'hFF,
                    "ADDI x1,x0,-1 expected FF");
        report_group(starting_errors, "Negative immediate test");

        starting_errors = errors;
        arithmetic_step(8'h08, "wraparound ADDI advances PC");
        check_value(arithmetic_cpu.core.registers.registers[2] === 8'h00,
                    "FF plus 1 wraps to 00 in x2");
        arithmetic_step(8'h09, "second negative-immediate ADDI advances PC");
        check_value(arithmetic_cpu.core.registers.registers[3] === 8'hFF,
                    "negative immediate produces FF in x3");
        arithmetic_step(8'h0A, "second wraparound ADDI advances PC");
        check_value(arithmetic_cpu.core.registers.registers[4] === 8'h00,
                    "FF plus 1 wraps to 00 in x4");
        arithmetic_step(8'h0B, "ADDI sets x2=1 for ALU integration tests");
        check_value(arithmetic_cpu.core.registers.registers[2] === 8'h01,
                    "x2 contains shift operand 1");
        report_group(starting_errors, "Arithmetic wraparound test");

        starting_errors = errors;
        arithmetic_step(8'h0C, "AND advances PC");
        check_value(arithmetic_cpu.core.registers.registers[4] === 8'h01,
                    "integrated AND: FF & 01 = 01");
        arithmetic_step(8'h0D, "OR advances PC");
        check_value(arithmetic_cpu.core.registers.registers[4] === 8'hFF,
                    "integrated OR: FF | 01 = FF");
        arithmetic_step(8'h0E, "XOR advances PC");
        check_value(arithmetic_cpu.core.registers.registers[4] === 8'hFE,
                    "integrated XOR: FF ^ 01 = FE");
        arithmetic_step(8'h0F, "SLL advances PC");
        check_value(arithmetic_cpu.core.registers.registers[4] === 8'hFE,
                    "integrated SLL uses rs2[2:0]=1");
        arithmetic_step(8'h10, "SRL advances PC");
        check_value(arithmetic_cpu.core.registers.registers[4] === 8'h7F,
                    "integrated SRL uses rs2[2:0]=1");
        report_group(starting_errors, "Integrated AND/OR/XOR/SLL/SRL test");

        starting_errors = errors;
        check_value(arithmetic_cpu.core.pc_next === 8'h13,
                    "equal BEQ selects forward target 19");
        arithmetic_step(8'h13, "taken forward BEQ advances to target 19");
        report_group(starting_errors, "Branch taken test");

        // x5 becomes zero, so the negative-offset BEQ goes back one
        // instruction. The repeated decrement makes x5 nonzero, so the
        // same BEQ then falls through, proving both negative-offset outcomes.
        starting_errors = errors;
        arithmetic_step(8'h14, "loop setup writes x5=1");
        check_value(arithmetic_cpu.core.registers.registers[5] === 8'h01,
                    "negative-BEQ loop starts with x5=1");
        arithmetic_step(8'h15, "decrement sets x5=0");
        check_value(arithmetic_cpu.core.registers.registers[5] === 8'h00,
                    "x5 becomes zero before negative BEQ");
        check_value(arithmetic_cpu.core.pc_next === 8'h14,
                    "equal BEQ with offset -2 selects backward target 20");
        arithmetic_step(8'h14, "taken negative BEQ returns to address 20");
        arithmetic_step(8'h15, "second decrement makes x5 nonzero");
        check_value(arithmetic_cpu.core.registers.registers[5] === 8'hFF,
                    "x5 becomes FF on second decrement");
        check_value(arithmetic_cpu.core.pc_next === 8'h16,
                    "unequal BEQ with offset -2 falls through");
        arithmetic_step(8'h16, "not-taken negative BEQ advances to 22");
        report_group(starting_errors, "Negative BEQ test");

        starting_errors = errors;
        arithmetic_step(8'h17, "wrapped STORE advances PC");
        check_value(arithmetic_cpu.data_ram.memory[0] === 8'hFF,
                    "STORE at base FF plus 1 writes memory[0]");
        arithmetic_step(8'h18, "wrapped LOAD advances PC");
        check_value(arithmetic_cpu.core.registers.registers[6] === 8'hFF,
                    "LOAD at base FF plus 1 reads memory[0]");
        report_group(starting_errors, "Data address wraparound test");

        starting_errors = errors;
        check_value(arithmetic_cpu.core.pc_next === 8'h19,
                    "unequal positive-offset BEQ selects sequential PC 25");
        arithmetic_step(8'h19, "not-taken BEQ falls through to 25");
        report_group(starting_errors, "Branch not taken test");

        starting_errors = errors;
        check_value(arithmetic_cpu.core.pc_next === 8'h1C,
                    "JAL selects PC-relative target 28");
        arithmetic_step(8'h1C, "JAL jumps forward to address 28");
        check_value(arithmetic_cpu.core.registers.registers[6] === 8'd26,
                    "JAL link register receives PC+1 value 26");
        report_group(starting_errors, "JAL link test");

        // Both illegal forms must assert illegal_instr, suppress writes, and
        // advance sequentially without changing any architectural state.
        starting_errors = errors;
        check_value(arithmetic_illegal === 1'b1, "reserved R funct3 asserts illegal_instr");
        check_value(arithmetic_cpu.core.reg_write === 1'b0,
                    "reserved R funct3 suppresses RegWrite");
        check_value(arithmetic_cpu.core.data_write_enable === 1'b0,
                    "reserved R funct3 suppresses MemWrite");
        check_value(arithmetic_cpu.core.pc_next === 8'h1D,
                    "reserved R funct3 selects PC+1");
        capture_arithmetic_state;
        arithmetic_step(8'h1D, "reserved R funct3 advances PC normally");
        check_arithmetic_state_unchanged;

        check_value(arithmetic_illegal === 1'b1, "unassigned opcode asserts illegal_instr");
        check_value(arithmetic_cpu.core.reg_write === 1'b0,
                    "unassigned opcode suppresses RegWrite");
        check_value(arithmetic_cpu.core.data_write_enable === 1'b0,
                    "unassigned opcode suppresses MemWrite");
        check_value(arithmetic_cpu.core.pc_next === 8'h1E,
                    "unassigned opcode selects PC+1");
        capture_arithmetic_state;
        arithmetic_step(8'h1E, "unassigned opcode advances PC normally");
        check_arithmetic_state_unchanged;
        report_group(starting_errors, "Illegal instruction test");

        starting_errors = errors;
        arithmetic_step(8'h1E, "JAL x0,-1 performs a backward self-jump");
        report_group(starting_errors, "Backward JAL test");

        // Reset after architectural state and both tested memory locations
        // contain nonzero values. Registers and PC reset; RAM contents persist.
        starting_errors = errors;
        @(negedge clk);
        arithmetic_rst = 1'b1;
        @(posedge clk);
        #1;
        check_value(arithmetic_cpu.pc === 8'h00, "post-execution reset clears PC");
        check_value(({
            arithmetic_cpu.core.registers.registers[1],
            arithmetic_cpu.core.registers.registers[2],
            arithmetic_cpu.core.registers.registers[3],
            arithmetic_cpu.core.registers.registers[4],
            arithmetic_cpu.core.registers.registers[5],
            arithmetic_cpu.core.registers.registers[6],
            arithmetic_cpu.core.registers.registers[7]
        } === 56'h0), "post-execution reset clears x1-x7");
        check_value(arithmetic_cpu.data_ram.memory[0] === 8'hFF,
                    "post-execution reset preserves wrapped memory[0]");
        check_value(arithmetic_cpu.data_ram.memory[20] === 8'd15,
                    "post-execution reset preserves memory[20]");
        report_group(starting_errors, "Post-execution reset test");

        // Release the loop CPU from reset and run until its STORE completes.
        @(negedge clk);
        loop_rst = 1'b0;
        starting_errors = errors;
        while ((loop_cpu.pc !== 8'h08) && (loop_cycles < 40)) begin
            loop_pc_before = loop_cpu.pc;
            @(posedge clk);
            #1;
            loop_cycles = loop_cycles + 1;
            if ((loop_pc_before == 8'h05) && (loop_cpu.pc == 8'h07))
                taken_branch_count = taken_branch_count + 1;
            if ((loop_pc_before == 8'h06) && (loop_cpu.pc == 8'h03))
                backward_jump_count = backward_jump_count + 1;
        end

        check_value(loop_cpu.pc === 8'h08, "loop program reaches instruction after STORE");
        check_value(loop_cpu.data_ram.memory[20] === 8'd5,
                    "loop program expected data_mem[20]=5");
        check_value(loop_cpu.core.registers.registers[1] === 8'd5,
                    "loop program expected x1=5");
        check_value(loop_cpu.core.registers.registers[3] === 8'd0,
                    "loop counter x3 reaches zero");
        check_value(taken_branch_count === 1,
                    "loop BEQ is taken once to DONE");
        check_value(backward_jump_count === 4,
                    "loop JAL returns backward four times");
        report_group(starting_errors, "Branch/JAL loop test");

        $display("\n========================================");
        if (errors == 0) begin
            $display("ALL CPU TESTS PASSED");
            $display("Total checks: %0d", checks);
            $finish;
        end else begin
            $display("CPU TESTS FAILED: %0d error(s) across %0d checks", errors, checks);
            $fatal(1);
        end
    end

endmodule
