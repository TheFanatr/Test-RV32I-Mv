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

  
  output logic [6:0] o_opcode,
  output logic [7:0] o_funct7,
  output logic [2:0] o_funct3,
  output logic [4:0] o_rs1,
  output logic [4:0] o_rs2,
  output logic [4:0] o_rd,
  output logic [31:0] o_imm,

  output logic o_valid
);

  bit [6:0] opcode;
  bit [7:0] funct7;
  bit [2:0] funct3;
  bit [4:0] rs1;
  bit [4:0] rs2;
  bit [4:0] rd;
  bit [31:0] imm;

  inst_type_e inst_type;

  wire valid = (|inst_type);

  wire no_output = rst | ~valid;

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
  end

  always_comb begin
    if (no_output) begin
      funct7 = 0;
      funct3 = 0;
      rs1 = 0;
      rs2 = 0;
      rd = 0;
      imm = 0;
      opcode = 0;
    end else begin
      opcode = i_instruction[6:0];

      unique case (inst_type)
        R: begin
          funct7 = i_instruction[31:25];
          rs2 = i_instruction[24:20];
          rs1 = i_instruction[19:15];
          funct3 = i_instruction[14:12];
          rd = i_instruction[11:7];

          imm = 0;
        end
        I: begin
          imm[11:0] = i_instruction[31:20];
          rs1 = i_instruction[19:15];
          funct3 = i_instruction[14:12];
          rd = i_instruction[11:7];
          
          funct7 = 0;
          rs2 = 0;
        end
        S: begin
          imm[11:5] = i_instruction[31:25];
          rs2 = i_instruction[24:20];
          rs1 = i_instruction[19:15];
          funct3 = i_instruction[14:12];
          imm[4:0] = i_instruction[11:7];
          
          funct7 = 0;
          rd = 0;
        end
        B: begin
          imm[12] = i_instruction[31];
          imm[10:5] = i_instruction[30:25];
          rs2 = i_instruction[24:20];
          rs1 = i_instruction[19:15];
          funct3 = i_instruction[14:12];
          imm[4:1] = i_instruction[11:8];
          imm[11] = i_instruction[7];

          funct7 = 0;
          rd = 0;
        end
        U: begin
          imm[31:12] = i_instruction[31:12];
          rd = i_instruction[11:7];

          funct7 = 0;
          funct3 = 0;
          rs1 = 0;
          rs2 = 0;
        end
        J: begin
          imm[20] = i_instruction[31];
          imm[10:1] = i_instruction[30:21];
          imm[11] = i_instruction[20];
          imm[19:12] = i_instruction[19:12];
          rd = i_instruction[11:7];

          funct7 = 0;
          funct3 = 0;
          rs1 = 0;
          rs2 = 0;
        end
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (clk_en) begin
      o_valid <= valid;
      
      o_funct7 <= funct7;
      o_funct3 <= funct3;
      o_rs1 <= rs1;
      o_rs2 <= rs2;
      o_rd <= rd;
      o_imm <= imm;
      o_opcode <= opcode;

      $display("Instruction Type: %0h", inst_type);
    end
  end

endmodule