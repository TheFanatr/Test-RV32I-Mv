`timescale 1ns / 1ps

module ram #(
    ADDR_WIDTH = 31,
    DATA_WIDTH = 31
)(
    input clk,
    input clk_en,
    input rst,

    //Read
    input i_read_req,
    input [ADDR_WIDTH:0] i_read_addr,
    output [DATA_WIDTH:0] o_read_data,


    //Read fetch
    input [ADDR_WIDTH:0] i_read_fetch_addr,
    output [DATA_WIDTH:0] o_read_fetch_data,

    // Write
    input i_write_enable,
    input [3:0] i_byte_enable,
    input [ADDR_WIDTH:0] i_write_addr,
    input [DATA_WIDTH:0] i_write_data
);

`ifdef TESTING1
    always @(posedge clk) begin
        $display("clk: ", clk);
        $display("clk_en: ", clk_en);
        $display("rst: ", rst);
        $display("i_read_req: ", i_read_req);
        $display("i_read_addr: ", i_read_addr);
        $display("o_read_data: ", o_read_data);
        $display("i_write_enable: ", i_write_enable);
        $display("i_byte_enable: ", i_byte_enable);
        $display("i_write_addr: ", i_write_addr);
        $display("i_write_data: ", i_write_data);
    end
`endif

//2**ADDR_WIDTH - 1 
(* ram_style = "block" *) logic [7:0] mem_a [32-1:0];
(* ram_style = "block" *) logic [7:0] mem_b [32-1:0];
(* ram_style = "block" *) logic [7:0] mem_c [32-1:0];
(* ram_style = "block" *) logic [7:0] mem_d [32-1:0];


always_ff @(posedge clk) begin
    if (clk_en) begin
        if (i_write_enable) begin
            if (i_byte_enable[0])
                mem_a[i_write_addr] <= i_write_data[7:0];
            if (i_byte_enable[1])
                mem_b[i_write_addr] <= i_write_data[15:8];
            if (i_byte_enable[2])
                mem_c[i_write_addr] <= i_write_data[23:16];
            if (i_byte_enable[3])
                mem_d[i_write_addr] <= i_write_data[31:24];
        end
    end
end

assign o_read_data = {mem_d[i_read_addr], mem_c[i_read_addr], mem_b[i_read_addr], mem_a[i_read_addr]};

assign o_read_fetch_data = {mem_d[i_read_fetch_addr], mem_c[i_read_fetch_addr], mem_b[i_read_fetch_addr], mem_a[i_read_fetch_addr]};

endmodule
