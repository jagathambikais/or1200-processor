module hazard_unit(
    // From ID stage
    input [4:0] id_rs,          // Source register 1 in ID
    input [4:0] id_rt,          // Source register 2 in ID

    // From EX stage
    input [4:0] ex_rd,          // Destination in EX
    input       ex_reg_write,   // Does EX write?
    input       ex_mem_read,    // Is EX a LW?

    // From MEM stage
    input [4:0] mem_rd,         // Destination in MEM
    input       mem_reg_write,  // Does MEM write?

    // From WB stage
    input [4:0] wb_rd,          // Destination in WB
    input       wb_reg_write,   // Does WB write?

    // Outputs
    output reg        stall,           // Pause pipeline?
    output reg [1:0]  forward_a,       // Forward for RS
    output reg [1:0]  forward_b        // Forward for RT
);

    // ── Forwarding Control ──────────────────────────

    always @(*) begin

        // ── Forward A (for RS) ──────────────────
        // Priority: EX/MEM → MEM/WB → no forward

        if (mem_reg_write && mem_rd != 5'b00000 && mem_rd == id_rs)
            forward_a = 2'b10;  // Forward from MEM stage
        else if (wb_reg_write && wb_rd != 5'b00000 && wb_rd == id_rs)
            forward_a = 2'b01;  // Forward from WB stage
        else
            forward_a = 2'b00;  // No forwarding

        // ── Forward B (for RT) ──────────────────

        if (mem_reg_write && mem_rd != 5'b00000 && mem_rd == id_rt)
            forward_b = 2'b10;  // Forward from MEM stage
        else if (wb_reg_write && wb_rd != 5'b00000 && wb_rd == id_rt)
            forward_b = 2'b01;  // Forward from WB stage
        else
            forward_b = 2'b00;  // No forwarding

        // ── Stall Detection ─────────────────────

        // Stall if:
        // 1. LW in EX stage
        // 2. Next instruction needs that register
        // 3. Can't be forwarded from MEM yet

        if (ex_mem_read && ex_reg_write && ex_rd != 5'b00000 &&
            (ex_rd == id_rs || ex_rd == id_rt))
            stall = 1'b1;
        else
            stall = 1'b0;

    end

endmodule