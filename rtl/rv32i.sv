`include "types.svh"

module rv32i (
    input clk,
    input clk_en,
    input rst
);

ram u_ram (
  .clk(clk),
  .clk_en(clk_en),
  .rst(rst)
);

`ifdef TESTING
  always @(posedge clk) begin
    //$display("CPU");
  end
`endif

endmodule
