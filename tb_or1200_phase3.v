`timescale 1ns/1ps
module tb_or1200_phase3;

    reg clk, rst;
    wire [31:0] pc_out, alu_result_out;
    wire [31:0] reg_r1, reg_r2, reg_r3, reg_r4, reg_r5, reg_r6, reg_r7, reg_r8;
    wire [31:0] total_cache_hits, total_cache_misses;

    // Variables for calculations (module level)
    integer estimated_hits, estimated_misses;
    integer hit_time, miss_time, total_time;
    integer no_cache_time;

    // Instantiate cached processor
    or1200_cached cpu(
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
        .total_cache_hits(total_cache_hits),
        .total_cache_misses(total_cache_misses)
    );

    // Clock generation
    initial clk = 0;
    always #10 clk = ~clk;

    // Test program
    initial begin
        $dumpfile("or1200_phase3.vcd");
        $dumpvars(0, tb_or1200_phase3);

        $display("====================================");
        $display("  OR1200 Phase 3 - Cache Test");
        $display("====================================");
        $display("");

        rst = 1;
        #200;
        rst = 0;
        #200;

        $display("Test 1: I-Cache Behavior");
        #10000;

        $display("  PC = %h", pc_out);
        $display("  R1 = %0d, R2 = %0d, R3 = %0d", reg_r1, reg_r2, reg_r3);
        $display("");

        $display("Test 2: Sequential Execution");
        #20000;

        $display("  R1 = %0d", reg_r1);
        $display("  R2 = %0d", reg_r2);
        $display("  R3 = %0d", reg_r3);
        $display("  R4 = %0d (R1+R2)", reg_r4);
        $display("  R5 = %0d (R2+R3)", reg_r5);
        $display("  R6 = %0d (R4+R5)", reg_r6);
        $display("  R7 = %0d (R6-R1)", reg_r7);
        $display("  R8 = %0d (R1&R5)", reg_r8);
        $display("");

        #50000;

        $display("====================================");
        $display("  Cache Statistics");
        $display("====================================");
        $display("Total Hits:   %0d", total_cache_hits);
        $display("Total Misses: %0d", total_cache_misses);

        if (total_cache_hits + total_cache_misses > 0) begin
            $display("Hit Rate: %0d%%", 
                (total_cache_hits * 100) / (total_cache_hits + total_cache_misses));
        end
        $display("");

        estimated_hits = total_cache_hits;
        estimated_misses = total_cache_misses;
        hit_time = estimated_hits;
        miss_time = estimated_misses * 51;
        total_time = hit_time + miss_time;

        $display("Performance Analysis:");
        $display("  %0d hits × 1 cycle = %0d cycles", estimated_hits, hit_time);
        $display("  %0d misses × 51 cycles = %0d cycles", estimated_misses, miss_time);
        $display("  Total: %0d cycles", total_time);

        no_cache_time = (estimated_hits + estimated_misses) * 50;
        if (total_time > 0) begin
            $display("  Without cache: %0d cycles", no_cache_time);
            $display("  With cache: %0d cycles", total_time);
            $display("  Speedup: %0d×", no_cache_time / total_time);
        end
        $display("");

        $display("====================================");
        $display("  Final State:");
        $display("====================================");
        $display("PC = %h, ALU = %0d", pc_out, alu_result_out);
        $display("R1=%0d R2=%0d R3=%0d R4=%0d", reg_r1, reg_r2, reg_r3, reg_r4);
        $display("R5=%0d R6=%0d R7=%0d R8=%0d", reg_r5, reg_r6, reg_r7, reg_r8);
        $display("");
        $display("====================================");
        $display("Phase 3 Cache Testing Complete!");
        $display("====================================");

        $finish;
    end

endmodule