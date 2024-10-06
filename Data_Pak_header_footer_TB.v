module Data_Pak_header_footer_TB;

  // Parameters
  localparam integer IN_WIDTH = 32;
  localparam integer OUT_WIDTH = 32;
  localparam integer DEPTH = 1024;
  localparam integer MAX_LEN = 381+1;

  // Signals
  reg clock;
  reg resetn;
  reg [IN_WIDTH-1 : 0] dataIn;
  reg validIn;
  reg lastIn;
  wire [OUT_WIDTH -1 : 0] dataOut;
  wire validOut;
  wire lastOut;
  wire overflow;

  // Instantiate FIFO module
  Data_Pak_Header_Footer #(
    .IN_WIDTH(IN_WIDTH),
    .OUT_WIDTH(OUT_WIDTH),
    .DEPTH(DEPTH),
    .MAX_LEN(MAX_LEN)
  ) inst (
    .clock(clock),
    .resetn(resetn),
    .dataIn(dataIn),
    .validIn(validIn),
    .lastIn(lastIn),
    .dataOut(dataOut),
    .validOut(validOut),
    .lastOut(lastOut),
    .overflow(overflow)
  );

  // Clock generation
  initial begin
    clock = 0;
    forever #5 clock = ~clock; // 100 MHz clock (period = 10 ns)
  end

  // Testbench logic
  integer k;
  initial begin
    resetn = 0;
    validIn = 0;
    dataIn = 0;
    lastIn = 0;

    // Apply reset
    reset_task();

    // Write some data after reset
    for (k=0; k<100;k=k+1)begin
    data_write(400,4);
    end

    // End simulation after some time
    #1000 $finish;
  end

  integer i;
  integer wait_n;
  // Task to write data into FIFO
  task automatic data_write;
  input integer num;
  input integer throttle;
  begin
    wait(resetn == 1);  // Wait until reset is de-asserted
    for(i = 0; i < num; i = i + 1) begin
      @(posedge clock);
      dataIn <= $urandom;   // Drive random input data
//      validIn <= $urandom % 2;  
      validIn <=1'b1;       // Assert valid signal
      lastIn <= (i == num-1);  // Assert lastIn on the last data word
    end
    // De-assert valid and last signals after data write
//    @(posedge clock);
//    validIn <= 0;
//    lastIn <= 0;
      wait_n = $urandom % throttle;
      repeat (wait_n) begin
        @(posedge clock);
      end
  end
  endtask

  // Task to handle reset sequence
task automatic reset_task;
begin
    repeat(10)
    @(posedge clock);
    resetn =~resetn;
end
endtask

endmodule
