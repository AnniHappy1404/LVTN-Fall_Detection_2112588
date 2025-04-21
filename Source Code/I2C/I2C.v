module I2C (
    input wire clk,
    input wire rst,
    input wire [2:0] address,
    input wire [7:0] write_data,
    input wire we,
    input wire re,
    output reg [7:0] read_data
);
    // Địa chỉ ánh xạ thanh ghi
    localparam ENABLE            = 3'b000;
    localparam SLAVE_ADDRESS     = 3'b001;
    localparam READ_WRITE        = 3'b010;
    localparam REGISTER_ADDRESS  = 3'b011;
    localparam DATA_IN           = 3'b100;
    localparam DATA_OUT          = 3'b101;

    // Các thanh ghi điều khiển
    reg enable;
    reg [6:0] slave_address;
    reg read_write;
    reg [7:0] register_address;
    reg [7:0] data_in;
    wire [7:0] data_out;

    // Ghi dữ liệu vào thanh ghi
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            enable           <= 0;
            slave_address    <= 0;
            read_write       <= 0;
            register_address <= 0;
            data_in          <= 0;
        end else if (we) begin
            case (address)
                ENABLE:           enable           <= write_data[0];
                SLAVE_ADDRESS:    slave_address    <= write_data[6:0];
                READ_WRITE:       read_write       <= write_data[0];
                REGISTER_ADDRESS: register_address <= write_data;
                DATA_IN:          data_in          <= write_data;
            endcase
        end
    end

    // Đọc dữ liệu ra ngoài
    always @(posedge clk) begin
        if (re && address == DATA_OUT) begin
            read_data <= data_out;
        end
    end

    // Tín hiệu I2C
    wire scl, tristate, sda_out, sda_in;

    // I2C Master
    I2C_Master i2c_master_inst (
        .clk(clk),
        .rst(rst),
        .en(enable),
        .scl(scl),
        .ext_slave_address_in(slave_address),
        .ext_read_write_in(read_write),
        .ext_register_address_in(register_address),
        .ext_data_in(data_in),
        .tristate(tristate),
        .sda_out(sda_out),
        .sda_in(sda_in),
        .ext_data_out(data_out)
    );

    // I2C Slave (mô phỏng – chỉ cần cho testbench)
    I2C_Slave i2c_slave_inst (
        .clk(clk),
        .rst(rst),
        .scl(scl),
        .sda_out(sda_out),
        .sda_in(sda_in)
    );
endmodule
