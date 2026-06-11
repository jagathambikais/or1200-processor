module simple_cache(
    input clk,
    input rst,

    // Processor interface
    input [31:0]  proc_addr,
    input [31:0]  proc_data_in,
    input         proc_read,
    input         proc_write,

    output [31:0] cache_data_out,
    output        cache_hit,
    output        cache_stall,

    // Memory interface
    input [31:0]  mem_data,
    input         mem_valid,
    output [31:0] mem_addr,
    output [31:0] mem_write_data,
    output        mem_read_req,
    output        mem_write_req
);

    // Cache configuration
    parameter CACHE_ENTRIES = 256;      // 1KB cache (256 × 32-bit entries)
    parameter ADDR_BITS = 8;            // 8-bit index for 256 entries
    parameter TAG_BITS = 24;            // 32 - 8 = 24-bit tag

    // Cache storage
    reg [31:0] cache_data [0:CACHE_ENTRIES-1];
    reg [TAG_BITS-1:0] cache_tags [0:CACHE_ENTRIES-1];
    reg cache_valid [0:CACHE_ENTRIES-1];

    // Address breakdown
    wire [TAG_BITS-1:0] addr_tag = proc_addr[31:ADDR_BITS];
    wire [ADDR_BITS-1:0] addr_index = proc_addr[ADDR_BITS-1:0];

    // Cache lookup (combinational)
    wire tag_match = (cache_tags[addr_index] == addr_tag);
    wire cache_hit_w = cache_valid[addr_index] && tag_match;

    // State machine
    parameter IDLE = 2'b00;
    parameter FETCH = 2'b01;
    parameter WAIT_MEM = 2'b10;

    reg [1:0] state;
    reg [31:0] saved_addr;
    reg [31:0] saved_data;
    reg saved_write;
    reg [7:0] mem_latency;

    // Memory latency counter
    parameter MEM_LATENCY = 50;

    // Initialize cache
    integer i;
    initial begin
        for (i = 0; i < CACHE_ENTRIES; i = i + 1) begin
            cache_valid[i] = 1'b0;
            cache_tags[i] = 24'h000000;
            cache_data[i] = 32'h00000000;
        end
    end

    // Cache statistics
    reg [31:0] hit_count;
    reg [31:0] miss_count;

    always @(posedge clk) begin
        if (rst) begin
            hit_count <= 32'h00000000;
            miss_count <= 32'h00000000;
        end
        else if (proc_read || proc_write) begin
            if (cache_hit_w)
                hit_count <= hit_count + 1;
            else
                miss_count <= miss_count + 1;
        end
    end

    // Main state machine
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            cache_stall <= 1'b0;
            cache_hit <= 1'b0;
            cache_data_out <= 32'h00000000;
            mem_read_req <= 1'b0;
            mem_write_req <= 1'b0;
            mem_addr <= 32'h00000000;
            mem_write_data <= 32'h00000000;
            mem_latency <= 8'h00;
        end
        else begin
            case (state)

                IDLE: begin
                    cache_stall <= 1'b0;
                    mem_read_req <= 1'b0;
                    mem_write_req <= 1'b0;

                    if (proc_read || proc_write) begin
                        saved_addr <= proc_addr;
                        saved_data <= proc_data_in;
                        saved_write <= proc_write;

                        if (cache_hit_w) begin
                            // Cache hit
                            cache_data_out <= cache_data[addr_index];
                            cache_hit <= 1'b1;
                            cache_stall <= 1'b0;

                            // If write: update cache
                            if (proc_write) begin
                                cache_data[addr_index] <= proc_data_in;
                            end
                        end
                        else begin
                            // Cache miss
                            cache_stall <= 1'b1;
                            cache_hit <= 1'b0;
                            state <= FETCH;
                        end
                    end
                end

                FETCH: begin
                    // Request from memory
                    if (saved_write) begin
                        mem_write_req <= 1'b1;
                        mem_addr <= saved_addr;
                        mem_write_data <= saved_data;
                    end
                    else begin
                        mem_read_req <= 1'b1;
                        mem_addr <= saved_addr;
                    end

                    cache_stall <= 1'b1;
                    mem_latency <= 8'h00;
                    state <= WAIT_MEM;
                end

                WAIT_MEM: begin
                    // Wait for memory response
                    if (mem_latency < MEM_LATENCY) begin
                        mem_latency <= mem_latency + 1;
                    end
                    else begin
                        // Memory data ready
                        mem_read_req <= 1'b0;
                        mem_write_req <= 1'b0;

                        // Update cache
                        cache_valid[addr_index] <= 1'b1;
                        cache_tags[addr_index] <= saved_addr[31:ADDR_BITS];
                        cache_data[addr_index] <= mem_data;
                        cache_data_out <= mem_data;

                        cache_hit <= 1'b1;
                        cache_stall <= 1'b0;
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

    // Output cache statistics (for debugging)
    // wire [31:0] hits = hit_count;
    // wire [31:0] misses = miss_count;

endmodule