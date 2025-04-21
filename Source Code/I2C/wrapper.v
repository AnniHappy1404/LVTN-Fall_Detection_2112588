module wrapper (
    input wire clk_50,  // Clock 50MHz từ DE0-Nano
    input wire rst,
    input wire en,
    input wire [3:0] register_selector, // Chọn thanh ghi cần đọc/ghi
    output wire scl,
    output wire tristate,
    inout wire sda,
    output wire [7:0] data
);

    wire clk_i2c;

    // Clock Divider: chia từ 50MHz → 100kHz cho I2C
    clock_divider #(500) clkdiv_inst (
        .clk_in (clk_50),
        .clk_out (clk_i2c)
    );

    // Kết nối SDA theo chuẩn I2C
    wire sda_out;
    assign sda = tristate ? 1'bz : sda_out;

    // Các tín hiệu điều khiển
    reg [6:0] ext_slave_address_in;
    reg ext_read_write_in;
    reg [7:0] ext_register_address_in;
    reg [7:0] ext_data_in;

    I2C_Master i2c_master_inst (
        .clk (clk_i2c),
        .rst (rst),
        .en (en),
        .scl (scl),
        .ext_slave_address_in (ext_slave_address_in),
        .ext_read_write_in (ext_read_write_in),
        .ext_register_address_in (ext_register_address_in),
        .ext_data_in (ext_data_in),
        .tristate (tristate),
        .sda_out (sda_out),
        .sda_in (sda),
        .ext_data_out (data)
    );

    // Địa chỉ MPU6050 (AD0 = GND)
    localparam SLAVE_ADDRESS = 7'b110_1000;
    localparam WRITE = 1'b0, READ = 1'b1;

    // Địa chỉ thanh ghi
    localparam [7:0]
        REGISTER_WHO_AM_I = 8'h75,
        REGISTER_PWR_MGMT_1 = 8'h6B;

    localparam [3:0]
        READ_WHO_AM_I = 4'b0001,
        WRITE_PWR_RESET = 4'b0010;

    always @(*) begin
        ext_slave_address_in     = SLAVE_ADDRESS;
        ext_read_write_in        = READ;
        ext_register_address_in  = 8'h00;
        ext_data_in              = 8'h00;

        case (register_selector)
            READ_WHO_AM_I: begin
                ext_read_write_in       = READ;
                ext_register_address_in = REGISTER_WHO_AM_I;
            end
            WRITE_PWR_RESET: begin
                ext_read_write_in       = WRITE;
                ext_register_address_in = REGISTER_PWR_MGMT_1;
                ext_data_in             = 8'h00; // Reset chip
            end
            default: ;
        endcase
    end
endmodule
