`timescale 1ns/1ps

// Extracts the shared signed 6-bit immediate/branch offset and signed
// 9-bit JAL offset from a 16-bit instruction.
module immediate_generator (
    input  [15:0] instruction,
    output wire signed [7:0] imm6_ext,
    output wire signed [8:0] offset9
);

    // I, S, and B formats place their signed 6-bit value in instruction[5:0].
    // Sign-extend it to the processor's 8-bit datapath width.
    assign imm6_ext = {{2{instruction[5]}}, instruction[5:0]};

    // The J-format offset is already 9 bits. Preserve all bits so the
    // dedicated PC arithmetic can perform its wider signed addition.
    assign offset9 = instruction[8:0];

endmodule
