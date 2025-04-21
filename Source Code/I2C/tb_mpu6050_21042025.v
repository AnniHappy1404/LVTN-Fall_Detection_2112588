`timescale 1ns / 1ps

module tb_wrapper;

    // Clock và Reset
    reg clk_50;
    reg rst;
    reg en;
    reg [3:0] register_selector;
    wire scl, tristate;
    wire [7:0] data;
    wire sda;

    // Tín hiệu SDA điều khiển mô phỏng
    wire sda_from_master;
    wire sda_from_slave;
    reg sda_line;

    assign sda_from_master = (tristate) ? 1'bz : wrapper_inst.sda_out;
    assign sda_from_slave = (sda_line == 1'bz) ? 1'bz : sda_line;

    assign sda = (tristate) ? sda_from_slave : sda_from_master;

    // Sinh clock 50MHz
    initial clk_50 = 0;
    always #10 clk_50 = ~clk_50;  // 20ns chu kỳ => 50 MHz

    // DUT
    wrapper wrapper_inst (
        .clk_50(clk_50),
        .rst(rst),
        .en(en),
        .register_selector(register_selector),
        .scl(scl),
        .tristate(tristate),
        .sda(sda),
        .data(data)
    );

    // Mô phỏng MPU6050 trả lời qua SDA
    initial begin
        sda_line = 1'bz;
        wait(tristate == 1);  // đợi master nhả SDA
        forever begin
            @(negedge scl);
            // Gửi ACK sau byte địa chỉ + thanh ghi
            if (wrapper_inst.i2c_master_inst.state == 3 || 
                wrapper_inst.i2c_master_inst.state == 5 || 
                wrapper_inst.i2c_master_inst.state == 7) begin
                sda_line = 1'b0; // ACK
            end else begin
                sda_line = 1'bz;
            end
        end
    end

    initial begin
        // Khởi tạo
        rst = 1;
        en = 0;
        register_selector = 4'b0000;
        #100;

        rst = 0;
        #100;

        // Test đọc WHO_AM_I
        register_selector = 4'b0001;  // READ_WHO_AM_I
        en = 1;
        #1000000; // Chờ truyền xong

        // Test ghi vào PWR_MGMT_1
        register_selector = 4'b0010;  // WRITE_PWR_RESET
        en = 1;
        #1000000;

        $stop;
    end
endmodule
