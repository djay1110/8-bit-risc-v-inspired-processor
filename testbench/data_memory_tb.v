`timescale 1ns/1ps

module data_memory_tb;

    reg clk;
    reg we;
    reg [7:0] address;
    reg [7:0] write_data;
    wire [7:0] read_data;
    integer errors;

    data_memory dut (
        .clk(clk),
        .we(we),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    task check_read;
        input [7:0] expected_data;
        input [511:0] label_text;
        begin
            if (read_data !== expected_data) begin
                $display("FAIL: %0s at address %02h expected %02h, got %02h at %0t",
                         label_text, address, expected_data, read_data, $time);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s address=%02h data=%02h",
                         label_text, address, read_data);
            end
        end
    endtask

    task write_byte;
        input [7:0] test_address;
        input [7:0] test_data;
        input [511:0] label_text;
        begin
            @(negedge clk);
            address = test_address;
            write_data = test_data;
            we = 1'b1;
            @(posedge clk);
            #1;
            check_read(test_data, label_text);
        end
    endtask

    initial begin
        clk = 1'b0;
        we = 1'b0;
        address = 8'h00;
        write_data = 8'h00;
        errors = 0;

        // Seed a known value before checking synchronous overwrite behavior.
        write_byte(8'h20, 8'hA5, "initial write to address 20");

        // A write must not change memory before the active clock edge.
        @(negedge clk);
        address = 8'h20;
        write_data = 8'h5A;
        we = 1'b1;
        #1;
        check_read(8'hA5, "old value before write edge");
        @(posedge clk);
        #1;
        check_read(8'h5A, "new value after write edge");

        // Store values at other locations, including the top of the address range.
        write_byte(8'h21, 8'h3C, "write address 21");
        write_byte(8'hFE, 8'hAA, "write address FE");
        write_byte(8'hFF, 8'h55, "write address FF");

        // Changing address changes read_data without waiting for a clock.
        we = 1'b0;
        address = 8'h20;
        #1;
        check_read(8'h5A, "combinational read address 20");
        address = 8'h21;
        #1;
        check_read(8'h3C, "combinational read address 21");
        address = 8'hFE;
        #1;
        check_read(8'hAA, "combinational read address FE");
        address = 8'hFF;
        #1;
        check_read(8'h55, "combinational read address FF");

        // With write-enable low, data must persist across clock edges.
        address = 8'h20;
        write_data = 8'h00;
        repeat (2) begin
            @(posedge clk);
            #1;
            check_read(8'h5A, "value persists with write disabled");
        end

        if (errors == 0) begin
            $display("\nDATA MEMORY TEST PASSED");
            $finish;
        end else begin
            $display("\nDATA MEMORY TEST FAILED: %0d error(s)", errors);
            $fatal(1);
        end
    end

endmodule
