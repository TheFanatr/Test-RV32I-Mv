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

   
    input [3:0] i_write_enable,
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
(* ram_style = "block" *) logic [DATA_WIDTH:0] mem_a [16: 0];
(* ram_style = "block" *) logic [DATA_WIDTH:0] mem_b [16: 0];
(* ram_style = "block" *) logic [DATA_WIDTH:0] mem_c [16: 0];
(* ram_style = "block" *) logic [DATA_WIDTH:0] mem_d [16: 0];

always @(posedge clk) begin
    if (clk_en) begin
        if (i_write_enable[0])
            mem_a[i_write_addr] <= i_write_data[7:0];
        if (i_write_enable[1])
            mem_b[i_write_addr] <= i_write_data[15:8];
        if (i_write_enable[2])
            mem_c[i_write_addr] <= i_write_data[23:16];
        if (i_write_enable[3])
            mem_d[i_write_addr] <= i_write_data[31:24];
    end
end

always @(posedge clk) begin
    if (clk_en) begin
        if (i_read_enable)
            o_read_data <= {mem_a[i_read_addr], mem_b[i_read_addr], mem_c[i_read_addr], mem_d[i_read_addr]};
    end
end



endmodule
