module reg_bias (
    input wire clk,
    input wire [12:0] address,
    output reg [31:0] q
);
    reg [31:0] memory [0:2307];

    initial begin
        $readmemh("D:/LVTN_21112588_FINAL_1/svm_inference/bias.mif", memory);
    end

    always @(posedge clk) begin
        q <= memory[address];
    end
endmodule
