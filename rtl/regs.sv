module regs (
    input clk,
    input clk_en,
    input rst,

    input [4:0] i_write_addr,
    input [31:0] i_write_data,
    input i_write_en,


    input [4:0] i_a_addr,
    output [31:0] o_a_data,

    input [4:0] i_b_addr,
    output [31:0] o_b_data
);
  reg [31:0] registers[32];

  always_ff @(posedge clk) begin
    if(rst) begin
      integer i;
      for (i = 0; i < 32; i = i + 1) begin
        registers[i] = 32'd0;
      end
    end
    if (i_write_en & clk_en) begin  
      registers[i_write_addr] <= i_write_data;
    end
  end

  assign o_a_data = |i_a_addr ? registers[i_a_addr] : 0;
  assign o_b_data = |i_b_addr ? registers[i_b_addr] : 0;
endmodule