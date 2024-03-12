module async_fifo #(
  parameter WIDTH = 1,
  parameter DEPTH = 4
)(
  input   logic[WIDTH-1:0]  i_wdata,
  input   logic             i_wen,
  output  logic             o_full,
  input   logic             i_wclk,
  input   logic             i_wrst,

  output  logic[WIDTH-1:0]  o_rdata,
  input   logic             i_ren,
  output  logic             o_empty,
  input   logic             i_rclk,
  input   logic             i_rrst
);

  localparam PTR_WIDTH = $clog2(DEPTH);

  logic unsigned[PTR_WIDTH:0] wpointer_wclk;        // write pointer intentionally 1 bit "too long" for full/empty differentiation
  logic unsigned[PTR_WIDTH:0] gray_wpointer_wclk;   // gray-code write pointer in aclk domain
  logic unsigned[PTR_WIDTH:0] gray_wpointer_cdc;    // ff reg used for CDC
  logic unsigned[PTR_WIDTH:0] gray_wpointer_rclk;   // gray-code write pointer in rclk domain after double-flop CDC
  logic unsigned[PTR_WIDTH:0] wpointer_rclk;        // write pointer in rclk domain
  
  logic unsigned[PTR_WIDTH:0] rpointer_rclk;        // read pointer intentionally 1 bit "too long" for full/empty differentiation
  logic unsigned[PTR_WIDTH:0] gray_rpointer_rclk;   // gray-code read pointer in rclk domain
  logic unsigned[PTR_WIDTH:0] gray_rpointer_cdc;    // ff reg used for CDC
  logic unsigned[PTR_WIDTH:0] gray_rpointer_wclk;   // gray-code read pointer in wclk domain after double-flop CDC
  logic unsigned[PTR_WIDTH:0] rpointer_wclk;        // read pointer in wclk domain

  logic[WIDTH-1:0]            mem[DEPTH-1:0];

  // convert binary to gray code
  function [PTR_WIDTH:0] bin2gray;
    input  [PTR_WIDTH:0] bin;
    logic  [PTR_WIDTH:0] gray;
    begin
      gray = bin ^ (bin >> 1);
      bin2gray = gray;
    end
  endfunction

  // convert gray code to binary
  function [PTR_WIDTH:0] gray2bin;
    input  [PTR_WIDTH:0] gray;
    logic  [PTR_WIDTH:0] bin;
    begin
      for(int i = 0; i < PTR_WIDTH; i++) begin
        bin[i] = ^(gray >> i);
      end
      gray2bin = bin;
    end
  endfunction

  // write
  always_ff @(posedge i_wclk) begin : write_block
    if (i_wrst) begin
        wpointer_wclk <= '0;
        for(int i = 0; i < DEPTH; i++) begin
          mem[i] <= '0;
        end
    end else if (~i_wrst) begin
        if (i_wen && ~o_full) begin
          mem[wpointer_wclk[PTR_WIDTH-1:0]] <= i_wdata;
          wpointer_wclk <= wpointer_wclk + 1;
        end
    end
  end

  // read
  always_ff @(posedge i_rclk) begin : read_block
    if (i_rrst) begin
      rpointer_rclk <= '0;
    end else if (~i_rrst) begin
      if (i_ren && ~o_empty) begin
        rpointer_rclk <= rpointer_rclk + 1;
      end
    end
  end

  assign o_rdata = mem[rpointer_rclk[PTR_WIDTH-1:0]];

  // generate full and empty flags from gray codes
  // this combinatorial chain is getting long... I should probably rework to register this output
  assign o_full   = wpointer_wclk == rpointer_wclk;
  assign o_empty  = (wpointer_rclk[PTR_WIDTH-1:0] == rpointer_rclk[PTR_WIDTH-1:0]) && (wpointer_rclk[PTR_WIDTH] ^ rpointer_rclk[PTR_WIDTH]);

  // generate gray code equivalents of pointers
  assign gray_wpointer_wclk = bin2gray(wpointer_wclk);
  assign gray_rpointer_rclk = bin2gray(rpointer_rclk);

  // generate binary equivalents of gray code pointers
  assign wpointer_rclk = gray2bin(gray_wpointer_rclk);
  assign rpointer_wclk = gray2bin(gray_rpointer_wclk);

  // CDC for write pointer
  always_ff @(posedge i_wclk) begin : wpointer_cdc
    if (i_wrst) begin
      gray_rpointer_cdc   <= '0;
      gray_rpointer_wclk  <= '0;
    end else if (~i_wrst) begin
      gray_rpointer_cdc   <= gray_rpointer_rclk;
      gray_rpointer_wclk  <= gray_rpointer_cdc;
    end
  end

  // CDC for read pointer
  always_ff @(posedge i_wclk) begin : rpointer_cdc
    if (i_wrst) begin
      gray_wpointer_cdc   <= '0;
      gray_wpointer_rclk  <= '0;
    end else if (~i_wrst) begin
      gray_wpointer_cdc   <= gray_wpointer_wclk;
      gray_wpointer_rclk  <= gray_wpointer_cdc;
    end
  end
endmodule

