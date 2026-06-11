module wb_stage(
    input clk,
    input rst,

    // From MEM/WB pipeline register
    input [31:0] mem_data,       // Data from memory
    input [31:0] alu_result,     // Result from ALU
    input [4:0]  dest_reg,       // Destination register
    input        reg_write,      // Write enable
    input        reg_src,        // 0=ALU, 1=Memory

    // Output to register file
    output [31:0] write_data,    // Data to write to register
    output [4:0]  write_addr,    // Which register to write
    output        write_en       // Write enable signal
);

    // Select between memory data and ALU result
    assign write_data = reg_src ? mem_data : alu_result;
    assign write_addr = dest_reg;
    assign write_en   = reg_write;

endmodule