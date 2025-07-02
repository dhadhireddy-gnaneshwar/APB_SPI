// Code your design here
`include "master.sv"
`include "slave.sv"
`include "apb.sv"
`include "bridge.sv"
`include "spi.sv"


module axi_top(
  input clk,
  input reset,
  
  // User-provided write & read data
  input [127:0] write_data,
  input [63:0] write_address,
  output [127:0] read_data,
  input [2:0] Burst_size,
  input [1:0] Burst_type,
  input [1:0] Burst_len,
  input [63:0] read_address,
  
//   input for read or write operation for qspi
  input r_w
);

  // Internal signals connecting master & slave
  wire AWVALID, AWREADY;
  wire WDVALID, WDREADY;
  wire BVALID, BREADY, BRESP;
  wire RAVALID, RAREADY;
  wire RDVALID, RDREADY;

  wire [127:0] out_write_data, out_read_data;
  wire [63:0] out_write_address, out_read_address;
  

  // Instantiating AXI Master
  axi_master master (
    .clk(clk),
    .reset(reset),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),
    .Burst_size(Burst_size),
    .Burst_type(Burst_type),
    .Burst_len(Burst_len),
    .WDVALID(WDVALID),
    .WDREADY(WDREADY),
    .BVALID(BVALID),
    .BREADY(BREADY),
    .BRESP(BRESP),
    .RAVALID(RAVALID),
    .RAREADY(RAREADY),
    .RDVALID(RDVALID),
    .RDREADY(RDREADY),
    .write_data(write_data),
    .write_address(write_address),
    .read_address(read_address),
    .out_write_data(out_write_data),
    .out_write_address(out_write_address),
    .out_read_data(out_read_data),
    .out_read_address(out_read_address),
    .m_read_data(read_data),
    //input siganl  read or write operation
    .r_w(r_w)
  );

  // Instantiating AXI Slave
  axi_slave slave (
    .clk(clk),
    .reset(reset),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),
    .Burst_size(Burst_size),
    .Burst_type(Burst_type),
    .Burst_len(Burst_len),
    .WDVALID(WDVALID),
    .WDREADY(WDREADY),
    .BVALID(BVALID),
    .BREADY(BREADY),
    .BRESP(BRESP),
    .RAVALID(RAVALID),
    .RAREADY(RAREADY),
    .RDVALID(RDVALID),
    .RDREADY(RDREADY),
    .out_write_data(out_write_data),
    .out_write_addr(out_write_address),
    .out_read_data(out_read_data),
    .out_read_addr(out_read_address),
    
    //connecting with the apb through fifo as bridge
    .s_w_r(r_w),
    .recev(w_recev),
    .apb_addr(apb_addr),
    .apb_data(apb_data),
    //read data
    .spi_read_data(out_data_from_slave)
  );
  
  
  wire w_recev;
  wire [15:0] apb_addr;
  wire [63:0] apb_data;
  wire [15:0] S1_out_w_addr,S2_out_w_addr,S3_out_w_addr;//B1_out_addr,B2_out_addr,B3_out_addr;
  wire [63:0] S1_out_w_data,S2_out_w_data,S3_out_w_data;
//   wire [31:0] B1_out_data,B2_out_data,B3_out_data;
  wire S1_R_W,S2_R_W,S3_R_W;   //B1_out_R_W,B2_out_R_W,B3_out_R_W;
  
  
  //Instatiating APB with AXI slave
  top apb(
    .clk(clk),
    .reset(reset),
    .in_data(apb_data),
    .in_addr(apb_addr),
    .write(r_w),
    .recev(w_recev),
    //bridge_1 output apb_slve_1
    .S1_out_w_addr(S1_out_w_addr),
    .S1_out_w_data(S1_out_w_data),
    .S1_R_W(S1_R_W),
    //bridge_2 output apb_slave_2
    .S2_out_w_addr(S2_out_w_addr),
    .S2_out_w_data(S2_out_w_data),
    .S2_R_W(S2_R_W),
    //bridge_3 output apb_slave_3
    .S3_out_w_addr(S3_out_w_addr),
    .S3_out_w_data(S3_out_w_data),
    .S3_R_W(S3_R_W),
    
    //read operation data
    .m_r_data_from_B(B_m_t_data),
    .out_data_from_slave(out_data_from_slave)
  );
  
  
  
  wire [7:0] B_m_t_data,out_data_from_slave;
  //connecting briges to slaves separating 
  bridge bridge3(
    .clk(clk),
    .B_in_addr(S3_out_w_addr),
    .B_in_data(S3_out_w_data),
    .B_R_W(S3_R_W),
    .get(w_get),
    .M1_out_data(M1_out_data),
    .M2_out_data(M2_out_data),
    .M3_out_data(M3_out_data),
    //spi output data to apb through bridge
    .B_m_r_bit(m_r_bit),
    .B_m_t_data(B_m_t_data)
  );
  
  
  
  wire w_get;
  wire [7:0] M1_out_data,M2_out_data,M3_out_data,m_r_bit;
  //connecting spi protocol 
  
  spi_top #(.s1max(0),.s1min(90)) spi1(
    .clk(clk),
    .s_reset(reset),
    .get(w_get),
    .data_in(M1_out_data),
    .m_r_bit(m_r_bit)
  );
  
  
  spi_top #(.s1max(91),.s1min(170)) spi2(
    .clk(clk),
    .s_reset(reset),
    .get(w_get),
    .data_in(M2_out_data),
    .m_r_bit(m_r_bit)
  );
  
  
  spi_top #(.s1max(171),.s1min(255)) spi3(
    .clk(clk),
    .s_reset(reset),
    .get(w_get),
    .data_in(M3_out_data),
    .m_r_bit(m_r_bit)
  );
  
  
endmodule

  