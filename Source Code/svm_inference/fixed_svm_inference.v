module svm_inference (
    input wire clk,
    input wire reset_n,
    input wire start,
    input wire signed [31:0] feature_mean,
    input wire signed [31:0] feature_std,
    output reg fall_detected
);

    localparam NUM_SV = 5502 ;
    localparam STATE_IDLE = 2'b00,
               STATE_READ = 2'b01,
               STATE_COMPUTE = 2'b10,
               STATE_DONE = 2'b11;

    reg [1:0] state;
    reg [12:0] addr;
    reg signed [31:0] sum;
    wire signed [31:0] sv, alpha, bias;

    reg_sv regSV (
        .clk(clk),
        .address(addr),
        .q(sv)
    );

    reg_alpha regAlpha (
        .clk(clk),
        .address(addr),
        .q(alpha)
    );

    reg_bias regBias (
        .clk(clk),
        .address(13'd0),
        .q(bias)
    );

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= STATE_IDLE;
            addr <= 0;
            sum <= 0;
            fall_detected <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (start) begin
                        addr <= 0;
                        sum <= 0;
                        state <= STATE_READ;
                    end
                end
                STATE_READ: begin
                    state <= STATE_COMPUTE;
                end
                STATE_COMPUTE: begin
                    sum <= sum + ((feature_mean * sv) >>> 16) * alpha;
                    if (addr == NUM_SV - 1)
                        state <= STATE_DONE;
                    else begin
                        addr <= addr + 1;
                        state <= STATE_READ;
                    end
                end
                STATE_DONE: begin
                    fall_detected <= (sum > bias);
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule
