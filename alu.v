module alu(
    input [31:0] operand_a,     // First operand
    input [31:0] operand_b,     // Second operand
    input [3:0]  alu_op,        // Operation select
    input        carry_in,      // Carry input
    
    output reg [31:0] result,   // ALU result
    output reg        carry_out,// Carry output
    output reg        zero_flag,// Result is zero?
    output reg        sign_flag,// Result is negative?
    output reg        overflow  // Overflow occurred?
);

    // ALU Operation Codes
    parameter ALU_ADD  = 4'b0000;
    parameter ALU_ADDC = 4'b0001;
    parameter ALU_SUB  = 4'b0010;
    parameter ALU_SUBC = 4'b0011;
    parameter ALU_AND  = 4'b0100;
    parameter ALU_OR   = 4'b0101;
    parameter ALU_XOR  = 4'b0110;
    parameter ALU_SLL  = 4'b0111;  // Shift Left Logical
    parameter ALU_SRL  = 4'b1000;  // Shift Right Logical
    parameter ALU_SRA  = 4'b1001;  // Shift Right Arithmetic
    parameter ALU_MUL  = 4'b1010;
    parameter ALU_CMP  = 4'b1011;  // Compare

    wire [32:0] add_result;
    wire [32:0] sub_result;
    wire [31:0] and_result;
    wire [31:0] or_result;
    wire [31:0] xor_result;
    wire [31:0] shift_result;
    wire [63:0] mul_result;

    // Adder with carry
    assign add_result = operand_a + operand_b + carry_in;
    
    // Subtractor with carry
    assign sub_result = operand_a - operand_b - carry_in;

    // Logical operations
    assign and_result = operand_a & operand_b;
    assign or_result  = operand_a | operand_b;
    assign xor_result = operand_a ^ operand_b;

    // Shifter operations
    wire [4:0] shift_amount = operand_b[4:0];
    assign shift_result = (alu_op == ALU_SLL) ? (operand_a << shift_amount) :
                         (alu_op == ALU_SRL) ? (operand_a >> shift_amount) :
                         (alu_op == ALU_SRA) ? ($signed(operand_a) >>> shift_amount) :
                         32'h00000000;

    // Multiplier
    assign mul_result = operand_a * operand_b;

    always @(*) begin
        case (alu_op)

            ALU_ADD: begin
                result      = add_result[31:0];
                carry_out   = add_result[32];
                sign_flag   = add_result[31];
                overflow    = (operand_a[31] == operand_b[31]) && 
                             (add_result[31] != operand_a[31]);
            end

            ALU_ADDC: begin
                result      = add_result[31:0];
                carry_out   = add_result[32];
                sign_flag   = add_result[31];
                overflow    = (operand_a[31] == operand_b[31]) && 
                             (add_result[31] != operand_a[31]);
            end

            ALU_SUB: begin
                result      = sub_result[31:0];
                carry_out   = sub_result[32];
                sign_flag   = sub_result[31];
                overflow    = (operand_a[31] != operand_b[31]) && 
                             (sub_result[31] != operand_a[31]);
            end

            ALU_SUBC: begin
                result      = sub_result[31:0];
                carry_out   = sub_result[32];
                sign_flag   = sub_result[31];
                overflow    = (operand_a[31] != operand_b[31]) && 
                             (sub_result[31] != operand_a[31]);
            end

            ALU_AND: begin
                result    = and_result;
                carry_out = 0;
                sign_flag = and_result[31];
                overflow  = 0;
            end

            ALU_OR: begin
                result    = or_result;
                carry_out = 0;
                sign_flag = or_result[31];
                overflow  = 0;
            end

            ALU_XOR: begin
                result    = xor_result;
                carry_out = 0;
                sign_flag = xor_result[31];
                overflow  = 0;
            end

            ALU_SLL, ALU_SRL, ALU_SRA: begin
                result    = shift_result;
                carry_out = 0;
                sign_flag = shift_result[31];
                overflow  = 0;
            end

            ALU_MUL: begin
                result    = mul_result[31:0];
                carry_out = 0;
                sign_flag = mul_result[31];
                overflow  = 0;
            end

            ALU_CMP: begin
                // Compare: result = (a < b) ? -1 : (a == b) ? 0 : 1
                if (operand_a < operand_b)
                    result = 32'hFFFFFFFF;  // -1
                else if (operand_a == operand_b)
                    result = 32'h00000000;  // 0
                else
                    result = 32'h00000001;  // 1
                carry_out = 0;
                sign_flag = result[31];
                overflow  = 0;
            end

            default: begin
                result    = 32'h00000000;
                carry_out = 0;
                sign_flag = 0;
                overflow  = 0;
            end

        endcase

        // Zero flag
        zero_flag = (result == 32'h00000000) ? 1 : 0;
    end

endmodule