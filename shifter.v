module shifter(
    input [31:0] data_in,       // Data to shift
    input [4:0]  shift_amount,  // How much to shift (0-31)
    input [2:0]  shift_op,      // Operation: SLL, SRL, SRA
    
    output [31:0] result        // Shifted result
);

    // Shift operation codes
    parameter SHIFT_LL = 3'b000;  // Shift Left Logical
    parameter SHIFT_RL = 3'b001;  // Shift Right Logical
    parameter SHIFT_RA = 3'b010;  // Shift Right Arithmetic

    // Barrel shifter implementation using cascade
    wire [31:0] shift_stage1;
    wire [31:0] shift_stage2;
    wire [31:0] shift_stage3;
    wire [31:0] shift_stage4;
    wire [31:0] shift_stage5;

    // Stage 1: Shift by 0 or 1 bit
    assign shift_stage1 = shift_amount[0] ? 
                         shift_left_right(data_in, 1, shift_op) : 
                         data_in;

    // Stage 2: Shift by 0 or 2 bits
    assign shift_stage2 = shift_amount[1] ? 
                         shift_left_right(shift_stage1, 2, shift_op) : 
                         shift_stage1;

    // Stage 3: Shift by 0 or 4 bits
    assign shift_stage3 = shift_amount[2] ? 
                         shift_left_right(shift_stage2, 4, shift_op) : 
                         shift_stage2;

    // Stage 4: Shift by 0 or 8 bits
    assign shift_stage4 = shift_amount[3] ? 
                         shift_left_right(shift_stage3, 8, shift_op) : 
                         shift_stage3;

    // Stage 5: Shift by 0 or 16 bits
    assign shift_stage5 = shift_amount[4] ? 
                         shift_left_right(shift_stage4, 16, shift_op) : 
                         shift_stage4;

    assign result = shift_stage5;

    // Function for individual shift
    function [31:0] shift_left_right(
        input [31:0] data,
        input [4:0]  amount,
        input [2:0]  op
    );
        reg [31:0] temp;
        integer i;
        begin
            temp = data;
            
            case (op)
                SHIFT_LL: begin
                    // Shift Left Logical
                    for (i = 0; i < amount; i = i + 1)
                        temp = {temp[30:0], 1'b0};
                end
                
                SHIFT_RL: begin
                    // Shift Right Logical
                    for (i = 0; i < amount; i = i + 1)
                        temp = {1'b0, temp[31:1]};
                end
                
                SHIFT_RA: begin
                    // Shift Right Arithmetic (preserve sign)
                    for (i = 0; i < amount; i = i + 1)
                        temp = {temp[31], temp[31:1]};
                end
                
                default:
                    temp = data;
            endcase
            
            shift_left_right = temp;
        end
    endfunction

endmodule