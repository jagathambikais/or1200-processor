module or1200_pipeline(
    input clk,
    input rst,
    input [31:0] instruction,

    // Memory interface
    input [31:0]  mem_data_in,
    output [31:0] mem_addr,
    output [31:0] mem_data_out,
    output        mem_read,
    output        mem_write,

    // Debug outputs
    output [31:0] pc_out,
    output [31:0] alu_result_out,
    output [31:0] reg_r1, reg_r2, reg_r3, reg_r4,
    output [31:0] reg_r5, reg_r6, reg_r7, reg_r8
);

    // ── IF Stage Signals ────────────────────────────
    wire [31:0] if_pc;
    wire [31:0] if_instruction;

    // ── ID Stage Signals ────────────────────────────
    wire [31:0] id_pc;
    wire [31:0] id_instruction;
    wire [31:0] id_reg_data1, id_reg_data2;
    wire [31:0] id_sign_ext;
    wire [4:0]  id_rs, id_rt, id_rd;
    wire [3:0]  id_alu_op;
    wire        id_alu_src_b, id_mem_read, id_mem_write;
    wire [1:0]  id_mem_size;
    wire        id_reg_write, id_reg_src;

    // ── EX Stage Signals ────────────────────────────
    wire [31:0] ex_reg_data1, ex_reg_data2, ex_sign_ext;
    wire [4:0]  ex_rs, ex_rt, ex_rd;
    wire [3:0]  ex_alu_op;
    wire        ex_alu_src_b, ex_mem_read, ex_mem_write;
    wire [1:0]  ex_mem_size;
    wire        ex_reg_write, ex_reg_src;
    wire [31:0] ex_pc;
    wire [31:0] ex_alu_result;
    wire [31:0] ex_reg_data2_out;
    wire [4:0]  ex_dest_reg;

    // ── MEM Stage Signals ────────────────────────────
    wire [31:0] mem_alu_result, mem_reg_data2;
    wire [4:0]  mem_dest_reg;
    wire        mem_mem_read, mem_mem_write;
    wire [1:0]  mem_mem_size;
    wire        mem_reg_write, mem_reg_src;
    wire [31:0] mem_data_result;
    wire [31:0] mem_alu_result_out;
    wire [4:0]  mem_dest_reg_out;
    wire        mem_reg_write_out, mem_reg_src_out;

    // ── WB Stage Signals ────────────────────────────
    wire [31:0] wb_mem_data, wb_alu_result;
    wire [4:0]  wb_dest_reg;
    wire        wb_reg_write, wb_reg_src;
    wire [31:0] wb_write_data;
    wire [4:0]  wb_write_addr;
    wire        wb_write_en;

    // ── Pipeline Register Signals ───────────────────
    wire [31:0] id_if_pc, id_if_instruction;
    wire [31:0] ex_id_reg_data1, ex_id_reg_data2, ex_id_sign_ext;
    wire [4:0]  ex_id_rs, ex_id_rt, ex_id_rd;
    wire [3:0]  ex_id_alu_op;
    wire        ex_id_alu_src_b, ex_id_mem_read, ex_id_mem_write;
    wire [1:0]  ex_id_mem_size;
    wire        ex_id_reg_write, ex_id_reg_src;
    wire [31:0] ex_id_pc;
    wire [31:0] mem_ex_alu_result, mem_ex_reg_data2;
    wire [4:0]  mem_ex_dest_reg;
    wire        mem_ex_mem_read, mem_ex_mem_write;
    wire [1:0]  mem_ex_mem_size;
    wire        mem_ex_reg_write, mem_ex_reg_src;
    wire [31:0] wb_mem_data_piped, wb_alu_result_piped;
    wire [4:0]  wb_dest_reg_piped;
    wire        wb_reg_write_piped, wb_reg_src_piped;

    // ── Hazard Control Signals ──────────────────────
    wire        stall;
    wire [1:0]  forward_a, forward_b;

    // ── Forwarding Muxes ───────────────────────────
    wire [31:0] forwarded_data1, forwarded_data2;

    assign forwarded_data1 = (forward_a == 2'b10) ? mem_alu_result :
                             (forward_a == 2'b01) ? wb_alu_result :
                             ex_reg_data1;

    assign forwarded_data2 = (forward_b == 2'b10) ? mem_alu_result :
                             (forward_b == 2'b01) ? wb_alu_result :
                             ex_reg_data2;

    // ── PC Management (simple increment) ────────────
    reg [31:0] pc;
    assign if_pc = pc;
    assign pc_out = pc;

    always @(posedge clk) begin
        if (rst)
            pc <= 32'h00000000;
        else if (!stall)
            pc <= pc + 4;
    end

    // ── Phase 1: Core (IF, ID, EX) ──────────────────

    or1200_core_basic core(
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .mem_data_in(32'h00000000),  // Not used in Phase 2 pipeline
        .mem_addr(),                  // Not used
        .mem_data_out(),              // Not used
        .mem_read(),                  // Not used
        .mem_write(),                 // Not used
        .pc_out(),                    // Overridden
        .alu_result(ex_alu_result),
        .reg_r1(reg_r1),
        .reg_r2(reg_r2),
        .reg_r3(reg_r3),
        .reg_r4(reg_r4),
        .reg_r5(reg_r5),
        .reg_r6(reg_r6),
        .reg_r7(reg_r7),
        .reg_r8(reg_r8)
    );

    // ── Pipeline Registers ──────────────────────────

    pipeline_regs pregs(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .if_pc(if_pc),
        .if_instruction(instruction),
        .id_pc(id_pc),
        .id_instruction(id_instruction),
        .id_reg_data1(id_reg_data1),
        .id_reg_data2(id_reg_data2),
        .id_sign_ext(id_sign_ext),
        .id_rs(id_rs),
        .id_rt(id_rt),
        .id_rd(id_rd),
        .id_alu_op(id_alu_op),
        .id_alu_src_b(id_alu_src_b),
        .id_mem_read(id_mem_read),
        .id_mem_write(id_mem_write),
        .id_mem_size(id_mem_size),
        .id_reg_write(id_reg_write),
        .id_reg_src(id_reg_src),
        .ex_reg_data1(ex_reg_data1),
        .ex_reg_data2(ex_reg_data2),
        .ex_sign_ext(ex_sign_ext),
        .ex_rs(ex_rs),
        .ex_rt(ex_rt),
        .ex_rd(ex_rd),
        .ex_alu_op(ex_alu_op),
        .ex_alu_src_b(ex_alu_src_b),
        .ex_mem_read(ex_mem_read),
        .ex_mem_write(ex_mem_write),
        .ex_mem_size(ex_mem_size),
        .ex_reg_write(ex_reg_write),
        .ex_reg_src(ex_reg_src),
        .ex_pc(ex_pc),
        .ex_alu_result(ex_alu_result),
        .ex_reg_data2_out(ex_reg_data2_out),
        .ex_dest_reg(ex_dest_reg),
        .ex_mem_read_out(ex_mem_read),
        .ex_mem_write_out(ex_mem_write),
        .ex_mem_size_out(ex_mem_size),
        .ex_reg_write_out(ex_reg_write),
        .ex_reg_src_out(ex_reg_src),
        .mem_alu_result(mem_alu_result),
        .mem_reg_data2(mem_reg_data2),
        .mem_dest_reg(mem_dest_reg),
        .mem_mem_read(mem_mem_read),
        .mem_mem_write(mem_mem_write),
        .mem_mem_size(mem_mem_size),
        .mem_reg_write(mem_reg_write),
        .mem_reg_src(mem_reg_src),
        .mem_data_result(mem_data_result),
        .mem_alu_result_out(mem_alu_result_out),
        .mem_dest_reg_out(mem_dest_reg_out),
        .mem_reg_write_out(mem_reg_write_out),
        .mem_reg_src_out(mem_reg_src_out),
        .wb_mem_data(wb_mem_data),
        .wb_alu_result(wb_alu_result),
        .wb_dest_reg(wb_dest_reg),
        .wb_reg_write(wb_reg_write),
        .wb_reg_src(wb_reg_src)
    );

    // ── Hazard Unit ─────────────────────────────────

    hazard_unit hu(
        .id_rs(id_rs),
        .id_rt(id_rt),
        .ex_rd(ex_rd),
        .ex_reg_write(ex_reg_write),
        .ex_mem_read(ex_mem_read),
        .mem_rd(mem_dest_reg),
        .mem_reg_write(mem_reg_write),
        .wb_rd(wb_dest_reg),
        .wb_reg_write(wb_reg_write),
        .stall(stall),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // ── Memory Stage (NEW - Phase 2) ─────────────────

    mem_stage mem(
        .clk(clk),
        .rst(rst),
        .alu_result(mem_alu_result),
        .reg_data2(mem_reg_data2),
        .dest_reg(mem_dest_reg),
        .mem_read(mem_mem_read),
        .mem_write(mem_mem_write),
        .mem_size(mem_mem_size),
        .reg_write(mem_reg_write),
        .reg_src(mem_reg_src),
        .mem_addr(mem_addr),
        .mem_data_out(mem_data_out),
        .mem_wr_en(mem_write),
        .mem_rd_en(mem_read),
        .mem_data_in(mem_data_in),
        .mem_data_result(mem_data_result),
        .alu_result_out(mem_alu_result_out),
        .dest_reg_out(mem_dest_reg_out),
        .reg_write_out(mem_reg_write_out),
        .reg_src_out(mem_reg_src_out)
    );

    // ── Write Back Stage (NEW - Phase 2) ─────────────

    wb_stage wb(
        .clk(clk),
        .rst(rst),
        .mem_data(wb_mem_data),
        .alu_result(wb_alu_result),
        .dest_reg(wb_dest_reg),
        .reg_write(wb_reg_write),
        .reg_src(wb_reg_src),
        .write_data(wb_write_data),
        .write_addr(wb_write_addr),
        .write_en(wb_write_en)
    );

    // ── Output assignments ──────────────────────────
    assign alu_result_out = ex_alu_result;

endmodule