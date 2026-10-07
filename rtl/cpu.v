`timescale 1ns/1ps

// Top-level processor: instruction ROM, integrated datapath, and data RAM.
module cpu #(
    parameter INIT_FILE = "programs/cpu_top_test.mem"
) (
    input  clk,
    input  rst,
    output illegal_instr
);

    wire [7:0] pc;
    wire [15:0] instruction;
    wire [7:0] data_address;
    wire [7:0] data_write_data;
    wire data_write_enable;
    wire [7:0] data_read_data;

    instruction_memory #(
        .INIT_FILE(INIT_FILE)
    ) instruction_rom (
        .address(pc),
        .instruction(instruction)
    );

    datapath core (
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

    data_memory data_ram (
        .clk(clk),
        .we(data_write_enable),
        .address(data_address),
        .write_data(data_write_data),
        .read_data(data_read_data)
    );

endmodule
