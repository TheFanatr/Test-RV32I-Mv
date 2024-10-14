`timescale 1ns/1ps

`include "types.svh"

module decode (
  input clk,
  input clk_en,
  input rst,

  input [31:0] i_instruction,
  
  output bit [6:0] o_opcode,
  output bit [7:0] o_funct7,
  output bit [2:0] o_funct3,
  output bit [4:0] o_rs1,
  output bit [4:0] o_rs2,
  output bit [4:0] o_rd,
  output bit [31:0] o_imm,

  output inst_type_e o_inst_type,

  output bit o_valid
);

  wire no_output = rst | ~o_valid;

  //xxxxx11 = not compressed

  always_comb begin
    unique case (i_instruction[6:0])
      7'b0110011: o_inst_type = R;
      7'b0010011: o_inst_type = I;
      7'b0000011: o_inst_type = I;
      7'b0100011: o_inst_type = S;
      7'b1100011: o_inst_type = B;
      7'b1101111: o_inst_type = J;
      7'b1100111: o_inst_type = I;
      7'b0110111: o_inst_type = U;
      7'b0010111: o_inst_type = U;
      7'b1110011: o_inst_type = I;
      default: o_inst_type = ERROR;
    endcase

    o_valid = (|o_inst_type);
  end

  always_comb begin
    if (no_output) begin
      o_funct7 = 8'b0;
      o_funct3 = 3'b0;
      o_rs1 = 5'b0;
      o_rs2 = 5'b0;
      o_rd = 5'b0;
      o_imm = 32'b0;
      o_opcode = 8'b0;
    end else begin
      o_opcode = i_instruction[6:0];

      unique case (o_inst_type)
        R: begin
          o_funct7 = i_instruction[31:25];
          o_rs2 = i_instruction[24:20];
          o_rs1 = i_instruction[19:15];
          o_funct3 = i_instruction[14:12];
          o_rd = i_instruction[11:7];

          o_imm = 32'b0;
        end
        I: begin
          o_rs1 = i_instruction[19:15];
          o_funct3 = i_instruction[14:12];
          o_rd = i_instruction[11:7];
          // _20_[11:0]
          o_imm = {20'b0, i_instruction[31:20]};
          
          o_funct7 = 8'b0;
          o_rs2 = 5'b0;
        end
        S: begin
          o_rs2 = i_instruction[24:20];
          o_rs1 = i_instruction[19:15];
          o_funct3 = i_instruction[14:12];
          // _20_[11:5][4:0]
          o_imm = {20'b0, i_instruction[31:25], i_instruction[11:7]};
          
          o_funct7 = 8'b0;
          o_rd = 5'b0;
        end
        B: begin
          o_rs2 = i_instruction[24:20];
          o_rs1 = i_instruction[19:15];
          o_funct3 = i_instruction[14:12];
          // _19_[12][11][10:5][4:1]_1_
          o_imm = {19'b0, i_instruction[31], i_instruction[7], i_instruction[30:25], i_instruction[11:8], 1'b0};

          o_funct7 = 8'b0;
          o_rd = 5'b0;
        end
        U: begin
          o_rd = i_instruction[11:7];
          // [31:12]_12_
          o_imm = {i_instruction[31:12], 12'b0};

          o_funct7 = 8'b0;
          o_funct3 = 3'b0;
          o_rs1 = 5'b0;
          o_rs2 = 5'b0;
        end
        J: begin
          o_rd = i_instruction[11:7];
          // _11_[20][19:12][11][10:1]_1_
          o_imm = {11'b0, i_instruction[31], i_instruction[19:12], i_instruction[20], i_instruction[30:21], 1'b0};

          o_funct7 = 8'b0;
          o_funct3 = 3'b0;
          o_rs1 = 5'b0;
          o_rs2 = 5'b0;
        end
      endcase
    end
  end

endmodule