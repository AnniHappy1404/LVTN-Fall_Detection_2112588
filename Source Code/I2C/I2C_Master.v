module I2C_Master (
    input wire clk,
    input wire rst,
    input wire en,
    output reg scl,
    input wire [6:0] ext_slave_address_in,
    input wire ext_read_write_in,
    input wire [7:0] ext_register_address_in,
    input wire [7:0] ext_data_in,
    output reg tristate,
    output reg sda_out,
    input wire sda_in,
    output reg [7:0] ext_data_out
);
    // Các trạng thái FSM
    localparam IDLE        = 4'h0,
               START       = 4'h1,
               SLAVE_ADDR  = 4'h2,
               SLAVE_ACK   = 4'h3,
               REG_ADDR    = 4'h4,
               REG_ACK     = 4'h5,
               DATA_PHASE  = 4'h6,
               DATA_ACK    = 4'h7,
               STOP        = 4'h8;

    reg [3:0] state = IDLE;
    reg [3:0] bit_cnt = 0;
    reg [7:0] shift_reg = 0;
    reg rw_flag = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            scl <= 1;
            sda_out <= 1;
            tristate <= 1;
            ext_data_out <= 8'd0;
            bit_cnt <= 0;
        end else begin
            case (state)
                IDLE: begin
                    scl <= 1;
                    sda_out <= 1;
                    tristate <= 1;
                    if (en) begin
                        rw_flag <= ext_read_write_in;
                        shift_reg <= {ext_slave_address_in, ext_read_write_in};
                        state <= START;
                    end
                end
                START: begin
                    sda_out <= 0;
                    scl <= 1;
                    state <= SLAVE_ADDR;
                    bit_cnt <= 0;
                end
                SLAVE_ADDR: begin
                    scl <= 0;
                    sda_out <= shift_reg[7];
                    shift_reg <= shift_reg << 1;
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) state <= SLAVE_ACK;
                end
                SLAVE_ACK: begin
                    tristate <= 1;
                    scl <= 1;
                    if (sda_in == 0) begin
                        state <= REG_ADDR;
                        shift_reg <= ext_register_address_in;
                        bit_cnt <= 0;
                        tristate <= 0;
                    end else begin
                        state <= STOP;
                    end
                end
                REG_ADDR: begin
                    scl <= 0;
                    sda_out <= shift_reg[7];
                    shift_reg <= shift_reg << 1;
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) state <= REG_ACK;
                end
                REG_ACK: begin
                    tristate <= 1;
                    scl <= 1;
                    if (sda_in == 0) begin
                        if (rw_flag == 0) begin
                            // Write tiếp
                            shift_reg <= ext_data_in;
                            bit_cnt <= 0;
                            tristate <= 0;
                            state <= DATA_PHASE;
                        end else begin
                            // Repeated Start chưa xử lý
                            state <= STOP;
                        end
                    end else state <= STOP;
                end
                DATA_PHASE: begin
                    scl <= 0;
                    sda_out <= shift_reg[7];
                    shift_reg <= shift_reg << 1;
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) state <= DATA_ACK;
                end
                DATA_ACK: begin
                    tristate <= 1;
                    scl <= 1;
                    if (sda_in == 0) begin
                        state <= STOP;
                    end else begin
                        state <= STOP;
                    end
                end
                STOP: begin
                    scl <= 1;
                    sda_out <= 0;
                    tristate <= 0;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
