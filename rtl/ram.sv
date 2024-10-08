`include "types.svh"

module ram #(
    ADDR_WIDTH = 31,
    DATA_WIDTH = 31,
    NUM_BYTES = 4,
    BYTE_WIDTH = 8
)(
    input clk,
    input clk_en,
    input rst,

    input i_read_enable,
    input [ADDR_WIDTH:0] i_read_addr,
    output [DATA_WIDTH:0] o_read_data,

   
    input [3:0] i_write_enable,
    input [3:0] i_byte_enable,
    input [ADDR_WIDTH:0] i_write_addr,
    input [DATA_WIDTH:0] i_write_data
);


`ifdef TESTING
    always @(posedge clk) begin
    $display("i_read_addr: ", i_read_addr);
    $display("o_read_data: ", o_read_data);
    $display("i_write_addr: ", i_write_addr);
    $display("i_write_data: ", i_write_data);
    end
`endif

//2**ADDR_WIDTH - 1 
(* ram_style = "block" *) reg [NUM_BYTES-1:0][BYTE_WIDTH-1:0] mem [2048: 0];

always @(posedge clk) begin
    if (i_write_enable) begin
        for (int i = 0; i < NUM_BYTES; i = i + 1) begin
            if(write_enable[i]) mem[i_write_addr][i] <= i_write_data[i*BYTE_WIDTH +: BYTE_WIDTH];
        end
    end
end

always @(posedge clk) begin
    if (clk_en) begin
        if (i_read_enable)
            o_read_data <= mem[i_read_addr];
    end
end

endmodule
