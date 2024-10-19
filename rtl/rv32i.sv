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
  core u_core (
    .clk(clk),
    .clk_en(booted),
    .rst(rstrst),
  );




`ifdef TESTING
  always @(posedge clk) begin
    //$display("CPU");
  end
`endif

endmodule
