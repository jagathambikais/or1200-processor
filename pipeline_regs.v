module pipeline_regs(
    input clk,
    input rst,
    input stall,  // Insert bubble if stall=1

    // ── IF/ID Pipeline Register ──────────────────

    // Write side (from IF stage)
    input [31:0] if_pc,
    input [31:0] if_instruction,

    // Read side (to ID stage)
    output reg [31:0] id_pc,
    output reg [31:0] id_instruction,

    // ── ID/EX Pipeline Register ──────────────────

    // Write side (from ID stage)
    input [31:0] id_reg_data1,
    input [31:0] id_reg_data2,
    input [31:0] id_sign_ext,
    input [4:0]  id_rs,
    input [4:0]  id_rt,
    input [4:0]  id_rd,
    input [3:0]  id_alu_op,
    input        id_alu_src_b,
    input        id_mem_read,
    input        id_mem_write,
    input [1:0]  id_mem_size,
    input        id_reg_write,
    input        id_reg_src,

    // Read side (to EX stage)
    output reg [31:0] ex_reg_data1,
    output reg [31:0] ex_reg_data2,
    output reg [31:0] ex_sign_ext,
    output reg [4:0]  ex_rs,
    output reg [4:0]  ex_rt,
    output reg [4:0]  ex_rd,
    output reg [3:0]  ex_alu_op,
    output reg        ex_alu_src_b,
    output reg        ex_mem_read,
    output reg        ex_mem_write,
    output reg [1:0]  ex_mem_size,
    output reg        ex_reg_write,
    output reg        ex_reg_src,
    output reg [31:0] ex_pc,

    // ── EX/MEM Pipeline Register ────────────────

    // Write side (from EX stage)
    input [31:0] ex_alu_result,
    input [31:0] ex_reg_data2_out,
    input [4:0]  ex_dest_reg,
    input        ex_mem_read_out,
    input        ex_mem_write_out,
    input [1:0]  ex_mem_size_out,
    input        ex_reg_write_out,
    input        ex_reg_src_out,

    // Read side (to MEM stage)
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_reg_data2,
    output reg [4:0]  mem_dest_reg,
    output reg        mem_mem_read,
    output reg        mem_mem_write,
    output reg [1:0]  mem_mem_size,
    output reg        mem_reg_write,
    output reg        mem_reg_src,

    // ── MEM/WB Pipeline Register ────────────────

    // Write side (from MEM stage)
    input [31:0] mem_data_result,
    input [31:0] mem_alu_result_out,
    input [4:0]  mem_dest_reg_out,
    input        mem_reg_write_out,
    input        mem_reg_src_out,

    // Read side (to WB stage)
    output reg [31:0] wb_mem_data,
    output reg [31:0] wb_alu_result,
    output reg [4:0]  wb_dest_reg,
    output reg        wb_reg_write,
    output reg        wb_reg_src
);

    always @(posedge clk) begin
        if (rst) begin
            // Reset IF/ID
            id_pc          <= 32'h00000000;
            id_instruction <= 32'h00000000;

            // Reset ID/EX
            ex_reg_data1  <= 32'h00000000;
            ex_reg_data2  <= 32'h00000000;
            ex_sign_ext   <= 32'h00000000;
            ex_rs         <= 5'b00000;
            ex_rt         <= 5'b00000;
            ex_rd         <= 5'b00000;
            ex_alu_op     <= 4'b0000;
            ex_alu_src_b  <= 1'b0;
            ex_mem_read   <= 1'b0;
            ex_mem_write  <= 1'b0;
            ex_mem_size   <= 2'b00;
            ex_reg_write  <= 1'b0;
            ex_reg_src    <= 1'b0;
            ex_pc         <= 32'h00000000;

            // Reset EX/MEM
            mem_alu_result  <= 32'h00000000;
            mem_reg_data2   <= 32'h00000000;
            mem_dest_reg    <= 5'b00000;
            mem_mem_read    <= 1'b0;
            mem_mem_write   <= 1'b0;
            mem_mem_size    <= 2'b00;
            mem_reg_write   <= 1'b0;
            mem_reg_src     <= 1'b0;

            // Reset MEM/WB
            wb_mem_data   <= 32'h00000000;
            wb_alu_result <= 32'h00000000;
            wb_dest_reg   <= 5'b00000;
            wb_reg_write  <= 1'b0;
            wb_reg_src    <= 1'b0;
        end
        else begin
            // ── Update IF/ID Register ──────────────

            // If stall, freeze IF/ID (don't update)
            // Otherwise, load new instruction
            if (!stall) begin
                id_pc          <= if_pc;
                id_instruction <= if_instruction;
            end

            // ── Update ID/EX Register ──────────────

            // If stall, insert bubble (NOP) into pipeline
            if (stall) begin
                // Insert bubble: all control signals = 0
                ex_reg_data1  <= 32'h00000000;
                ex_reg_data2  <= 32'h00000000;
                ex_sign_ext   <= 32'h00000000;
                ex_rs         <= 5'b00000;
                ex_rt         <= 5'b00000;
                ex_rd         <= 5'b00000;
                ex_alu_op     <= 4'b0000;
                ex_alu_src_b  <= 1'b0;
                ex_mem_read   <= 1'b0;
                ex_mem_write  <= 1'b0;
                ex_mem_size   <= 2'b00;
                ex_reg_write  <= 1'b0;
                ex_reg_src    <= 1'b0;
                ex_pc         <= 32'h00000000;
            end
            else begin
                // Normal operation: load from ID stage
                ex_reg_data1  <= id_reg_data1;
                ex_reg_data2  <= id_reg_data2;
                ex_sign_ext   <= id_sign_ext;
                ex_rs         <= id_rs;
                ex_rt         <= id_rt;
                ex_rd         <= id_rd;
                ex_alu_op     <= id_alu_op;
                ex_alu_src_b  <= id_alu_src_b;
                ex_mem_read   <= id_mem_read;
                ex_mem_write  <= id_mem_write;
                ex_mem_size   <= id_mem_size;
                ex_reg_write  <= id_reg_write;
                ex_reg_src    <= id_reg_src;
                ex_pc         <= id_pc;
            end

            // ── Update EX/MEM Register ─────────────

            // Always update (no stalling here)
            mem_alu_result  <= ex_alu_result;
            mem_reg_data2   <= ex_reg_data2_out;
            mem_dest_reg    <= ex_dest_reg;
            mem_mem_read    <= ex_mem_read_out;
            mem_mem_write   <= ex_mem_write_out;
            mem_mem_size    <= ex_mem_size_out;
            mem_reg_write   <= ex_reg_write_out;
            mem_reg_src     <= ex_reg_src_out;

            // ── Update MEM/WB Register ─────────────

            // Always update (final stage)
            wb_mem_data   <= mem_data_result;
            wb_alu_result <= mem_alu_result_out;
            wb_dest_reg   <= mem_dest_reg_out;
            wb_reg_write  <= mem_reg_write_out;
            wb_reg_src    <= mem_reg_src_out;
        end
    end

endmodule