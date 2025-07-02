`include "SPI_TOP"
`include "APB_MASTER"

module APB_SPI_TOP(
  input [7:0] in_data,
  input [7:0] in_addr,
  input clk,
  input rst,
  input [2:0] intrpt,
  input tx_trigger,
  input [2:0] tx_count,
  output [7:0] read_data,
  output wire Pready,
  output reg [7:0] intrupt_data
  
);
  wire [7:0] pwdata,paddr;
  wire [7:0] prdata;
  wire psel;
  wire ready;
  assign Pready=ready;
  APB_MASTER#(.NUMBER_OF_SLAVE(1)) APB1 (
    .pclk(clk),
    .prst(rst),
    .pready(ready),
    .in_data(in_data),
    .in_addr(in_addr),
    .psel(psel),
    .pwdata(pwdata),
    .paddr(paddr),
    .prdata(prdata),
    .pwrite(in_addr[7])
  );
  
  SPI_CONTROLLER_TX SPI(
    .in_data(pwdata),
    .in_addr(paddr),
    .tx_trigger(psel),
    .tx_count(tx_count),
    .clk(clk),
    .rst(rst),
    .read_data(prdata),
    .ready(ready),
    .intrpt(intrpt),
    .intrupt_data(intrupt_data)
  );
endmodule