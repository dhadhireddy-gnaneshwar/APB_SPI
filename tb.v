`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.04.2025 14:53:14
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb(

    );
    
    reg clk=0,rst,rxd;
    wire txd;
    
    AXI_UART_IP_wrapper DUT (clk,rst,rxd,txd);
    
    always #5 clk = ~clk;
    
    initial
        begin
            rst=0;
            #30;
            rst=1;
        end
endmodule
