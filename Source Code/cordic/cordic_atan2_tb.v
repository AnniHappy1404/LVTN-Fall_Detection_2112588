`timescale 1ns / 1ps

module tb_cordic_atan2;

    // Signals
    reg clk;
    reg reset_n;
    reg start;
    reg signed [15:0] x_in;
    reg signed [15:0] y_in;
    wire signed [15:0] angle;
    wire valid;

    // Instantiate the Unit Under Test (UUT)
    cordic_atan2 uut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .x_in(x_in),
        .y_in(y_in),
        .angle(angle),
        .valid(valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        reset_n = 0;
        start = 0;
        x_in = 0;
        y_in = 0;

        // Reset
        #10;
        reset_n = 1;
        #10;

        // Test case 1: x=1000, y=0, expected angle=0
        x_in = 1000;
        y_in = 0;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        $display("Test 1: x=1000, y=0, angle=%d, expected=0", angle);
        if (angle == 0) $display("Pass");
        else $display("Fail");
        #10;

        // Test case 2: x=0, y=1000, expected angle≈16384
        x_in = 0;
        y_in = 1000;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        $display("Test 2: x=0, y=1000, angle=%d, expected=16384", angle);
        if (angle >= 16380 && angle <= 16388) $display("Pass");
        else $display("Fail");
        #10;

        // Test case 3: x=-1000, y=0, expected angle≈32767
        x_in = -1000;
        y_in = 0;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        $display("Test 3: x=-1000, y=0, angle=%d, expected=32767", angle);
        if (angle >= 32760 && angle <= 32767) $display("Pass");
        else $display("Fail");
        #10;

        // Test case 4: x=0, y=-1000, expected angle≈-16384
        x_in = 0;
        y_in = -1000;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        $display("Test 4: x=0, y=-1000, angle=%d, expected=-16384", angle);
        if (angle >= -16388 && angle <= -16380) $display("Pass");
        else $display("Fail");
        #10;

        // Test case 5: x=1000, y=1000, expected angle≈8192
        x_in = 1000;
        y_in = 1000;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        $display("Test 5: x=1000, y=1000, angle=%d, expected=8192", angle);
        if (angle >= 8190 && angle <= 8194) $display("Pass");
        else $display("Fail");
        #10;

        // Test case 6: x=-1000, y=1000, expected angle≈24576
        x_in = -1000;
        y_in = 1000;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        $display("Test 6: x=-1000, y=1000, angle=%d, expected=24576", angle);
        if (angle >= 24570 && angle <= 24582) $display("Pass");
        else $display("Fail");
        #10;

        // Test case 7: x=-1000, y=-1000, expected angle≈-24576
        x_in = -1000;
        y_in = -1000;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        $display("Test 7: x=-1000, y=-1000, angle=%d, expected=-24576", angle);
        if (angle >= -24582 && angle <= -24570) $display("Pass");
        else $display("Fail");
        #10;

        // Test case 8: x=1000, y=-1000, expected angle≈-8192
        x_in = 1000;
        y_in = -1000;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        $display("Test 8: x=1000, y=-1000, angle=%d, expected=-8192", angle);
        if (angle >= -8194 && angle <= -8190) $display("Pass");
        else $display("Fail");
        #10;

        // Test case 9: x=0, y=0, expected angle=0
        x_in = 0;
        y_in = 0;
        start = 1;
        #10;
        start = 0;
        wait(valid == 1);
        $display("Test 9: x=0, y=0, angle=%d, expected=0", angle);
        if (angle == 0) $display("Pass");
        else $display("Fail");
        #10;

        $finish;
    end

endmodule
