`timescale 1ns / 1ps

module tb_cordic_sqrt_scalar;

    // Signals
    reg clk;
    reg reset_n;
    reg start;
    reg [31:0] value_in;
    wire [15:0] sqrt_out;
    wire valid;

    // Instantiate DUT
    cordic_sqrt_scalar dut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .value_in(value_in),
        .sqrt_out(sqrt_out),
        .valid(valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Reset and test sequence
    initial begin
        // Initialize
        reset_n = 0;
        start = 0;
        value_in = 0;
        #10;
        reset_n = 1;
        #10;

        // Test case 1: value_in = 0
        value_in = 0;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 0) 
            $display("Test 1 passed: value_in = %d, sqrt_out = %d, expected = 0", value_in, sqrt_out);
        else 
            $display("Test 1 failed: value_in = %d, sqrt_out = %d, expected = 0", value_in, sqrt_out);
        #10;

        // Test case 2: value_in = 1
        value_in = 1;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 1) 
            $display("Test 2 passed: value_in = %d, sqrt_out = %d, expected = 1", value_in, sqrt_out);
        else 
            $display("Test 2 failed: value_in = %d, sqrt_out = %d, expected = 1", value_in, sqrt_out);
        #10;

        // Test case 3: value_in = 4
        value_in = 4;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 2) 
            $display("Test 3 passed: value_in = %d, sqrt_out = %d, expected = 2", value_in, sqrt_out);
        else 
            $display("Test 3 failed: value_in = %d, sqrt_out = %d, expected = 2", value_in, sqrt_out);
        #10;

        // Test case 4: value_in = 9
        value_in = 9;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 3) 
            $display("Test 4 passed: value_in = %d, sqrt_out = %d, expected = 3", value_in, sqrt_out);
        else 
            $display("Test 4 failed: value_in = %d, sqrt_out = %d, expected = 3", value_in, sqrt_out);
        #10;

        // Test case 5: value_in = 16
        value_in = 16;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 4) 
            $display("Test 5 passed: value_in = %d, sqrt_out = %d, expected = 4", value_in, sqrt_out);
        else 
            $display("Test 5 failed: value_in = %d, sqrt_out = %d, expected = 4", value_in, sqrt_out);
        #10;

        // Test case 6: value_in = 25
        value_in = 25;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 5) 
            $display("Test 6 passed: value_in = %d, sqrt_out = %d, expected = 5", value_in, sqrt_out);
        else 
            $display("Test 6 failed: value_in = %d, sqrt_out = %d, expected = 5", value_in, sqrt_out);
        #10;

        // Test case 7: value_in = 100
        value_in = 100;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 10) 
            $display("Test 7 passed: value_in = %d, sqrt_out = %d, expected = 10", value_in, sqrt_out);
        else 
            $display("Test 7 failed: value_in = %d, sqrt_out = %d, expected = 10", value_in, sqrt_out);
        #10;

        // Test case 8: value_in = 4294967295 (maximum 32-bit unsigned)
        value_in = 32'hFFFFFFFF;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 65535) 
            $display("Test 8 passed: value_in = %d, sqrt_out = %d, expected = 65535", value_in, sqrt_out);
        else 
            $display("Test 8 failed: value_in = %d, sqrt_out = %d, expected = 65535", value_in, sqrt_out);
        #10;

        // Test case 9: value_in = 2
        value_in = 2;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 1) 
            $display("Test 9 passed: value_in = %d, sqrt_out = %d, expected = 1", value_in, sqrt_out);
        else 
            $display("Test 9 failed: value_in = %d, sqrt_out = %d, expected = 1", value_in, sqrt_out);
        #10;

        // Test case 10: value_in = 3
        value_in = 3;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 1) 
            $display("Test 10 passed: value_in = %d, sqrt_out = %d, expected = 1", value_in, sqrt_out);
        else 
            $display("Test 10 failed: value_in = %d, sqrt_out = %d, expected = 1", value_in, sqrt_out);
        #10;

        // Test case 11: value_in = 5
        value_in = 5;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 2) 
            $display("Test 11 passed: value_in = %d, sqrt_out = %d, expected = 2", value_in, sqrt_out);
        else 
            $display("Test 11 failed: value_in = %d, sqrt_out = %d, expected = 2", value_in, sqrt_out);
        #10;

        // Test case 12: value_in = 8
        value_in = 8;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 2) 
            $display("Test 12 passed: value_in = %d, sqrt_out = %d, expected = 2", value_in, sqrt_out);
        else 
            $display("Test 12 failed: value_in = %d, sqrt_out = %d, expected = 2", value_in, sqrt_out);
        #10;

        // Test case 13: value_in = 15
        value_in = 15;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        if (sqrt_out == 3) 
            $display("Test 13 passed: value_in = %d, sqrt_out = %d, expected = 3", value_in, sqrt_out);
        else 
            $display("Test 13 failed: value_in = %d, sqrt_out = %d, expected = 3", value_in, sqrt_out);
        #10;

        // End simulation
        $finish;
    end

endmodule
