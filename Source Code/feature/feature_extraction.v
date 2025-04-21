module feature_extraction (
    input wire clk,
    input wire reset_n,
    input wire data_valid,
    input wire [15:0] magnitude,
    output reg feature_valid,
    output reg [15:0] feature_mean,
    output reg [15:0] feature_std
);

    // Định nghĩa FSM state bằng localparam (Verilog 2001)
    localparam IDLE      = 3'd0,
               COLLECT   = 3'd1,
               CALC_MEAN = 3'd2,
               CALC_VAR  = 3'd3,
               CALC_STD  = 3'd4,
               DONE      = 3'd5;

    reg [2:0] state;
    parameter SAMPLE_COUNT = 100;
    reg [6:0] sample_counter;
    reg [31:0] sum;
    reg [47:0] sum_square;
    reg [15:0] mean;
    reg [31:0] variance;
    wire [15:0] sqrt_out;
    wire sqrt_valid;

    cordic_sqrt sqrt_inst (
        .clk(clk),
        .reset_n(reset_n),
        .start(state == CALC_STD),
        .x_in(variance[15:0]),  // ✅ truyền đúng variance thay vì mean
        .y_in(16'd0),
        .z_in(16'd0),
        .magnitude(sqrt_out),
        .valid(sqrt_valid)
    );

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            sample_counter <= 0;
            sum <= 0;
            sum_square <= 0;
            mean <= 0;
            variance <= 0;
            feature_mean <= 0;
            feature_std <= 0;
            feature_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (data_valid) begin
                        state <= COLLECT;
                        sum <= 0;
                        sum_square <= 0;
                        sample_counter <= 0;
                        feature_valid <= 0;
                    end
                end
                COLLECT: begin
                    if (data_valid) begin
                        sum <= sum + magnitude;
                        sum_square <= sum_square + magnitude * magnitude;
                        sample_counter <= sample_counter + 1;
                        if (sample_counter == SAMPLE_COUNT - 1) begin
                            state <= CALC_MEAN;
                        end
                    end
                end
                CALC_MEAN: begin
                    mean <= sum / SAMPLE_COUNT;
                    state <= CALC_VAR;
                end
                CALC_VAR: begin
                    variance <= (sum_square / SAMPLE_COUNT) - (mean * mean);
                    state <= CALC_STD;
                end
                CALC_STD: begin
                    if (sqrt_valid) begin
                        feature_mean <= mean;
                        feature_std <= sqrt_out;
                        feature_valid <= 1;
                        state <= DONE;
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
