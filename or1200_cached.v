module or1200_cached(
    input clk,
    input rst,

    // Debug outputs
    output [31:0] pc_out,
    output [31:0] alu_result_out,
    output [31:0] reg_r1, reg_r2, reg_r3, reg_r4,
    output [31:0] reg_r5, reg_r6, reg_r7, reg_r8,

    // Cache statistics
    output [31:0] total_cache_hits,
    output [31:0] total_cache_misses
);

    // ── Internal Signals ────────────────────────────

    // Instruction fetch
    wire [31:0] if_addr;
    wire        if_read;
    wire [31:0] if_instruction;
    wire        if_hit;
    wire        if_stall_cache;

    // Data memory
    wire [31:0] mem_addr;
    wire [31:0] mem_data_write;
    wire        mem_read;
    wire        mem_write;
    wire [1:0]  mem_size;
    wire [31:0] mem_data_read;
    wire        mem_hit;
    wire        mem_stall_cache;

    // Combined stall signal
    wire        pipeline_stall = if_stall_cache || mem_stall_cache;

    // ── Pipeline (Phase 2) ──────────────────────────

    or1200_pipeline pipeline(
        .clk(clk),
        .rst(rst),
        .instruction(if_instruction),
        .mem_data_in(mem_data_read),
        .mem_addr(mem_addr),
        .mem_data_out(mem_data_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .pc_out(pc_out),
        .alu_result_out(alu_result_out),
        .reg_r1(reg_r1),
        .reg_r2(reg_r2),
        .reg_r3(reg_r3),
        .reg_r4(reg_r4),
        .reg_r5(reg_r5),
        .reg_r6(reg_r6),
        .reg_r7(reg_r7),
        .reg_r8(reg_r8)
    );

    // ── Memory Hierarchy (Phase 3) ──────────────────

    memory_hierarchy mem_hier(
        .clk(clk),
        .rst(rst),
        .if_addr(if_addr),
        .if_read(if_read),
        .if_instruction(if_instruction),
        .if_hit(if_hit),
        .if_stall(if_stall_cache),
        .mem_addr(mem_addr),
        .mem_data_write(mem_data_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_size(mem_size),
        .mem_data_read(mem_data_read),
        .mem_hit(mem_hit),
        .mem_stall(mem_stall_cache),
        .total_hits(total_cache_hits),
        .total_misses(total_cache_misses)
    );

    // ── Instruction Fetch Control ───────────────────

    reg [31:0] pc;
    assign if_addr = pc;
    assign if_read = !if_stall_cache;

    always @(posedge clk) begin
        if (rst)
            pc <= 32'h00000000;
        else if (!pipeline_stall && !if_stall_cache)
            pc <= pc + 4;
    end

    // ── Data Size Control ───────────────────────────

    assign mem_size = 2'b10;  // Always word access (32-bit)

endmodule