module memory_hierarchy(
    input clk,
    input rst,

    input [31:0]  if_addr,
    input         if_read,
    output [31:0] if_instruction,
    output        if_hit,
    output        if_stall,

    input [31:0]  mem_addr,
    input [31:0]  mem_data_write,
    input         mem_read,
    input         mem_write,
    input [1:0]   mem_size,
    output [31:0] mem_data_read,
    output        mem_hit,
    output        mem_stall,

    output [31:0] total_hits,
    output [31:0] total_misses
);

    reg [31:0] main_memory [0:8388607];

    initial begin
        main_memory[0]   = 32'b001000_00000_00001_0000000001100100;
        main_memory[1]   = 32'b001000_00000_00010_0000000000110010;
        main_memory[2]   = 32'b001000_00000_00011_0000000001001011;
        main_memory[3]   = 32'b000000_00001_00010_00100_00000_100000;
        main_memory[4]   = 32'b000000_00010_00011_00101_00000_100000;
        main_memory[5]   = 32'b000000_00100_00101_00110_00000_100000;
        main_memory[6]   = 32'b000000_00110_00001_00111_00000_100010;
        main_memory[7]   = 32'b000000_00001_00101_01000_00000_100100;

        main_memory[256] = 32'h12345678;
        main_memory[257] = 32'h87654321;
        main_memory[258] = 32'hDEADBEEF;
        main_memory[259] = 32'hCAFEBABE;
    end

    reg [31:0]  mem_read_addr;
    reg [31:0]  mem_write_addr;
    reg [31:0]  mem_write_data;
    wire [31:0] mem_read_data_i;
    wire [31:0] mem_read_data_d;
    reg         mem_read_pending_i;
    reg         mem_read_pending_d;

    parameter MEM_LATENCY = 50;
    reg [7:0]   mem_latency_counter_i;
    reg [7:0]   mem_latency_counter_d;

    always @(posedge clk) begin
        if (rst) begin
            mem_latency_counter_i <= 8'h00;
            mem_read_pending_i    <= 1'b0;
        end
        else if (mem_read_pending_i) begin
            if (mem_latency_counter_i < MEM_LATENCY) begin
                mem_latency_counter_i <= mem_latency_counter_i + 1;
            end
            else begin
                mem_read_pending_i <= 1'b0;
            end
        end
    end

    assign mem_read_data_i = main_memory[mem_read_addr[22:2]];

    always @(posedge clk) begin
        if (rst) begin
            mem_latency_counter_d <= 8'h00;
            mem_read_pending_d    <= 1'b0;
        end
        else if (mem_read_pending_d) begin
            if (mem_latency_counter_d < MEM_LATENCY) begin
                mem_latency_counter_d <= mem_latency_counter_d + 1;
            end
            else begin
                mem_read_pending_d <= 1'b0;
            end
        end
    end

    assign mem_read_data_d = main_memory[mem_write_addr[22:2]];

    reg mem_write_pending_d;

    always @(posedge clk) begin
        if (!rst && mem_write_pending_d) begin
            main_memory[mem_write_addr[22:2]] <= mem_write_data;
            mem_write_pending_d <= 1'b0;
        end
    end

    wire icache_mem_read;
    wire [31:0] icache_hits, icache_misses;

    l1_icache icache(
        .clk(clk),
        .rst(rst),
        .if_addr(if_addr),
        .if_read(if_read),
        .if_instruction(if_instruction),
        .if_hit(if_hit),
        .if_stall(if_stall),
        .mem_instr(mem_read_data_i),
        .mem_ready(!mem_read_pending_i),
        .mem_addr(mem_read_addr),
        .mem_read(icache_mem_read),
        .icache_hits(icache_hits),
        .icache_misses(icache_misses)
    );

    always @(posedge clk) begin
        if (icache_mem_read) begin
            mem_latency_counter_i <= 8'h00;
            mem_read_pending_i    <= 1'b1;
        end
    end

    wire dcache_mem_read, dcache_mem_write;
    wire [31:0] dcache_hits, dcache_misses;

    l1_dcache dcache(
        .clk(clk),
        .rst(rst),
        .mem_addr(mem_addr),
        .mem_data_write(mem_data_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_size(mem_size),
        .mem_data_read(mem_data_read),
        .mem_hit(mem_hit),
        .mem_stall(mem_stall),
        .main_mem_data(mem_read_data_d),
        .main_mem_ready(!mem_read_pending_d),
        .main_mem_addr(mem_write_addr),
        .main_mem_data_out(mem_write_data),
        .main_mem_read(dcache_mem_read),
        .main_mem_write(dcache_mem_write),
        .dcache_hits(dcache_hits),
        .dcache_misses(dcache_misses)
    );

    always @(posedge clk) begin
        if (dcache_mem_read) begin
            mem_latency_counter_d <= 8'h00;
            mem_read_pending_d    <= 1'b1;
        end
        if (dcache_mem_write) begin
            mem_write_pending_d   <= 1'b1;
        end
    end

    assign total_hits = icache_hits + dcache_hits;
    assign total_misses = icache_misses + dcache_misses;

endmodule