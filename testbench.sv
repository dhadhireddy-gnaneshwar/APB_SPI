// Code your testbench here
// or browse Examples
module axi_tb;
  reg clk=0;
  reg reset;
  reg [127:0] write_data;
  reg [63:0] write_address;
  wire [127:0] read_data;
  reg [63:0] read_address;
  reg [2:0] Burst_size;
  reg [1:0] Burst_type;
  reg [1:0] Burst_len;
  reg r_w;

  axi_top dut (
    .clk(clk),
    .reset(reset),
    .write_data(write_data),
    .write_address(write_address),
    .read_data(read_data),
    .read_address(read_address),
    .Burst_size(Burst_size),
    .Burst_type(Burst_type),
    .Burst_len(Burst_len),
    .r_w(r_w)
  );
   

  // Clock Generation
  always #5 clk = ~clk; 

  initial begin
      $dumpfile("test.vcd");
      $dumpvars;
      reset = 1;
      Burst_size = 3'b011; // Burst size is 8 bytes (64-bit)
      Burst_type = 2'b01;
      Burst_len = 3'b011;
      r_w = 0;
      write_address = 64'h0000_1234_5678_ABCD;
      write_data = 128'hB4C33BFA_939103C9_6DD7447D_37984B29;
      #30;
      write_data = 128'hA5A5A5A5_5A5A5A5A_A5A5A5A5_5A5A5A5B;
      #30;
      write_data = 128'hD5D17169_7FA14DDC_5DE9FF27_4EC3FB5D;
      #2500
//       read_address = 64'h0000_1234_5678_ABCD;
//       #7130
//       reset=1;
      r_w=1;
      #1000
      reset=0;
  end

endmodule
