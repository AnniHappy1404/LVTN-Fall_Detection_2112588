module I2C_Slave (
    input wire clk,
    input wire rst,
    input wire scl,
    input wire sda_out,
    output reg sda_in
);
    // Mô phỏng phản hồi slave I2C cho testbench
    // Mặc định giữ SDA ở mức cao (không kéo xuống)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sda_in <= 1'b1;
        end else begin
            // Giả lập ACK khi nhận địa chỉ hoặc dữ liệu
            if (scl && !sda_out) begin
                sda_in <= 1'b0; // ACK
            end else begin
                sda_in <= 1'b1;
            end
        end
    end
endmodule
