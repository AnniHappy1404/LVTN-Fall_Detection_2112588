`timescale 1ns/1ps

module tb_svm_inference;

    reg clk;
    reg reset_n;
    reg start;
    reg signed [31:0] feature_mean;
    reg signed [31:0] feature_std;
    wire fall_detected;

    // Instantiate DUT
    svm_inference dut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .feature_mean(feature_mean),
        .feature_std(feature_std),
        .fall_detected(fall_detected)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    reg [15:0] test_vectors [0:6]; // 7 đặc trưng

    initial begin
        $display("=== BẮT ĐẦU TEST ===");

        // Sửa đường dẫn tại đây
        $readmemh("D:/LVTN_21112588_FINAL_1/svm_inference/test1_vectors.hex", test_vectors);

        feature_mean = {{16{test_vectors[0][15]}}, test_vectors[0]};
        feature_std  = {{16{test_vectors[1][15]}}, test_vectors[1]};

        reset_n = 0;
        start = 0;
        #20;
        reset_n = 1;
        #20;

        start = 1;
        #10;
        start = 0;

        wait(fall_detected === 1 || fall_detected === 0);
        #100;

        $display("Fall detected: %b", fall_detected);
        $stop;
    end

endmodule
