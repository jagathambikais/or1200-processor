module multiplier(
    input clk,
    input rst,
    input [31:0] multiplicand,  // First operand (A)
    input [31:0] multiplier,    // Second operand (B)
    input        multiply_en,   // Start multiplication
    
    output reg [63:0] product,  // 64-bit result
    output reg        ready      // Result ready
);

    // Pipeline stages for sequential multiplier
    reg [31:0] a_reg, b_reg;
    reg [63:0] partial_product;
    reg [4:0]  bit_counter;
    reg        multiplying;

    // Fast multiplier using built-in operator
    wire [63:0] fast_product = multiplicand * multiplier;

    always @(posedge clk) begin
        if (rst) begin
            product     <= 64'h0000000000000000;
            ready       <= 1'b1;
            multiplying <= 1'b0;
            bit_counter <= 5'b00000;
        end
        else if (multiply_en && !multiplying) begin
            // Start multiplication
            a_reg       <= multiplicand;
            b_reg       <= multiplier;
            product     <= fast_product;  // Use built-in multiplier
            ready       <= 1'b1;
            multiplying <= 1'b0;
        end
    end

endmodule