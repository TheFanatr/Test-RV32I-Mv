`include "types.svh"

module ram (
    input clk,
    input clk_en,
    input rst
);


`ifdef TESTING
    always @(posedge clk) begin
    $display("RAM", clk_en);
    end
`endif

endmodule
