`timescale 1ns/1ps

module datapath_tb;

    reg clk;
    reg rst;
    wire [7:0] pc;
    wire [15:0] instruction;
    wire [7:0] data_address;
    wire [7:0] data_write_data;
    wire data_write_enable;
    wire [7:0] data_read_data;
    wire illegal_instr;

    reg [15:0] rom [0:255];
    integer errors;
    integer checks;
    integer i;

    assign instruction = rom[pc];

    datapath dut (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .data_read_data(data_read_data),
        .pc(pc),
        .data_address(data_address),
        .data_write_data(data_write_data),
        .data_write_enable(data_write_enable),
        .illegal_instr(illegal_instr)
    );

    data_memory data_mem (
        .clk(clk),
        .we(data_write_enable),
        .address(data_address),
        .write_data(data_write_data),
        .read_data(data_read_data)
    );

    always #5 clk = ~clk;

    function [15:0] enc_i;
        input [3:0] op;
        input [2:0] destination;
        input [2:0] source;
        input [5:0] immediate;
        begin
            enc_i = {op, destination, source, immediate};
        end
    endfunction

    function [15:0] enc_r;
        input [2:0] destination;
        input [2:0] source_a;
        input [2:0] source_b;
        input [2:0] function_code;
        begin
            enc_r = {4'b0000, destination, source_a, source_b, function_code};
        end
    endfunction

    function [15:0] enc_s;
        input [2:0] data_reg;
        input [2:0] base_reg;
        input [5:0] immediate;
        begin
            enc_s = {4'b0011, data_reg, base_reg, immediate};
        end
    endfunction

    function [15:0] enc_b;
        input [2:0] source_a;
        input [2:0] source_b;
        input [5:0] offset;
        begin
            enc_b = {4'b0100, source_a, source_b, offset};
        end
    endfunction

    function [15:0] enc_j;
        input [2:0] destination;
        input [8:0] offset;
        begin
            enc_j = {4'b0101, destination, offset};
        end
    endfunction

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

    task execute_and_check_pc;
        input [7:0] expected_pc;
        input [511:0] label_text;
        begin
            @(posedge clk);
            #1;
            check_value(pc === expected_pc, label_text);
        end
    endtask

    task check_register;
        input [2:0] index;
        input [7:0] expected_value;
        input [511:0] label_text;
        begin
            case (index)
                3'd1: check_value(dut.registers.registers[1] === expected_value, label_text);
                3'd2: check_value(dut.registers.registers[2] === expected_value, label_text);
                3'd3: check_value(dut.registers.registers[3] === expected_value, label_text);
                3'd4: check_value(dut.registers.registers[4] === expected_value, label_text);
                3'd5: check_value(dut.registers.registers[5] === expected_value, label_text);
                3'd6: check_value(dut.registers.registers[6] === expected_value, label_text);
                3'd7: check_value(dut.registers.registers[7] === expected_value, label_text);
                default: check_value(expected_value === 8'h00, label_text);
            endcase
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        errors = 0;
        checks = 0;
        for (i = 0; i < 256; i = i + 1)
            rom[i] = 16'hF000;

        // Integration program: arithmetic, store/load, taken and untaken
        // branches, JAL link, illegal instruction, x0 write, and reset.
        rom[0]  = enc_i(4'b0001, 3'd1, 3'd0, 6'd5);       // ADDI x1,x0,5
        rom[1]  = enc_i(4'b0001, 3'd2, 3'd0, 6'd3);       // ADDI x2,x0,3
        rom[2]  = enc_r(3'd3, 3'd1, 3'd2, 3'b000);        // ADD x3,x1,x2
        rom[3]  = enc_r(3'd4, 3'd1, 3'd2, 3'b001);        // SUB x4,x1,x2
        rom[4]  = enc_s(3'd3, 3'd0, 6'd10);              // STORE x3,10(x0)
        rom[5]  = enc_i(4'b0010, 3'd5, 3'd0, 6'd10);      // LOAD x5,10(x0)
        rom[6]  = enc_b(3'd5, 3'd3, 6'd2);               // BEQ -> address 9
        rom[7]  = enc_i(4'b0001, 3'd6, 3'd0, 6'd31);     // skipped
        rom[8]  = enc_i(4'b0001, 3'd6, 3'd0, 6'd30);     // skipped
        rom[9]  = enc_j(3'd7, 9'd2);                     // JAL x7 -> 12
        rom[10] = enc_i(4'b0001, 3'd6, 3'd0, 6'd29);     // skipped
        rom[11] = enc_i(4'b0001, 3'd6, 3'd0, 6'd28);     // skipped
        rom[12] = enc_i(4'b0001, 3'd6, 3'd0, 6'd7);      // ADDI x6,x0,7
        rom[13] = enc_b(3'd5, 3'd4, 6'd2);               // BEQ not taken
        rom[14] = 16'hF000;                              // illegal opcode
        rom[15] = enc_j(3'd0, 9'd0);                     // JAL x0,+0 -> 16
        rom[16] = enc_s(3'd3, 3'd0, 6'd10);              // STORE held off by reset

        // Demonstrate reset clears registers and PC, but not data memory.
        data_mem.memory[10] = 8'h00;
        @(posedge clk);
        #1;
        check_value(pc === 8'h00, "synchronous reset initializes PC");
        for (i = 1; i <= 7; i = i + 1)
            check_register(i[2:0], 8'h00, "reset clears x1-x7");
        rst = 1'b0;

        #1;
        check_value(!illegal_instr, "ADDI is legal");
        execute_and_check_pc(8'h01, "ADDI advances PC to 1");
        check_register(3'd1, 8'd5, "ADDI writes x1=5");

        execute_and_check_pc(8'h02, "second ADDI advances PC to 2");
        check_register(3'd2, 8'd3, "ADDI writes x2=3");
        execute_and_check_pc(8'h03, "ADD advances PC to 3");
        check_register(3'd3, 8'd8, "ADD writes x3=8");
        execute_and_check_pc(8'h04, "SUB advances PC to 4");
        check_register(3'd4, 8'd2, "SUB writes x4=2");

        #1;
        check_value(data_address === 8'd10, "STORE effective address is 10");
        check_value(data_write_data === 8'd8, "STORE selects x3 as write data");
        check_value(data_write_enable === 1'b1, "STORE asserts memory write");
        execute_and_check_pc(8'h05, "STORE advances PC to 5");
        check_value(data_mem.memory[10] === 8'd8, "STORE writes data memory at address 10");

        execute_and_check_pc(8'h06, "LOAD advances PC to 6");
        check_register(3'd5, 8'd8, "LOAD writes memory value to x5");

        execute_and_check_pc(8'h09, "equal BEQ takes branch to address 9");
        check_register(3'd6, 8'h00, "taken BEQ skips both intervening instructions");
        execute_and_check_pc(8'h0C, "JAL jumps to address 12");
        check_register(3'd7, 8'd10, "JAL writes PC+1 link value to x7");
        execute_and_check_pc(8'h0D, "instruction at address 12 advances to 13");
        check_register(3'd6, 8'd7, "instruction at branch target writes x6=7");
        execute_and_check_pc(8'h0E, "unequal BEQ falls through to address 14");

        #1;
        check_value(illegal_instr === 1'b1, "unsupported opcode raises illegal_instr");
        check_value(dut.reg_write === 1'b0, "illegal instruction suppresses register write");
        check_value(data_write_enable === 1'b0, "illegal instruction suppresses memory write");
        execute_and_check_pc(8'h0F, "illegal instruction advances PC normally");
        check_register(3'd1, 8'd5, "illegal instruction leaves x1 unchanged");
        check_register(3'd7, 8'd10, "illegal instruction leaves x7 unchanged");
        check_value(data_mem.memory[10] === 8'd8, "illegal instruction leaves memory unchanged");

        execute_and_check_pc(8'h10, "JAL x0 performs unconditional jump");
        check_value(pc === 8'h10, "JAL x0 link write is discarded and jump reaches 16");
        rst = 1'b1;
        #1;
        check_value(data_write_enable === 1'b0, "reset disables a STORE memory write");
        check_value(data_mem.memory[10] === 8'd8, "STORE does not alter memory during reset");
        @(posedge clk);
        #1;
        check_value(pc === 8'h00, "reset returns PC to zero");
        check_register(3'd1, 8'h00, "reset clears a previously written register");
        check_value(data_mem.memory[10] === 8'd8, "CPU reset leaves data memory unchanged");

        if (errors == 0) begin
            $display("\nDATAPATH TEST PASSED: %0d checks", checks);
            $finish;
        end else begin
            $display("\nDATAPATH TEST FAILED: %0d error(s) across %0d checks", errors, checks);
            $fatal(1);
        end
    end

endmodule
