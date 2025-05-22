module svm_inference (
    input wire clk,             // Xung clock dùng để đồng bộ hóa hoạt động của module
    input wire reset_n,         // Tín hiệu reset mức thấp (active-low), khởi tạo lại module khi = 0
    input wire start,           // Tín hiệu kích hoạt quá trình suy luận khi = 1
    input wire signed [15:0] feature_0,  // Đặc trưng đầu vào 0 (16-bit có dấu)
    input wire signed [15:0] feature_1,  // Đặc trưng đầu vào 1
    input wire signed [15:0] feature_2,  // Đặc trưng đầu vào 2
    input wire signed [15:0] feature_3,  // Đặc trưng đầu vào 3
    input wire signed [15:0] feature_4,  // Đặc trưng đầu vào 4
    input wire signed [15:0] feature_5,  // Đặc trưng đầu vào 5
    input wire signed [15:0] feature_6,  // Đặc trưng đầu vào 6
    output reg fall_detected,   // Kết quả suy luận: 1 nếu phát hiện té ngã, 0 nếu không
    output reg done             // Tín hiệu báo hiệu quá trình suy luận đã hoàn tất
);

    // **Định nghĩa hằng số**
    localparam NUM_SV = 786;    // Số lượng vector hỗ trợ (Support Vectors) trong mô hình SVM
    localparam NUM_FEAT = 7;    // Số lượng đặc trưng đầu vào (7 đặc trưng từ feature_0 đến feature_6)

    // **Định nghĩa các trạng thái của FSM (Finite State Machine - Máy trạng thái hữu hạn)**
    localparam STATE_IDLE      = 3'b000,  // Trạng thái chờ, không thực hiện hoạt động nào
               STATE_READ_SV   = 3'b001,  // Trạng thái đọc dữ liệu vector hỗ trợ từ RAM
               STATE_WAIT_SV   = 3'b010,  // Trạng thái chờ dữ liệu từ RAM được tải
               STATE_COMPUTE   = 3'b011,  // Trạng thái tính toán tích vô hướng
               STATE_ACCUM     = 3'b100,  // Trạng thái tích lũy kết quả từ các vector hỗ trợ
               STATE_ADD_BIAS  = 3'b101,  // Trạng thái cộng giá trị bias vào tổng
               STATE_DECIDE    = 3'b110,  // Trạng thái đưa ra quyết định cuối cùng
               STATE_DONE      = 3'b111;  // Trạng thái hoàn tất suy luận

    // **Khai báo các biến nội bộ**
    reg [2:0] state;            // Biến lưu trạng thái hiện tại của FSM (3-bit)
    reg [12:0] sv_index;        // Chỉ số của vector hỗ trợ hiện tại (0 đến 785, cần 13-bit để biểu diễn 786 giá trị)
    reg [2:0] feat_index;       // Chỉ số của đặc trưng hiện tại (0 đến 6, cần 3-bit)
    reg signed [31:0] dot_product;  // Tích vô hướng giữa vector đặc trưng đầu vào và vector hỗ trợ (32-bit có dấu)
    reg signed [31:0] total_sum;    // Tổng tích lũy kết quả từ tất cả vector hỗ trợ (32-bit có dấu)
    reg signed [15:0] current_sv_component;  // Thành phần hiện tại của vector hỗ trợ từ RAM (16-bit có dấu)
    reg signed [31:0] current_alpha;         // Hệ số alpha hiện tại của vector hỗ trợ (32-bit có dấu)
    reg signed [31:0] current_bias;          // Giá trị bias hiện tại của mô hình (32-bit có dấu)

    // **Khai báo tín hiệu từ RAM**
    wire signed [15:0] sv_component;  // Thành phần của vector hỗ trợ được đọc từ RAM
    wire [15:0] alpha_q;              // Hệ số alpha từ RAM (16-bit không dấu)
    wire signed [31:0] alpha;         // Hệ số alpha mở rộng thành 32-bit có dấu
    wire signed [31:0] bias;          // Giá trị bias từ RAM (32-bit có dấu)

    // **Tạo mảng đặc trưng đầu vào**
    wire signed [15:0] features [0:6];  // Mảng lưu trữ 7 đặc trưng đầu vào
    assign features[0] = feature_0;     // Gán feature_0 vào phần tử đầu tiên của mảng
    assign features[1] = feature_1;     // Gán feature_1 vào phần tử thứ hai
    assign features[2] = feature_2;     // Gán feature_2
    assign features[3] = feature_3;     // Gán feature_3
    assign features[4] = feature_4;     // Gán feature_4
    assign features[5] = feature_5;     // Gán feature_5
    assign features[6] = feature_6;     // Gán feature_6

    // **Tính toán địa chỉ cho RAM**
    wire [12:0] sv_addr = sv_index * 7 + feat_index;  // Địa chỉ RAM = (chỉ số SV * số đặc trưng) + chỉ số đặc trưng hiện tại

    // **Khởi tạo các module RAM**
    fixed_reg_sv reg_sv (
        .clk(clk),              // Kết nối xung clock
        .address(sv_addr),      // Địa chỉ để truy xuất thành phần của vector hỗ trợ
        .q(sv_component)        // Dữ liệu đầu ra từ RAM (thành phần của vector hỗ trợ)
    );

    fixed_reg_alpha reg_alpha (
        .clk(clk),              // Kết nối xung clock
        .address(sv_index[9:0]), // Sử dụng 10 bit thấp của sv_index làm địa chỉ (giả sử alpha có ít hơn 786 mục)
        .q(alpha_q)             // Dữ liệu đầu ra từ RAM (hệ số alpha 16-bit)
    );
    assign alpha = {{16{alpha_q[15]}}, alpha_q};  // Mở rộng dấu: sao chép bit dấu của alpha_q thêm 16 lần để thành 32-bit

    fixed_reg_bias reg_bias (
        .clk(clk),              // Kết nối xung clock
        .address(13'd0),        // Địa chỉ cố định (0) để lấy giá trị bias
        .q(bias)                // Dữ liệu đầu ra từ RAM (giá trị bias)
    );

    // **Luồng xử lý chính (FSM)**
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Khi reset_n = 0, khởi tạo lại tất cả các giá trị
            state <= STATE_IDLE;        // Đặt trạng thái về chờ
            sv_index <= 0;              // Đặt chỉ số vector hỗ trợ về 0
            feat_index <= 0;            // Đặt chỉ số đặc trưng về 0
            dot_product <= 0;           // Đặt tích vô hướng về 0
            total_sum <= 0;             // Đặt tổng tích lũy về 0
            fall_detected <= 0;         // Đặt kết quả phát hiện té ngã về 0
            done <= 0;                  // Đặt tín hiệu hoàn tất về 0
            current_sv_component <= 0;  // Đặt thành phần SV hiện tại về 0
            current_alpha <= 0;         // Đặt hệ số alpha hiện tại về 0
            current_bias <= 0;          // Đặt giá trị bias hiện tại về 0
        end else begin
            case (state)
                STATE_IDLE: begin
                    done <= 0;  // Đặt tín hiệu hoàn tất về 0 khi đang chờ
                    if (start) begin
                        // Khi start = 1, bắt đầu quá trình suy luận
                        sv_index <= 0;         // Đặt lại chỉ số vector hỗ trợ
                        feat_index <= 0;       // Đặt lại chỉ số đặc trưng
                        total_sum <= 0;        // Đặt lại tổng tích lũy
                        dot_product <= 0;      // Đặt lại tích vô hướng
                        state <= STATE_READ_SV; // Chuyển sang trạng thái đọc vector hỗ trợ
                    end
                end

                STATE_READ_SV: begin
                    // Đọc dữ liệu alpha và bias từ RAM
                    current_alpha <= alpha;        // Lưu hệ số alpha hiện tại
                    if (sv_index == 0) current_bias <= bias;  // Lưu bias khi xử lý vector hỗ trợ đầu tiên
                    state <= STATE_WAIT_SV;        // Chuyển sang trạng thái chờ dữ liệu từ RAM
                end

                STATE_WAIT_SV: begin
                    // Lấy thành phần của vector hỗ trợ từ RAM
                    current_sv_component <= sv_component;  // Lưu trữ thành phần hiện tại
                    state <= STATE_COMPUTE;        // Chuyển sang trạng thái tính toán
                end

                STATE_COMPUTE: begin
                    // Tính tích vô hướng: dot_product += (feature * sv_component) / 2^15
                    dot_product <= dot_product + ((features[feat_index] * current_sv_component) >>> 15);
                    if (feat_index == NUM_FEAT - 1) begin
                        state <= STATE_ACCUM;      // Nếu đã xử lý hết đặc trưng, chuyển sang tích lũy
                    end else begin
                        feat_index <= feat_index + 1;  // Tăng chỉ số đặc trưng
                        state <= STATE_READ_SV;    // Quay lại đọc thành phần tiếp theo
                    end
                end

                STATE_ACCUM: begin
                    // Tích lũy kết quả: total_sum += (alpha * dot_product) / 2^15
                    total_sum <= total_sum + ((current_alpha * dot_product) >>> 15);
                    if (sv_index == NUM_SV - 1) begin
                        state <= STATE_ADD_BIAS;   // Nếu đã xử lý hết SV, chuyển sang cộng bias
                    end else begin
                        sv_index <= sv_index + 1;  // Tăng chỉ số vector hỗ trợ
                        feat_index <= 0;           // Đặt lại chỉ số đặc trưng
                        dot_product <= 0;          // Đặt lại tích vô hướng
                        state <= STATE_READ_SV;    // Quay lại đọc SV tiếp theo
                    end
                end

                STATE_ADD_BIAS: begin
                    // Cộng giá trị bias vào tổng tích lũy
                    total_sum <= total_sum + current_bias;
                    state <= STATE_DECIDE;         // Chuyển sang trạng thái quyết định
                end

                STATE_DECIDE: begin
                    // Quyết định kết quả dựa trên dấu của total_sum
                    fall_detected <= (total_sum >= 0) ? 1'b1 : 1'b0;  // Nếu total_sum >= 0 thì phát hiện té ngã
                    state <= STATE_DONE;           // Chuyển sang trạng thái hoàn tất
                end

                STATE_DONE: begin
                    done <= 1;                     // Đánh dấu quá trình suy luận hoàn tất
                    state <= STATE_IDLE;           // Quay lại trạng thái chờ
                end
            endcase
        end
    end

endmodule
