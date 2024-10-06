module Sine #(
    parameter INPUT_BITS = 16,
    parameter OUTPUT_BITS = 18,
    parameter LUT_DEPTH_BITS = 10
) (
    input wire clk,
    input wire resetn,
    input wire [INPUT_BITS - 1:0] theta,
    input wire validIn,
    output reg [OUTPUT_BITS - 1:0] sineTheta,
    output reg validOut
);

    localparam LUT_DEPTH = 1 << LUT_DEPTH_BITS;

    reg [OUTPUT_BITS-1:0] sin_lut [0:LUT_DEPTH-1];
    reg [OUTPUT_BITS-1:0] cos_lut [0:LUT_DEPTH-1];

    reg [LUT_DEPTH_BITS-1:0] xa;
    reg [OUTPUT_BITS-1:0] sin_xa, cos_xa;
    reg [OUTPUT_BITS:0] delta_theta;

    initial begin
        // Initialize the sine and cosine LUTs here
        $readmemh("sin_table.mem", sin_lut); 
        $readmemh("cosin_table.mem", cos_lut);
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            sineTheta <= 0;
            validOut <= 0;
        end else if (validIn) begin
            xa = theta[INPUT_BITS-1:INPUT_BITS-LUT_DEPTH_BITS];
            sin_xa = sin_lut[xa];
            cos_xa = cos_lut[xa];
            delta_theta = theta[INPUT_BITS-LUT_DEPTH_BITS-1:0];
            
            sineTheta <= sin_xa + ((delta_theta * cos_xa) >> (INPUT_BITS - LUT_DEPTH_BITS));
            validOut <= 1;
        end else begin
            validOut <= 0;
        end
    end

endmodule
