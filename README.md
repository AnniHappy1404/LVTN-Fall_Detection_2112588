# LVTN-Fall_Detection_2112588
i2c_master.v: Điều khiển toàn bộ giao tiếp I2C (start, send address, send/receive data, ACK/NACK, stop). Kết nối trực tiếp ra chân SDA, SCL của kit DE0-Nano. Đây là module cốt lõi để đọc thanh ghi từ MPU-6050.
mpu6050_reader.v (wrapper): Gọi i2c_master nhiều lần để đọc liên tục 6 thanh ghi: ACCEL_X/Y/Z và GYRO_X/Y/Z. Lưu kết quả vào các thanh ghi đầu ra (reg_acc_x, v.v.) FSM điều khiển thứ tự đọc và trạng thái chờ ACK.
