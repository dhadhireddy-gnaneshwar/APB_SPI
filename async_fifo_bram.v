`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2025 09:51:16
// Design Name: 
// Module Name: FIFO_2
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


module async_fifo_bram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 9,
    parameter DEPTH = 1 << ADDR_WIDTH
)(
    input  wire                  wr_clk,
    input  wire                  wr_rst,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  full,

    input  wire                  rd_clk,
    input  wire                  rd_rst,
    input  wire                  rd_en,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire                  empty
);

    // Internal pointers
    reg  [ADDR_WIDTH:0] wr_ptr_bin, rd_ptr_bin;
    reg  [ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg  [ADDR_WIDTH:0] wr_ptr_gray_rdclk, rd_ptr_gray_wrclk;

    // Pointer synchronization
    reg  [ADDR_WIDTH:0] rd_ptr_gray_wrclk_d1, rd_ptr_gray_wrclk_d2;
    reg  [ADDR_WIDTH:0] wr_ptr_gray_rdclk_d1, wr_ptr_gray_rdclk_d2;

    // FIFO Full/Empty logic
    wire [ADDR_WIDTH:0] wr_ptr_bin_next = wr_ptr_bin + (wr_en & ~full);
    wire [ADDR_WIDTH:0] rd_ptr_bin_next = rd_ptr_bin + (rd_en & ~empty);

    assign full  = (wr_ptr_gray == {~rd_ptr_gray_wrclk_d2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_wrclk_d2[ADDR_WIDTH-2:0]});
    assign empty = (rd_ptr_gray == wr_ptr_gray_rdclk_d2);

    // Binary to Gray
    function [ADDR_WIDTH:0] bin2gray(input [ADDR_WIDTH:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary
    function [ADDR_WIDTH:0] gray2bin(input [ADDR_WIDTH:0] gray);
        integer i;
        begin
            gray2bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Write pointer logic (write clock domain)
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_ptr_bin  <= 0;
            wr_ptr_gray <= 0;
        end else begin
            if (wr_en & ~full)
                wr_ptr_bin <= wr_ptr_bin_next;
            wr_ptr_gray <= bin2gray(wr_ptr_bin_next);
        end
    end

    // Read pointer logic (read clock domain)
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
        end else begin
            if (rd_en & ~empty)
                rd_ptr_bin <= rd_ptr_bin_next;
            rd_ptr_gray <= bin2gray(rd_ptr_bin_next);
        end
    end

    // Synchronize read pointer into write domain
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            rd_ptr_gray_wrclk_d1 <= 0;
            rd_ptr_gray_wrclk_d2 <= 0;
        end else begin
            rd_ptr_gray_wrclk_d1 <= rd_ptr_gray;
            rd_ptr_gray_wrclk_d2 <= rd_ptr_gray_wrclk_d1;
        end
    end

    // Synchronize write pointer into read domain
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            wr_ptr_gray_rdclk_d1 <= 0;
            wr_ptr_gray_rdclk_d2 <= 0;
        end else begin
            wr_ptr_gray_rdclk_d1 <= wr_ptr_gray;
            wr_ptr_gray_rdclk_d2 <= wr_ptr_gray_rdclk_d1;
        end
    end

    // BRAM Memory Array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge wr_clk) begin
        if (wr_en && ~full)
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
    end

    reg [DATA_WIDTH-1:0] rd_data_reg;
    assign rd_data = rd_data_reg;

    always @(posedge rd_clk) begin
        if (rd_en && ~empty)
            rd_data_reg <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
    end

endmodule

