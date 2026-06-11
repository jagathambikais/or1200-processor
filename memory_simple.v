module memory_simple(
    input clk,
    input rst,

    // Read interface
    input [31:0]  read_addr,
    input         read_req,
    output [31:0] read_data,
    output        read_valid,

    // Write interface
    input [31:0]  write_addr,
    input [31:0]  write_data,
    input         write_req,
    output        write_valid
);

    // Main memory: 32MB = 8M words
    reg [31:0] memory [0:8388607];

    // Latency counters
    reg [7:0] read_latency_counter;
    reg [7:0] write_latency_counter;
    reg read_pending;
    reg write_pending;
    reg [31:0] read_data_reg;

    parameter MEM_LATENCY = 50;

    // Initialize memory with test program
    initial begin
        // Load test instructions
        memory[0]   = 32'b001000_00000_00001_0000000001100100; // ADDI R1, R0, 100
        memory[1]   = 32'b001000_00000_00010_0000000000110010; // ADDI R2, R0, 50
        memory[2]   = 32'b001000_00000_00011_0000000001001011; // ADDI R3, R0, 75
        memory[3]   = 32'b000000_00001_00010_00100_00000_100000; // ADD R4, R1, R2
        memory[4]   = 32'b000000_00010_00011_00101_00000_100000; // ADD R5, R2, R3
        memory[5]   = 32'b000000_00100_00101_00110_00000_100000; // ADD R6, R4, R5
        memory[6]   = 32'b000000_00110_00001_00111_00000_100010; // SUB R7, R6, R1
        memory[7]   = 32'b000000_00001_00101_01000_00000_100100; // AND R8, R1, R5

        // Load test data
        memory[256] = 32'h12345678;
        memory[257] = 32'h87654321;
        memory[258] = 32'hDEADBEEF;
        memory[259] = 32'hCAFEBABE;
    end

    // Read operation
    always @(posedge clk) begin
        if (rst) begin
            read_latency_counter <= 8'h00;
            read_pending <= 1'b0;
            read_data_reg <= 32'h00000000;
        end
        else if (read_req && !read_pending) begin
            // Start read
            read_latency_counter <= 8'h00;
            read_pending <= 1'b1;
            read_data_reg <= memory[read_addr[22:2]];
        end
        else if (read_pending) begin
            if (read_latency_counter < MEM_LATENCY) begin
                read_latency_counter <= read_latency_counter + 1;
            end
            else begin
                read_pending <= 1'b0;
            end
        end
    end

    assign read_data = read_data_reg;
    assign read_valid = !read_pending;

    // Write operation
    always @(posedge clk) begin
        if (rst) begin
            write_latency_counter <= 8'h00;
            write_pending <= 1'b0;
        end
        else if (write_req && !write_pending) begin
            // Start write
            write_latency_counter <= 8'h00;
            write_pending <= 1'b1;
            memory[write_addr[22:2]] <= write_data;
        end
        else if (write_pending) begin
            if (write_latency_counter < MEM_LATENCY) begin
                write_latency_counter <= write_latency_counter + 1;
            end
            else begin
                write_pending <= 1'b0;
            end
        end
    end

    assign write_valid = !write_pending;

endmodule