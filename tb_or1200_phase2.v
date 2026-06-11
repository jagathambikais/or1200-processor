`timescale 1ns/1ps
module tb_or1200_phase2;

    reg clk, rst;
    reg [31:0] instruction;
    wire [31:0] mem_addr, mem_data_out;
    wire mem_read, mem_write;
    wire [31:0] pc_out, alu_result_out;
    wire [31:0] reg_r1, reg_r2, reg_r3, reg_r4, reg_r5, reg_r6, reg_r7, reg_r8;
    
    reg [31:0] mem_data_in;

    // Instantiate pipelined processor
    or1200_pipeline pipeline(
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .mem_data_in(mem_data_in),
        .mem_addr(mem_addr),
        .mem_data_out(mem_data_out),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .pc_out(pc_out),
        .alu_result_out(alu_result_out),
        .reg_r1(reg_r1),
        .reg_r2(reg_r2),
        .reg_r3(reg_r3),
        .reg_r4(reg_r4),
        .reg_r5(reg_r5),
        .reg_r6(reg_r6),
        .reg_r7(reg_r7),
        .reg_r8(reg_r8)
    );

    // Clock generation
    initial clk = 0;
    always #10 clk = ~clk;

    // Test program
    initial begin
        $dumpfile("or1200_phase2.vcd");
        $dumpvars(0, tb_or1200_phase2);

        $display("====================================");
        $display("  OR1200 Phase 2 - Pipeline Test");
        $display("====================================");
        $display("");

        // Reset
        rst = 1;
        instruction = 32'h00000000;
        mem_data_in = 32'h00000000;
        #200;
        rst = 0;
        #200;

        // ── Test 1: Load initial values (no hazards) ────

        $display("Test 1: Load Initial Values");
        $display("  Executing: ADDI R1, R0, 100");
        instruction = 32'b001000_00000_00001_0000000001100100;
        #200;

        $display("  Executing: ADDI R2, R0, 50");
        instruction = 32'b001000_00000_00010_0000000000110010;
        #200;

        $display("  Executing: ADDI R3, R0, 75");
        instruction = 32'b001000_00000_00011_0000000001001011;
        #200;

        #200;
        $display("  R1=%0d, R2=%0d, R3=%0d", reg_r1, reg_r2, reg_r3);
        $display("");

        // ── Test 2: No hazard - independent instructions ────

        $display("Test 2: No Hazard - Independent Instructions");
        $display("  Executing: ADD R4, R1, R2");
        instruction = 32'b000000_00001_00010_00100_00000_100000;
        #200;

        $display("  Executing: ADD R5, R2, R3 (independent)");
        instruction = 32'b000000_00010_00011_00101_00000_100000;
        #200;

        #200;
        $display("  R4=%0d (expected 150)", reg_r4);
        $display("  R5=%0d (expected 125)", reg_r5);
        $display("");

        // ── Test 3: Forwarding scenario ────────────────

        $display("Test 3: Forwarding - Data Hazard with Forward");
        $display("  Executing: ADD R6, R4, R5");
        instruction = 32'b000000_00100_00101_00110_00000_100000;
        #200;

        $display("  Executing: SUB R7, R6, R1 (uses R6 from previous ADD)");
        instruction = 32'b000000_00110_00001_00111_00000_100010;
        #200;

        #200;
        $display("  R6=%0d (expected 275)", reg_r6);
        $display("  R7=%0d (expected 175)", reg_r7);
        $display("");

        // ── Test 4: Multiple independent instructions ─────

        $display("Test 4: Pipeline Efficiency - Multiple Instructions");
        $display("  Instruction sequence:");
        $display("    ADD R1, R2, R3");
        $display("    AND R4, R1, R5");
        $display("    OR  R8, R6, R7");
        
        instruction = 32'b000000_00010_00011_00001_00000_100000;
        #200;

        instruction = 32'b000000_00001_00101_00100_00000_100100;
        #200;

        instruction = 32'b000000_00110_00111_01000_00000_100101;
        #200;

        #200;
        $display("  R1=%0d (ADD result)", reg_r1);
        $display("  R4=%0d (AND result)", reg_r4);
        $display("  R8=%0d (OR result)", reg_r8);
        $display("");

        // ── Test 5: ALU Operations ──────────────────────

        $display("Test 5: Various ALU Operations");

        instruction = 32'b001000_00000_00001_0000000001100100; // ADDI R1=100
        #200;

        instruction = 32'b000000_00001_00001_00010_00000_100010; // SUB R2 = R1 - R1 = 0
        #200;

        instruction = 32'b001100_00001_00011_0000000001111111; // ANDI R3, R1, 127
        #200;

        instruction = 32'b001101_00001_00100_0000000010000000; // ORI R4, R1, 128
        #200;

        #200;
        $display("  R1=%0d (100)", reg_r1);
        $display("  R2=%0d (0)", reg_r2);
        $display("  R3=%0d (AND result)", reg_r3);
        $display("  R4=%0d (OR result)", reg_r4);
        $display("");

        // ── Final Register State ────────────────────────

        #200;
        $display("====================================");
        $display("  Final Pipeline State:");
        $display("====================================");
        $display("PC     = %h", pc_out);
        $display("ALU    = %0d", alu_result_out);
        $display("");
        $display("Registers:");
        $display("  R1 = %0d", reg_r1);
        $display("  R2 = %0d", reg_r2);
        $display("  R3 = %0d", reg_r3);
        $display("  R4 = %0d", reg_r4);
        $display("  R5 = %0d", reg_r5);
        $display("  R6 = %0d", reg_r6);
        $display("  R7 = %0d", reg_r7);
        $display("  R8 = %0d", reg_r8);
        $display("");
        $display("====================================");
        $display("Phase 2 Pipeline Testing Complete!");
        $display("====================================");
        $display("");

        $finish;
    end

endmodule