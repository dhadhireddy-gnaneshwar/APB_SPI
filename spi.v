module SPI_SLAVE#(parameter TX_DATA=8'hab,slave_addr=8'h51)(
  input sclk,
  input slave_mosi,
  input cs,
  input in_interupt,
  output reg slave_miso,
  output wire out_intr
);
  
  assign out_intr=intrpt?intrpt:1'bz;
  
  reg [7:0] slave_r_data_tx=TX_DATA;
  reg [7:0] slave_r_data_rx=0;
  reg [2:0] state=0;
  reg [4:0] slave_bit_count_tx=0;
  reg [4:0] slave_bit_count_rx=0;
  reg [4:0] slave_bit_count_int=0;
  reg start=0;
  reg stop=1;
  reg intrpt=0;
  
  parameter IDEAL=0,OPER=1,WRITE=2,READ=3;
  
  //sampling logic
  always@(posedge sclk &&  !intrpt)
    begin
      case(state)
        IDEAL:
          begin
            slave_miso<=1'bz;
            slave_r_data_rx<=0;
            if(cs)
              begin
                state<=OPER;
              end
            else
              begin
                state<=IDEAL;
              end
          end
        OPER:
          begin
            if(slave_mosi==0)
              begin
                state<=WRITE;
              end
            else
              begin
                state<=READ;
              end
          end
      READ:
        begin
          //sampling logic
          if(slave_bit_count_rx>8)
              begin
                stop<=1;
                start<=0;
                slave_bit_count_rx<=0;
                $display("INFO: /SPI SLAVE @%0tns slave received data=%0h",$time,slave_r_data_rx);
                state<=IDEAL;
              end
            else
              begin
                if(slave_mosi || ~slave_mosi)
                  begin
                    slave_r_data_rx[slave_bit_count_rx]<=slave_mosi;
                    slave_bit_count_rx<=slave_bit_count_rx+1;
                  end
              end
          end
      endcase
    end
  always@(negedge sclk  &&  !intrpt)
    begin
      if(state==WRITE)
        begin
          //transmission logic
          if(slave_bit_count_tx>8)
            begin
              stop<=1;
              start<=0;
              $display("INFO: /SPI SLAVE @%0tns slave written data=%0h",$time,slave_r_data_tx);
              slave_bit_count_tx<=0;
              state<=IDEAL;
            end
          else
            begin
              slave_miso<=slave_r_data_tx[slave_bit_count_tx];
              slave_bit_count_tx<=slave_bit_count_tx+1;
            end
        end
    end
  
  //interupt logic 
  always@(negedge sclk && intrpt)
    begin
      slave_r_data_tx<=slave_addr;
      if(slave_bit_count_int<=7)
        begin
          slave_miso<=slave_r_data_tx[slave_bit_count_int];
          slave_bit_count_int<=slave_bit_count_int+1;
        end
      else
        begin
          intrpt<=0;
          slave_bit_count_int<=0;
          slave_r_data_tx<=TX_DATA;
        end
    end
  
  always@(posedge in_interupt)
    begin
      intrpt<=in_interupt;
      $display("INFO: /SPI SLAVE @%0tns !!!!!!!!!!!!!!interupt found!!!!!!!!",$time,);
    end
  
  always@(cs)
    begin
      if(cs)
        begin
          start=1;
          stop=0;
        end
      else
        begin
          start=0;
          stop=1;
        end
    end
endmodule