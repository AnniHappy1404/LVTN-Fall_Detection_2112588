module cordic_sqrt (
    input wire clk,             // Xung clock dùng để đồng bộ hóa module
    input wire reset_n,         // Tín hiệu reset mức thấp (active-low), khởi tạo lại module khi = 0
    input wire start,           // Tín hiệu bắt đầu tính toán, kích hoạt khi = 1
    input wire signed [15:0] x_in,  // Đầu vào 16-bit có dấu, biểu diễn tọa độ trục X
    input wire signed [15:0] y_in,  // Đầu vào 16-bit có dấu, biểu diễn tọa độ trục Y
    input wire signed [15:0] z_in,  // Đầu vào 16-bit có dấu, biểu diễn tọa độ trục Z
    output reg [15:0] magnitude,    // Độ lớn đầu ra 16-bit, kết quả của sqrt(x_in^2 + y_in^2 + z_in^2)
    output reg valid                // Tín hiệu xác nhận kết quả hợp lệ, = 1 khi magnitude sẵn sàng
);

    // Khai báo các biến nội bộ
    reg [31:0] a;        // Biến 32-bit lưu tổng bình phương: x_in^2 + y_in^2 + z_in^2
    reg [31:0] guess;    // Giá trị dự đoán cho căn bậc hai, được cập nhật qua các lần lặp
    reg [4:0] iter;      // Biến đếm số lần lặp (0 đến 15), dùng trong quá trình tính căn bậc hai
    reg [1:0] state;     // Biến trạng thái của máy trạng thái hữu hạn (FSM)
    reg [31:0] test_guess; // Biến tạm 32-bit để kiểm tra giá trị dự đoán trong thuật toán

    // Định nghĩa các trạng thái của FSM
    localparam STATE_IDLE    = 2'd0,  // Trạng thái chờ, module không hoạt động cho đến khi start = 1
               STATE_SQUARE  = 2'd1,  // Trạng thái tính tổng bình phương của các đầu vào
               STATE_COMPUTE = 2'd2,  // Trạng thái tính căn bậc hai bằng phương pháp đoán bit
               STATE_DONE    = 2'd3;  // Trạng thái hoàn thành, xuất kết quả và chờ lệnh mới

    // Khối logic đồng bộ, kích hoạt bởi cạnh lên của clock hoặc cạnh xuống của reset_n
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Khi reset_n = 0, khởi tạo lại tất cả các biến về giá trị ban đầu
            state <= STATE_IDLE;        // Đặt trạng thái về chờ
            magnitude <= 16'b0;         // Khởi tạo đầu ra magnitude về 0
            valid <= 1'b0;              // Đặt tín hiệu valid về 0 (kết quả chưa hợp lệ)
            a <= 0;                     // Đặt tổng bình phương về 0
            guess <= 0;                 // Đặt giá trị dự đoán về 0
            iter <= 5'd0;               // Đặt biến đếm lặp về 0
            test_guess <= 0;            // Đặt biến tạm về 0
        end else begin
            // Xử lý logic dựa trên trạng thái hiện tại
            case (state)
                STATE_IDLE: begin
                    valid <= 1'b0;  // Đặt valid về 0 trong trạng thái chờ
                    if (start) begin
                        // Khi start = 1, bắt đầu tính toán
                        // Tính tổng bình phương a = x_in^2 + y_in^2 + z_in^2
                        // Mở rộng dấu cho các đầu vào 16-bit thành 32-bit trước khi nhân
                        a <= ({{16{x_in[15]}}, x_in} * {{16{x_in[15]}}, x_in}) +
                             ({{16{y_in[15]}}, y_in} * {{16{y_in[15]}}, y_in}) +
                             ({{16{z_in[15]}}, z_in} * {{16{z_in[15]}}, z_in});
                        state <= STATE_SQUARE;  // Chuyển sang trạng thái tính tổng bình phương
                    end
                end
                STATE_SQUARE: begin
                    // Trạng thái này chờ một chu kỳ clock để phép tính a hoàn tất
                    state <= STATE_COMPUTE;     // Chuyển sang trạng thái tính căn bậc hai
                    guess <= 0;                 // Khởi tạo giá trị dự đoán về 0
                    iter <= 5'd0;               // Đặt biến đếm lặp về 0
                end
                STATE_COMPUTE: begin
                    if (iter < 5'd16) begin
                        // Thực hiện 16 lần lặp để tính căn bậc hai bằng phương pháp đoán bit
                        test_guess = guess | (32'd1 << (15 - iter));  // Thử đặt bit tại vị trí (15 - iter)
                        if (test_guess * test_guess <= a) begin
                            guess <= test_guess;  // Nếu bình phương của test_guess <= a, cập nhật guess
                        end
                        iter <= iter + 1;         // Tăng biến đếm lặp
                    end else begin
                        state <= STATE_DONE;      // Khi hoàn thành 16 lần lặp, chuyển sang trạng thái hoàn thành
                    end
                end
                STATE_DONE: begin
                    // Xuất kết quả và kết thúc quá trình
                    magnitude <= guess[15:0];     // Gán 16 bit thấp của guess cho magnitude
                    valid <= 1'b1;                // Đặt valid = 1 để báo kết quả hợp lệ
                    state <= STATE_IDLE;          // Quay lại trạng thái chờ cho lệnh tiếp theo
                end
            endcase
        end
    end
endmodule
