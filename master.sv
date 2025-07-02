 module axi_master(
  input clk,
  input reset,
  //address write channel
  output reg AWVALID=1,
  input AWREADY,
  input [2:0] Burst_size,
  input [1:0] Burst_type,
  input [1:0] Burst_len,
  input [63:0] write_address,//user sending address for write
  //write data channel
  output reg WDVALID=1, 
  input WDREADY,
  input [127:0] write_data,//user sending data for write 
  //response channel 
  output reg BVALID=1,
  input BREADY,
  input BRESP,
  //read address channel
  output reg RAVALID=1,
  input RAREADY,
  input [63:0] read_address,,//user sending address for read 
  //read data channel
  output reg  RDREADY=1,
  input RDVALID,
  input [127:0] out_read_data,// receving data from slave
  output [127:0] m_read_data,//transiting out the receved data fromm slave
  
  //transmiting the data and output port for master and input port's for slave
  output reg [127:0] out_write_data,
  output reg [63:0] out_write_address,
  output reg [63:0] out_read_address,
  
//   read or write the data signal
  input r_w
);
  
  reg [127:0] read_data=0;
  
  parameter WA_VALID=2'b00,WA_ADDR=2'b10,WA_DONE=2'b11;//write address channel parameter's
  parameter WD_VALID=2'b00,WD_DATA=2'b01,WD_DONE=2'b11;//write data channel parameter's
  parameter RES_VALID=2'b00,RES_DONE=2'b11;//responce channel parameter's
  parameter RA_VALID=2'b00,RA_ADDR=2'b10,RA_DONE=2'b11;//read address channel parameter's
  parameter RD_READY=2'b00,RD_DATA=2'b01,RD_DONE=2'b11;//read DATA channel parameter's
  
  
  reg [2:0] AW_pres_state=WA_VALID , AW_next_state=WA_VALID;//write address channel state's
  reg [2:0] WD_pres_state=WD_VALID , WD_next_state=WD_VALID;//write data channel state's
  reg [2:0] B_pres_state=RES_VALID , B_next_state=RES_VALID;//responce channel state's
  reg [2:0] RA_pres_state=RA_VALID , RA_next_state=RA_VALID;//read address channel state's
  reg [2:0] RD_pres_state=RD_READY , RD_next_state=RD_READY;//read data channel state's
  
  
  always@(posedge clk)
    begin
      if(~reset)
        begin
          AWVALID=0;
          WDVALID=0;
          BVALID=0;
          RAVALID=0;
          RDREADY=0;
        end
    end
  
  //write address channel state's
  always@(posedge clk)
    begin
      case(AW_pres_state)
        WA_VALID:
          begin
            if(reset) 
              begin
                AWVALID=1;
                out_write_address=write_address;
                AW_next_state=WA_ADDR;
              end
            else
              AWVALID=0;
          end
        
        WA_ADDR:
          begin
            if(AWVALID && AWREADY)
              begin
                AW_next_state=WA_DONE;//for handishaking checking state
              end
            else
              AW_next_state=WA_VALID;
          end
        
        WA_DONE:
          begin
            AWVALID=0;
            AW_next_state=WA_VALID;
          end
      endcase
      AW_pres_state=AW_next_state;
    end
  
  //write data channel state's
  always@(posedge clk)
    begin
      case(WD_pres_state)
        WD_VALID:
          begin
            if(reset) 
              begin
                WDVALID=1;
                out_write_data=write_data;
                WD_next_state=WD_DATA;
              end
            else
              WDVALID=0;
          end
        
        WD_DATA:
          begin
            if(WDVALID && WDREADY)
              begin
                WD_next_state=WD_DONE;
              end
            else
              WD_next_state=WD_VALID;
          end
        
        WD_DONE:
          begin
            WDVALID=0;
            WD_next_state=WD_VALID;
          end
      endcase
      WD_pres_state=WD_next_state;
    end
  
  //RESPONCE channel state's
  always@(posedge clk)
    begin
      case(B_pres_state)
        RES_VALID:
          begin
            if(reset)
              begin
                BVALID=1;
                B_next_state=RES_DONE;
              end
            else
              BVALID=0;
          end
        
        RES_DONE:begin
          if(BVALID && BREADY && BRESP)
            begin
              BVALID=0;
              B_next_state=RES_VALID;
            end
        end
      endcase
      B_pres_state=B_next_state;
    end
  
 //READ ADDRESS CHANNELstate's
  always@(posedge clk)
    begin
      case(RA_pres_state)
        RA_VALID:
          begin
            if(reset) 
              begin
                RAVALID=1;
                out_read_address=read_address;
                RA_next_state=RA_ADDR;
              end
            else
              RAVALID=0;
          end
        
        RA_ADDR:
          begin
            if(RAVALID && RAREADY)
              begin
                RA_next_state=RA_DONE;
              end
            else
              RA_next_state=RA_VALID;
          end
        
        RA_DONE:
          begin
            RAVALID=0;
            RA_next_state=RA_VALID;
          end
      endcase
      RA_pres_state=RA_next_state;
    end
  
  
   //read data channel state's
  always@(posedge clk)
    begin
      case(RD_pres_state)
        RD_READY:
          begin
            if(reset && RDVALID) 
              begin
                RDREADY=1;
                RD_next_state=RD_DATA;
              end
            else
              RDREADY=0;
          end
        
        RD_DATA:
          begin
            if(RDVALID && RDREADY)
              begin
                read_data=out_read_data;
                RD_next_state=RD_DONE;
              end
            else
              RD_next_state=RD_READY;
          end
        
        RD_DONE:
          begin
            RDREADY=0;
            RD_next_state=RD_READY;
          end
      endcase
      RD_pres_state=RD_next_state;
    end
  
  assign m_read_data = read_data;
  
endmodule
           