`timescale 1ns / 1ps

module tb_cordic_sqrt;
    // Inputs
    reg clk;
    reg reset_n;
    reg start;
    reg [15:0] x_in;
    reg [15:0] y_in;
    reg [15:0] z_in;

    // Outputs
    wire [15:0] magnitude;
    wire valid;

    // Instantiate the Unit Under Test (UUT)
    cordic_sqrt uut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .x_in(x_in),
        .y_in(y_in),
        .z_in(z_in),
        .magnitude(magnitude),
        .valid(valid)
    );

    // Clock generation
    always #5 clk = ~clk;  // 100MHz clock, period = 10ns

    initial begin
        // Initialize Inputs
        clk = 0;
        reset_n = 0;
        start = 0;
        x_in = 0;
        y_in = 0;
        z_in = 0;

        // Reset the system
        #10;
        reset_n = 1;
        #10;

        // Test case 1: x=3, y=4, z=0, expected magnitude ≈ 5
        x_in = 16'd3;
        y_in = 16'd4;
        z_in = 16'd0;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        $display("Test 1: x_in=3, y_in=4, z_in=0, magnitude=%d, valid=%b", magnitude, valid);

        // Wait a few cycles before next test
        #20;

        // Test case 2: x=1, y=1, z=1, expected magnitude ≈ sqrt(3) ≈ 1.732
        x_in = 16'd1;
        y_in = 16'd1;
        z_in = 16'd1;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        $display("Test 2: x_in=1, y_in=1, z_in=1, magnitude=%d, valid=%b", magnitude, valid);

        // Wait a few cycles before next test
        #20;

        // Test case 3: x=0, y=0, z=0, expected magnitude = 0
        x_in = 16'd0;
        y_in = 16'd0;
        z_in = 16'd0;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        $display("Test 3: x_in=0, y_in=0, z_in=0, magnitude=%d, valid=%b", magnitude, valid);

        // End simulation
        #100;
        $display("Simulation completed.");
        $finish;
    end
endmodule