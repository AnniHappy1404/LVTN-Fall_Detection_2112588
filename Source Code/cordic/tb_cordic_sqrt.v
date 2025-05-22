`timescale 1ns / 1ps

module cordic_sqrt_tb;
    // Khai báo các tín hi?u
    reg clk;
    reg reset_n;
    reg start;
    reg signed [15:0] x_in;
    reg signed [15:0] y_in;
    reg signed [15:0] z_in;
    wire [15:0] magnitude;
    wire valid;
    reg [31:0] sum_squares; // Bi?n ?? l?u t?ng bình ph??ng

    // Kh?i t?o module cordic_sqrt
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

    // T?o clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Chu k? clock 10ns
    end

    // Hàm tính c?n b?c hai tham chi?u
    function [15:0] ref_sqrt;
        input [31:0] sum_squares;
        real temp;
        begin
            temp = $sqrt(sum_squares);
            ref_sqrt = $rtoi(temp);
        end
    endfunction

    // Quá trình ki?m tra
    initial begin
        // Kh?i t?o tín hi?u
        reset_n = 0;
        start = 0;
        x_in = 0;
        y_in = 0;
        z_in = 0;
        sum_squares = 0;

        // Reset
        #20;
        reset_n = 1;
        #10;

        // Test case 1: x_in = 3, y_in = 0, z_in = 4
        x_in = 16'd3;
        y_in = 16'd0;
        z_in = 16'd4;
        sum_squares = (x_in * x_in) + (y_in * y_in) + (z_in * z_in);
        $display("Test case 1: x_in = %d, y_in = %d, z_in = %d, sum_squares = %d", x_in, y_in, z_in, sum_squares);
        start = 1;
        #10;
        start = 0;
        wait(valid);
        #10;
        if (magnitude == ref_sqrt(sum_squares)) begin
            $display("PASS: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end else begin
            $display("FAIL: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end
        #20;

        // Test case 2: x_in = 5, y_in = 0, z_in = 12
        x_in = 16'd5;
        y_in = 16'd0;
        z_in = 16'd12;
        sum_squares = (x_in * x_in) + (y_in * y_in) + (z_in * z_in);
        $display("Test case 2: x_in = %d, y_in = %d, z_in = %d, sum_squares = %d", x_in, y_in, z_in, sum_squares);
        start = 1;
        #10;
        start = 0;
        wait(valid);
        #10;
        if (magnitude == ref_sqrt(sum_squares)) begin
            $display("PASS: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end else begin
            $display("FAIL: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end
        #20;

        // Test case 3: x_in = -8, y_in = 0, z_in = 6
        x_in = -16'd8;
        y_in = 16'd0;
        z_in = 16'd6;
        sum_squares = (x_in * x_in) + (y_in * y_in) + (z_in * z_in);
        $display("Test case 3: x_in = %d, y_in = %d, z_in = %d, sum_squares = %d", x_in, y_in, z_in, sum_squares);
        start = 1;
        #10;
        start = 0;
        wait(valid);
        #10;
        if (magnitude == ref_sqrt(sum_squares)) begin
            $display("PASS: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end else begin
            $display("FAIL: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end
        #20;

        // Test case 4: x_in = 0, y_in = 0, z_in = 0
        x_in = 16'd0;
        y_in = 16'd0;
        z_in = 16'd0;
        sum_squares = (x_in * x_in) + (y_in * y_in) + (z_in * z_in);
        $display("Test case 4: x_in = %d, y_in = %d, z_in = %d, sum_squares = %d", x_in, y_in, z_in, sum_squares);
        start = 1;
        #10;
        start = 0;
        wait(valid);
        #10;
        if (magnitude == ref_sqrt(sum_squares)) begin
            $display("PASS: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end else begin
            $display("FAIL: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end
        #20;

        // Test case 5: x_in = 1, y_in = 1, z_in = 0
        x_in = 16'd1;
        y_in = 16'd1;
        z_in = 16'd0;
        sum_squares = (x_in * x_in) + (y_in * y_in) + (z_in * z_in);
        $display("Test case 5: x_in = %d, y_in = %d, z_in = %d, sum_squares = %d", x_in, y_in, z_in, sum_squares);
        start = 1;
        #10;
        start = 0;
        wait(valid);
        #10;
        if (magnitude == ref_sqrt(sum_squares)) begin
            $display("PASS: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end else begin
            $display("FAIL: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end
        #20;

        // Test case 6: x_in = 5, y_in = 1, z_in = 0
        x_in = 16'd5;
        y_in = 16'd1;
        z_in = 16'd0;
        sum_squares = (x_in * x_in) + (y_in * y_in) + (z_in * z_in);
        $display("Test case 6: x_in = %d, y_in = %d, z_in = %d, sum_squares = %d", x_in, y_in, z_in, sum_squares);
        start = 1;
        #10;
        start = 0;
        wait(valid);
        #10;
        if (magnitude == ref_sqrt(sum_squares)) begin
            $display("PASS: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end else begin
            $display("FAIL: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end
        #20;

        // Test case 7: x_in = 10, y_in = 10, z_in = 10
        x_in = 16'd10;
        y_in = 16'd10;
        z_in = 16'd10;
        sum_squares = (x_in * x_in) + (y_in * y_in) + (z_in * z_in);
        $display("Test case 7: x_in = %d, y_in = %d, z_in = %d, sum_squares = %d", x_in, y_in, z_in, sum_squares);
        start = 1;
        #10;
        start = 0;
        wait(valid);
        #10;
        if (magnitude == ref_sqrt(sum_squares)) begin
            $display("PASS: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end else begin
            $display("FAIL: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end
        #20;

        // Test case 8: x_in = 32767, y_in = 0, z_in = 0
        x_in = 16'd32767;
        y_in = 16'd0;
        z_in = 16'd0;
        sum_squares = (x_in * x_in) + (y_in * y_in) + (z_in * z_in);
        $display("Test case 8: x_in = %d, y_in = %d, z_in = %d, sum_squares = %d", x_in, y_in, z_in, sum_squares);
        start = 1;
        #10;
        start = 0;
        wait(valid);
        #10;
        if (magnitude == ref_sqrt(sum_squares)) begin
            $display("PASS: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end else begin
            $display("FAIL: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end
        #20;

        // Test case 9: x_in = -32768, y_in = 0, z_in = 0
        x_in = -16'd32768;
        y_in = 16'd0;
        z_in = 16'd0;
        sum_squares = (x_in * x_in) + (y_in * y_in) + (z_in * z_in);
        $display("Test case 9: x_in = %d, y_in = %d, z_in = %d, sum_squares = %d", x_in, y_in, z_in, sum_squares);
        start = 1;
        #10;
        start = 0;
        wait(valid);
        #10;
        if (magnitude == ref_sqrt(sum_squares)) begin
            $display("PASS: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end else begin
            $display("FAIL: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end
        #20;

        // Test case 10: x_in = 32767, y_in = 32767, z_in = 32767
        x_in = 16'd32767;
        y_in = 16'd32767;
        z_in = 16'd32767;
        sum_squares = (x_in * x_in) + (y_in * y_in) + (z_in * z_in);
        $display("Test case 10: x_in = %d, y_in = %d, z_in = %d, sum_squares = %d", x_in, y_in, z_in, sum_squares);
        start = 1;
        #10;
        start = 0;
        wait(valid);
        #10; // ?ã s?a dòng l?i thành ?? tr? h?p l?
        if (magnitude == ref_sqrt(sum_squares)) begin
            $display("PASS: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end else begin
            $display("FAIL: magnitude = %d, expected = %d", magnitude, ref_sqrt(sum_squares));
        end
        #20;

        $display("Simulation completed!");
        $finish;
    end

    // Giám sát tín hi?u
    initial begin
        $monitor("Time = %t, state = %d, x_in = %d, y_in = %d, z_in = %d, magnitude = %d, valid = %b",
                 $time, uut.state, x_in, y_in, z_in, magnitude, valid);
    end
endmodule
