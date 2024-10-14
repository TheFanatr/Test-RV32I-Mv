`timescale 1ns / 1ps

module fetch #(
    ADDR_WIDTH = 31,
    DATA_WIDTH = 31
) (
    input clk,
    input clk_en,
    input rst,

    input [31:0] i_pc,

    //RAM
    output [ADDR_WIDTH:0] o_read_fetch_addr,
    input  [DATA_WIDTH:0] i_read_fetch_data,

    output [31:0] o_instruction
);

    assign o_read_fetch_addr = i_pc;

    assign o_instruction = i_read_fetch_data;

endmodule