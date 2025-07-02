// Code your design here
// Code your design here
module spi_top#(parameter s1min,s1max)(
  input [7:0] data_in,
  input s_reset,
  input clk,
  output reg get,
  output reg [7:0] m_r_bit
);
  
  wire cs,seq_clk,mosi,miso;
//   reg [7:0] r_data_in;
//   reg r_c_phase,r_c_polarity,w_c_phas,w_c_pol;
  
  Spi_master master(.cs(cs),.seq_clk(seq_clk),.clk(clk),.data_in(data_in),.mosi(mosi),.miso(miso),.get(get),.m_r_bit(m_r_bit),.reset(s_reset));
  
  
  Spi_slave slave (.cs(cs),.seq_clk(seq_clk),.miso(miso),.mosi(mosi));
  
  
endmodule

// Code your design here
module Spi_master(
  input clk,
  input reset,
  input miso,
  input [7:0] data_in,
  output reg get=1,
  output reg cs=1,
  output reg seq_clk=0,
  output reg mosi,
  output reg [7:0] m_r_bit
);  
  
  parameter ideal=2'b00,mode=2'b01;
  parameter clk_cyc_bit=2;
  
  reg [1:0] p_state=ideal,n_state=ideal;
  
  reg [2:0] count_r=0;
  reg [4:0] count_tx=0,count_rx=0;
  
  reg [7:0] m_t_bit=0;
  

  
  
  always@(posedge clk)
    begin
      if(reset)
        begin
          if(count_r==(clk_cyc_bit/2))
            begin
              seq_clk=~seq_clk;
              count_r=0;
            end
          else
            count_r=count_r+1;
        end
      else
        seq_clk=0;
    end
  

  
  //data transfor(MOSI) in modes at posedge in clock cycle 
  
  always@(posedge seq_clk)
    begin
      case(p_state)
        ideal:
          begin
            m_t_bit=data_in;
            cs=0;
            get=0;
            n_state=mode;
          end
        
        mode:
          begin
            if(count_rx<=7)
              begin
                m_r_bit[count_rx]=miso;
                count_rx=count_rx+1;
              end
            else
              begin
                count_rx=0;
                m_r_bit=0;
                cs=1;
                n_state=ideal;
                get=1;
              end
          end
        endcase
      p_state=n_state;
    end
  
  //data read(MISO) in modes at negedge in clock cycle
  
  parameter n_ideal=2'b00,n_mode=2'b01;
  
  reg [1:0] pres_state=n_ideal,next_state=n_ideal;
  
  always@(negedge seq_clk)
    begin
      case(pres_state)
        n_ideal:
          begin
            next_state=n_mode;
            get=0;
          end
        
        n_mode:
          begin
            if(count_tx<=7)
              begin
                mosi=m_t_bit[count_tx];
                count_tx=count_tx+1;
              end
            else
              begin
                count_tx=0;
                get=1;
              end
          end
      endcase
      pres_state=next_state;
    end
endmodule

// Code your design here
module Spi_slave(
  input cs,mosi,seq_clk,
  output reg miso);
  
  parameter ideal=2'b00,mode=2'b01;
  
  reg [1:0] p_s=ideal,n_s=ideal;
  
  reg [3:0] count_tx=0,count_rx=0;
  
  reg [7:0] s_t_bit=16'b1011101110101100;
  reg [7:0] s_r_bit=0;
  
  //data  read(MOSI) in modes at posedge in clock cycle 
  
  always@(posedge seq_clk)
    begin
      case(p_s)
        ideal:
          begin
            n_s=mode;
          end
        
        mode:
          begin
            if(count_rx<=7)
              begin
                s_r_bit[count_rx]<=mosi;
                count_rx<=count_rx+1;
              end
            else
              begin
                count_rx=0;
                s_r_bit=0;
                n_s=ideal;
              end
          end
      endcase
      p_s=n_s;
    end
  

  //data transfer(MISO) in modes at negedge in clock cycle
  
  
  parameter n_ideal=2'b00,n_mode=2'b01;
  
  reg [1:0] pres_s=ideal,next_s=ideal;
  
  always@(negedge seq_clk)
    begin
      case(pres_s)
        ideal:
          begin
            next_s=n_mode;
          end
        
        n_mode:
          begin
            if(count_tx<=7)
              begin
                miso=s_t_bit[count_tx];
                count_tx=count_tx+1;
              end
            else
              begin
                count_tx=0;
//                 s_t_bit=0;
                next_s=ideal;
              end
          end
      endcase
      pres_s=next_s;
    end
  
endmodule

