module mpu6050_interface (
    input wire clk,             // Xung clock hệ thống 50 MHz
    input wire rst,             // Tín hiệu reset mức cao
    input wire start_read,      // Tín hiệu bắt đầu đọc dữ liệu
    output reg signed [15:0] accel_x_g,  // Gia tốc trục X (đơn vị g)
    output reg signed [15:0] accel_y_g,  // Gia tốc trục Y (đơn vị g)
    output reg signed [15:0] accel_z_g,  // Gia tốc trục Z (đơn vị g)
    output reg signed [15:0] gyro_x_dps, // Vận tốc góc trục X (đơn vị °/s)
    output reg signed [15:0] gyro_y_dps, // Vận tốc góc trục Y (đơn vị °/s)
    output reg signed [15:0] gyro_z_dps, // Vận tốc góc trục Z (đơn vị °/s)
    output reg data_ready,      // Tín hiệu báo dữ liệu sẵn sàng
    inout wire sda,             // Đường dữ liệu I2C
    inout wire scl,             // Đường clock I2C
    output wire [4:0] current_state,  // Cổng xuất trạng thái FSM
    output wire addr_ack_received,    // Trạng thái ACK cho địa chỉ I2C
    output wire reg_ack_received,     // Trạng thái ACK cho địa chỉ thanh ghi
    output reg error_flag             // Cờ báo lỗi khi không nhận được ACK
);

    // Parameters
    parameter I2C_FREQ = 10_000;        // Giảm tần số I2C xuống 10 kHz
    parameter CLK_FREQ = 50_000_000;    // Tần số clock hệ thống 50 MHz
    parameter SLAVE_ADDR = 7'h68;       // Địa chỉ I2C của MPU-6050
    parameter PWR_MGMT_1 = 8'h6B;       // Địa chỉ thanh ghi PWR_MGMT_1
    parameter ACCEL_CONFIG = 8'h1C;     // Địa chỉ thanh ghi ACCEL_CONFIG
    parameter GYRO_CONFIG = 8'h1B;      // Địa chỉ thanh ghi GYRO_CONFIG
    parameter ACCEL_REG = 8'h3B;        // Địa chỉ thanh ghi ACCEL_XOUT_H
    parameter GYRO_REG = 8'h43;         // Địa chỉ thanh ghi GYRO_XOUT_H
    parameter WHO_AM_I = 8'h75;         // Thanh ghi WHO_AM_I

    // Configuration values
    parameter PWR_MGMT_1_VAL = 8'h00;   // Thoát chế độ sleep
    parameter ACCEL_CONFIG_VAL = 8'h18; // Dải đo ±16g
    parameter GYRO_CONFIG_VAL = 8'h18;  // Dải đo ±2000°/s

    // Clock divider cho I2C
    localparam CLK_DIV = CLK_FREQ / (I2C_FREQ * 2); // 10kHz
    reg [15:0] clk_count;

    // FSM states
    parameter WAIT_STARTUP = 5'd0,
              CHECK_WHO_AM_I = 5'd1,
              SEND_ADDR_W_WHO = 5'd2,
              SEND_REG_WHO = 5'd3,
              RESTART_WHO = 5'd4,
              SEND_ADDR_R_WHO = 5'd5,
              READ_WHO = 5'd6,
              IDLE = 5'd7,
              CONFIG_PWR = 5'd8,
              CONFIG_ACCEL = 5'd9,
              CONFIG_GYRO = 5'd10,
              SEND_ADDR_W_CONFIG = 5'd11,
              SEND_REG_CONFIG = 5'd12,
              SEND_VAL = 5'd13,
              START_ACCEL = 5'd14,
              SEND_ADDR_W_ACCEL = 5'd15,
              SEND_REG_ACCEL = 5'd16,
              RESTART_ACCEL = 5'd17,
              SEND_ADDR_R_ACCEL = 5'd18,
              READ_ACCEL = 5'd19,
              START_GYRO = 5'd20,
              SEND_ADDR_W_GYRO = 5'd21,
              SEND_REG_GYRO = 5'd22,
              RESTART_GYRO = 5'd23,
              SEND_ADDR_R_GYRO = 5'd24,
              READ_GYRO = 5'd25,
              STOP = 5'd26,
              PROCESS_DATA = 5'd27,
              ERROR_STATE = 5'd28;

    // Internal registers
    reg [4:0] state;
    reg [7:0] byte_to_send;
    reg [3:0] bit_count;
    reg [3:0] byte_count;
    reg sda_oen;
    reg scl_oen;
    reg scl_state; // 0: low, 1: high
    reg config_done;
    reg [1:0] config_step;
    reg [47:0] accel_buffer;
    reg [47:0] gyro_buffer;
    reg signed [15:0] accel_x_raw, accel_y_raw, accel_z_raw;
    reg signed [15:0] gyro_x_raw, gyro_y_raw, gyro_z_raw;
    reg set_tick, sample_tick;
    reg addr_ack_received_reg;
    reg reg_ack_received_reg;
    reg [22:0] startup_counter; // Bộ đếm cho 100ms (5,000,000 chu kỳ)
    reg [7:0] who_am_i_value;   // Lưu giá trị WHO_AM_I
    reg [1:0] ack_check_count;  // Đếm số lần kiểm tra ACK

    // Tri-state buffer cho SDA và SCL
    assign sda = sda_oen ? 1'bz : 1'b0;
    assign scl = scl_oen ? 1'bz : 1'b0;

    // Gán trạng thái hiện tại và ACK cho cổng xuất
    assign current_state = state;
    assign addr_ack_received = addr_ack_received_reg;
    assign reg_ack_received = reg_ack_received_reg;

    // Bộ đồng bộ hóa cho tín hiệu SDA
    reg sda_sync;
    always @(posedge clk) begin
        sda_sync <= sda;
    end

    // Tạo tín hiệu tick cho thời gian I2C
    always @(posedge clk) begin
        set_tick <= (clk_count == CLK_DIV / 2) && (scl_state == 0);
        sample_tick <= (clk_count == CLK_DIV / 2) && (scl_state == 1);
    end

    // FSM và logic I2C
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= WAIT_STARTUP;
            scl_oen <= 1; // Thả SCL
            sda_oen <= 1; // Thả SDA
            scl_state <= 1; // Bắt đầu với SCL cao
            clk_count <= 0;
            bit_count <= 0;
            byte_count <= 0;
            config_done <= 0;
            config_step <= 0;
            data_ready <= 0;
            accel_buffer <= 0;
            gyro_buffer <= 0;
            accel_x_g <= 0;
            accel_y_g <= 0;
            accel_z_g <= 0;
            gyro_x_dps <= 0;
            gyro_y_dps <= 0;
            gyro_z_dps <= 0;
            addr_ack_received_reg <= 0;
            reg_ack_received_reg <= 0;
            error_flag <= 0;
            startup_counter <= 0;
            who_am_i_value <= 0;
            ack_check_count <= 0;
        end else begin
            // Tạo xung SCL 10 kHz
            if (clk_count < CLK_DIV - 1) begin
                clk_count <= clk_count + 1;
            end else begin
                clk_count <= 0;
                if (scl_state == 0) begin
                    scl_oen <= 1; // Thả SCL để cao
                    scl_state <= 1;
                end else begin
                    scl_oen <= 0; // Kéo SCL thấp
                    scl_state <= 0;
                end
            end

            // FSM logic
            case (state)
                WAIT_STARTUP: begin
                    if (startup_counter < 5_000_000) begin // 100ms
                        startup_counter <= startup_counter + 1;
                    end else begin
                        state <= CHECK_WHO_AM_I;
                    end
                end

                CHECK_WHO_AM_I: begin
                    byte_to_send <= {SLAVE_ADDR, 1'b0};
                    state <= SEND_ADDR_W_WHO;
                    bit_count <= 0;
                    ack_check_count <= 0;
                end

                SEND_ADDR_W_WHO: begin
                    if (set_tick) begin
                        if (bit_count < 8) begin
                            sda_oen <= byte_to_send[7 - bit_count];
                            bit_count <= bit_count + 1;
                        end else begin
                            sda_oen <= 1; // Thả để nhận ACK
                        end
                    end
                    if (sample_tick && bit_count == 8) begin
                        if (sda_sync == 0) begin
                            addr_ack_received_reg <= 1;
                            byte_to_send <= WHO_AM_I;
                            state <= SEND_REG_WHO;
                            bit_count <= 0;
                            ack_check_count <= 0;
                        end else if (ack_check_count < 2) begin
                            ack_check_count <= ack_check_count + 1; // Thử lại
                        end else begin
                            addr_ack_received_reg <= 0;
                            state <= ERROR_STATE;
                            error_flag <= 1;
                        end
                    end
                end

                SEND_REG_WHO: begin
                    if (set_tick) begin
                        if (bit_count < 8) begin
                            sda_oen <= byte_to_send[7 - bit_count];
                            bit_count <= bit_count + 1;
                        end else begin
                            sda_oen <= 1;
                        end
                    end
                    if (sample_tick && bit_count == 8) begin
                        if (sda_sync == 0) begin
                            reg_ack_received_reg <= 1;
                            state <= RESTART_WHO;
                            bit_count <= 0;
                            ack_check_count <= 0;
                        end else if (ack_check_count < 2) begin
                            ack_check_count <= ack_check_count + 1; // Thử lại
                        end else begin
                            reg_ack_received_reg <= 0;
                            state <= ERROR_STATE;
                            error_flag <= 1;
                        end
                    end
                end

                RESTART_WHO: begin
                    if (set_tick && scl_state == 0) begin
                        sda_oen <= 1; // Thả SDA
                    end
                    if (sample_tick && scl_state == 1) begin
                        sda_oen <= 0; // Kéo SDA thấp để restart
                        byte_to_send <= {SLAVE_ADDR, 1'b1};
                        state <= SEND_ADDR_R_WHO;
                        bit_count <= 0;
                    end
                end

                SEND_ADDR_R_WHO: begin
                    if (set_tick) begin
                        if (bit_count < 8) begin
                            sda_oen <= byte_to_send[7 - bit_count];
                            bit_count <= bit_count + 1;
                        end else begin
                            sda_oen <= 1;
                        end
                    end
                    if (sample_tick && bit_count == 8) begin
                        if (sda_sync == 0) begin
                            addr_ack_received_reg <= 1;
                            state <= READ_WHO;
                            bit_count <= 0;
                            ack_check_count <= 0;
                        end else if (ack_check_count < 2) begin
                            ack_check_count <= ack_check_count + 1; // Thử lại
                        end else begin
                            addr_ack_received_reg <= 0;
                            state <= ERROR_STATE;
                            error_flag <= 1;
                        end
                    end
                end

                READ_WHO: begin
                    if (sample_tick) begin
                        if (bit_count < 8) begin
                            who_am_i_value[7 - bit_count] <= sda_sync;
                            bit_count <= bit_count + 1;
                        end
                    end
                    if (set_tick && bit_count == 8) begin
                        sda_oen <= 1; // NACK
                    end
                    if (sample_tick && bit_count == 8) begin
                        sda_oen <= 1;
                        state <= STOP;
                        if (who_am_i_value != 8'h68) begin
                            error_flag <= 1;
                        end
                    end
                end

                IDLE: begin
                    error_flag <= 0;
                    if (start_read && scl == 1) begin
                        sda_oen <= 0; // Start condition
                        if (!config_done) begin
                            state <= CONFIG_PWR;
                            config_step <= 0;
                        end else begin
                            state <= START_ACCEL;
                        end
                    end
                end

                CONFIG_PWR: begin
                    byte_to_send <= {SLAVE_ADDR, 1'b0};
                    state <= SEND_ADDR_W_CONFIG;
                    bit_count <= 0;
                    ack_check_count <= 0;
                end

                SEND_ADDR_W_CONFIG: begin
                    if (set_tick) begin
                        if (bit_count < 8) begin
                            sda_oen <= byte_to_send[7 - bit_count];
                            bit_count <= bit_count + 1;
                        end else begin
                            sda_oen <= 1;
                        end
                    end
                    if (sample_tick && bit_count == 8) begin
                        if (sda_sync == 0) begin
                            addr_ack_received_reg <= 1;
                            case (config_step)
                                0: byte_to_send <= PWR_MGMT_1;
                                1: byte_to_send <= ACCEL_CONFIG;
                                2: byte_to_send <= GYRO_CONFIG;
                            endcase
                            state <= SEND_REG_CONFIG;
                            bit_count <= 0;
                            ack_check_count <= 0;
                        end else if (ack_check_count < 2) begin
                            ack_check_count <= ack_check_count + 1; // Thử lại
                        end else begin
                            addr_ack_received_reg <= 0;
                            state <= ERROR_STATE;
                            error_flag <= 1;
                        end
                    end
                end

                SEND_REG_CONFIG: begin
                    if (set_tick) begin
                        if (bit_count < 8) begin
                            sda_oen <= byte_to_send[7 - bit_count];
                            bit_count <= bit_count + 1;
                        end else begin
                            sda_oen <= 1;
                        end
                    end
                    if (sample_tick && bit_count == 8) begin
                        if (sda_sync == 0) begin
                            reg_ack_received_reg <= 1;
                            case (config_step)
                                0: byte_to_send <= PWR_MGMT_1_VAL;
                                1: byte_to_send <= ACCEL_CONFIG_VAL;
                                2: byte_to_send <= GYRO_CONFIG_VAL;
                            endcase
                            state <= SEND_VAL;
                            bit_count <= 0;
                            ack_check_count <= 0;
                        end else if (ack_check_count < 2) begin
                            ack_check_count <= ack_check_count + 1; // Thử lại
                        end else begin
                            reg_ack_received_reg <= 0;
                            state <= ERROR_STATE;
                            error_flag <= 1;
                        end
                    end
                end

                SEND_VAL: begin
                    if (set_tick) begin
                        if (bit_count < 8) begin
                            sda_oen <= byte_to_send[7 - bit_count];
                            bit_count <= bit_count + 1;
                        end else begin
                            sda_oen <= 1;
                        end
                    end
                    if (sample_tick && bit_count == 8) begin
                        if (sda_sync == 0) begin
                            if (config_step < 2) begin
                                config_step <= config_step + 1;
                                state <= CONFIG_PWR;
                            end else begin
                                config_done <= 1;
                                state <= STOP;
                            end
                        end else if (ack_check_count < 2) begin
                            ack_check_count <= ack_check_count + 1; // Thử lại
                        end else begin
                            state <= ERROR_STATE;
                            error_flag <= 1;
                        end
                    end
                end

                START_ACCEL: begin
                    byte_to_send <= {SLAVE_ADDR, 1'b0};
                    state <= SEND_ADDR_W_ACCEL;
                    bit_count <= 0;
                    ack_check_count <= 0;
                end

                SEND_ADDR_W_ACCEL: begin
                    if (set_tick) begin
                        if (bit_count < 8) begin
                            sda_oen <= byte_to_send[7 - bit_count];
                            bit_count <= bit_count + 1;
                        end else begin
                            sda_oen <= 1;
                        end
                    end
                    if (sample_tick && bit_count == 8) begin
                        if (sda_sync == 0) begin
                            addr_ack_received_reg <= 1;
                            byte_to_send <= ACCEL_REG;
                            state <= SEND_REG_ACCEL;
                            bit_count <= 0;
                            ack_check_count <= 0;
                        end else if (ack_check_count < 2) begin
                            ack_check_count <= ack_check_count + 1; // Thử lại
                        end else begin
                            addr_ack_received_reg <= 0;
                            state <= ERROR_STATE;
                            error_flag <= 1;
                        end
                    end
                end

                SEND_REG_ACCEL: begin
                    if (set_tick) begin
                        if (bit_count < 8) begin
                            sda_oen <= byte_to_send[7 - bit_count];
                            bit_count <= bit_count + 1;
                        end else begin
                            sda_oen <= 1;
                        end
                    end
                    if (sample_tick && bit_count == 8) begin
                        if (sda_sync == 0) begin
                            reg_ack_received_reg <= 1;
                            state <= RESTART_ACCEL;
                            bit_count <= 0;
                            ack_check_count <= 0;
                        end else if (ack_check_count < 2) begin
                            ack_check_count <= ack_check_count + 1; // Thử lại
                        end else begin
                            reg_ack_received_reg <= 0;
                            state <= ERROR_STATE;
                            error_flag <= 1;
                        end
                    end
                end

                RESTART_ACCEL: begin
                    if (set_tick && scl_state == 0) begin
                        sda_oen <= 1; // Thả SDA
                    end
                    if (sample_tick && scl_state == 1) begin
                        sda_oen <= 0; // Kéo SDA thấp để restart
                        byte_to_send <= {SLAVE_ADDR, 1'b1};
                        state <= SEND_ADDR_R_ACCEL;
                        bit_count <= 0;
                    end
                end

                SEND_ADDR_R_ACCEL: begin
                    if (set_tick) begin
                        if (bit_count < 8) begin
                            sda_oen <= byte_to_send[7 - bit_count];
                            bit_count <= bit_count + 1;
                        end else begin
                            sda_oen <= 1;
                        end
                    end
                    if (sample_tick && bit_count == 8) begin
                        if (sda_sync == 0) begin
                            addr_ack_received_reg <= 1;
                            state <= READ_ACCEL;
                            bit_count <= 0;
                            byte_count <= 0;
                            ack_check_count <= 0;
                        end else if (ack_check_count < 2) begin
                            ack_check_count <= ack_check_count + 1; // Thử lại
                        end else begin
                            addr_ack_received_reg <= 0;
                            state <= ERROR_STATE;
                            error_flag <= 1;
                        end
                    end
                end

                READ_ACCEL: begin
                    if (sample_tick) begin
                        if (bit_count < 8) begin
                            accel_buffer[47 - bit_count - byte_count * 8] <= sda_sync;
                            bit_count <= bit_count + 1;
                        end
                    end
                    if (set_tick && bit_count == 8) begin
                        sda_oen <= (byte_count < 5) ? 0 : 1; // ACK hoặc NACK
                    end
                    if (sample_tick && bit_count == 8) begin
                        sda_oen <= 1;
                        if (byte_count < 5) begin
                            byte_count <= byte_count + 1;
                            bit_count <= 0;
                        end else begin
                            state <= START_GYRO;
                        end
                    end
                end

                START_GYRO: begin
                    byte_to_send <= {SLAVE_ADDR, 1'b0};
                    state <= SEND_ADDR_W_GYRO;
                    bit_count <= 0;
                    ack_check_count <= 0;
                end

                SEND_ADDR_W_GYRO: begin
                    if (set_tick) begin
                        if (bit_count < 8) begin
                            sda_oen <= byte_to_send[7 - bit_count];
                            bit_count <= bit_count + 1;
                        end else begin
                            sda_oen <= 1;
                        end
                    end
                    if (sample_tick && bit_count == 8) begin
                        if (sda_sync == 0) begin
                            addr_ack_received_reg <= 1;
                            byte_to_send <= GYRO_REG;
                            state <= SEND_REG_GYRO;
                            bit_count <= 0;
                            ack_check_count <= 0;
                        end else if (ack_check_count < 2) begin
                            ack_check_count <= ack_check_count + 1; // Thử lại
                        end else begin
                            addr_ack_received_reg <= 0;
                            state <= ERROR_STATE;
                            error_flag <= 1;
                        end
                    end
                end

                SEND_REG_GYRO: begin
                    if (set_tick) begin
                        if (bit_count < 8) begin
                            sda_oen <= byte_to_send[7 - bit_count];
                            bit_count <= bit_count + 1;
                        end else begin
                            sda_oen <= 1;
                        end
                    end
                    if (sample_tick && bit_count == 8) begin
                        if (sda_sync == 0) begin
                            reg_ack_received_reg <= 1;
                            state <= RESTART_GYRO;
                            bit_count <= 0;
                            ack_check_count <= 0;
                        end else if (ack_check_count < 2) begin
                            ack_check_count <= ack_check_count + 1; // Thử lại
                        end else begin
                            reg_ack_received_reg <= 0;
                            state <= ERROR_STATE;
                            error_flag <= 1;
                        end
                    end
                end

                RESTART_GYRO: begin
                    if (set_tick && scl_state == 0) begin
                        sda_oen <= 1; // Thả SDA
                    end
                    if (sample_tick && scl_state == 1) begin
                        sda_oen <= 0; // Kéo SDA thấp để restart
                        byte_to_send <= {SLAVE_ADDR, 1'b1};
                        state <= SEND_ADDR_R_GYRO;
                        bit_count <= 0;
                    end
                end

                SEND_ADDR_R_GYRO: begin
                    if (set_tick) begin
                        if (bit_count < 8) begin
                            sda_oen <= byte_to_send[7 - bit_count];
                            bit_count <= bit_count + 1;
                        end else begin
                            sda_oen <= 1;
                        end
                    end
                    if (sample_tick && bit_count == 8) begin
                        if (sda_sync == 0) begin
                            addr_ack_received_reg <= 1;
                            state <= READ_GYRO;
                            bit_count <= 0;
                            byte_count <= 0;
                            ack_check_count <= 0;
                        end else if (ack_check_count < 2) begin
                            ack_check_count <= ack_check_count + 1; // Thử lại
                        end else begin
                            addr_ack_received_reg <= 0;
                            state <= ERROR_STATE;
                            error_flag <= 1;
                        end
                    end
                end

                READ_GYRO: begin
                    if (sample_tick) begin
                        if (bit_count < 8) begin
                            gyro_buffer[47 - bit_count - byte_count * 8] <= sda_sync;
                            bit_count <= bit_count + 1;
                        end
                    end
                    if (set_tick && bit_count == 8) begin
                        sda_oen <= (byte_count < 5) ? 0 : 1; // ACK hoặc NACK
                    end
                    if (sample_tick && bit_count == 8) begin
                        sda_oen <= 1;
                        if (byte_count < 5) begin
                            byte_count <= byte_count + 1;
                            bit_count <= 0;
                        end else begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    if (set_tick && scl_state == 0) begin
                        sda_oen <= 0; // Đảm bảo SDA thấp
                    end
                    if (sample_tick && scl_state == 1) begin
                        sda_oen <= 1; // Thả SDA để cao
                        if (config_done) begin
                            state <= PROCESS_DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end

                PROCESS_DATA: begin
                    accel_x_raw <= {accel_buffer[47:40], accel_buffer[39:32]};
                    accel_y_raw <= {accel_buffer[31:24], accel_buffer[23:16]};
                    accel_z_raw <= {accel_buffer[15:8], accel_buffer[7:0]};
                    gyro_x_raw  <= {gyro_buffer[47:40], gyro_buffer[39:32]};
                    gyro_y_raw  <= {gyro_buffer[31:24], gyro_buffer[23:16]};
                    gyro_z_raw  <= {gyro_buffer[15:8], gyro_buffer[7:0]};

                    accel_x_g <= $signed(accel_x_raw) / 2048;   // ±16g, độ nhạy 2048 LSB/g
                    accel_y_g <= $signed(accel_y_raw) / 2048;
                    accel_z_g <= $signed(accel_z_raw) / 2048;
                    gyro_x_dps <= $signed(gyro_x_raw) / 16;     // ±2000°/s, gần đúng với 16 thay vì 16.4
                    gyro_y_dps <= $signed(gyro_y_raw) / 16;
                    gyro_z_dps <= $signed(gyro_z_raw) / 16;

                    data_ready <= 1;
                    state <= IDLE;
                end

                ERROR_STATE: begin
                    error_flag <= 1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
