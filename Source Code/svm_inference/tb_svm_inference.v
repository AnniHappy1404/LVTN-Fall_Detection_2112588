`timescale 1ns/1ps

module tb_svm_inference;

    reg clk = 0;
    reg reset_n = 0;
    reg start = 0;

    reg signed [15:0] feature0, feature1, feature2, feature3, feature4, feature5, feature6;
    wire fall_detected;
    wire done;

    // Clock 50MHz
    always #10 clk = ~clk;

    // Instantiate DUT
    svm_inference dut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .feature_0(feature0),  // Sửa thành feature_0
        .feature_1(feature1),  // Sửa thành feature_1
        .feature_2(feature2),  // Sửa thành feature_2
        .feature_3(feature3),  // Sửa thành feature_3
        .feature_4(feature4),  // Sửa thành feature_4
        .feature_5(feature5),  // Sửa thành feature_5
        .feature_6(feature6),  // Sửa thành feature_6
        .fall_detected(fall_detected),
        .done(done)
    );

    reg [15:0] hex_data [0:6];

    initial begin
        $display("=== MO PHONG PHAT HIEN TE NGA ===");
        $readmemh("D:\\LVTN_21112588_FINAL_1\\svm_inference\\F15_SA01_R01_features.hex", hex_data);

        feature0 = hex_data[0];
        feature1 = hex_data[1];
        feature2 = hex_data[2];
        feature3 = hex_data[3];
        feature4 = hex_data[4];
        feature5 = hex_data[5];
        feature6 = hex_data[6];

        reset_n = 0;
        #50;
        reset_n = 1;

        #20;
        start = 1;
        #20;
        start = 0;

        wait (done == 1);
        #20;

        $display("FALL DETECTED = %b", fall_detected);
        $finish;
    end
endmodule
