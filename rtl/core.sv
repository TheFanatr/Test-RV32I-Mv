`timescale 1ns / 1ps

module core (
    input clk,
    input clk_en,
    input rst,

    // RAM
    output o_read_req,
    output [ADDR_WIDTH:0] o_read_addr,
    input wire [DATA_WIDTH:0] i_read_data,

    output o_write_enable,
    output [3:0] o_byte_enable,
    output logic [ADDR_WIDTH:0] o_write_addr,
    output logic [DATA_WIDTH:0] o_write_data
);

fetch u_fetch();
    
endmodule