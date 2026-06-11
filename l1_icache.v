module l1_icache(
    input clk,
    input rst,

    // From IF stage
    input [31:0]  if_addr,        // Instruction address
    input         if_read,        // Fetch instruction?

    // To IF stage
    output [31:0] if_instruction, // Fetched instruction
    output        if_hit,         // Was it a hit?
    output        if_stall,       // Need to stall?

    // Main memory interface
    input [31:0]  mem_instr,      // Instruction from memory
    input         mem_ready,      // Memory ready?
    output [31:0] mem_addr,       // Address to memory
    output        mem_read,       // Read request

    // Debug
    output [31:0] icache_hits,
    output [31:0] icache_misses
);

    // ── State Machine ───────────────────────────────

    parameter IDLE       = 2'b00;
    parameter CHECK_CACHE = 2'b01;
    parameter FETCH_MEM  = 2'b10;
    parameter UPDATE     = 2'b11;

    reg [1:0] state;
    reg [31:0] saved_addr;
    reg [31:0] fetched_instr;

    // ── Cache Instance ──────────────────────────────

    wire        cache_hit_w;
    wire [31:0] cache_instr;
    wire        hit_way;

    // Simple cache for instructions (2-way, 8KB)
    cache_array icache_data(
        .clk(clk),
        .rst(rst),
        .address(if_addr),
        .read_en(if_read),
        .hit(cache_hit_w),
        .read_data(cache_instr),
        .hit_way(hit_way),
        .write_en(state == UPDATE),
        .write_data(mem_instr),
        .write_way(~hit_way),
        .hits(icache_hits),
        .misses(icache_misses)
    );

    // ── Main State Machine ──────────────────────────

    always @(posedge clk) begin
        if (rst) begin
            state            <= IDLE;
            if_instruction   <= 32'h00000000;
            if_hit           <= 1'b0;
            if_stall         <= 1'b0;
            mem_read         <= 1'b0;
            mem_addr         <= 32'h00000000;
            saved_addr       <= 32'h00000000;
            fetched_instr    <= 32'h00000000;
        end
        else begin
            case (state)

                // ── IDLE: Wait for fetch request ────────

                IDLE: begin
                    if_stall <= 1'b0;
                    mem_read <= 1'b0;

                    if (if_read) begin
                        saved_addr <= if_addr;
                        state      <= CHECK_CACHE;
                    end
                end

                // ── CHECK_CACHE: Hit or miss? ──────────

                CHECK_CACHE: begin
                    if (cache_hit_w) begin
                        // ── HIT: Return immediately ──
                        if_instruction <= cache_instr;
                        if_hit         <= 1'b1;
                        if_stall       <= 1'b0;
                        state          <= IDLE;
                    end
                    else begin
                        // ── MISS: Fetch from memory ──
                        if_stall <= 1'b1;
                        state    <= FETCH_MEM;
                    end
                end

                // ── FETCH_MEM: Get from memory ─────────

                FETCH_MEM: begin
                    mem_read <= 1'b1;
                    mem_addr <= saved_addr;
                    if_stall <= 1'b1;

                    if (mem_ready) begin
                        // Instruction arrived
                        fetched_instr <= mem_instr;
                        mem_read      <= 1'b0;
                        state         <= UPDATE;
                    end
                end

                // ── UPDATE: Load into cache ────────────

                UPDATE: begin
                    if_instruction <= fetched_instr;
                    if_hit         <= 1'b1;
                    if_stall       <= 1'b0;
                    state          <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule