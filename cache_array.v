module cache_array(
    input clk,
    input rst,

    // Address from processor
    input [31:0] address,
    
    // Read port
    input        read_en,
    output       hit,            // Cache hit?
    output [31:0] read_data,     // Data from cache
    output       hit_way,        // Which way hit? (0 or 1)

    // Write port (from memory on cache miss)
    input        write_en,
    input [31:0] write_data,
    input        write_way,      // Which way to write to

    // Cache statistics
    output [31:0] hits,
    output [31:0] misses
);

    // Cache configuration
    parameter CACHE_SIZE = 8192;    // 8KB
    parameter LINE_SIZE  = 4;       // 4 bytes per line
    parameter WAYS       = 2;       // 2-way associative
    parameter LINES_PER_WAY = CACHE_SIZE / LINE_SIZE / WAYS;  // 1024 lines per way

    // Address breakdown
    wire [19:0] tag    = address[31:12];  // Upper 20 bits
    wire [9:0]  index  = address[11:2];   // Middle 10 bits (selects line)
    wire [1:0]  offset = address[1:0];    // Lower 2 bits (byte within word)

    // Two cache ways (2-way associative)
    wire        hit0, hit1;
    wire [31:0] data0, data1;
    wire        valid0, valid1;

    // Instantiate Way 0
    cache_line way0_lines(
        .clk(clk),
        .rst(rst),
        .write_en(write_en && (write_way == 1'b0)),
        .write_tag(tag),
        .write_data(write_data),
        .read_tag(tag),
        .hit(hit0),
        .read_data(data0),
        .valid(valid0)
    );

    // Instantiate Way 1
    cache_line way1_lines(
        .clk(clk),
        .rst(rst),
        .write_en(write_en && (write_way == 1'b1)),
        .write_tag(tag),
        .write_data(write_data),
        .read_tag(tag),
        .hit(hit1),
        .read_data(data1),
        .valid(valid1)
    );

    // Combine results from both ways
    assign hit = hit0 | hit1;           // Hit if either way hits
    assign hit_way = hit1 ? 1'b1 : 1'b0;  // Return which way hit
    assign read_data = hit1 ? data1 : data0;  // Return data from hitting way

    // Statistics counters
    reg [31:0] hit_count;
    reg [31:0] miss_count;

    always @(posedge clk) begin
        if (rst) begin
            hit_count  <= 32'h00000000;
            miss_count <= 32'h00000000;
        end
        else if (read_en) begin
            if (hit)
                hit_count <= hit_count + 1;
            else
                miss_count <= miss_count + 1;
        end
    end

    assign hits = hit_count;
    assign misses = miss_count;

endmodule