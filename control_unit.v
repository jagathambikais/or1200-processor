module control_unit(
    input [31:0] instruction,  // 32-bit instruction
    input        clk,
    input        rst,
    
    // ALU control
    output reg [3:0]  alu_op,      // ALU operation
    output reg        alu_src_b,   // 0=register, 1=immediate
    
    // Register file control
    output reg        reg_write,   // Write to register?
    output reg [4:0]  write_reg,   // Which register to write
    output reg        reg_src,     // 0=ALU, 1=memory
    
    // Memory control
    output reg        mem_read,    // Read from memory?
    output reg        mem_write,   // Write to memory?
    output reg [1:0]  mem_size,    // 00=byte, 01=half, 10=word
    
    // Branch control
    output reg        branch,      // Is branch instruction?
    output reg        branch_cond, // 0=unconditional, 1=conditional
    
    // Instruction fields
    output reg [4:0]  rs,          // Source register 1
    output reg [4:0]  rt,          // Source register 2
    output reg [4:0]  rd,          // Destination register
    output reg [15:0] immediate,   // Immediate value
    output reg [25:0] jump_target, // Jump target
    
    // Special signals
    output reg        illegal_instruction
);

    // Instruction format definitions
    // RISC: [opcode:6][rs:5][rt:5][rd:5][shamt:5][func:6]
    wire [5:0] opcode = instruction[31:26];
    wire [5:0] func   = instruction[5:0];

    // Instruction field extraction
    always @(*) begin
        rs        = instruction[25:21];
        rt        = instruction[20:16];
        rd        = instruction[15:11];
        immediate = instruction[15:0];
        jump_target = instruction[25:0];
    end

    // Control signal generation
    always @(*) begin
        // Default values
        alu_op             = 4'b0000;
        alu_src_b          = 1'b0;
        reg_write          = 1'b0;
        write_reg          = 5'b00000;
        reg_src            = 1'b0;
        mem_read           = 1'b0;
        mem_write          = 1'b0;
        mem_size           = 2'b10;     // word by default
        branch             = 1'b0;
        branch_cond        = 1'b0;
        illegal_instruction = 1'b0;

        case (opcode)

            // R-type instructions (opcode = 000000)
            6'b000000: begin
                alu_src_b = 1'b0;      // Use register for operand B
                reg_write = 1'b1;      // Write result to register
                write_reg = rd;        // Result goes to RD
                reg_src   = 1'b0;      // ALU result to register

                // Decode function field
                case (func)
                    6'b100000: alu_op = 4'b0000;  // ADD
                    6'b100010: alu_op = 4'b0010;  // SUB
                    6'b100100: alu_op = 4'b0100;  // AND
                    6'b100101: alu_op = 4'b0101;  // OR
                    6'b100110: alu_op = 4'b0110;  // XOR
                    6'b000100: alu_op = 4'b0111;  // SLL (shift left)
                    6'b000101: alu_op = 4'b1000;  // SRL (shift right)
                    6'b000111: alu_op = 4'b1001;  // SRA (arithmetic shift)
                    6'b011000: alu_op = 4'b1010;  // MUL
                    default: illegal_instruction = 1'b1;
                endcase
            end

            // I-type: ADDI (001000)
            6'b001000: begin
                alu_op      = 4'b0000;  // ADD
                alu_src_b   = 1'b1;     // Use immediate
                reg_write   = 1'b1;
                write_reg   = rt;       // Result to RT
                reg_src     = 1'b0;
            end

            // I-type: SUBI (001001)
            6'b001001: begin
                alu_op      = 4'b0010;  // SUB
                alu_src_b   = 1'b1;
                reg_write   = 1'b1;
                write_reg   = rt;
                reg_src     = 1'b0;
            end

            // I-type: ANDI (001100)
            6'b001100: begin
                alu_op      = 4'b0100;  // AND
                alu_src_b   = 1'b1;
                reg_write   = 1'b1;
                write_reg   = rt;
                reg_src     = 1'b0;
            end

            // I-type: ORI (001101)
            6'b001101: begin
                alu_op      = 4'b0101;  // OR
                alu_src_b   = 1'b1;
                reg_write   = 1'b1;
                write_reg   = rt;
                reg_src     = 1'b0;
            end

            // I-type: XORI (001110)
            6'b001110: begin
                alu_op      = 4'b0110;  // XOR
                alu_src_b   = 1'b1;
                reg_write   = 1'b1;
                write_reg   = rt;
                reg_src     = 1'b0;
            end

            // I-type: LW (Load Word) (100011)
            6'b100011: begin
                alu_op      = 4'b0000;  // ADD (for address calc)
                alu_src_b   = 1'b1;     // Use immediate offset
                mem_read    = 1'b1;
                mem_size    = 2'b10;    // Word (32-bit)
                reg_write   = 1'b1;
                write_reg   = rt;
                reg_src     = 1'b1;     // Memory to register
            end

            // I-type: SW (Store Word) (101011)
            6'b101011: begin
                alu_op      = 4'b0000;  // ADD (for address calc)
                alu_src_b   = 1'b1;     // Use immediate offset
                mem_write   = 1'b1;
                mem_size    = 2'b10;    // Word (32-bit)
                reg_write   = 1'b0;     // Don't write to register
            end

            // I-type: BEQ (Branch if Equal) (000100)
            6'b000100: begin
                alu_op      = 4'b0010;  // SUB (for comparison)
                alu_src_b   = 1'b0;     // Use register
                branch      = 1'b1;
                branch_cond = 1'b1;     // Conditional branch
                reg_write   = 1'b0;
            end

            // I-type: BNE (Branch if Not Equal) (000101)
            6'b000101: begin
                alu_op      = 4'b0010;  // SUB
                alu_src_b   = 1'b0;
                branch      = 1'b1;
                branch_cond = 1'b1;
                reg_write   = 1'b0;
            end

            // J-type: JAL (Jump and Link) (000011)
            6'b000011: begin
                branch      = 1'b1;
                branch_cond = 1'b0;     // Unconditional
                reg_write   = 1'b1;
                write_reg   = 5'b11111; // Link register (R31)
                reg_src     = 1'b0;
                alu_op      = 4'b0000;  // Return address = PC+4
            end

            // J-type: JR (Jump Register) (JR - special)
            6'b000010: begin
                branch      = 1'b1;
                branch_cond = 1'b0;
                reg_write   = 1'b0;
            end

            // NOP (No Operation) - all zeros
            32'h00000000: begin
                alu_op      = 4'b0000;
                reg_write   = 1'b0;
            end

            default: begin
                illegal_instruction = 1'b1;
            end

        endcase
    end

endmodule