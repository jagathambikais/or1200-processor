`timescale 1ns/1ps
module tb_or1200;

    reg clk;
    reg rst;
    reg [31:0] instruction;
    wire [31:0] mem_addr;
    wire [31:0] mem_data_out;
    wire        mem_read;
    wire        mem_write;
    wire [31:0] pc_out;
    wire [31:0] alu_result;
    wire [31:0] reg_r1, reg_r2, reg_r3, reg_r4, reg_r5, reg_r6, reg_r7, reg_r8;

    // Simulated memory
    reg [31:0] memory [0:255];
    wire [31:0] mem_data_in;

    // Instantiate OR1200 core
    or1200_core_basic core(
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .mem_data_in(mem_data_in),
        .mem_addr(mem_addr),
        .mem_data_out(mem_data_out),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .pc_out(pc_out),
        .alu_result(alu_result),
        .reg_r1(reg_r1),
        .reg_r2(reg_r2),
        .reg_r3(reg_r3),
        .reg_r4(reg_r4),
        .reg_r5(reg_r5),
        .reg_r6(reg_r6),
        .reg_r7(reg_r7),
        .reg_r8(reg_r8)
    );

    // Memory read
    assign mem_data_in = memory[mem_addr >> 2];

    // Clock generation — 50MHz (20ns period)
    initial clk = 0;
    always #10 clk = ~clk;

    // Initialize memory and run tests
    initial begin
        $dumpfile("or1200_phase1.vcd");
        $dumpvars(0, tb_or1200);

        $display("====================================");
        $display("  OR1200 Processor - Phase 1 Test");
        $display("====================================");
        $display("");

        // Initialize memory with test data
        memory[0] = 32'h00000000;
        memory[1] = 32'h00000001;
        memory[2] = 32'h00000002;
        memory[3] = 32'h00000003;

        // Reset
        rst = 1;
        instruction = 32'h00000000;
        #200;
        rst = 0;
        #200;

        // Initialize registers by writing directly
        // We'll do this by loading initial values with ADDI
        
        // ── Pre-load R2=20 with ADDI ────────────────
        $display("Pre-load: R2 = 20");
        instruction = 32'b001000_00000_00010_0000000000010100; // ADDI R2, R0, 20
        #100;
        $display("  After execute: R2=%0d, ALU=%0d", reg_r2, alu_result);
        #100;

        // ── Pre-load R3=30 with ADDI ────────────────
        $display("Pre-load: R3 = 30");
        instruction = 32'b001000_00000_00011_0000000000011110; // ADDI R3, R0, 30
        #100;
        $display("  After execute: R3=%0d, ALU=%0d", reg_r3, alu_result);
        #100;

        // ── Pre-load R5=50 with ADDI ────────────────
        $display("Pre-load: R5 = 50");
        instruction = 32'b001000_00000_00101_0000000000110010; // ADDI R5, R0, 50
        #100;
        $display("  After execute: R5=%0d, ALU=%0d", reg_r5, alu_result);
        #100;

        $display("");
        
        // ── Test 1: ADD R1, R2, R3 ──────────────────
        $display("Test 1: ADD R1, R2, R3");
        $display("  R2=%0d, R3=%0d", reg_r2, reg_r3);
        instruction = 32'b000000_00010_00011_00001_00000_100000;
        #100;
        $display("  ALU Output: %0d", alu_result);
        #100;
        $display("  Result: R1=%0d (expected 50)", reg_r1);
        $display("");

        // ── Test 2: ADDI R4, R5, 100 ────────────────
        $display("Test 2: ADDI R4, R5, 100");
        $display("  R5=%0d", reg_r5);
        instruction = 32'b001000_00101_00100_0000000001100100;
        #100;
        $display("  ALU Output: %0d", alu_result);
        #100;
        $display("  Result: R4=%0d (expected 150)", reg_r4);
        $display("");

        // ── Test 3: SUB R6, R1, R2 ──────────────────
        $display("Test 3: SUB R6, R1, R2");
        $display("  R1=%0d, R2=%0d", reg_r1, reg_r2);
        instruction = 32'b000000_00001_00010_00110_00000_100010;
        #100;
        $display("  ALU Output: %0d", alu_result);
        #100;
        $display("  Result: R6=%0d (expected 30)", reg_r6);
        $display("");

        // ── Test 4: AND R7, R1, R3 ──────────────────
        $display("Test 4: AND R1 & R3");
        $display("  R1=%0d, R3=%0d", reg_r1, reg_r3);
        instruction = 32'b000000_00001_00011_00111_00000_100100;
        #100;
        $display("  ALU Output: %0d (AND result)", alu_result);
        #100;
        $display("  Result: R7=%0d", reg_r7);
        $display("");

        // ── Test 5: OR R8, R1, R2 ───────────────────
        $display("Test 5: OR R1 | R2");
        $display("  R1=%0d, R2=%0d", reg_r1, reg_r2);
        instruction = 32'b000000_00001_00010_01000_00000_100101;
        #100;
        $display("  ALU Output: %0d (OR result)", alu_result);
        #100;
        $display("  Result: R8=%0d", reg_r8);
        $display("");

        // ── Final Register State ────────────────────
        #100;
        $display("====================================");
        $display("  Final Register State:");
        $display("====================================");
        $display("R1 = %0d (50)", reg_r1);
        $display("R2 = %0d (20)", reg_r2);
        $display("R3 = %0d (30)", reg_r3);
        $display("R4 = %0d (150)", reg_r4);
        $display("R5 = %0d (50)", reg_r5);
        $display("R6 = %0d (30)", reg_r6);
        $display("R7 = %0d (AND result)", reg_r7);
        $display("R8 = %0d (OR result)", reg_r8);
        $display("");
        $display("PC = %h", pc_out);
        $display("");
        $display("====================================");
        $display("Phase 1 Testing Complete!");
        $display("====================================");
        $display("");

        $finish;
    end

endmodule