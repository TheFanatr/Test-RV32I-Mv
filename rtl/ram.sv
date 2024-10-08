`include "types.svh"

module ram #(
    ADDR_WIDTH = 31,
    DATA_WIDTH = 31
)(
    input clk,
    input clk_en,
    input rst,

    input i_read_enable,
    input [ADDR_WIDTH:0] i_read_addr,
    output [DATA_WIDTH:0] o_read_data,

    input [3:0] write_enable,
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
(* ram_style = "block" *) reg [DATA_WIDTH:0] mem [2048: 0];

always @(posedge clk) begin
    if (clk_en) begin
        if (write_enable[0])
            mem[i_write_addr][7:0] <= i_write_data[7:0];
        if (write_enable[1])
            mem[i_write_addr][15:8] <= i_write_data[15:8];
        if (write_enable[2])
            mem[i_write_addr][23:16] <= i_write_data[23:16];
        if (write_enable[3])
            mem[i_write_addr][31:24] <= i_write_data[31:24];
    end
end

always @(posedge clk) begin
    if (clk_en) begin
        if (i_read_enable)
            o_read_data <= mem[i_read_addr];
    end
end



endmodule
