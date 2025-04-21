module clock_divider #(parameter DIVISOR = 27'd500) (
    input wire clk_in,
    output reg clk_out
);
    reg [26:0] counter = 27'd0;

    always @(posedge clk_in) begin
        if (counter >= (DIVISOR - 1)) begin
            counter <= 27'd0;
        end else begin
            counter <= counter + 1;
        end

        clk_out <= (counter < (DIVISOR / 2)) ? 1'b0 : 1'b1;
    end
endmodule
