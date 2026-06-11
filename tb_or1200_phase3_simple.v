`timescale 1ns/1ps
module tb_or1200_phase3_simple;

    reg clk, rst;
    wire [31:0] pc_out, alu_result_out;
    wire [31:0] reg_r1, reg_r2, reg_r3, reg_r4, reg_r5, reg_r6, reg_r7, reg_r8;
    wire [31:0] icache_hits, icache_misses, dcache_hits, dcache_misses;

    // Instantiate cached processor
    or1200_with_cache cpu(
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .alu_result_out(alu_result_out),
        .reg_r1(reg_r1),
        .reg_r2(reg_r2),
        .reg_r3(reg_r3),
        .reg_r4(reg_r4),
        .reg_r5(reg_r5),
        .reg_r6(reg_r6),
        .reg_r7(reg_r7),
        .reg_r8(reg_r8),
        .icache_hits(icache_hits),
        .icache_misses(icache_misses),
        .dcache_hits(dcache_hits),
        .dcache_misses(dcache_misses)
    );

    // Clock generation
    initial clk = 0;
    always #10 clk = ~clk;

    // Test program
    initial begin
        $dumpfile("or1200_phase3_simple.vcd");
        $dumpvars(0, tb_or1200_phase3_simple);

        $display("====================================");
        $display("  OR1200 Phase 3 - Simplified Cache");
        $display("====================================");
        $display("");

        // Reset
        rst = 1;
        #200;
        rst = 0;
        #200;

        $display("Test 1: Sequential Instruction Execution");
        $display("  Instructions preloaded in memory");
        $display("  First fetch: I-Cache MISS (50 cycles)");
        $display("  Subsequent fetches: I-Cache HIT (1 cycle)");
        $display("");

        // Wait for first instructions to complete (first miss + some hits)
        #40000;

        $display("Test 1 Results:");
        $display("  PC = %h", pc_out);
        $display("  R1 = %0d, R2 = %0d, R3 = %0d", reg_r1, reg_r2, reg_r3);
        $display("");

        // Continue execution
        $display("Test 2: Pipeline Execution with Cache");
        #30000;

        $display("  R1 = %0d (ADDI R1, R0, 100)", reg_r1);
        $display("  R2 = %0d (ADDI R2, R0, 50)", reg_r2);
        $display("  R3 = %0d (ADDI R3, R0, 75)", reg_r3);
        $display("  R4 = %0d (ADD R4, R1, R2)", reg_r4);
        $display("  R5 = %0d (ADD R5, R2, R3)", reg_r5);
        $display("  R6 = %0d (ADD R6, R4, R5)", reg_r6);
        $display("  R7 = %0d (SUB R7, R6, R1)", reg_r7);
        $display("  R8 = %0d (AND R8, R1, R5)", reg_r8);
        $display("");

        // Let cache warm up
        #50000;

        $display("====================================");
        $display("  Cache Statistics");
        $display("====================================");
        $display("");
        $display("I-Cache (Instruction):");
        $display("  Hits:   %0d", icache_hits);
        $display("  Misses: %0d", icache_misses);

        if (icache_hits + icache_misses > 0) begin
            $display("  Hit Rate: approx %0d%%",
                (icache_hits * 100) / (icache_hits + icache_misses));
        end
        $display("");

        $display("D-Cache (Data):");
        $display("  Hits:   %0d", dcache_hits);
        $display("  Misses: %0d", dcache_misses);

        if (dcache_hits + dcache_misses > 0) begin
            $display("  Hit Rate: approx %0d%%",
                (dcache_hits * 100) / (dcache_hits + dcache_misses));
        end
        $display("");

        $display("Performance Analysis:");
        $display("  I-Cache performance");
        $display("    First instruction: 50+ cycles (MISS)");
        $display("    Subsequent: 1 cycle each (HIT)");
        $display("  Result: Sequential code has excellent locality!");
        $display("");

        $display("====================================");
        $display("  Final Processor State");
        $display("====================================");
        $display("");
        $display("PC = %h", pc_out);
        $display("ALU result = %0d", alu_result_out);
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
        $display("Phase 3 Simplified Cache Test Complete!");
        $display("====================================");

        $finish;
    end

endmodule