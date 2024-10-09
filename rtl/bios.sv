// 2 STATES: BOOT; RUN
// BOOT = listening for commands
// RUN = stops listening for commands and simply forwards rx and tx directly to cpu gpio system

// BOOT MODE COMMANDS
// ===========================
// nop; does nothing will be zero
// boot; enters into boot mode
// rst; triger internal reset of cpu
// write; write to ram
//      writesize writeaddr data
// read; read from ram
//      readsize readaddr


typedef enum logic [7:0] {
  ST_READ_OPCODE,
  ST_READ_A,
  ST_READ_B,
  ST_READ_C,
  ST_EXEC,
  ST_RESET
} state_t;

typedef enum logic [7:0] {
  BOP_NOP,
  BOP_BOOT,
  BOP_RST,
  BOP_ADR_LOWER,
  BOP_ADR_UPPER,
  BOP_WRITE,
  BOP_READ
} bios_opcode_t;

typedef struct packed {
  state_t state;
  // UART
  logic o_in_ready;  // i can read data atm sure
  
  logic exec;
  logic reset_control;
} fsm_state_t;

typedef struct packed {
  logic [7:0] a;
  logic [7:0] b;
  logic [7:0] c;
  logic [7:0] d;
} addr_t;

typedef struct packed {
  // UART
  logic o_valid;  // the data im sending is good to go
  // CONTROL
  logic o_rst;
  logic o_booted;
  //RAM
  logic o_write_enable;
  logic o_read_enable;
} control_vec_t;

module bios #(
    ADDR_WIDTH = 31,
    DATA_WIDTH = 31
) (
    input clk,
    input clk_en,
    input rst,

    output o_rst,
    output o_booted,

    // RAM
    output o_read_req,
    output [ADDR_WIDTH:0] o_read_addr,
    input wire [DATA_WIDTH:0] i_read_data,

    output o_write_enable,
    output [3:0] o_byte_enable,
    output logic [ADDR_WIDTH:0] o_write_addr,
    output logic [DATA_WIDTH:0] o_write_data,

    /*
     * AXI input
     */
    input  wire [8-1:0] i_data,
    input  wire         i_valid,
    output reg         o_in_ready,

    /*
     * AXI output
     */
    output wire [8-1:0] o_data,
    output wire         o_valid,
    input  wire         i_out_ready
);

  fsm_state_t fsm;
  control_vec_t control;


  addr_t ram_addr;

  bios_opcode_t opcode;
  logic [7:0] a;
  logic [7:0] b;
  logic [7:0] c;


  assign o_in_ready = fsm.o_in_ready;
  //assign o_valid = control.o_valid;
  assign o_rst = control.o_rst;
  assign o_booted = control.o_booted;

  //ram
  assign o_byte_enable = 4'b0001;
  assign o_write_enable = control.o_write_enable;
  assign o_write_addr = ram_addr;
  assign o_read_addr = ram_addr;
  assign o_write_data = a;
  assign o_data = i_read_data;
  assign o_read_req = control.o_read_enable;

  always_ff @(posedge clk) begin
    if (rst)
			control <= {1'd0, 1'd0, 1'd0, 1'd0, 1'd0};
    if (fsm.reset_control)
			control <= {1'd0, 1'd0, 1'd0, 1'd0, 1'd0};
    if (fsm.exec)
        case (opcode)
            BOP_NOP:
                control <= {1'd0, 1'd0, 1'd0, 1'd0, 1'd0};
            BOP_BOOT:
                control <= {1'd0, 1'd0, 1'd1, 1'd0, 1'd0};
            BOP_RST: 
                control <= {1'd0, 1'd1, 1'd0, 1'd0, 1'd0};
            BOP_ADR_LOWER: begin
                ram_addr.a <= a;
                ram_addr.b <= b;
                control <= {1'd0, 1'd0, 1'd0, 1'd0, 1'd0};
            end
            BOP_ADR_UPPER: begin
                ram_addr.c <= a;
                ram_addr.d <= b;
                control <= {1'd0, 1'd0, 1'd0, 1'd0, 1'd0};
            end
            BOP_WRITE:
                control <= {1'd0, 1'd0, 1'd0, 1'd1, 1'd0};
            BOP_READ: begin 
                control <= {1'd1, 1'd0, 1'd0, 1'd0, 1'd1};
                o_valid <= 1;
            end
            default:
                control <= {1'd0, 1'd0, 1'd0, 1'd0, 1'd0};
        endcase
  end

  wire read_en = i_valid & fsm.o_in_ready;
  always_ff @(posedge clk) begin
    if (rst) fsm <= {ST_READ_OPCODE, 1'd1, 1'd0, 1'd0};
    if (clk_en & ~rst & ~control.o_booted)
      case (fsm.state)
        ST_READ_OPCODE:
        if (read_en) begin
          opcode <= bios_opcode_t'(i_data);
          fsm <= {ST_READ_A, 1'd1, 1'd0, 1'd0};
        end
        ST_READ_A:
        if (read_en) begin
          a <= i_data;
          fsm <= {ST_READ_B, 1'd1, 1'd0, 1'd0};
        end
        ST_READ_B:
        if (read_en) begin
          b <= i_data;
          fsm <= {ST_READ_C, 1'd1, 1'd0, 1'd0};
        end
        ST_READ_C:
        if (read_en) begin
          c <= i_data;
          fsm <= {ST_EXEC,1'd0, 1'd0, 1'd0};
        end
        ST_EXEC:
            fsm <= {ST_READ_OPCODE, 1'd1, 1'd1, 1'd0};
        // ST_RESET:
        //     fsm <= {ST_READ_OPCODE, 1'd1, 1'd0, 1'd0};
        default: 
            fsm <= {ST_READ_OPCODE, 1'd1, 1'd0, 1'd0};
      endcase
  end

`ifdef TESTING1
  always @(posedge clk) begin
    $display("clk: ", clk);
    $display("clk_en: ", clk_en);
    $display("rst: ", rst);
  end
`endif

endmodule
