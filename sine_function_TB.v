`timescale 1ns/1ps
module sine_function_tb();

    parameter INPUT_BITS = 16;
    parameter OUTPUT_BITS = 18;
    parameter LUT_DEPTH_BITS = 10;

    reg clk;
    reg resetn;
    reg [INPUT_BITS-1:0] theta;
    reg validIn;
    wire [OUTPUT_BITS-1:0] sineTheta;
    wire validOut;

    // Instantiate the Sine module
    Sine #(
        .INPUT_BITS(INPUT_BITS),
        .OUTPUT_BITS(OUTPUT_BITS),
        .LUT_DEPTH_BITS(LUT_DEPTH_BITS)
    ) uut (
        .clk(clk),
        .resetn(resetn),
        .theta(theta),
        .validIn(validIn),
        .sineTheta(sineTheta),
        .validOut(validOut)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // Test sequence
    initial begin
        resetn = 0;
        validIn = 0;
        theta = 0;
        #20;
        resetn = 1;

        // Apply test vectors
        #10;
        validIn = 1;
        theta = 16'h0000;  // 0 degrees
        #10;
        theta = 16'h4000;  // 90 degrees
        #10;
        theta = 16'h8000;  // 180 degrees
        #10;
        theta = 16'hC000;  // 270 degrees
        #10;
        theta = 16'hFFFF;  // Slightly less than 360 degrees

        // End simulation
        #100;
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0t | theta: %h | sineTheta: %h | validOut: %b",
                  $time, theta, sineTheta, validOut);
    end

endmodule
