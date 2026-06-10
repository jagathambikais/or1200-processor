module or1200_core_basic(
    input clk,
    input rst,
    input [31:0] instruction,   // Instruction to execute
    
    // Memory interface
    input [31:0]  mem_data_in,  // Data from memory
    output [31:0] mem_addr,     // Address to memory
    output [31:0] mem_data_out, // Data to memory
    output        mem_read,     // Read signal
    output        mem_write,    // Write signal
    
    // Debug outputs for testbench
    output [31:0] pc_out,       // Current PC
    output [31:0] alu_result,   // ALU result
    output [31:0] reg_r1,       // Register 1
    output [31:0] reg_r2,       // Register 2
    output [31:0] reg_r3,       // Register 3
    output [31:0] reg_r4,       // Register 4
    output [31:0] reg_r5,       // Register 5,
    output [31:0] reg_r6,
    output [31:0] reg_r7,
    output [31:0] reg_r8
);

    // ── Program Counter ──────────────────────────────
    reg [31:0] pc;
    assign pc_out = pc;

    always @(posedge clk) begin
        if (rst)
            pc <= 32'h00000000;
        else
            pc <= pc + 4;  // Next instruction (32-bit aligned)
    end

    // ── Control Unit ─────────────────────────────────
    wire [3:0]  alu_op;
    wire        alu_src_b;
    wire        reg_write;
    wire [4:0]  write_reg;
    wire        reg_src;
    wire        mem_read_ctrl;
    wire        mem_write_ctrl;
    wire [1:0]  mem_size;
    wire        branch;
    wire        branch_cond;
    wire [4:0]  rs, rt, rd;
    wire [15:0] immediate;
    wire [25:0] jump_target;
    wire        illegal_instr;

    control_unit ctrl(
        .instruction(instruction),
        .clk(clk),
        .rst(rst),
        .alu_op(alu_op),
        .alu_src_b(alu_src_b),
        .reg_write(reg_write),
        .write_reg(write_reg),
        .reg_src(reg_src),
        .mem_read(mem_read_ctrl),
        .mem_write(mem_write_ctrl),
        .mem_size(mem_size),
        .branch(branch),
        .branch_cond(branch_cond),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .immediate(immediate),
        .jump_target(jump_target),
        .illegal_instruction(illegal_instr)
    );

    // ── Register File ───────────────────────────────
    wire [31:0] read_data1, read_data2;
    wire [31:0] write_data;

    register_file regfile(
        .clk(clk),
        .rst(rst),
        .read_addr1(rs),
        .read_addr2(rt),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .write_addr(write_reg),
        .write_data(write_data),
        .write_enable(reg_write),
        .r1_out(reg_r1),
        .r2_out(reg_r2),
        .r3_out(reg_r3),
        .r4_out(reg_r4),
        .r5_out(reg_r5),
        .r6_out(reg_r6),
        .r7_out(reg_r7),
        .r8_out(reg_r8)
    );

    // ── Sign Extended Immediate ─────────────────────
    wire [31:0] imm_extended = {{16{immediate[15]}}, immediate};

    // ── ALU Operand B Mux ───────────────────────────
    wire [31:0] alu_operand_b = alu_src_b ? imm_extended : read_data2;

    // ── ALU ──────────────────────────────────────────
    wire        carry_out, zero_flag, sign_flag, overflow_flag;

    alu alu_unit(
        .operand_a(read_data1),
        .operand_b(alu_operand_b),
        .alu_op(alu_op),
        .carry_in(1'b0),
        .result(alu_result),
        .carry_out(carry_out),
        .zero_flag(zero_flag),
        .sign_flag(sign_flag),
        .overflow(overflow_flag)
    );

    // ── Shifter ──────────────────────────────────────
    wire [31:0] shift_result;
    wire [2:0]  shift_op = alu_op[2:0];

    shifter shifter_unit(
        .data_in(read_data1),
        .shift_amount(alu_operand_b[4:0]),
        .shift_op(shift_op),
        .result(shift_result)
    );

    // ── Multiplier ───────────────────────────────────
    wire [63:0] mul_result;

    multiplier mul_unit(
        .clk(clk),
        .rst(rst),
        .multiplicand(read_data1),
        .multiplier(alu_operand_b),
        .multiply_en(alu_op == 4'b1010),  // MUL operation
        .product(mul_result),
        .ready()
    );

    // ── Memory Address Calculation ──────────────────
    assign mem_addr = alu_result;  // Address from ALU
    assign mem_data_out = read_data2;  // Data to write
    assign mem_read = mem_read_ctrl;
    assign mem_write = mem_write_ctrl;

    // ── Write Back Data Selection ───────────────────
    // reg_src: 0=ALU result, 1=Memory data
    assign write_data = reg_src ? mem_data_in : alu_result;

    // ── Status Flags ─────────────────────────────────
    wire [3:0] flags = {carry_out, zero_flag, sign_flag, overflow_flag};

endmodule