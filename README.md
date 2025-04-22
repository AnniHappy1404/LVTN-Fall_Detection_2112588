# LVTN-Fall_Detection_2112588
# 🎯 Fall Detection System using DE0-Nano + MPU-6050

Dự án này triển khai hệ thống **phát hiện té ngã** thời gian thực sử dụng:
- Kit FPGA **DE0-Nano**
- Cảm biến **MPU-6050**
- Mô hình **SVM** huấn luyện bằng MATLAB và triển khai bằng Verilog

---

## 🔧 Thành phần hệ thống Verilog

### `i2c_master.v`
- Điều khiển giao tiếp I2C:
  - Start condition
  - Gửi địa chỉ slave
  - Đọc/ghi dữ liệu từ/to MPU-6050
  - ACK/NACK & Stop condition
- Giao tiếp trực tiếp với các chân SDA/SCL thực tế của kit.

---

### `wrapper.v`
- Đóng vai trò gọi `i2c_master` liên tục để:
  - Đọc 6 thanh ghi: `ACCEL_X`, `ACCEL_Y`, `ACCEL_Z`, `GYRO_X`, `GYRO_Y`, `GYRO_Z`
- Kết quả lưu vào các thanh ghi nội bộ (`reg_acc_x`, `reg_gyro_y`, ...).
- FSM quản lý trạng thái đọc cảm biến.

---

### `feature_extraction.v`
- Nhận dữ liệu gia tốc và con quay, thực hiện:
  - Tính trung bình (mean)
  - Độ lệch chuẩn (std)
  - Tính độ lớn (magnitude)
- Kết quả đặc trưng đưa vào suy luận SVM.

---

### `svm_inference.v`
- Thực hiện suy luận bằng **mô hình SVM tuyến tính**:
  - Dùng ROM chứa `support vectors`, `alpha`, và `bias`
  - Chuẩn hóa đặc trưng đầu vào
  - Tính tích vô hướng + bias
- Kết quả:
  - `fall_detected = 1`: phát hiện té ngã
  - `fall_detected = 0`: bình thường

---

### `top_level.v`
- Tích hợp toàn bộ hệ thống:
  - Giao tiếp I2C với MPU-6050
  - Trích xuất đặc trưng
  - Phân loại bằng SVM
  - Xuất tín hiệu LED

