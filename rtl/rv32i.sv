`timescale 1ns / 1ps

module rv32i (
    input clk,
    input clk_en,
    input rst,

    //UART
    input rx,
    output tx,

    //Booted
    output booted
);

  //uart - out
  logic [7:0] s_axis_tdata;
  wire        s_axis_tvalid;
  wire        s_axis_tready;

  //uart - in
  wire [7:0]  m_axis_tdata;
  wire       m_axis_tvalid;
  wire       m_axis_tready;

  wire tx_busy;
  wire rx_busy;
  wire rx_overrun_error;
  wire rx_frame_error;

  // RAM 
  
  wire [31:0] fetch_addr;
  wire [31:0] fetch_data;
  
  
  wire read_req;
  wire [31:0] read_addr;
  wire [31:0] read_data;

  wire write_enable;
  wire [3:0] byte_enable;
  wire [31:0] write_addr;
  wire [31:0] write_data;

  wire ebreak;

  // RAM <-> BIOS
  wire rb_read_req;
  wire [31:0] rb_read_addr;

  wire rb_write_enable;
  wire [3:0] rb_byte_enable;
  wire [31:0] rb_write_addr;
  wire [31:0] rb_write_data;

  // RAM <-> CORE
  wire rc_read_req;
  wire [31:0] rc_read_addr;

  wire rc_write_enable;
  wire [3:0] rc_byte_enable;
  wire [31:0] rc_write_addr;
  wire [31:0] rc_write_data;

  Mux2  #(.BITS(1)) ram_read_req_mux(
    .a(rb_read_req), // not booted
    .b(rc_read_req), // booted
    .s(booted),
    .o(read_req)
  );


  Mux2  #(.BITS(31)) ram_read_addr_mux(
    .a(rb_read_addr),// not booted
    .b(rc_read_addr),// booted
    .s(booted),
    .o(read_addr)
  );

    Mux2  #(.BITS(1)) ram_write_enable_mux(
    .a(rb_write_enable),// not booted
    .b(rc_write_enable),// booted
    .s(booted),
    .o(write_enable)
  );

    Mux2  #(.BITS(3)) ram_byte_enable_mux(
    .a(rb_byte_enable),// not booted
    .b(rc_byte_enable),// booted
    .s(booted),
    .o(byte_enable)
  );

  Mux2  #(.BITS(31)) ram_write_addr_mux(
    .a(rb_write_addr),// not booted
    .b(rc_write_addr),// booted
    .s(booted),
    .o(write_addr)
  );

    Mux2  #(.BITS(31)) ram_write_data_mux (
    .a(rb_write_data),// not booted
    .b(rc_write_data),// booted
    .s(booted),
    .o(write_data)
  );

  ram u_ram(
  .clk(clk),
  .clk_en(clk_en),
  .rst(rst),

  .i_read_req(read_req),
  .i_read_addr(read_addr),
  .o_read_data(read_data),
  .i_read_fetch_addr(fetch_addr),
  .o_read_fetch_data(fetch_data),


  // Write
  .i_write_enable(write_enable),
  .i_byte_enable(byte_enable),
  .i_write_addr(write_addr),
  .i_write_data(write_data)
  );
  wire bios_rst;

  core u_core (
    .clk(clk),
    .clk_en(booted),
    .rst(rst | bios_rst),

      // RAM
    .o_read_req(rc_read_req),
    .o_read_addr(rc_read_addr),
    .i_read_data(read_data),

    .o_read_fetch_addr(fetch_addr),
    .i_read_fetch_data(fetch_data),

    .o_write_enable(rc_write_enable),
    .o_byte_enable(rc_byte_enable),
    .o_write_addr(rc_write_addr),
    .o_write_data(rc_write_data),

    .o_ebreak(ebreak)
  );

  bios u_bios(
  .clk(clk),
  .clk_en(clk_en),
  .rst(rst),

  .i_ebreak(ebreak),

  .o_rst(bios_rst),
  .o_booted(booted),

  // RAM
  .o_read_req(rb_read_req),
  .o_read_addr(rb_read_addr),
  .i_read_data(read_data),

  .o_write_enable(rb_write_enable),
  .o_byte_enable(rb_byte_enable),
  .o_write_addr(rb_write_addr),
  .o_write_data(rb_write_data),


  /*
  * AXI input
  */
  .i_data(m_axis_tdata),
  .i_valid(m_axis_tvalid),
  .o_in_ready(m_axis_tready),

  /*
  * AXI output
  */
  .o_data(s_axis_tdata),
  .o_valid(s_axis_tvalid),
  .i_out_ready(s_axis_tready)
  );

  uart
  uart_inst (
  .clk(clk),
  .rst(rst),
  // AXI input
  .s_axis_tdata(s_axis_tdata),
  .s_axis_tvalid(s_axis_tvalid),
  .s_axis_tready(s_axis_tready),
  // AXI output
  .m_axis_tdata(m_axis_tdata),
  .m_axis_tvalid(m_axis_tvalid),
  .m_axis_tready(m_axis_tready),
  // uart
  .rxd(rx),
  .txd(tx),
  // status
  .tx_busy(tx_busy),
  .rx_busy(rx_busy),
  .rx_overrun_error(rx_overrun_error),
  .rx_frame_error(rx_frame_error),
  // configuration
  .prescale(50000000 / (9600 * 8))
  );


`ifdef TESTING
  always @(posedge clk) begin
    //$display("CPU");
  end
`endif

endmodule
