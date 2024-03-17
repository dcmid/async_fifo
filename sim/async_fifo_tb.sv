`include "../hdl/async_fifo.sv"

module async_fifo_tb;

  localparam WIDTH = 8;
  localparam DEPTH = 16;
  localparam FWFT  = 0;

  logic[WIDTH-1:0]  i_wdata;
  logic             i_wen;
  logic             o_full;
  logic             i_wclk;
  logic             i_wrst;
  
  logic[WIDTH-1:0]  o_rdata;
  logic             i_ren;
  logic             o_empty;
  logic             i_rclk;
  logic             i_rrst;

  int wcount, rcount;

  async_fifo #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH),
    .FWFT(FWFT)
  ) dut (
    .i_wdata(i_wdata),
    .i_wen(i_wen),
    .o_full(o_full),
    .i_wclk(i_wclk),
    .i_wrst(i_wrst),

    .o_rdata(o_rdata),
    .i_ren(i_ren),
    .o_empty(o_empty),
    .i_rclk(i_rclk),
    .i_rrst(i_rrst)
  );

  // write value to fifo
  task write_fifo;
    input [WIDTH-1:0] wdata;
    begin
      i_wdata <= wdata;
      i_wen   <= 1'b1;
      @(posedge i_wclk);
      i_wen   <= 1'b0;
    end
  endtask

  // read value from fifo
  task read_fifo;
    begin
      i_ren <= 1'b1;
      @(posedge i_rclk);
      i_ren <= 1'b0;
    end
  endtask

  // start clocks
  localparam WCLK_PERIOD = 10;
  always #(WCLK_PERIOD/2) i_wclk = ~i_wclk;
  localparam RCLK_PERIOD = 12;
  always #(RCLK_PERIOD/2) i_rclk = ~i_rclk;

  // VCD setup
  initial begin
    $dumpfile("async_fifo_tb.vcd");
    $dumpvars(0, async_fifo_tb);
  end

  // wclk domain stimulus
  initial begin
    i_wdata <= '0;
    i_wen   <= 1'b0;
    i_wclk  <= 1'b0;
    i_wrst  <= 1'b0;

    #50
    // reset the write side
    @(posedge i_wclk) i_wrst  <= 1'b1;
    repeat(2) @(posedge i_wclk);
    i_wrst  <= 1'b0;

    wcount = 0;
    while(~o_full) begin
      write_fifo(wcount + 1);
      wcount <= wcount + 1;
      @(posedge i_wclk);
    end
    
  end

  initial begin
    i_ren   <= 1'b0;
    i_rclk  <= 1'b0;
    i_rrst  <= 1'b0;

    #50
    // reset the read side
    @(posedge i_rclk) i_rrst  <= 1'b1;
    repeat(2) @(posedge i_rclk);
    i_rrst  <= 1'b0;
    repeat(100) @(posedge i_rclk);

    while(~o_empty) begin
      read_fifo();
      @(posedge i_rclk);
    end

    repeat(5) @(posedge i_rclk);
    $finish(2);
  end

endmodule