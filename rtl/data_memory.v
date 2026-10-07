`timescale 1ns/1ps

// 256-byte data memory with combinational read and synchronous write.
module data_memory (
    input        clk,
    input        we,
    input  [7:0] address,
    input  [7:0] write_data,
    output wire [7:0] read_data
);

    reg [7:0] memory [0:255];

    // A write takes effect only on a rising edge while write-enable is high.
    always @(posedge clk) begin
        if (we)
            memory[address] <= write_data;
    end

    // Reads respond combinationally to the current address.
    assign read_data = memory[address];

endmodule
