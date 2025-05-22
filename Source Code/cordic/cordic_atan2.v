module cordic_atan2 (
    input wire clk,
    input wire reset_n,
    input wire start,
    input wire signed [15:0] y_in, // accel_y
    input wire signed [15:0] x_in, // accel_xz_mag
    output reg signed [15:0] angle,       // Góc tính toán (atan2)
    output reg valid               // Tín hiệu valid
);

    // Định nghĩa trạng thái FSM
    localparam STATE_IDLE    = 2'd0,
               STATE_COMPUTE = 2'd1,
               STATE_DONE    = 2'd2;

    reg [1:0] state;
    reg [4:0] iter;                // Đếm số lần lặp (0-15)
    reg signed [17:0] x, y;        // Biến tính toán CORDIC, mở rộng thành 18 bit
    reg signed [15:0] z;           // Biến tích lũy góc
    reg signed [17:0] x_shift, y_shift; // Biến tạm để tính dịch bit
    reg x_neg;                     // Flag nếu x_in < 0
    reg y_pos;                     // Flag nếu y_in >= 0

    // Bảng tra cứu góc cho CORDIC (atan(2^-i) trong định dạng fixed-point)
    reg [15:0] atan_table [0:15];
    initial begin
        atan_table[0]  = 16'h2000; // 45 độ
        atan_table[1]  = 16'h12e4; // 26.565 độ
        atan_table[2]  = 16'h09fb; // 14.036 độ
        atan_table[3]  = 16'h0511; // 7.125 độ
        atan_table[4]  = 16'h028b; // 3.576 độ
        atan_table[5]  = 16'h0145; // 1.790 độ
        atan_table[6]  = 16'h00a2; // 0.895 độ
        atan_table[7]  = 16'h0051; // 0.448 độ
        atan_table[8]  = 16'h0029; // 0.224 độ
        atan_table[9]  = 16'h0014; // 0.112 độ
        atan_table[10] = 16'h000a; // 0.056 độ
        atan_table[11] = 16'h0005; // 0.028 độ
        atan_table[12] = 16'h0003; // 0.014 độ
        atan_table[13] = 16'h0001; // 0.007 độ
        atan_table[14] = 16'h0001; // 0.0035 độ
        atan_table[15] = 16'h0000; // 0.0018 độ
    end

    // Logic FSM
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= STATE_IDLE;
            valid <= 0;
            angle <= 0;
            iter  <= 0;
            x     <= 0;
            y     <= 0;
            z     <= 0;
            x_shift <= 0;
            y_shift <= 0;
            x_neg <= 0;
            y_pos <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    valid <= 0;
                    if (start) begin
$display("Time: %0t, cordic_atan2 start, x_in = %h, y_in = %h", $time, x_in, y_in);
                        // Kiểm tra nghiêm ngặt trường hợp x_in và y_in đều bằng 0
                        if (x_in === 16'b0 && y_in === 16'b0) begin
                            angle <= 0;
                            valid <= 1;
$display("Time: %0t, cordic_atan2 valid, angle = %h", $time, angle);
                        end else if (y_in === 16'b0) begin
                            if (x_in > 0) begin
                                angle <= 0;
                            end else begin
                                angle <= 16'sh7FFF; // ~180 độ
                            end
                            valid <= 1;
$display("Time: %0t, cordic_atan2 valid, angle = %h", $time, angle);
                        end else if (x_in === 16'b0) begin
                            if (y_in > 0) begin
                                angle <= 16'd16384; // 90 độ
                            end else begin
                                angle <= -16'd16384; // -90 độ
                            end
                            valid <= 1;
$display("Time: %0t, cordic_atan2 valid, angle = %h", $time, angle);
                        end else begin
                            x_neg <= (x_in < 0);
                            y_pos <= (y_in >= 0);
                            x <= (x_in < 0) ? -x_in : x_in;
                            y <= y_in;
                            z <= 0;
                            iter <= 0;
                            state <= STATE_COMPUTE;
                        end
                    end
                end

                STATE_COMPUTE: begin
                    if (iter < 16) begin
                        x_shift = x >>> iter;
                        y_shift = y >>> iter;
                        if (y >= 0) begin
                            x <= x + y_shift;
                            y <= y - x_shift;
                            z <= z - atan_table[iter];
                        end else begin
                            x <= x - y_shift;
                            y <= y + x_shift;
                            z <= z + atan_table[iter];
                        end
                        iter <= iter + 1;
                    end else begin
                        state <= STATE_DONE;
                    end
                end

                STATE_DONE: begin
                    if (!x_neg) begin
                        angle <= -z;
                    end else if (y_pos) begin
                        angle <= 16'sh7FFF + z; // ~180 độ + z
                    end else begin
                        angle <= 16'sh8000 + z; // ~-180 độ + z
                    end
                    valid <= 1;
$display("Time: %0t, cordic_atan2 valid, angle = %h", $time, angle);
                    state <= STATE_IDLE;
                end

                default: begin
                    state <= STATE_IDLE;
                    angle <= 0;
                    valid <= 0;
                end
            endcase
        end
    end
endmodule
