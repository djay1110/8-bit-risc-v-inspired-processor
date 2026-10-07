`timescale 1ns/1ps

module program_counter_tb;

    reg clk;
    reg rst;
    reg [7:0] register_pc_next;
    wire [7:0] registered_pc;

    reg [7:0] logic_pc;
    reg signed [7:0] branch_offset;
    reg signed [8:0] jump_offset;
    reg [1:0] pc_src;
    reg zero;
    wire [7:0] pc_plus_1;
    wire [7:0] branch_target;
    wire [7:0] jump_target;
    wire [7:0] selected_pc_next;

    integer errors;

    program_counter pc_state (
        .clk(clk),
        .rst(rst),
        .pc_next(register_pc_next),
        .pc(registered_pc)
    );

    next_pc_logic pc_logic (
        .pc(logic_pc),
        .branch_offset(branch_offset),
        .jump_offset(jump_offset),
        .pc_src(pc_src),
        .zero(zero),
        .pc_plus_1(pc_plus_1),
        .branch_target(branch_target),
        .jump_target(jump_target),
        .pc_next(selected_pc_next)
    );

    always #5 clk = ~clk;

    task check_pc_register;
        input [7:0] expected_pc;
        input [511:0] label_text;
        begin
            if (registered_pc !== expected_pc) begin
                $display("FAIL: %0s expected PC=%02h, got %02h at %0t",
                         label_text, expected_pc, registered_pc, $time);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s PC=%02h", label_text, registered_pc);
            end
        end
    endtask

    task check_next_pc;
        input [7:0] test_pc;
        input signed [7:0] test_branch_offset;
        input signed [8:0] test_jump_offset;
        input [1:0] test_pc_src;
        input test_zero;
        input [7:0] expected_pc_plus_1;
        input [7:0] expected_branch_target;
        input [7:0] expected_jump_target;
        input [7:0] expected_pc_next;
        input [511:0] label_text;
        begin
            logic_pc = test_pc;
            branch_offset = test_branch_offset;
            jump_offset = test_jump_offset;
            pc_src = test_pc_src;
            zero = test_zero;
            #1;

            if ((pc_plus_1 !== expected_pc_plus_1) ||
                (branch_target !== expected_branch_target) ||
                (jump_target !== expected_jump_target) ||
                (selected_pc_next !== expected_pc_next)) begin
                $display("FAIL: %0s expected pc+1=%02h branch=%02h jump=%02h next=%02h",
                         label_text, expected_pc_plus_1, expected_branch_target,
                         expected_jump_target, expected_pc_next);
                $display("      got pc+1=%02h branch=%02h jump=%02h next=%02h",
                         pc_plus_1, branch_target, jump_target, selected_pc_next);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s pc+1=%02h branch=%02h jump=%02h next=%02h",
                         label_text, pc_plus_1, branch_target, jump_target,
                         selected_pc_next);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        register_pc_next = 8'h55;
        logic_pc = 8'h00;
        branch_offset = 8'sd0;
        jump_offset = 9'sd0;
        pc_src = 2'b00;
        zero = 1'b0;
        errors = 0;

        // Synchronous reset takes effect at the rising edge.
        @(posedge clk);
        #1;
        check_pc_register(8'h00, "reset PC to zero");
        rst = 1'b0;

        // A new PC value is not visible until the next rising edge.
        @(negedge clk);
        register_pc_next = 8'h2A;
        #1;
        check_pc_register(8'h00, "PC holds before update edge");
        @(posedge clk);
        #1;
        check_pc_register(8'h2A, "PC updates at rising edge");

        // Reset asserted between edges must not act asynchronously.
        @(negedge clk);
        rst = 1'b1;
        #1;
        check_pc_register(8'h2A, "PC holds before synchronous reset edge");
        @(posedge clk);
        #1;
        check_pc_register(8'h00, "synchronous reset clears PC");
        rst = 1'b0;

        // Sequential, taken/not-taken branch, signed offsets, and PC wrap.
        check_next_pc(8'h05, 8'sd1, 9'sd0, 2'b00, 1'b0,
                      8'h06, 8'h07, 8'h06, 8'h06, "sequential PC and +1 branch");
        check_next_pc(8'h05, 8'sd1, 9'sd0, 2'b01, 1'b1,
                      8'h06, 8'h07, 8'h06, 8'h07, "taken BEQ");
        check_next_pc(8'h05, 8'sd1, 9'sd0, 2'b01, 1'b0,
                      8'h06, 8'h07, 8'h06, 8'h06, "not-taken BEQ");
        check_next_pc(8'h03, -8'sd4, -9'sd4, 2'b01, 1'b1,
                      8'h04, 8'h00, 8'h00, 8'h00, "negative branch offset");
        check_next_pc(8'hFF, 8'sd1, 9'sd0, 2'b00, 1'b0,
                      8'h00, 8'h01, 8'h00, 8'h00, "PC and target wraparound");

        // JAL offset cases include the signed 9-bit endpoints.
        check_next_pc(8'h06, 8'sd0, -9'sd4, 2'b10, 1'b0,
                      8'h07, 8'h07, 8'h03, 8'h03, "JAL backward by four words");
        check_next_pc(8'h00, 8'sd0, -9'sd256, 2'b10, 1'b0,
                      8'h01, 8'h01, 8'h01, 8'h01, "JAL minimum offset -256");
        check_next_pc(8'h00, 8'sd0, 9'sd255, 2'b10, 1'b0,
                      8'h01, 8'h01, 8'h00, 8'h00, "JAL maximum offset +255");

        // Reserved PCSrc has a safe sequential default.
        check_next_pc(8'h20, 8'sd0, 9'sd0, 2'b11, 1'b1,
                      8'h21, 8'h21, 8'h21, 8'h21, "reserved PCSrc default");

        if (errors == 0) begin
            $display("\nPROGRAM COUNTER TEST PASSED");
            $finish;
        end else begin
            $display("\nPROGRAM COUNTER TEST FAILED: %0d error(s)", errors);
            $fatal(1);
        end
    end

endmodule
