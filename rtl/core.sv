`timescale 1ns / 1ps

module core #(
    ADDR_WIDTH = 31,
    DATA_WIDTH = 31
)(
    input clk,
    input clk_en,
    input rst,

    // RAM
    output [ADDR_WIDTH:0] o_read_fetch_addr,
    input  [DATA_WIDTH:0] i_read_fetch_data,

    output o_read_req,
    output [ADDR_WIDTH:0] o_read_addr,
    input  [DATA_WIDTH:0] i_read_data,
    //input  i_read_ready, // wait untill read is ready

    output o_write_enable,
    output [3:0] o_byte_enable,
    output logic [ADDR_WIDTH:0] o_write_addr,
    output logic [DATA_WIDTH:0] o_write_data
);

reg [31:0] pc;

wire [31:0] instruction;

wire invalid_instruction;

wire valid_decoder_output;

assign invalid_instruction = ~(|instruction) | ~valid_decoder_output;

always_ff @(posedge clk)
    if(rst)
        pc <= 0;
    else if (clk_en)
        if(~invalid_instruction)
            pc <= pc + 1;
        else
            $finish();

fetch #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_fetch(
    .clk(clk),
    .clk_en(clk_en),
    .rst(rst),

    .i_pc(pc),

    .o_read_fetch_addr(o_read_fetch_addr),
    .i_read_fetch_data(i_read_fetch_data),

    .o_instruction(instruction)
);

decoder u_decoder (
    .clk(clk),
    .clk_en(clk_en),
    .rst(rst),

    .i_instruction(instruction),

    .o_valid(valid_decoder_output)
);
    
endmodule