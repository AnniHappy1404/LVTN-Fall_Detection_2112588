module i2c_master (
    input wire clk,           // 50 MHz clock
    input wire reset_n,       // Active-low reset
    output reg i2c_scl,       // I2C clock
    inout wire i2c_sda,       // I2C data (inout)
    output reg [15:0] accel_x,
    output reg [15:0] accel_y,
    output reg [15:0] accel_z,
    output reg [15:0] gyro_x,
    output reg [15:0] gyro_y,
    output reg [15:0] gyro_z,
    output reg data_valid
);
    // Địa chỉ MPU-6050 và các thanh ghi
    localparam MPU6050_ADDR   = 7'h68;       // Địa chỉ I2C của MPU-6050
    localparam REG_PWR_MGMT_1 = 8'h6B;       // Thanh ghi quản lý nguồn
    localparam REG_SMPLRT_DIV = 8'h19;       // Thanh ghi chia tần số lấy mẫu
    localparam REG_ACCEL_CONFIG = 8'h1C;     // Thanh ghi cấu hình gia tốc
    localparam REG_GYRO_CONFIG = 8'h1B;      // Thanh ghi cấu hình con quay
    localparam REG_ACCEL_XOUT_H = 8'h3B;     // Thanh ghi bắt đầu dữ liệu gia tốc
    localparam REG_GYRO_XOUT_H = 8'h43;      // Thanh ghi bắt đầu dữ liệu con quay

    // Trạng thái FSM
    localparam STATE_IDLE       = 4'd0,
               STATE_START      = 4'd1,
               STATE_ADDR       = 4'd2,
               STATE_REG        = 4'd3,
               STATE_WRITE      = 4'd4,
               STATE_READ       = 4'd5,
               STATE_STOP       = 4'd6,
               STATE_INIT       = 4'd7,
               STATE_WAIT       = 4'd8;

    reg [3:0] state;
    reg [7:0] bit_count;
    reg [7:0] data_out;
    reg sda_out;
    reg sda_out_en;
    reg [17:0] sample_counter; // Đếm để lấy mẫu 200 Hz
    reg [7:0] byte_count;
    reg [7:0] data_in;
    reg [2:0] init_step;       // Bước khởi tạo
    reg init_done;             // Cờ hoàn tất khởi tạo

    // Gán I2C SDA
    assign i2c_sda = (sda_out_en) ? sda_out : 1'bz;

    // Tạo clock I2C (400 kHz, chu kỳ 2.5 us)
    localparam I2C_DIV = 8'd125; // 50 MHz / 125 = 400 kHz
    reg [7:0] counter;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 8'd0;
            i2c_scl <= 1'b1;
        end else begin
            if (counter == (I2C_DIV/2 - 8'd1)) begin
                i2c_scl <= ~i2c_scl;
                counter <= 8'd0;
            end else begin
                counter <= counter + 8'd1;
            end
        end
    end

    // Đếm để lấy mẫu 200 Hz (5 ms = 250,000 chu kỳ tại 50 MHz)
    localparam SAMPLE_COUNT = 18'd250000;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sample_counter <= 18'd0;
        end else if (state == STATE_WAIT) begin
            if (sample_counter < SAMPLE_COUNT - 18'd1) begin
                sample_counter <= sample_counter + 18'd1;
            end else begin
                sample_counter <= 18'd0;
            end
        end else begin
            sample_counter <= 18'd0;
        end
    end

    // FSM điều khiển giao tiếp I2C và khởi tạo MPU-6050
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= STATE_IDLE;
            sda_out <= 1'b1;
            sda_out_en <= 1'b0;
            bit_count <= 8'd0;
            data_valid <= 1'b0;
            accel_x <= 16'd0;
            accel_y <= 16'd0;
            accel_z <= 16'd0;
            gyro_x <= 16'd0;
            gyro_y <= 16'd0;
            gyro_z <= 16'd0;
            byte_count <= 8'd0;
            init_step <= 3'd0;
            init_done <= 1'b0;
        end else if (counter == 8'd0 && i2c_scl == 1'b1) begin
            case (state)
                STATE_IDLE: begin
                    sda_out <= 1'b1;
                    sda_out_en <= 1'b1;
                    if (!init_done) begin
                        state <= STATE_INIT;
                    end else if (sample_counter == SAMPLE_COUNT - 18'd1) begin
                        state <= STATE_START;
                    end
                end

                STATE_INIT: begin
                    case (init_step)
                        3'd0: begin // Ghi PWR_MGMT_1 = 0x00 (tắt sleep)
                            sda_out <= 1'b0; // Bắt đầu
                            state <= STATE_ADDR;
                            bit_count <= 8'd0;
                            data_out <= {MPU6050_ADDR, 1'b0}; // Ghi
                            init_step <= 3'd1;
                        end
                        3'd1: begin // Ghi SMPLRT_DIV = 0x04 (200 Hz)
                            sda_out <= 1'b0;
                            state <= STATE_ADDR;
                            bit_count <= 8'd0;
                            data_out <= {MPU6050_ADDR, 1'b0};
                            init_step <= 3'd2;
                        end
                        3'd2: begin // Ghi ACCEL_CONFIG = 0x00 (±2g)
                            sda_out <= 1'b0;
                            state <= STATE_ADDR;
                            bit_count <= 8'd0;
                            data_out <= {MPU6050_ADDR, 1'b0};
                            init_step <= 3'd3;
                        end
                        3'd3: begin // Ghi GYRO_CONFIG = 0x00 (±250°/s)
                            sda_out <= 1'b0;
                            state <= STATE_ADDR;
                            bit_count <= 8'd0;
                            data_out <= {MPU6050_ADDR, 1'b0};
                            init_step <= 3'd4;
                        end
                        3'd4: begin // Hoàn tất khởi tạo
                            init_done <= 1'b1;
                            state <= STATE_IDLE;
                            init_step <= 3'd0;
                        end
                    endcase
                end

                STATE_START: begin
                    sda_out <= 1'b0;
                    state <= STATE_ADDR;
                    bit_count <= 8'd0;
                    data_out <= {MPU6050_ADDR, 1'b0}; // Ghi địa chỉ để chọn thanh ghi
                end

                STATE_ADDR: begin
                    if (bit_count < 8'd8) begin
                        sda_out <= data_out[7-bit_count];
                        bit_count <= bit_count + 8'd1;
                    end else begin
                        sda_out_en <= 1'b0; // Chờ ACK
                        bit_count <= 8'd0;
                        state <= STATE_REG;
                        if (!init_done) begin
                            case (init_step)
                                3'd1: data_out <= REG_PWR_MGMT_1;
                                3'd2: data_out <= REG_SMPLRT_DIV;
                                3'd3: data_out <= REG_ACCEL_CONFIG;
                                3'd4: data_out <= REG_GYRO_CONFIG;
                            endcase
                        end else begin
                            data_out <= REG_ACCEL_XOUT_H;
                        end
                    end
                end

                STATE_REG: begin
                    if (bit_count < 8'd8) begin
                        sda_out <= data_out[7-bit_count];
                        sda_out_en <= 1'b1;
                        bit_count <= bit_count + 8'd1;
                    end else begin
                        sda_out_en <= 1'b0; // Chờ ACK
                        bit_count <= 8'd0;
                        if (!init_done) begin
                            state <= STATE_WRITE;
                            case (init_step)
                                3'd1: data_out <= 8'h00; // PWR_MGMT_1
                                3'd2: data_out <= 8'h04; // SMPLRT_DIV (200 Hz)
                                3'd3: data_out <= 8'h00; // ACCEL_CONFIG (±2g)
                                3'd4: data_out <= 8'h00; // GYRO_CONFIG (±250°/s)
                            endcase
                        end else begin
                            state <= STATE_START; // Quay lại gửi địa chỉ đọc
                            data_out <= {MPU6050_ADDR, 1'b1}; // Đọc
                        end
                    end
                end

                STATE_WRITE: begin
                    if (bit_count < 8'd8) begin
                        sda_out <= data_out[7-bit_count];
                        sda_out_en <= 1'b1;
                        bit_count <= bit_count + 8'd1;
                    end else begin
                        sda_out_en <= 1'b0; // Chờ ACK
                        bit_count <= 8'd0;
                        state <= STATE_STOP;
                    end
                end

                STATE_READ: begin
                    if (bit_count < 8'd8) begin
                        sda_out_en <= 1'b0;
                        data_in[7-bit_count] <= i2c_sda;
                        bit_count <= bit_count + 8'd1;
                    end else begin
                        sda_out_en <= 1'b1;
                        sda_out <= (byte_count < 8'd11) ? 1'b0 : 1'b1; // ACK/NACK
                        bit_count <= 8'd0;
                        byte_count <= byte_count + 8'd1;
                        case (byte_count)
                            8'd0: accel_x[15:8] <= data_in; // ACCEL_XOUT_H
                            8'd1: accel_x[7:0] <= data_in;  // ACCEL_XOUT_L
                            8'd2: accel_y[15:8] <= data_in; // ACCEL_YOUT_H
                            8'd3: accel_y[7:0] <= data_in;  // ACCEL_YOUT_L
                            8'd4: accel_z[15:8] <= data_in; // ACCEL_ZOUT_H
                            8'd5: accel_z[7:0] <= data_in;  // ACCEL_ZOUT_L
                            8'd6: gyro_x[15:8] <= data_in;  // GYRO_XOUT_H
                            8'd7: gyro_x[7:0] <= data_in;   // GYRO_XOUT_L
                            8'd8: gyro_y[15:8] <= data_in;  // GYRO_YOUT_H
                            8'd9: gyro_y[7:0] <= data_in;   // GYRO_YOUT_L
                            8'd10: gyro_z[15:8] <= data_in; // GYRO_ZOUT_H
                            8'd11: begin
                                gyro_z[7:0] <= data_in;     // GYRO_ZOUT_L
                                data_valid <= 1'b1;
                                state <= STATE_STOP;
                            end
                        endcase
                    end
                end

                STATE_STOP: begin
                    sda_out <= 1'b0;
                    sda_out_en <= 1'b1;
                    state <= (init_done && byte_count >= 8'd12) ? STATE_WAIT : STATE_IDLE;
                    data_valid <= 1'b0;
                    byte_count <= 8'd0;
                end

                STATE_WAIT: begin
                    if (sample_counter == SAMPLE_COUNT - 18'd1) begin
                        state <= STATE_START;
                    end
                end
            endcase
        end
    end
endmodule