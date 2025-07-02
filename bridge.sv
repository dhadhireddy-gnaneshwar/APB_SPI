module bridge(
  input clk,
  input [15:0] B_in_addr,
  input [63:0] B_in_data,
  input B_R_W,
  input get,//signal from spi for bridge handling 
  
  output reg [7:0] M1_out_data,
  output reg [7:0] M2_out_data,
  output reg [7:0] M3_out_data,
  
  //input port for bridge and ouput data by spi
  input [7:0] B_m_r_bit,
  output reg [7:0] B_m_t_data
);
  
  
  reg [7:0] FIFO [40:0];
  reg [5:0] w_count=0,r_count=0,f_count=0;
  
  reg [15:0] last_addr=0,store_addr;
  reg [63:0] last_data=0,store_data;
  
  parameter ideal=2'b00,s_fifo=2'b01;
  
  reg [1:0] p_state=ideal,n_state=ideal;
  
  
  parameter s1min=8'b00000000;//0
  parameter s1max=8'b01011010;//90
  parameter s2min=8'b01011011;//91
  parameter s2max=8'b10101010;//170
  parameter s3min=8'b10101011;//171
  parameter s3max=8'b11111111;//255
  
  
  
  always@(posedge clk)
    begin
      case(p_state)
        ideal:
          begin
            if(B_in_addr >= 16'h0000 && B_in_addr <= 16'hffff)
              begin
                n_state=s_fifo;
              end
            else
              n_state=ideal;
          end
        
        s_fifo:
          begin
            if(B_R_W==0)
            begin
              if(f_count < 35 & w_count < 35)
                begin
                  store_addr=B_in_addr;
                  store_data=B_in_data;
                  if(last_addr!=B_in_addr || last_data!=B_in_data)
                    begin
                      FIFO[w_count]=store_addr[7:0];
                      w_count=w_count+1;
                      FIFO[w_count]=store_data[7:0];
                      w_count=w_count+1;
                      f_count=f_count+2;
                      last_addr=store_addr;
                      last_data=store_data;
                      n_state=ideal;
                    end
                  else
                    begin
                      n_state=s_fifo;
                    end
                end
  //                 for(int i =0;i<=10;i=i+1)
  //                     begin
  //                       $display("addr=%h,data=%0h",store_addr,FIFO[i]);
  //                     end
              else
                begin
                  f_count=0;
                  w_count=0;
                end
            end
          end
      endcase
      p_state<=n_state;
    end
  
  
  parameter IDEAL=3'b000,ADDR=3'b001,spi1=3'b010,spi2=3'b011,spi3=3'b100,wait1=3'b101;
//   parameter data1=3'b000,wait1=3'b001,data2=3'b010,wait2=011,data3=3'b100,wait3=101,data4=3'b110;
  
  reg [2:0] pres_s=IDEAL,next_s=IDEAL;
//   reg [2:0] p_n=data1,n_s=data1;
  
  reg [7:0] address;
//   reg [7:0] data;
  
  always@(posedge clk)
    begin
      case(pres_s)
        IDEAL:
          begin
            if(f_count > 0 & B_R_W==0)
              begin
                r_count=0;
                next_s=ADDR;
              end
            else
              next_s=IDEAL;
          end
        
        ADDR:
          begin
            if(f_count >0 & B_R_W==0)
              begin
                address=FIFO[r_count];
                f_count=f_count-1;
                r_count=r_count+1;
                if(address>=8'h00 && address<=s1max)
                  begin
                    next_s=spi1;
                  end
                else if(address>=s2min && address<=s2max)
                  begin
                    next_s=spi2;
                  end
                else if(address>=s3min && address<=s3max)
                  begin
                    next_s=spi3;
                  end
                else
                  next_s=ADDR;
              end
            else
              next_s=IDEAL;
          end
        
        
        spi1:
          begin
            if(get==1)
              begin
                M1_out_data=FIFO[r_count];
                r_count=r_count+1;
                f_count=f_count-1;
                next_s=wait1;
              end
            else
              begin
                next_s=spi1;
              end
          end
        
        spi2:
          begin
            if(get==1)
              begin
                M2_out_data=FIFO[r_count];
                r_count=r_count+1;
                f_count=f_count-1;
                next_s=wait1;
              end
            else
              begin
                next_s=spi2;
              end
          end
        
        spi3:
          begin
            if(get==1)
              begin
                M3_out_data=FIFO[r_count];
                r_count=r_count+1;
                f_count=f_count-1;
                next_s=wait1;
              end
            else
              begin
                next_s=spi3;
              end
          end
        
        wait1:
          begin
            if(get==0)
              next_s=ADDR;
            else
              next_s=wait1;
          end
      endcase
      pres_s<=next_s;
    end
  
  always@(posedge clk)
    begin
      if(B_R_W==1)
        B_m_t_data=B_m_r_bit;
      else
        B_m_t_data=0;
    end
  
endmodule

        
      