`timescale 1ns/1ps

module tb_svm_inference;

    reg clk;
    reg reset_n;
    reg start;
    reg signed [31:0] feature_mean;
    reg signed [31:0] feature_std;
    wire fall_detected;

    svm_inference uut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .feature_mean(feature_mean),
        .feature_std(feature_std),
        .fall_detected(fall_detected)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset_n = 0;
        start = 0;
        feature_mean = 32'd10000;
        feature_std = 32'd3000;
        #20;
        reset_n = 1;
        #20;
        start = 1;
        #10;
        start = 0;
        #100000;
        $display("Fall detected: %b", fall_detected);
        $finish;
    end
endmodule
