module feature_pipeline (
    input wire clk,
    input wire reset_n,
    input wire start,
    input wire [15:0] accel_x,
    input wire [15:0] accel_y,
    input wire [15:0] accel_z,
    output wire [15:0] feature_mean,
    output wire [15:0] feature_std,
    output wire feature_valid
);
    wire [15:0] magnitude;
    wire mag_valid;

    magnitude_calc mag_calc_inst (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .accel_x(accel_x),
        .accel_y(accel_y),
        .accel_z(accel_z),
        .magnitude(magnitude),
        .valid(mag_valid)
    );

    feature_extraction feat_ext_inst (
        .clk(clk),
        .reset_n(reset_n),
        .data_valid(mag_valid),
        .magnitude(magnitude),
        .feature_valid(feature_valid),
        .feature_mean(feature_mean),
        .feature_std(feature_std)
    );
endmodule
