`timescale 1ns / 1ps

`include "types.svh"

module ram #(
    ADDR_WIDTH = 31,
    DATA_WIDTH = 31,
    ADDR_COUNT = 1024
)(
    input clk,
    input clk_en,
    input rst,

    //Read
    input i_read_req,
    input [ADDR_WIDTH:0] i_read_addr,
    output reg [DATA_WIDTH:0] o_read_data,

    //Read fetch
    input [ADDR_WIDTH:0] i_read_fetch_addr,
    output reg [DATA_WIDTH:0] o_read_fetch_data,

    // Write
    input i_write_enable,
    input [3:0] i_byte_enable,
    input [ADDR_WIDTH:0] i_write_addr,
    input [DATA_WIDTH:0] i_write_data,

    // UART
    output [7:0] o_write_uart,
    output bit o_write_uart_en,

    // SYSTEM BITS
    output sysflags_e o_sys
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
(* ram_style = "block" *) logic [7:0] mem_a [ADDR_COUNT-1:0];
(* ram_style = "block" *) logic [7:0] mem_b [ADDR_COUNT-1:0];
(* ram_style = "block" *) logic [7:0] mem_c [ADDR_COUNT-1:0];
(* ram_style = "block" *) logic [7:0] mem_d [ADDR_COUNT-1:0];

assign o_write_uart = i_write_data[7:0];

always_ff @(posedge clk)
    if (clk_en)
        if (i_write_addr == ADDR_COUNT * 2) begin
            if (i_write_enable) begin
                if (i_byte_enable[0]) begin
                    // $write("%c", o_write_uart);
                    o_write_uart_en <= 1'b1;
                end
                else o_write_uart_en <= 1'b0;
            end
            else o_write_uart_en <= 1'b0;
        end else if (i_write_addr == ADDR_COUNT) begin
            o_sys <= sysflags_e'{sysflags_e'(i_write_data[0])};
            o_write_uart_en <= 1'b0;
        end
    else o_write_uart_en <= 1'b0;

always_ff @(posedge clk) begin
    if (clk_en) begin
        if (i_write_enable) begin
            if (i_byte_enable[0]) begin
                // if (i_read_addr == 32'd128)
                    // $display("a: %c", i_write_data[7:0]);
                mem_a[i_write_addr] <= i_write_data[7:0];
            end
            if (i_byte_enable[1]) begin
                // if (i_read_addr == 32'd128)
                    // $display("b: %c", i_write_data[15:8]);
                mem_b[i_write_addr] <= i_write_data[15:8];
            end
            if (i_byte_enable[2]) begin
                // if (i_read_addr == 32'd128)
                //     $display("c: %c", i_write_data[23:16]);
                mem_c[i_write_addr] <= i_write_data[23:16];
            end
            if (i_byte_enable[3]) begin
                // if (i_read_addr == 32'd128)
                //     $display("d: %c", i_write_data[31:24]);
                mem_d[i_write_addr] <= i_write_data[31:24];
            end
        end
    end
end

always_ff @(posedge clk)
    o_read_data <= {mem_d[i_read_addr], mem_c[i_read_addr], mem_b[i_read_addr], mem_a[i_read_addr]};

always_ff @(posedge clk)
    o_read_fetch_data <= {mem_d[i_read_fetch_addr], mem_c[i_read_fetch_addr], mem_b[i_read_fetch_addr], mem_a[i_read_fetch_addr]};

endmodule
