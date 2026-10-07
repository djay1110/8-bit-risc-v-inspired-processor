`timescale 1ns/1ps

// 256-word instruction ROM with a combinational read port.
module instruction_memory #(
    parameter INIT_FILE = "programs/instruction_memory_test.mem"
) (
    input  [7:0] address,
    output wire [15:0] instruction
);

    reg [15:0] memory [0:255];

    // FPGA tools can use this initialization file to initialize the ROM.
    initial begin
        $readmemh(INIT_FILE, memory);
    end

    // The addressed instruction is available combinationally.
    assign instruction = memory[address];

endmodule
