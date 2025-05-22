module cordic_sqrt_scalar (
    input wire clk,
    input wire reset_n,
    input wire start,
    input wire [31:0] value_in,  // Đầu vào 32-bit dương (ví dụ: phương sai)
    output reg [15:0] sqrt_out,  // Đầu ra căn bậc hai 16-bit
    output reg valid
);
    reg [31:0] a;        // Lưu trữ giá trị đầu vào
    reg [31:0] guess;    // Giá trị dự đoán căn bậc hai
    reg [4:0] iter;      // Bộ đếm số lần lặp (0 đến 15)
    reg [1:0] state;     // Trạng thái máy trạng thái
    reg [31:0] test_guess; // Giá trị dự đoán tạm thời để kiểm tra

    // Định nghĩa các trạng thái
    localparam STATE_IDLE    = 2'd0,
               STATE_COMPUTE = 2'd1,
               STATE_DONE    = 2'd2;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= STATE_IDLE;
            sqrt_out <= 16'b0;
            valid <= 1'b0;
            a <= 0;
            guess <= 0;
            iter <= 5'd0;
            test_guess <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    valid <= 1'b0;  // Đặt valid về 0 trong trạng thái chờ
                    if (start) begin
                        a <= value_in;
                        state <= STATE_COMPUTE;
                        guess <= 0;
                        iter <= 5'd0;
                    end
                end
                STATE_COMPUTE: begin
                    if (iter < 5'd16) begin
                        test_guess = guess | (32'd1 << (15 - iter));
                        if (test_guess * test_guess <= a) begin
                            guess <= test_guess;
                        end
                        iter <= iter + 1;
                    end else begin
                        state <= STATE_DONE;
                    end
                end
                STATE_DONE: begin
                    sqrt_out <= guess[15:0];  // Lấy 16 bit thấp làm đầu ra
                    valid <= 1'b1;          // Đặt valid về 1 khi hoàn thành
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule
