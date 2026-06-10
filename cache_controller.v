module cache_controller(
    input clk,
    input rst,

    // From processor (pipeline MEM stage)
    input [31:0]  proc_addr,      // Address to access
    input [31:0]  proc_data,      // Data to write (for SW)
    input         proc_read,      // Read request
    input         proc_write,     // Write request
    input [1:0]   proc_size,      // Access size (byte/half/word)

    // To processor
    output reg [31:0] cache_data, // Data to processor
    output reg        cache_hit,  // Was it a hit?
    output reg        stall,      // Stall pipeline?

    // Main memory interface
    input [31:0]  mem_data,       // Data from memory
    input         mem_ready,      // Memory has data ready?
    output reg [31:0] mem_addr,   // Address to memory
    output reg [31:0] mem_data_out, // Data to memory
    output reg        mem_read,   // Read from memory
    output reg        mem_write,  // Write to memory

    // Debug outputs
    output [31:0] cache_hits,
    output [31:0] cache_misses
);

    // ── State Machine ───────────────────────────────

    parameter IDLE       = 3'b000;
    parameter CACHE_CHECK = 3'b001;
    parameter MEM_READ   = 3'b010;
    parameter MEM_WRITE  = 3'b011;
    parameter UPDATE_CACHE = 3'b100;

    reg [2:0] state;
    reg [31:0] saved_addr;
    reg [31:0] saved_data;
    reg        saved_write;

    // ── Cache Array Instance ────────────────────────

    wire        cache_hit_w;
    wire [31:0] cache_data_w;
    wire        hit_way;

    cache_array cache(
        .clk(clk),
        .rst(rst),
        .address(proc_addr),
        .read_en(proc_read || proc_write),
        .hit(cache_hit_w),
        .read_data(cache_data_w),
        .hit_way(hit_way),
        .write_en(state == UPDATE_CACHE),
        .write_data(mem_data),
        .write_way(~hit_way),  // Write to non-hitting way
        .hits(cache_hits),
        .misses(cache_misses)
    );

    // ── Main State Machine ──────────────────────────

    always @(posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            cache_data    <= 32'h00000000;
            cache_hit     <= 1'b0;
            stall         <= 1'b0;
            mem_read      <= 1'b0;
            mem_write     <= 1'b0;
            mem_addr      <= 32'h00000000;
            mem_data_out  <= 32'h00000000;
            saved_addr    <= 32'h00000000;
            saved_data    <= 32'h00000000;
            saved_write   <= 1'b0;
        end
        else begin
            case (state)

                // ── IDLE: Wait for processor request ──────

                IDLE: begin
                    stall    <= 1'b0;
                    mem_read <= 1'b0;
                    mem_write <= 1'b0;

                    if (proc_read || proc_write) begin
                        saved_addr <= proc_addr;
                        saved_data <= proc_data;
                        saved_write <= proc_write;
                        state <= CACHE_CHECK;
                    end
                end

                // ── CACHE_CHECK: Check if hit or miss ──

                CACHE_CHECK: begin
                    if (cache_hit_w) begin
                        // ── HIT: Return data immediately ──
                        cache_data <= cache_data_w;
                        cache_hit  <= 1'b1;
                        stall      <= 1'b0;
                        state      <= IDLE;
                    end
                    else begin
                        // ── MISS: Go to memory ──
                        stall <= 1'b1;  // Stall pipeline
                        if (saved_write)
                            state <= MEM_WRITE;
                        else
                            state <= MEM_READ;
                    end
                end

                // ── MEM_READ: Request from memory ──────

                MEM_READ: begin
                    mem_read <= 1'b1;
                    mem_addr <= saved_addr;
                    stall    <= 1'b1;

                    if (mem_ready) begin
                        // Data arrived from memory
                        mem_read <= 1'b0;
                        state    <= UPDATE_CACHE;
                    end
                end

                // ── MEM_WRITE: Write to memory ─────────

                MEM_WRITE: begin
                    mem_write    <= 1'b1;
                    mem_addr     <= saved_addr;
                    mem_data_out <= saved_data;
                    stall        <= 1'b1;

                    if (mem_ready) begin
                        // Write complete
                        mem_write <= 1'b0;
                        state     <= IDLE;
                    end
                end

                // ── UPDATE_CACHE: Load data into cache ──

                UPDATE_CACHE: begin
                    stall      <= 1'b1;
                    cache_data <= mem_data;
                    cache_hit  <= 1'b1;
                    state      <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

    // ── Hit/Miss Summary ────────────────────────────

    always @(*) begin
        if (state == CACHE_CHECK) begin
            cache_hit = cache_hit_w;
        end
    end

endmodule