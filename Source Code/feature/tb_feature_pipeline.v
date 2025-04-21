
`timescale 1ns / 1ps

module tb_feature_pipeline;
    reg clk;
    reg reset_n;
    reg start;
    reg [15:0] accel_x, accel_y, accel_z;
    wire [15:0] feature_mean;
    wire [15:0] feature_std;
    wire feature_valid;

    // Khởi tạo instance
    feature_pipeline uut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .accel_x(accel_x),
        .accel_y(accel_y),
        .accel_z(accel_z),
        .feature_mean(feature_mean),
        .feature_std(feature_std),
        .feature_valid(feature_valid)
    );

    // Clock 50MHz
    always #10 clk = ~clk;

    initial begin
        $dumpfile("tb_feature_pipeline.vcd");
        $dumpvars(0, tb_feature_pipeline);

        // Khởi tạo
        clk = 0;
        reset_n = 0;
        start = 0;
        accel_x = 0;
        accel_y = 0;
        accel_z = 0;

        // Reset
        #100;
        reset_n = 1;

        // Cung cấp dữ liệu đầu vào liên tục
        repeat (100) begin
            @(posedge clk);
            start <= 1;
            accel_x <= $random % 256;
            accel_y <= $random % 256;
            accel_z <= $random % 256;
        end

        // Tắt start
        @(posedge clk);
        start <= 0;

        // Chờ kết quả
        wait (feature_valid);
        $display("Feature Mean = %d, Std = %d", feature_mean, feature_std);

        #100;
        $finish;
    end
endmodule
