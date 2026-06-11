module or1200_with_cache(
    input clk,
    input rst,

    // Debug outputs
    output [31:0] pc_out,
    output [31:0] alu_result_out,
    output [31:0] reg_r1, reg_r2, reg_r3, reg_r4,
    output [31:0] reg_r5, reg_r6, reg_r7, reg_r8,

    // Cache statistics
    output [31:0] icache_hits,
    output [31:0] icache_misses,
    output [31:0] dcache_hits,
    output [31:0] dcache_misses
);

    // ── Internal Signals ────────────────────────────

    // Instruction fetch
    wire [31:0] if_addr;
    wire        if_read;
    wire [31:0] if_instruction;
    wire        if_stall_cache;

    // Data memory
    wire [31:0] mem_addr;
    wire [31:0] mem_data_write;
    wire        mem_read;
    wire        mem_write;
    wire [31:0] mem_data_read;
    wire        mem_stall_cache;

    // Combined stall
    wire pipeline_stall = if_stall_cache || mem_stall_cache;

    // ── Phase 2 Pipeline ────────────────────────────

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

    // ── Cache System (Phase 3) ──────────────────────

    cache_wrapper cache_sys(
        .clk(clk),
        .rst(rst),
        .if_addr(if_addr),
        .if_read(if_read),
        .if_instruction(if_instruction),
        .if_stall(if_stall_cache),
        .mem_addr(mem_addr),
        .mem_data_write(mem_data_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_data_read(mem_data_read),
        .mem_stall(mem_stall_cache),
        .icache_hits(icache_hits),
        .icache_misses(icache_misses),
        .dcache_hits(dcache_hits),
        .dcache_misses(dcache_misses)
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

endmodule