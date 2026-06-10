module l1_dcache(
    input clk,
    input rst,

    // From MEM stage
    input [31:0]  mem_addr,       // Data address
    input [31:0]  mem_data_write, // Data to store (SW)
    input         mem_read,       // Read request
    input         mem_write,      // Write request
    input [1:0]   mem_size,       // Access size

    // To MEM stage
    output [31:0] mem_data_read,  // Data from cache
    output        mem_hit,        // Cache hit?
    output        mem_stall,      // Need to stall?

    // Main memory interface
    input [31:0]  main_mem_data,  // Data from main memory
    input         main_mem_ready, // Main memory ready?
    output [31:0] main_mem_addr,  // Address to main memory
    output [31:0] main_mem_data_out, // Data to main memory
    output        main_mem_read,  // Read request
    output        main_mem_write, // Write request

    // Debug
    output [31:0] dcache_hits,
    output [31:0] dcache_misses
);

    // ── State Machine ───────────────────────────────

    parameter IDLE       = 3'b000;
    parameter CHECK_CACHE = 3'b001;
    parameter WRITE_BACK = 3'b010;
    parameter FETCH_MEM  = 3'b011;
    parameter UPDATE     = 3'b100;

    reg [2:0] state;
    reg [31:0] saved_addr;
    reg [31:0] saved_data;
    reg        saved_write;
    reg [1:0]  saved_size;
    reg [31:0] fetched_data;

    // ── Cache Instance ──────────────────────────────

    wire        cache_hit_w;
    wire [31:0] cache_data;
    wire        hit_way;

    cache_array dcache_data(
        .clk(clk),
        .rst(rst),
        .address(mem_addr),
        .read_en(mem_read || mem_write),
        .hit(cache_hit_w),
        .read_data(cache_data),
        .hit_way(hit_way),
        .write_en(state == UPDATE),
        .write_data(main_mem_data),
        .write_way(~hit_way),
        .hits(dcache_hits),
        .misses(dcache_misses)
    );

    // ── Main State Machine ──────────────────────────

    always @(posedge clk) begin
        if (rst) begin
            state              <= IDLE;
            mem_data_read      <= 32'h00000000;
            mem_hit            <= 1'b0;
            mem_stall          <= 1'b0;
            main_mem_read      <= 1'b0;
            main_mem_write     <= 1'b0;
            main_mem_addr      <= 32'h00000000;
            main_mem_data_out  <= 32'h00000000;
            saved_addr         <= 32'h00000000;
            saved_data         <= 32'h00000000;
            saved_write        <= 1'b0;
            saved_size         <= 2'b00;
            fetched_data       <= 32'h00000000;
        end
        else begin
            case (state)

                // ── IDLE: Wait for access request ───────

                IDLE: begin
                    mem_stall       <= 1'b0;
                    main_mem_read   <= 1'b0;
                    main_mem_write  <= 1'b0;

                    if (mem_read || mem_write) begin
                        saved_addr  <= mem_addr;
                        saved_data  <= mem_data_write;
                        saved_write <= mem_write;
                        saved_size  <= mem_size;
                        state       <= CHECK_CACHE;
                    end
                end

                // ── CHECK_CACHE: Hit or miss? ──────────

                CHECK_CACHE: begin
                    if (cache_hit_w) begin
                        // ── HIT: Process immediately ──
                        mem_data_read <= cache_data;
                        mem_hit       <= 1'b1;
                        mem_stall     <= 1'b0;
                        
                        // If write: update cache immediately
                        if (saved_write) begin
                            // Write-through: write to main memory too
                            state <= WRITE_BACK;
                        end
                        else begin
                            state <= IDLE;
                        end
                    end
                    else begin
                        // ── MISS: Fetch from memory ──
                        mem_stall <= 1'b1;
                        state     <= FETCH_MEM;
                    end
                end

                // ── WRITE_BACK: Write to main memory ────

                WRITE_BACK: begin
                    main_mem_write    <= 1'b1;
                    main_mem_addr     <= saved_addr;
                    main_mem_data_out <= saved_data;
                    mem_stall         <= 1'b0;

                    if (main_mem_ready) begin
                        main_mem_write <= 1'b0;
                        state          <= IDLE;
                    end
                end

                // ── FETCH_MEM: Get from main memory ────

                FETCH_MEM: begin
                    main_mem_read <= 1'b1;
                    main_mem_addr <= saved_addr;
                    mem_stall     <= 1'b1;

                    if (main_mem_ready) begin
                        // Data arrived
                        fetched_data   <= main_mem_data;
                        main_mem_read  <= 1'b0;
                        state          <= UPDATE;
                    end
                end

                // ── UPDATE: Load into cache ────────────

                UPDATE: begin
                    mem_data_read <= fetched_data;
                    mem_hit       <= 1'b1;
                    mem_stall     <= 1'b0;

                    if (saved_write) begin
                        state <= WRITE_BACK;
                    end
                    else begin
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule