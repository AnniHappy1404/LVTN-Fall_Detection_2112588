module cordic_sqrt (
    input wire clk,
    input wire reset_n,
    input wire start,
    input wire [15:0] x_in,  // Đầu vào 16-bit có dấu
    input wire [15:0] y_in,  // Đầu vào 16-bit có dấu
    input wire [15:0] z_in,  // Đầu vào 16-bit có dấu
    output reg [15:0] magnitude,  // Độ lớn đầu ra 16-bit
    output reg valid
);
    reg [31:0] a;        // Tổng bình phương: x_in^2 + y_in^2 + z_in^2
    reg [31:0] guess;    // Giá trị dự đoán cho căn bậc hai
    reg [4:0] iter;      // Biến đếm số lần lặp (0 đến 15)
    reg [1:0] state;     // Trạng thái máy trạng thái
    reg [31:0] test_guess; // Biến tạm để kiểm tra giá trị dự đoán

    // Định nghĩa các trạng thái
    localparam STATE_IDLE    = 2'd0,
               STATE_SQUARE  = 2'd1,
               STATE_COMPUTE = 2'd2,
               STATE_DONE    = 2'd3;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= STATE_IDLE;
            magnitude <= 16'b0;  // Khởi tạo magnitude về 0
            valid <= 1'b0;
            a <= 0;
            guess <= 0;
            iter <= 5'd0;
            test_guess <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (start) begin
                        // Tính a = x_in^2 + y_in^2 + z_in^2
                        a <= ({{16{x_in[15]}}, x_in} * {{16{x_in[15]}}, x_in}) +
                             ({{16{y_in[15]}}, y_in} * {{16{y_in[15]}}, y_in}) +
                             ({{16{z_in[15]}}, z_in} * {{16{z_in[15]}}, z_in});
                        state <= STATE_SQUARE;
                        valid <= 1'b0;
                    end
                end
                STATE_SQUARE: begin
                    // Đợi một chu kỳ để tính toán a hoàn tất
                    state <= STATE_COMPUTE;
                    guess <= 0;
                    iter <= 5'd0;
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
                    magnitude <= guess[15:0];  // Gán 16 bit thấp của guess cho magnitude
                    valid <= 1'b1;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule