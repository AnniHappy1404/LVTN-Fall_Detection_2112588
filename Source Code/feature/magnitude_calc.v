module magnitude_calc (
    input wire clk,
    input wire reset_n,
    input wire start,
    input wire [15:0] accel_x,
    input wire [15:0] accel_y,
    input wire [15:0] accel_z,
    output wire [15:0] magnitude,
    output wire valid
);
    reg [31:0] sum_sq;
    wire [15:0] sqrt_out;
    wire sqrt_valid;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sum_sq <= 32'd0;
        end else if (start) begin
            sum_sq <= accel_x * accel_x + accel_y * accel_y + accel_z * accel_z;
        end
    end

    cordic_sqrt cordic_inst (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .x_in(sum_sq[15:0]),  // có thể điều chỉnh độ rộng nếu cần chính xác hơn
        .y_in(16'd0),
        .z_in(16'd0),
        .magnitude(sqrt_out),
        .valid(sqrt_valid)
    );

    assign magnitude = sqrt_out;
    assign valid = sqrt_valid;
endmodule
