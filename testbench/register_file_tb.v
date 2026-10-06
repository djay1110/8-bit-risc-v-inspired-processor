`timescale 1ns/1ps

module register_file_tb;

    reg clk;
    reg rst;
    reg we;
    reg [2:0] rs1;
    reg [2:0] rs2;
    reg [2:0] rd;
    reg [7:0] wd;
    wire [7:0] rd1;
    wire [7:0] rd2;

    integer errors;
    integer i;

    register_file dut (
        .clk(clk),
        .rst(rst),
        .we(we),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(wd),
        .rd1(rd1),
        .rd2(rd2)
    );

    always #5 clk = ~clk;

    task check_value;
        input [7:0] actual;
        input [7:0] expected;
        input [511:0] label_text;
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s expected %02h, got %02h at time %0t",
                         label_text, expected, actual, $time);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s = %02h", label_text, actual);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b0;
        we = 1'b0;
        rs1 = 3'b000;
        rs2 = 3'b000;
        rd = 3'b000;
        wd = 8'h00;
        errors = 0;

        // Assert reset away from the active edge. The reset is synchronous,
        // so it must not clear state until the next rising edge.
        @(negedge clk);
        rst = 1'b1;
        @(posedge clk);
        #1;
        rs1 = 3'd0;
        rs2 = 3'd0;
        check_value(rd1, 8'h00, "x0 read after reset (port 1)");
        check_value(rd2, 8'h00, "x0 read after reset (port 2)");

        // Check all writable registers were reset to zero.
        rst = 1'b0;
        for (i = 1; i <= 7; i = i + 1) begin
            rs1 = i[2:0];
            #1;
            check_value(rd1, 8'h00, "register reset value");
        end

        // Write x1. Its value must remain unchanged before the rising edge.
        @(negedge clk);
        rs1 = 3'd1;
        rd = 3'd1;
        wd = 8'hA5;
        we = 1'b1;
        #1;
        check_value(rd1, 8'h00, "x1 before synchronous write edge");
        @(posedge clk);
        #1;
        check_value(rd1, 8'hA5, "x1 after write");

        // Write a distinct value to x2, then read x1 and x2 simultaneously.
        @(negedge clk);
        rd = 3'd2;
        wd = 8'h3C;
        rs1 = 3'd1;
        rs2 = 3'd2;
        @(posedge clk);
        #1;
        check_value(rd1, 8'hA5, "simultaneous read port 1 (x1)");
        check_value(rd2, 8'h3C, "simultaneous read port 2 (x2)");

        // Write different values to the remaining registers.
        for (i = 3; i <= 7; i = i + 1) begin
            @(negedge clk);
            rd = i[2:0];
            wd = 8'h40 + i;
            @(posedge clk);
            #1;
            rs1 = i[2:0];
            #1;
            check_value(rd1, 8'h40 + i, "written register x3-x7");
        end

        // Attempted x0 write must be discarded, and x0 must remain zero.
        @(negedge clk);
        rd = 3'd0;
        wd = 8'hFF;
        we = 1'b1;
        rs1 = 3'd0;
        rs2 = 3'd0;
        @(posedge clk);
        #1;
        check_value(rd1, 8'h00, "x0 remains zero after attempted write (port 1)");
        check_value(rd2, 8'h00, "x0 remains zero after attempted write (port 2)");

        // With writes disabled, stored values must persist across clock edges.
        @(negedge clk);
        we = 1'b0;
        rd = 3'd1;
        wd = 8'h00;
        rs1 = 3'd1;
        rs2 = 3'd2;
        repeat (2) begin
            @(posedge clk);
            #1;
            check_value(rd1, 8'hA5, "x1 persists without write");
            check_value(rd2, 8'h3C, "x2 persists without write");
        end

        // Reset known nonzero state. It must clear only on a rising edge.
        @(negedge clk);
        rst = 1'b1;
        rs1 = 3'd1;
        rs2 = 3'd2;
        #1;
        check_value(rd1, 8'hA5, "x1 before synchronous reset edge");
        check_value(rd2, 8'h3C, "x2 before synchronous reset edge");
        @(posedge clk);
        #1;
        check_value(rd1, 8'h00, "x1 after reset edge");
        check_value(rd2, 8'h00, "x2 after reset edge");
        rs1 = 3'd0;
        rs2 = 3'd0;
        #1;
        check_value(rd1, 8'h00, "x0 remains zero after reset");
        check_value(rd2, 8'h00, "x0 second port remains zero after reset");

        if (errors == 0) begin
            $display("\nREGISTER FILE TEST PASSED");
            $finish;
        end else begin
            $display("\nREGISTER FILE TEST FAILED: %0d error(s)", errors);
            $fatal(1);
        end
    end

endmodule
