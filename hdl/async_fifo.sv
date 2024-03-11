module async_fifo #(
  parameter WIDTH = 1,
  parameter DEPTH = 4
)(
  input   logic[WIDTH-1:0]  i_wdata,
  input   logic             i_wen,
  input   logic             i_wclk,

  output  logic[WIDTH-1:0]  o_rdata,
  input   logic             i_ren,
  input   logic             i_rclk,

  input   logic             i_wrst,
  input   logic             i_rrst
);

  logic unsigned[$clog2(DEPTH)-1:0] wpointer;
  logic unsigned[$clog2(DEPTH)-1:0] rpointer;
  logic[WIDTH-1:0]                  mem[DEPTH-1:0];

  always_ff @(posedge i_wclk) begin : write_block
    if (i_wrst == 1'b1) begin
        wpointer <= '0;
        for(int i = 0; i < DEPTH; i++) begin
          mem[i] <= '0;
        end
    end else begin
        if (i_wdata == 1'b1 && ~full) begin
        end
    end
  end

  always_ff @(posedge i_rclk) begin : read_block
    if (i_rrst == 1'b1) begin
      rpointer <= '0;
    end else begin

    end
  end

endmodule

