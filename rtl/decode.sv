`timescale 1ns/1ps

typedef enum bit [2:0] {
  ERROR,
  R,
  I,
  S,
  B,
  U,
  J
} inst_type_e;

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

  output bit o_valid
);

  inst_type_e inst_type;

  wire no_output = rst | ~o_valid;

  //xxxxx11 = not compressed

  always_comb begin
    unique case (i_instruction[6:0])
      7'b0110011: inst_type = R;
      7'b0010011: inst_type = I;
      7'b0000011: inst_type = I;
      7'b0100011: inst_type = S;
      7'b1100011: inst_type = B;
      7'b1101111: inst_type = J;
      7'b1100111: inst_type = I;
      7'b0110111: inst_type = U;
      7'b0010111: inst_type = U;
      7'b1110011: inst_type = I;
      default: inst_type = ERROR;
    endcase

    o_valid = (|inst_type);
  end

  always_comb begin
    if (no_output) begin
      o_funct7 = 0;
      o_funct3 = 0;
      o_rs1 = 0;
      o_rs2 = 0;
      o_rd = 0;
      o_imm = 0;
      o_opcode = 0;
    end else begin
      o_opcode = i_instruction[6:0];

      unique case (inst_type)
        R: begin
          o_funct7 = i_instruction[31:25];
          o_rs2 = i_instruction[24:20];
          o_rs1 = i_instruction[19:15];
          o_funct3 = i_instruction[14:12];
          o_rd = i_instruction[11:7];

          o_imm = 0;
        end
        I: begin
          o_imm[11:0] = i_instruction[31:20];
          o_rs1 = i_instruction[19:15];
          o_funct3 = i_instruction[14:12];
          o_rd = i_instruction[11:7];
          
          o_funct7 = 0;
          o_rs2 = 0;
        end
        S: begin
          o_imm[11:5] = i_instruction[31:25];
          o_rs2 = i_instruction[24:20];
          o_rs1 = i_instruction[19:15];
          o_funct3 = i_instruction[14:12];
          o_imm[4:0] = i_instruction[11:7];
          
          o_funct7 = 0;
          o_rd = 0;
        end
        B: begin
          o_imm[12] = i_instruction[31];
          o_imm[10:5] = i_instruction[30:25];
          o_rs2 = i_instruction[24:20];
          o_rs1 = i_instruction[19:15];
          o_funct3 = i_instruction[14:12];
          o_imm[4:1] = i_instruction[11:8];
          o_imm[11] = i_instruction[7];

          o_funct7 = 0;
          o_rd = 0;
        end
        U: begin
          o_imm[31:12] = i_instruction[31:12];
          o_rd = i_instruction[11:7];

          o_funct7 = 0;
          o_funct3 = 0;
          o_rs1 = 0;
          o_rs2 = 0;
        end
        J: begin
          o_imm[20] = i_instruction[31];
          o_imm[10:1] = i_instruction[30:21];
          o_imm[11] = i_instruction[20];
          o_imm[19:12] = i_instruction[19:12];
          o_rd = i_instruction[11:7];

          o_funct7 = 0;
          o_funct3 = 0;
          o_rs1 = 0;
          o_rs2 = 0;
        end
      endcase
    end
  end

endmodule