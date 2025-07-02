module top(
  input clk,
  input [63:0] in_data,
  input [15:0] in_addr,//32-bit not abel to check the range 
  input reset,
  input write,
  output reg recev,
  output reg [15:0] S1_out_w_addr,
  output reg [63:0] S1_out_w_data,
  output reg S1_R_W,
  output reg [15:0] S2_out_w_addr,
  output reg [63:0] S2_out_w_data,
  output reg S2_R_W,
  output reg [15:0] S3_out_w_addr,
  output reg [63:0] S3_out_w_data,
  output reg S3_R_W,
  //input read data from slave
  input [7:0] m_r_data_from_B,
  output reg [15:0] out_data_from_slave
);
  
  wire w_enabel,w_write;
  wire [2:0] w_select,out_ready;
  wire [15:0] w_addr;
  wire [63:0] w_data,w_read;
  

  
  APB_master master (.clk(clk),.addr(in_addr),.data(in_data),.reset(reset),.write(write),.ss_write(w_write),.ready(out_ready),.enabel(w_enabel),.out_select(w_select),.out_addr(w_addr),.write_data(w_data),.read(w_read),.m_recev(recev),.out_read_data(out_data_from_slave));
  
  
  APB_slave #(.ss1min(0),.ss1max(21845)) slave_1 (.clk(clk),.s_addr(w_addr),.write_data(w_data),.enabel(w_enabel),.out_select(w_select[0]),.in_write(w_write),.ready(out_ready[0]),.read(w_read),.out_w_addr(S1_out_w_addr),.out_w_data(S1_out_w_data),.R_W(S1_R_W),.m_r_bit_s(m_r_data_from_B));
  
  
  APB_slave #(.ss1min(21846),.ss1max(43690)) slave_2 (.clk(clk),.s_addr(w_addr),.write_data(w_data),.enabel(w_enabel),.out_select(w_select[1]),.in_write(w_write),.ready(out_ready[1]),.read(w_read),.out_w_addr(S2_out_w_addr),.out_w_data(S2_out_w_data),.R_W(S2_R_W),.m_r_bit_s(m_r_data_from_B));
  
  
  APB_slave #(.ss1min(43691),.ss1max(65535)) slave_3 (.clk(clk),.s_addr(w_addr),.write_data(w_data),.enabel(w_enabel),.out_select(w_select[2]),.in_write(w_write),.ready(out_ready[2]),.read(w_read),.out_w_addr(S3_out_w_addr),.out_w_data(S3_out_w_data),.R_W(S3_R_W),.m_r_bit_s(m_r_data_from_B));
  
  
endmodule


// Code your design here
module APB_master (
  input clk,
  input [15:0] addr,
  input [63:0] data,
  input [15:0] read,
  input [2:0] ready,
  input write,
  input reset,
  output reg m_recev=0,
  output reg ss_write,
  output reg enabel,
  output reg [2:0] out_select,
  output reg [15:0] out_addr,
  output reg [63:0] write_data,
  output reg [15:0] out_read_data
);
  
  parameter s0=2'b00,s1=2'b01,s2=2'b10;
  
  reg [1:0] pres_state,next_state;
//   reg [15:0] r_addr;
  reg select=0;
  
  always@(write)
    ss_write=write;
  
//   always@(addr)
//     r_addr=addr;
  
  reg [2:0] ss1=3'b001,ss2=3'b010,ss3=3'b100;
  
  parameter ss1min=16'h0000;//0
  parameter ss1max=16'h5555;//21845
  parameter ss2min=16'h5556;//21846
  parameter ss2max=16'hAAAA;//43690
  parameter ss3min=16'hAAAB;//43691
  parameter ss3max=16'hFFFF;//65535

  
  
  initial begin
    enabel=0;
    pres_state=s0;
  end
  
  
  always@(posedge  clk)
    begin
      if(reset==1)begin

        if(addr>=8'h00 && addr<=ss1max) 
          begin
            out_select=ss1;
            select=1;
            m_recev=1;
//             $display("Address found in slave_1");
          end
        else if(addr>=ss2min && addr<=ss2max)
          begin
            out_select=ss2;
            select=1;
            m_recev=1;
//             $display("Address found in slave_2");
          end
        else if (addr>=ss3min && addr<=ss3max)
          begin
            out_select=ss3;
            select=1;
            m_recev=1;
//             $display("Address found in slave_3");
          end
        else
          begin
            select=0;
//             $display("Address NOT found in any slave");
          end
        
        case(pres_state)
          s0:
            begin
              if(select==1)
                next_state=s1;
              else
                begin
                  next_state=s0;
//                   out_addr=0;
//                   write_data=0;
                  enabel=0;
                end
            end
          
          s1:
            begin
              if(select==1 && enabel==1)begin
                next_state=s2;
                write_data=data;
                out_addr=addr;
//                 $display("write addr:%h",addr);
//                 $display("write data:%h",data);
              end
              else
                begin
                  enabel=1;
                  next_state=s1;
                end
            end
          
          s2:
            begin
              if(ready!=0)begin
                next_state=s0;
                m_recev=0;
                select=0;
                out_read_data=read;
              end
              else
                next_state=s2;
            end
        endcase
        pres_state=next_state;
      end
    end
endmodule


module APB_slave#(parameter ss1min,ss1max)(
  input clk,
  input [15:0] s_addr,
  input [63:0] write_data,
  input enabel,
  input out_select,
  input in_write,
  output reg ready,
  output reg [15:0] read,
  output reg [15:0] out_w_addr,
  output reg [63:0] out_w_data,
  output reg R_W,
  input [7:0] m_r_bit_s
);
  
//   reg [15:0] out_w_addr;
//   reg [63:0] out_w_data;
  
  
  always@(posedge clk)
    begin
      R_W=in_write;
      if (out_select==1 && enabel==1)begin
        ready=1;
        if (in_write==0)
          begin
            out_w_addr=s_addr;
            out_w_data=write_data;
            R_W=in_write;
//             read=32'b0;
//             $display("write addr:%h",out_w_addr);
//             $display("write data:%h",out_w_data);
//             $display("write operation=%h",in_write);
          end
        else
          begin
            read=m_r_bit_s;
//             $display("read data=%h",read);
          end       
      end
      else
        begin
          ready=0;
          read=32'bz;
        end
    end
           
endmodule


   

