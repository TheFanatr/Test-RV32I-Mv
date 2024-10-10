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


typedef enum logic [3:0] {
    BD_READ,
    BD_STORE,
    BD_ONE,
    BD_TWO
} bios_dispatcher_state_t; 

typedef enum logic [3:0] {
    BN_START,
    BN_ACT
} bios_none_state_t; 

typedef enum logic [7:0] {
  // no args
  BOP_NOP,      //0
  BOP_BOOT,     //1
  BOP_RST,      //2
  BOP_READ,     //3

  // one arg
  BOP_WRITE,    //4
  
  // 2 args
  BOP_ADR_LOWER,//5
  BOP_ADR_UPPER //6
} bios_opcode_t;

typedef struct packed {
  bios_none_state_t state;
  logic boot;
  logic rst;
  logic read_req;
  logic serial_out_valid;
} none_state_t;

typedef struct packed {
  bios_dispatcher_state_t state;
  logic o_in_ready;  // i can read data atm sure
  logic trigger_no_arg;
  logic trigger_one_arg;
  logic trigger_two_arg;
} dispatcher_state_t;



typedef struct packed {
  logic [7:0] a;
  logic [7:0] b;
  logic [7:0] c;
  logic [7:0] d;
} addr_t;

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
    output logic         o_in_ready,

    /*
     * AXI output
     */
    output wire [8-1:0] o_data,
    output wire         o_valid,
    input  wire         i_out_ready
);

  
  dispatcher_state_t dispatcher;
  none_state_t none;
	
 
  addr_t ram_addr;

  bios_opcode_t opcode;
  logic [7:0] a;
  logic [7:0] b;


  assign o_in_ready = dispatcher.o_in_ready;

  //ram
  assign o_byte_enable = 4'b0001;
  //assign o_write_enable = control.o_write_enable;
	
  assign o_booted = none.boot;
  assign o_rst = none.rst;
  assign o_read_req = none.read_req;
  assign o_valid = none.serial_out_valid;
  assign o_data = i_read_data;


  always_ff @(posedge clk) begin
    if (rst) begin
            none <= {BN_START, 4'b0_0_0_0}; // reset dispatcher
    end else begin
      case (none.state)
        BN_START:
            if (dispatcher.trigger_no_arg)
                none <= {BN_ACT, 4'b0_0_0_0};
            else
                none <= {BN_START, 4'b0_0_0_0};
        BN_ACT:
            case (opcode)
                BOP_NOP:
                    none <= {BN_START, 4'b0_0_0_0};
                BOP_BOOT:
                    none <= {BN_ACT, 4'b1_0_0_0};
                BOP_RST:
                    none <= {BN_START, 4'b0_1_0_0};
                BOP_READ:
                    if(i_out_ready)
                        none <= {BN_START, 4'b0_0_1_1};
                    else
                        none <= {BN_ACT, 4'b0_0_1_1};
                default:
                    none <= {BN_START, 4'b0_0_0_0};
            endcase
        default:
            none <= {BN_START, 4'b0_0_0_0};
      endcase
  end
end  

  wire read_en = i_valid & o_in_ready; // we are ready to read they are ready to read
  wire cycle_en = clk_en & ~rst & ~o_booted;
  always_ff @(posedge clk) begin
    if (rst) begin
            dispatcher <= {BD_READ, 4'b1_0_0_0}; // reset dispatcher
    end else if(cycle_en) begin
      case (dispatcher.state)
        BD_READ: // Read char
            if (read_en) begin
					 opcode <= bios_opcode_t'(i_data);
						if(opcode < 4) begin 
						 dispatcher <= {BD_READ, 4'b1_1_0_0}; 
						end else begin
						 dispatcher <= {BD_ONE, 4'b1_0_0_0}; 
						end
            end else begin
                dispatcher <= {BD_READ, 4'b1_0_0_0}; 
            end
        BD_ONE:
        if (read_en) begin
            a <= i_data;
            if(opcode > 4) begin 
                dispatcher <= {BD_TWO, 4'b1_0_0_0}; 
            end else begin
                dispatcher <= {BD_READ, 4'b1_0_1_0}; 
            end
        end
        BD_TWO: 
        if (read_en) begin
            b <= i_data;
            dispatcher <= {BD_STORE, 4'b1_0_0_1}; 
        end
        default: 
            dispatcher <= {BD_READ, 4'b1_0_0_0}; // reset dispatcher
      endcase
  end
end

`ifdef TESTING1
  always @(posedge clk) begin
    $display("clk: ", clk);
    $display("clk_en: ", clk_en);
    $display("rst: ", rst);
  end
`endif

endmodule
