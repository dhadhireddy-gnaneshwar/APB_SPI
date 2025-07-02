 module axi_slave(
  input clk,
  input reset,
  //address write channel
  input AWVALID,
  input [2:0] Burst_size,
  input [1:0] Burst_type,
  input [1:0] Burst_len,
  output reg AWREADY=1,
  input [63:0] out_write_addr,
  //write data channel
  input WDVALID,
  output reg WDREADY=1,
  input [127:0] out_write_data,
  //response channel
  input BVALID,
  output reg BREADY=1,
  output reg BRESP=0,
  //read address channel
  input RAVALID,
  output reg RAREADY=1,
  input [63:0] out_read_addr,
  //read data channel
  input RDREADY,
  output reg RDVALID=1,
  output reg [127:0] out_read_data,
   
  //apb output pins
   input s_w_r,
   input recev,
   output reg [15:0] apb_addr,
   output reg [63:0] apb_data,
   //read data from slave
   input reg [7:0] spi_read_data
 );
  
  
  parameter WA_READY=2'b00,WA_ADDR=2'b10,WA_DONE=2'b11;//write address channel parameter's
  parameter WD_READY=2'b00,WD_DATA=2'b01,WD_DONE=2'b11;//write data channel parameter's
  parameter RES_READY=2'b00,RES_DONE=2'b11;//responce channel parameter's
  parameter RA_READY=2'b00,RA_ADDR=2'b10,RA_DONE=2'b11;//read address channel parameter's
  parameter RD_VALID=2'b00,RD_DATA=2'b01,RD_DONE=2'b11;//read DATA channel parameter's
  
  
  reg [2:0] AW_pres_state=WA_READY , AW_next_state=WA_READY;//write address channel state's
  reg [2:0] WD_pres_state=WD_READY , WD_next_state=WD_READY;//write data channel state's
  reg [2:0] B_pres_state=RES_READY , B_next_state=RES_READY;//responce channel state's
  reg [2:0] RA_pres_state=RA_READY , RA_next_state=RA_READY;//read address channel state's
  reg [2:0] RD_pres_state=RD_VALID , RD_next_state=RD_VALID;//read data channel state's
  
  
  reg [63:0] w_addr=0,r_addr;
  reg [127:0] w_data,r_data;
  
  //fifo registers
  reg [63:0] fifo [0:31];
  reg [4:0] fifo_write=0,fifo_read=0,fifo_count=0;
  reg fifo_full=0,fifo_empty=1;
  reg [63:0] next_addr;
  
  always@(posedge clk)
    begin
      if(~reset)
        begin
          AWREADY=0;
          WDREADY=0;
          BREADY=0;
          RAREADY=0;
          RDVALID=0;
        end
    end

  
  //write address channel state's
  always@(posedge clk)
    begin
      case(AW_pres_state)
        WA_READY:
          begin
            if(reset && AWVALID)
              begin
                AWREADY=1;
                AW_next_state=WA_ADDR;
              end
          end
        
        WA_ADDR:
          begin
            if(AWVALID && AWREADY)
              begin
                w_addr=out_write_addr;// Start storing at the current address
                AW_next_state=WA_DONE;
              end
            else
              AW_next_state=WA_READY;
          end
        
        WA_DONE:
          begin
            AWREADY=0;
            AW_next_state=WA_READY;
          end
      endcase
      AW_pres_state=AW_next_state;
    end

   
  //WRITE data channel state's
  always@(posedge clk)
    begin
      case(WD_pres_state)
        WD_READY:
          begin
            if(reset && WDVALID)
              begin
                WDREADY=1;
                WD_next_state=WD_DATA;
              end
            else
              WD_next_state=WD_READY;
          end
        
        WD_DATA:
          begin
            if (WDREADY && WDVALID)
              begin
                w_data = out_write_data;//stroing the data into a register
                WD_next_state = WD_DONE;
              end
            else
              WD_next_state = WD_READY;
          end

        WD_DONE:
          begin
            WDREADY = 0;
            WD_next_state = WD_READY;
          end
        endcase
        WD_pres_state = WD_next_state;
      end
  
  //responce channel state's
  always@(posedge clk)
    begin
      case(B_pres_state)
        RES_READY:
          begin
            if(reset && BVALID)
              begin
                BREADY=1;
                B_next_state=RES_DONE;
              end
            else
              BREADY=0;
          end
        
         RES_DONE:
           begin
             if(BVALID && BREADY)
               begin
                 BRESP=1;
                 B_next_state=RES_READY;
               end
             else
               BRESP=0;
           end
      endcase
      B_pres_state=B_next_state;
    end
  
  //read address channel state's
  always@(posedge clk)
    begin
      case(RA_pres_state)
        RA_READY:
          begin
            if(reset && RAVALID)
              begin
                RAREADY=1;
                RA_next_state=RA_ADDR;
              end
            else
              RAREADY=0;
          end
        
        RA_ADDR:
          begin
            if(RAVALID && RAREADY)
              begin
                r_addr=out_read_addr;
                RA_next_state=RA_DONE;
              end
            else
              RA_next_state=RA_READY;
          end
        
        RA_DONE:
          begin
            RAREADY=0;
            RA_next_state=RA_READY;
          end
      endcase
      RA_pres_state=RA_next_state;
    end

  
 //read data channel state's
  always@(posedge clk)
    begin
      case(RD_pres_state)
        RD_VALID:
          begin
            if(reset)
              begin
                RDVALID=1;
                out_read_data=spi_read_data;
                RD_next_state=RD_DATA;
              end
          end
        
        RD_DATA:
          begin
            if(RDVALID && RDREADY)
              begin
                RD_next_state=RD_DONE;
              end
            else
              RD_next_state=RD_VALID;
          end
        
        RD_DONE:
          begin
            RDVALID=0;
            RD_next_state=RD_VALID;
          end
      endcase
      RD_pres_state=RD_next_state;
    end
   
  //storing in fifo
   
  reg [63:0] s_w_addr;
  reg [127:0] last_s_data=0;
  reg [2:0] burst_count=0;
  
  
  parameter t_ideal=2'b00, FIXED=2'b01, INCR=2'b10, WRAP=2'b11;
  reg [1:0] t_pres_state=t_ideal,t_next_state=t_ideal;
   
   
   //DATA STROING IN FIFO AND BURST FEATURE ALSO
   always@(posedge clk)
     begin
        case (t_pres_state)
          t_ideal:
            begin
              s_w_addr=w_addr;
              if (fifo_count < 26 && w_addr != 0)
                begin
                  case (Burst_type)
                    2'b00: t_next_state = FIXED;
                    2'b01: t_next_state = INCR;
                    2'b10: t_next_state = WRAP;
                  endcase
                end
              else
                begin
                  fifo_count=0;
                end
            end

          FIXED:
            begin
              if (WDVALID && WDREADY && burst_count <= Burst_len)
                begin
                  if(last_s_data != w_data && fifo_write <30)
                    begin
//                       $display("w_addr: %h", s_w_addr);
                      fifo[fifo_write] = s_w_addr[31:0]; // Store the address in FIFO
                      fifo_write = fifo_write + 1;
                      fifo_count = fifo_count + 1;

                      fifo[fifo_write] = w_data[63:0];
                      fifo_write = fifo_write + 1;
//                       $display("Time=%0t, burst_count=%d, w_data=%h", $time, burst_count, w_data);
//                       $display("fifo_count=%h",fifo_count);  

                      fifo[fifo_write] = w_data[127:64];
                      fifo_write = fifo_write + 1;

                      burst_count = burst_count + 1;
                      fifo_count = fifo_count + 2;
                      
                      last_s_data=w_data;
                    end
                  else
                    begin
                      fifo_write=0;
                    end
                end
//                 for(int i =0;i<=15;i=i+1)
//                 begin
//                   $display("addr=%h,data=%0h",w_addr,fifo[i]);
//                 end
            end

          INCR:
            begin
              if (last_s_data != w_data && WDVALID && WDREADY && fifo_write < 30)
                begin
                  fifo[fifo_write] = s_w_addr[31:0]; // Store the address in FIFO
                  fifo_write = fifo_write + 1;
                  fifo_count = fifo_count + 1;

//                   $display("Burst Count: %0d, Address: %h, Data: %h", burst_count, s_w_addr, w_data);

                  fifo[fifo_write] = w_data[63:0];
                  fifo_write = fifo_write + 1;

                  fifo[fifo_write] = w_data[127:64];
                  fifo_write = fifo_write + 1;

                  burst_count = burst_count + 1;
                  fifo_count = fifo_count + 2;

                  last_s_data = w_data;
                  s_w_addr = s_w_addr + (1 << Burst_size);
//                   $display("fifo_count=%h",fifo_count);  

//                   $display("After Update - Burst Count: %0d, Address: %h", burst_count, s_w_addr);
                      
//                   for(int i =0;i<=15;i=i+1)
//                   begin
//                     $display("addr=%h,data=%0h",w_addr,fifo[i]);
//                   end 
                end
            end

          WRAP:
            begin
              if (last_s_data != w_data && WDVALID && WDREADY)
                begin
                  fifo[fifo_write] = s_w_addr[31:0]; // Store the address in FIFO
                   
                  fifo_count = fifo_count + 1;

//                   $display("Burst Count: %0d, Address: %h, Data: %h", burst_count, s_w_addr, w_data);

                  fifo[fifo_write] = w_data[63:0];
                  fifo_write = fifo_write + 1;

                  fifo[fifo_write] = w_data[127:64];
                  fifo_write = fifo_write + 1;

                  burst_count = burst_count + 1;
                  fifo_count = fifo_count + 4;

                  last_s_data = w_data;
                  if (burst_count <= Burst_len)
                    begin
                        s_w_addr = (s_w_addr & ~(Burst_len << Burst_size)) | ((s_w_addr + (1 << Burst_size)) & (Burst_len << Burst_size));
                    end
                  else
                    begin
                        s_w_addr = s_w_addr + (1 << Burst_size);
                    end
//                   $display("After Update - Burst Count: %0d, Address: %h", burst_count, s_w_addr);
                  
//                   for(int i =0;i<=15;i=i+1)
//                   begin
//                     $display("addr=%h,data=%0h",w_addr,fifo[i]);
//                   end
                end
            end
        endcase
        t_pres_state = t_next_state;
      end
   
  
   
  //here connecting with AXI and APB and this will be also BRIDGE part
  //send the fifo stored data to the APB for the write operation
    
  reg [2:0] q_pres_state=3'b111,q_next_state=3'b111;
  reg fifo_send=0;
  reg [31:0] store_data,store_addr;
  
  
  parameter IDEAL=3'b111,Q_ADDR=3'b000,WAIT_APB_RES_1=3'b001,Q_DATA_1=3'b011,WAIT_APB_RES_2=3'b100;
  
   always@(posedge clk)
        begin
//           $display("Current State: %s, FIFO Count: %d", q_next_state, fifo_count);
          case(q_pres_state)
            IDEAL:
              begin
                if(fifo_count > 0 & s_w_r==0)
                begin
                  fifo_read=0;
                  fifo_send=0;
                  q_next_state=Q_ADDR;
                end
                else
                  q_next_state=IDEAL;
              end
            
            Q_ADDR:
              begin
                if(fifo_count >0 & s_w_r==0 & fifo_read < 30)
                begin
                  if(recev==0) 
                    begin
                      apb_addr=fifo[fifo_read];
                      fifo_read=fifo_read+1;
                      apb_data=fifo[fifo_read];
                      fifo_read=fifo_read+1;
                      fifo_count=fifo_count-2;
                      fifo_send=1;
                      q_next_state=WAIT_APB_RES_1;
                    end
                  else
                    q_next_state=Q_ADDR;
                end
                else
                  q_next_state=IDEAL;
              end
            
            WAIT_APB_RES_1:
              begin
                if(recev==1)
                  begin
                    q_next_state=WAIT_APB_RES_1;
                  end
                else
                  q_next_state=Q_DATA_1;
              end
            
            
            Q_DATA_1:
              begin
                if(recev==0)
                  begin
                    apb_data=fifo[fifo_read];
                    fifo_read=fifo_read+1;
                    fifo_count=fifo_count-1;
                    fifo_send=1;
                    q_next_state=WAIT_APB_RES_2;
                  end
                else
                  begin
                    q_next_state=Q_DATA_1;
                  end
              end
            
            WAIT_APB_RES_2:
              begin
                if(recev==1)
                  begin
                    q_next_state=Q_ADDR;
                  end
                else
                  q_next_state=WAIT_APB_RES_2;
              end
          endcase
          q_pres_state=q_next_state;
        end
   
endmodule


