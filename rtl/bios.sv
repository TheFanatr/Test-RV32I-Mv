`timescale 1ns / 1ps

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

typedef enum logic [3:0] {
    ONE_START,
    ONE_ACT
} bios_one_state_t; 

typedef enum logic [3:0] {
    TWO_START,
    TWO_ACT
} bios_two_state_t; 

typedef enum logic [7:0] {
  // no args
  BOP_NOP,          //0
  BOP_BOOT,         //1
  BOP_RST,          //2

  BOP_READ_ONE,     //3
  BOP_READ_TWO,     //4
  BOP_READ_THREE,   //5
  BOP_READ_FOUR,    //6

  // one arg
  BOP_WRITE_ONE,    //7
  BOP_WRITE_TWO,    //8
  BOP_WRITE_THREE,  //9
  BOP_WRITE_FOUR,   //10
  
  // 2 args
  BOP_ADR_LOWER,    //11
  BOP_ADR_UPPER     //12
} bios_opcode_t;

typedef struct packed {
  bios_none_state_t state;
  logic boot;
  logic rst;
  logic read_req;
  logic serial_out_valid;
} none_state_t;

typedef struct packed {
  bios_one_state_t state;
  logic write_enable;
} one_state_t;

typedef struct packed {
  bios_two_state_t state;
} two_state_t;

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
    output logic [3:0] o_byte_enable,
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
    output logic [8-1:0] o_data,
    output wire         o_valid,
    input  wire         i_out_ready
);

  
  dispatcher_state_t dispatcher;
  none_state_t none;
  one_state_t one;
  two_state_t two;
 
  addr_t ram_addr;

  bios_opcode_t opcode;
  logic [7:0] a;
  logic [7:0] b;

  assign o_in_ready = dispatcher.o_in_ready;
	
  assign o_booted = none.boot;
  assign o_rst = none.rst;
  assign o_read_req = none.read_req;
  assign o_valid = none.serial_out_valid; 
  assign o_write_enable = one.write_enable;
  assign o_write_addr = ram_addr;
  assign o_read_addr = ram_addr;


always_ff @(posedge clk) begin
    if (rst) begin
            two <= {TWO_START}; 
    end else begin
      case (two.state)
        TWO_START:
            if (dispatcher.trigger_two_arg)
                two <= {TWO_ACT};
            else
                two <= {TWO_START};
        TWO_ACT:
             case (opcode)
                BOP_ADR_LOWER: begin
                    ram_addr.c <= a;
                    ram_addr.d <= b;
                    two <= {TWO_START};
                end
                BOP_ADR_UPPER: begin
                    ram_addr.a <= a;
                    ram_addr.b <= b;
                    two <= {TWO_START};
                end
                default:
                    two <= {TWO_START};
            endcase
        default:
            two <= {TWO_START};
      endcase
  end
end  

always_ff @(posedge clk) begin
    if (rst) begin
            one <= {ONE_START, 1'b0}; 
    end else begin
      case (one.state)
        ONE_START:
            if (dispatcher.trigger_one_arg)
                one <= {ONE_ACT, 1'b0};
            else
                one <= {ONE_START, 1'b0};
        ONE_ACT:
            case(opcode)
            BOP_WRITE_ONE: begin
                    o_byte_enable <= 4'b0001;
                    o_write_data[7:0] <= a;
                    one <= {ONE_START, 1'b1};
            end
            BOP_WRITE_TWO: begin
                    o_byte_enable <= 4'b0010;
                     o_write_data[15:8] <= a;
                    one <= {ONE_START, 1'b1};
            end
            BOP_WRITE_THREE: begin
                    o_byte_enable <= 4'b0100;
                     o_write_data[23:16] <= a;
                    one <= {ONE_START, 1'b1};
            end
            BOP_WRITE_FOUR: begin
                    o_byte_enable <= 4'b1000;
                    o_write_data[31:24] <= a;
                    one <= {ONE_START, 1'b1};
            end
            endcase
        default:
            one <= {ONE_START, 1'b0};
      endcase
  end
end  

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
                BOP_READ_ONE:
                    if(i_out_ready) begin
                        o_data <= i_read_data[7:0];
                        none <= {BN_START, 4'b0_0_1_1};
                    end else
                        none <= {BN_ACT, 4'b0_0_1_1};
                BOP_READ_TWO:
                    if(i_out_ready) begin
                        o_data <= i_read_data[15:8];
                        none <= {BN_START, 4'b0_0_1_1};
                    end else
                        none <= {BN_ACT, 4'b0_0_1_1};
                BOP_READ_THREE:
                    if(i_out_ready) begin
                        o_data <= i_read_data[23:16];
                        none <= {BN_START, 4'b0_0_1_1};
                    end else
                        none <= {BN_ACT, 4'b0_0_1_1};
                BOP_READ_FOUR:
                    if(i_out_ready) begin
                        o_data <= i_read_data[31:24];
                        none <= {BN_START, 4'b0_0_1_1};
                    end else
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
                    if(i_data < 7) begin 
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
            if(opcode < 11) begin 
                dispatcher <= {BD_READ, 4'b1_0_1_0}; 
            end else begin
                dispatcher <= {BD_TWO, 4'b1_0_0_0}; 
            end
        end
        BD_TWO: 
        if (read_en) begin
            b <= i_data;
            dispatcher <= {BD_READ, 4'b1_0_0_1}; 
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
