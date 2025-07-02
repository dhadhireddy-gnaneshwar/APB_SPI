// Code your testbench here
// or browse Examples
class ADDR_DATA_GEN;
  rand logic [7:0] ADDR,DATA;
  
  constraint ADDR_CON { ADDR inside {[8'h51:8'h55],[8'hd1:8'hd5]};};
endclass
module tb;
  reg clk=0,miso,tx_trigger,rst=0;
  reg [2:0] tx_count,intrpt;
  reg [7:0] in_data,in_addr;
  wire ready,mosi,sclk;
  wire [5:1] cs;
  wire [7:0] read_data,intupt_data;

  
  APB_SPI_TOP DUV (
    .clk(clk),
    .in_data(in_data),
    .in_addr(in_addr),
    .tx_trigger(tx_trigger),
    .rst(rst),
    .tx_count(tx_count),
    .read_data(read_data),
    .Pready(ready),
    .intrpt(intrpt),
    .intrupt_data(intupt_data)
  );
  
  always #1 clk= ~clk;
  
  initial
    begin
      $dumpfile("test.vcd");
      $dumpvars;
      rst=1;
      @(posedge ready)
      tx_trigger=1;
      tx_count=3;
      in_data=8'hcd;
      in_addr=8'hd3;
      @(posedge ready)
      in_data=8'had;
      in_addr=8'h54;
      #10;
      intrpt=001;
      @(posedge ready)
      in_data=8'hcd;
      in_addr=8'hd3;
      #500;
      tx_trigger=0;
//       tx_count=2;
    end
endmodule