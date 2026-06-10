module mem_stage(
    input clk,
    input rst,

    // From EX/MEM pipeline register
    input [31:0] alu_result,      // Address or data
    input [31:0] reg_data2,       // Data to store
    input [4:0]  dest_reg,        // Destination register
    input        mem_read,        // Read from memory?
    input        mem_write,       // Write to memory?
    input [1:0]  mem_size,        // Byte/Half/Word
    input        reg_write,       // Write to register?
    input        reg_src,         // 0=ALU, 1=Memory

    // Memory interface
    output [31:0] mem_addr,       // Address to memory
    output [31:0] mem_data_out,   // Data to memory
    output        mem_wr_en,      // Memory write enable
    output        mem_rd_en,      // Memory read enable
    input [31:0]  mem_data_in,    // Data from memory

    // To MEM/WB register
    output reg [31:0] mem_data_result,  // Data read from memory
    output reg [31:0] alu_result_out,   // ALU result passed through
    output reg [4:0]  dest_reg_out,     // Destination register
    output reg        reg_write_out,    // Write enable
    output reg        reg_src_out       // Source selection
);

    // Data memory — 256 words (1KB)
    reg [31:0] memory [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'h00000000;
        
        // Load test values
        memory[0] = 32'h12345678;
        memory[1] = 32'h87654321;
        memory[2] = 32'hDEADBEEF;
        memory[3] = 32'hCAFEBABE;
    end

    // Word address (divide by 4)
    wire [7:0] word_addr = alu_result[9:2];

    // Memory write
    always @(posedge clk) begin
        if (!rst && mem_write) begin
            case (mem_size)
                2'b00: begin  // Byte write
                    case (alu_result[1:0])
                        2'b00: memory[word_addr][7:0]   <= reg_data2[7:0];
                        2'b01: memory[word_addr][15:8]  <= reg_data2[7:0];
                        2'b10: memory[word_addr][23:16] <= reg_data2[7:0];
                        2'b11: memory[word_addr][31:24] <= reg_data2[7:0];
                    endcase
                end
                2'b01: begin  // Half-word write
                    case (alu_result[1])
                        1'b0: memory[word_addr][15:0]  <= reg_data2[15:0];
                        1'b1: memory[word_addr][31:16] <= reg_data2[15:0];
                    endcase
                end
                2'b10: begin  // Word write
                    memory[word_addr] <= reg_data2;
                end
                default: ;
            endcase
        end
    end

    // Memory read
    wire [31:0] mem_read_data;
    assign mem_read_data = memory[word_addr];

    // Output selection based on read/write size
    always @(*) begin
        case (mem_size)
            2'b00: begin  // Byte read
                case (alu_result[1:0])
                    2'b00: mem_data_result = {{24{mem_read_data[7]}}, mem_read_data[7:0]};
                    2'b01: mem_data_result = {{24{mem_read_data[15]}}, mem_read_data[15:8]};
                    2'b10: mem_data_result = {{24{mem_read_data[23]}}, mem_read_data[23:16]};
                    2'b11: mem_data_result = {{24{mem_read_data[31]}}, mem_read_data[31:24]};
                endcase
            end
            2'b01: begin  // Half-word read
                case (alu_result[1])
                    1'b0: mem_data_result = {{16{mem_read_data[15]}}, mem_read_data[15:0]};
                    1'b1: mem_data_result = {{16{mem_read_data[31]}}, mem_read_data[31:16]};
                endcase
            end
            2'b10: begin  // Word read
                mem_data_result = mem_read_data;
            end
            default: mem_data_result = 32'h00000000;
        endcase
    end

    // Pass through ALU result and control signals
    always @(posedge clk) begin
        if (rst) begin
            alu_result_out <= 32'h00000000;
            dest_reg_out   <= 5'b00000;
            reg_write_out  <= 1'b0;
            reg_src_out    <= 1'b0;
        end
        else begin
            alu_result_out <= alu_result;
            dest_reg_out   <= dest_reg;
            reg_write_out  <= reg_write;
            reg_src_out    <= reg_src;
        end
    end

    // Memory interface signals
    assign mem_addr = alu_result;
    assign mem_data_out = reg_data2;
    assign mem_wr_en = mem_write;
    assign mem_rd_en = mem_read;

endmodule