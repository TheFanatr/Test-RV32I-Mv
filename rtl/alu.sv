`timescale 1ns/1ps

`include "types.svh"

module alu #(
  parameter DATA_WIDTH = 31
)(
  input  logic                   clk,
  input  logic                   clk_en,
  input  logic                   rst,

  input  logic [6:0]             i_opcode,
  input  logic [6:0]             i_funct7,
  input  logic [2:0]             i_funct3,
  input  logic [DATA_WIDTH:0]    i_rs1_data,
  input  logic [DATA_WIDTH:0]    i_rs2_data,
  input  logic [31:0]            i_imm,

  output logic [DATA_WIDTH:0]    o_rd_data
);

  always_comb begin
    case (i_opcode)
      7'b0110011: begin
        case (i_funct3)
          3'b000: begin // ADD or SUB
            if (i_funct7 == 7'h20)
              o_rd_data = i_rs1_data - i_rs2_data; // SUB
            else
              o_rd_data = i_rs1_data + i_rs2_data; // ADD
          end
          3'b001: o_rd_data = i_rs1_data << i_rs2_data[4:0]; // SLL
          3'b010: o_rd_data = ($signed(i_rs1_data) < $signed(i_rs2_data)) ? 1 : 0; // SLT
          3'b011: o_rd_data = (i_rs1_data < i_rs2_data) ? 1 : 0; // SLTU
          3'b100: o_rd_data = i_rs1_data ^ i_rs2_data; // XOR
          3'b101: begin // SRL or SRA
            if (i_funct7 == 7'h20)
              o_rd_data = $signed(i_rs1_data) >>> i_rs2_data[4:0]; // SRA
            else
              o_rd_data = i_rs1_data >> i_rs2_data[4:0]; // SRL
          end
          3'b110: o_rd_data = i_rs1_data | i_rs2_data; // OR
          3'b111: o_rd_data = i_rs1_data & i_rs2_data; // AND
          default: o_rd_data = 32'b0;
        endcase
      end

      7'b0010011: begin
        case (i_funct3)
          3'b000: o_rd_data = i_rs1_data + i_imm; // ADDI
          3'b010: o_rd_data = ($signed(i_rs1_data) < $signed(i_imm)) ? 1 : 0; // SLTI
          3'b011: o_rd_data = (i_rs1_data < i_imm) ? 1 : 0; // SLTIU
          3'b100: o_rd_data = i_rs1_data ^ i_imm; // XORI
          3'b110: o_rd_data = i_rs1_data | i_imm; // ORI
          3'b111: o_rd_data = i_rs1_data & i_imm; // ANDI
          3'b001: o_rd_data = i_rs1_data << i_imm[4:0]; // SLLI
          3'b101: begin // SRLI or SRAI
            if (i_imm[11:5] == 6'h20)
              o_rd_data = $signed(i_rs1_data) >>> i_imm[4:0]; // SRAI
            else
              o_rd_data = i_rs1_data >> i_imm[4:0]; // SRLI
          end
          default: o_rd_data = 32'b0;
        endcase
      end

      default: o_rd_data = 32'b0;
    endcase
  end

endmodule