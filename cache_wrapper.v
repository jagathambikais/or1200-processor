module cache_wrapper(
    input clk,
    input rst,

    // From pipeline IF stage (instruction fetch)
    input [31:0]  if_addr,
    input         if_read,
    output [31:0] if_instruction,
    output        if_stall,

    // From pipeline MEM stage (data memory)
    input [31:0]  mem_addr,
    input [31:0]  mem_write_data,
    input         mem_read,
    input         mem_write,
    output [31:0] mem_read_data,
    output        mem_stall
);

    // ── L1 Instruction Cache ────────────────────

    wire [31:0] icache_data_out;
    wire icache_hit;
    wire icache_stall;
    wire [31:0] imem_addr;
    wire imem_read_req;
    wire [31:0] imem_data;

    simple_cache i_cache(
        .clk(clk),
        .rst(rst),
        .proc_addr(if_addr),
        .proc_data_in(32'h00000000),
        .proc_read(if_read),
        .proc_write(1'b0),
        .cache_data_out(icache_data_out),
        .cache_hit(icache_hit),
        .cache_stall(icache_stall),
        .mem_data(imem_data),
        .mem_valid(1'b1),
        .mem_addr(imem_addr),
        .mem_write_data(),
        .mem_read_req(imem_read_req),
        .mem_write_req()
    );

    // ── L1 Data Cache ───────────────────────────

    wire [31:0] dcache_data_out;
    wire dcache_hit;
    wire dcache_stall;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_write_data;
    wire dmem_read_req;
    wire dmem_write_req;
    wire [31:0] dmem_data;

    simple_cache d_cache(
        .clk(clk),
        .rst(rst),
        .proc_addr(mem_addr),
        .proc_data_in(mem_write_data),
        .proc_read(mem_read),
        .proc_write(mem_write),
        .cache_data_out(dcache_data_out),
        .cache_hit(dcache_hit),
        .cache_stall(dcache_stall),
        .mem_data(dmem_data),
        .mem_valid(1'b1),
        .mem_addr(dmem_addr),
        .mem_write_data(dmem_write_data),
        .mem_read_req(dmem_read_req),
        .mem_write_req(dmem_write_req)
    );

    // ── Main Memory: Instruction Side ───────────

    memory_simple imem(
        .clk(clk),
        .rst(rst),
        .read_addr(imem_addr),
        .read_req(imem_read_req),
        .read_data(imem_data),
        .read_valid(),
        .write_addr(32'h00000000),
        .write_data(32'h00000000),
        .write_req(1'b0),
        .write_valid()
    );

    // ── Main Memory: Data Side ──────────────────

    memory_simple dmem(
        .clk(clk),
        .rst(rst),
        .read_addr(dmem_addr),
        .read_req(dmem_read_req),
        .read_data(dmem_data),
        .read_valid(),
        .write_addr(dmem_addr),
        .write_data(dmem_write_data),
        .write_req(dmem_write_req),
        .write_valid()
    );

    // ── Output to Pipeline ──────────────────────

    assign if_instruction = icache_data_out;
    assign if_stall = icache_stall;

    assign mem_read_data = dcache_data_out;
    assign mem_stall = dcache_stall;

endmodule