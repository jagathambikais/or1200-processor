module register_file(
    input clk,
    input rst,

    // Read ports (asynchronous)
    input [4:0]  read_addr1,   // R1 address (0-31)
    input [4:0]  read_addr2,   // R2 address (0-31)
    output [31:0] read_data1,  // R1 value
    output [31:0] read_data2,  // R2 value

    // Write port (synchronous)
    input [4:0]  write_addr,   // Register to write
    input [31:0] write_data,   // Data to write
    input        write_enable, // Write enable signal
    
    // Debug output
    output [31:0] r1_out,      // For testbench viewing
    output [31:0] r2_out,
    output [31:0] r3_out,
    output [31:0] r4_out,
    output [31:0] r5_out,
    output [31:0] r6_out,
    output [31:0] r7_out,
    output [31:0] r8_out
);

    // 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];

    integer i;
    initial begin
        // Initialize all registers to 0
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 32'h00000000;
        
        // Load test values (optional)
        registers[1] = 32'd10;   // R1 = 10
        registers[2] = 32'd20;   // R2 = 20
        registers[3] = 32'd30;   // R3 = 30
        registers[4] = 32'd40;   // R4 = 40
        registers[5] = 32'd50;   // R5 = 50
    end

    // Asynchronous read
    assign read_data1 = registers[read_addr1];
    assign read_data2 = registers[read_addr2];

    // Synchronous write
    always @(posedge clk) begin
        if (rst) begin
            // Reset all registers
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'h00000000;
        end
        else if (write_enable) begin
            // Write to register (R0 is always 0)
            if (write_addr != 5'b00000)
                registers[write_addr] <= write_data;
        end
    end

    // Debug outputs for testbench
    assign r1_out = registers[1];
    assign r2_out = registers[2];
    assign r3_out = registers[3];
    assign r4_out = registers[4];
    assign r5_out = registers[5];
    assign r6_out = registers[6];
    assign r7_out = registers[7];
    assign r8_out = registers[8];

endmodule