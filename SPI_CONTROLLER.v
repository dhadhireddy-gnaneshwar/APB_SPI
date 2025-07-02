module SPI_CONTROLLER#(parameter DATA_WIDTH=7,ADDR_WIDTH=7,SLAVE_SELECT=5)(
  input clk,
  input [DATA_WIDTH:0] pwrite,
  input [ADDR_WIDTH:0] paddr,
  input MISO,
  input tx_trigger,
  input rst,
  input [2:0] tx_count,
  input in_intrupt,//inperupt  
  
  output reg ready,
  output reg MOSI,
  output reg sclk,
  output reg [DATA_WIDTH:0] read_data,
  output reg [DATA_WIDTH:0] intrupt_data=8'h00,
  output reg [SLAVE_SELECT:1] cs=0
);
  
  parameter  IDEAL=0,ADDRESS=1,IDEAL_BTW_ADDR_DATA=3,W_DATA=4,R_DATA=5;
  reg intrupt;
  reg [7:0] [7:0] addr_reg;
  reg [7:0] [7:0] data_reg;
  reg [7:0] ctrl_reg=8'h00,master_r_data_inrt=0;;
  reg [3:0] count=0,fifo=0;
  reg [1:0] clk_count=0;
  reg [2:0] state=0;
  reg [3:0] master_bit_count_int=0;
   initial
    begin
      data_reg={8{8'h00}};
      addr_reg={8{8'h00}};
      ready=1;
      sclk=1;
      read_data=0;
    end
  
  task slave_select(input reg [7:0] address, output reg [SLAVE_SELECT:1] cs);
    cs=00000;
    if(address[6:0]==8'h51)
      begin
        cs=00001;
      end
    else if(address[6:0]==7'h52)
      begin
        cs=00010;
      end
    else if(address[6:0]==7'h53)
      begin
        cs=00100;
      end
    else if(address[6:0]==7'h54)
      begin
        cs=01000;
      end
    else if(address[6:0]==7'h55)
      begin
        cs=10000;
      end
    else
      begin
        cs=0;
      end
  endtask
  
  always@(posedge clk)
    begin
      //$monitor("the contrl reg =%0d",ctrl_reg[6:4]);
      ctrl_reg[0]=tx_trigger;
      if(ctrl_reg[0])
        begin
          if(clk_count==2)
            begin
              sclk<=~sclk;
              clk_count<=0;
            end
          else
            begin
              clk_count<=clk_count+1;
            end
        end
      
      if(in_intrupt)
        begin
          intrupt=1;
        end
      else
        intrupt=0;
    end
  
  always@(negedge sclk  && ~intrupt)
    begin
      if(!rst)
        begin
          data_reg=0;
          addr_reg=0;
          ready=1;
          MOSI=1;
          sclk=0;
          read_data=0;
        end
      else
        begin
          case(state)
            IDEAL:
              begin
                ctrl_reg[0]<=tx_trigger;
                if(ctrl_reg[0])
                  begin
                    if(~ctrl_reg[7])
                      begin
                        state<=ADDRESS;
                        $display("-------------------------------------------------------------------------------");
                        ready<=0;
                      end
                    else
                      begin
                        state<=IDEAL;
                        cs<=0;
                      end
                  end
                else
                  begin
                    state<=IDEAL;
                    cs<=0;
                  end
              end
            ADDRESS:
              begin
//                 if(count>8)
//                   begin
//                     count<=0;
//                     state<=IDEAL_BTW_ADDR_DATA;
//                   end
//                 else
//                   begin
//                     MOSI<=addr_reg[ctrl_reg[6:4]][count];
//                     count<=count+1;
//                   end
                
                $display("INFO: Entered Address state...\nINFO: @ %0t checking for the valid address........",$time);
                slave_select(addr_reg[ctrl_reg[6:4]],cs);
                 MOSI<=addr_reg[ctrl_reg[6:4]][7];
                if(cs!=0)
                  begin
                    state<=IDEAL_BTW_ADDR_DATA;
                    $display("INFO: /SPI CONTROLLER @%0t Entered address is valid....proceeding to next state",$time);
                    $display("INFO: /SPI CONTROLLER the slave selected is %0d at the address %0h || the data is %0h",cs/2,addr_reg[ctrl_reg[6:4]],data_reg[ctrl_reg[6:4]]);
                  end
                else
                  begin
                    state<=IDEAL;
                    $display("INFO: /SPI CONTROLLER @%0t Entered address is NOT a valid....Terminating the transmission",$time);
                  end
              end
            
            IDEAL_BTW_ADDR_DATA:
              begin
               
                if(addr_reg[ctrl_reg[6:4]][7])
                  begin
                    state<=W_DATA;
                    $display("INFO: /SPI CONTROLLER @%0t starting Write Operation.....",$time);
                  end
                else
                  begin
                    $display("INFO: /SPI CONTROLLER @%0t starting Read Operation.....",$time);
                    state<=R_DATA;
                  end
              end
            
            W_DATA:
              begin
                if(count<=7)
                  begin
                    if(MOSI || ~MOSI)
                      begin
                        MOSI<=data_reg[ctrl_reg[6:4]][count];
                        count<=count+1;
                        $display("INFO: /SPI CONTROLLER @%0t writing the %0d bit data %0b",$time,count,data_reg[ctrl_reg[6:4]][count]);
                      end
                  end
                else
                  begin
                     count<=0;
                    ready<=1;
                    ctrl_reg[6:4]=ctrl_reg[6:4]+1;
                    if(ctrl_reg[3:1]!=0)
                      ctrl_reg[3:1]=ctrl_reg[3:1]-1;
                    state<=IDEAL;
                    cs<=0;
                    if(ctrl_reg[3:1]==0)
                      begin
                        ctrl_reg[7]<=1;
                        $display("INFO: /SPI CONTROLLER @%0t All transactions are completed Successfully.....",$time);
                      end
                    else
                      begin
                        $display("INFO: /SPI CONTROLLER @%0t %0d transactions are completed going for the next transaction || remaining transactions are %0d.....",$time,ctrl_reg[6:4],ctrl_reg[3:1]);
                      end
                  end
              end
          endcase
        end
    end
  always@(posedge sclk && ~intrupt)
    begin
      if(state==R_DATA)
        begin
          if(count<=7)
            begin
              if(MISO || ~MISO)
                begin
                  ready<=1;
                  data_reg[ctrl_reg[6:4]][count]<=MISO;
                  count<=count+1;
                  $display("INFO: /SPI CONTROLLER @%0t READING the %0d bit data %0b",$time,count,MISO);
                end
            end
          else
            begin
              read_data<=data_reg[ctrl_reg[6:4]];
              count<=0;
              ctrl_reg[6:4]=ctrl_reg[6:4]+1;
              if(ctrl_reg[3:1]!=0)
                ctrl_reg[3:1]=ctrl_reg[3:1]-1;
              state<=IDEAL;
              cs<=0;
              if(ctrl_reg[3:1]==0)
                begin
                  ctrl_reg[7]<=1;
                  $display("INFO: /SPI CONTROLLER @%0t All transactions are completed Successfully.....",$time);
                end
              else
                begin
                  $display("INFO: /SPI CONTROLLER @%0t %0d transactions are completed going for the next transaction || remaining transactions are %0d.....",$time,ctrl_reg[6:4],ctrl_reg[3:1]);
                end
            end
        end
    end
  
  //interupt logic
  always@(posedge sclk && intrupt)
    begin
      
      if(master_bit_count_int<=7 && master_bit_count_int>=1)
        begin
          master_r_data_inrt[master_bit_count_int-1]=MISO;
          master_bit_count_int=master_bit_count_int+1;
        end
      else if(master_bit_count_int<1)
        master_bit_count_int<=master_bit_count_int+1;
      else
        begin
          master_bit_count_int=0;
          intrupt_data=master_r_data_inrt;
        end
    end
  
//   always@(tx_trigger or tx_count)
//     begin
  always@(pwrite or paddr)
    begin
      if(fifo<=7 && paddr>0)
        begin
          data_reg[fifo]<=pwrite;
          addr_reg[fifo]<=paddr;
          fifo=fifo+1;
        end
    end
  
  always@(tx_count)
    begin
      ctrl_reg[3:1]<=tx_count;
      ctrl_reg[7]=0;
    end
endmodule