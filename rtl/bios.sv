`include "types.svh"

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
    ST_START,

    ST_BOOT,
	 
	// two r branch
    ST_R_BRANCH,

    //send error
    ST_ERROR,

    //NOP
    ST_NOP_O,
    ST_NOP_P,

    //BOOT
    ST_BOOT_O1,
    ST_BOOT_O2,
    ST_BOOT_T,

    //RST
    ST_RST_S,
    ST_RST_T,

    //write
    ST_WRITE_R,
    ST_WRITE_I,
    ST_WRITE_T,
    ST_WRITE_E,

    ST_WRITE_SIZE0,
    ST_WRITE_SIZE1,
    ST_WRITE_SIZE2,
    ST_WRITE_SIZE3,

    ST_WRITE_ADDR0,
    ST_WRITE_ADDR1,
    ST_WRITE_ADDR2,
    ST_WRITE_ADDR3,

    ST_WRITE_DATALOOP,

    //read
    ST_READ_E,
    ST_READ_A,
    ST_READ_D
} state_t;

typedef enum logic [7:0] {  
    BIOS_ER_UNKNOWN = 8'(ASCII_0),
    BIOS_ER_BADCMD = 8'(ASCII_E),
    BIOS_ER_EXCEPTION =8'( ASCII_X)
} error_code_t;

typedef struct packed {
    state_t state;
    error_code_t error;
    // UART
    logic o_in_ready; // i can read data atm sure
    logic o_valid;    // the data im sending is good to go
    logic [7:0] o_data; // the data it self
    // CONTROL
    logic o_rst;
    logic o_booted;
    //RAM
    logic o_write_enable;
    logic [31:0] o_write_addr;
    logic [31:0] o_write_data;

    //WRITE/READ
    logic [31:0] size; 
} fsm_state_t;

module bios #(
    ADDR_WIDTH = 31,
    DATA_WIDTH = 31
)(
    input clk,
    input clk_en,
    input rst,

    output o_rst,
    output o_booted,

    // RAM
    output o_read_req,
    output [ADDR_WIDTH:0] o_read_addr,
    input logic [DATA_WIDTH:0] i_read_data,

    output o_write_enable,
    output [3:0] o_byte_enable,
    output [ADDR_WIDTH:0] o_write_addr,
    output [DATA_WIDTH:0] o_write_data,

     /*
     * AXI input
     */
    input  wire [7-1:0] i_data,
    input  wire         i_valid,
    output wire         o_in_ready,

    /*
     * AXI output
     */
    output wire [7-1:0] o_data,
    output wire         o_valid,
    input  wire         i_out_ready
);

fsm_state_t fsm;

assign o_in_ready = fsm.o_in_ready; 
assign o_valid = fsm.o_valid; 
assign o_data = fsm.o_data; 
assign o_rst = fsm.o_rst; 
assign o_booted = fsm.o_booted; 

//ram
assign o_byte_enable = 4'b0001;
assign o_write_enable = fsm.o_write_enable; 
assign o_write_addr = fsm.o_write_addr; 
assign o_write_data = fsm.o_write_data; 

wire read_en = i_valid & fsm.o_in_ready;
always_ff @(posedge clk) begin
    if(rst)
        fsm <= {ST_START, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
    if(clk_en & ~rst)
        case (fsm.state)
            ST_START: begin
                 fsm.o_in_ready <= 1; 
                 fsm.o_valid <= 0; 
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_n: //nop 
                            fsm <= {ST_NOP_O, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        ASCII_LOWER_b: //boot
                            fsm <= {ST_BOOT_O1, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        ASCII_LOWER_w: //write
                            fsm <= {ST_WRITE_R, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        ASCII_LOWER_r: //read or rst
                            fsm <= {ST_R_BRANCH, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_UNKNOWN, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            end
            ST_ERROR:
                fsm <= {ST_START, fsm.error, 1'd0, 1'd1, fsm.error, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // WRITE BACK ERROR CODE
            ST_BOOT:
                // we are done simply hlt in this state for ever
                fsm <= {ST_BOOT, BIOS_ER_UNKNOWN,  1'd1, 1'd0, 8'd0, 1'd0, 1'd1, 1'd0, 32'd0, 32'd0, 32'd0};
            ST_R_BRANCH:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_s: //rst 
                            fsm <= {ST_RST_T, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        ASCII_LOWER_e: //read 
                            fsm <= {ST_READ_A, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            // ==========
            // NOP
            // ==========
            ST_NOP_O:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_o: //nop 
                            fsm <= {ST_NOP_P, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            ST_NOP_P:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_p: //nop 
                            fsm <= {ST_START, BIOS_ER_UNKNOWN, 1'd1, 1'd1, 8'(ASCII_N), 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            // ==========
            // BOOT
            // ==========
            ST_BOOT_O1:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_o: //boot 
                            fsm <= {ST_BOOT_O2, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            ST_BOOT_O2:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_o: //boot 
                            fsm <= {ST_BOOT_T, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            ST_BOOT_T:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_t: //boot 
                            //rst cpu then hang on boot
                            fsm <= {ST_BOOT, BIOS_ER_UNKNOWN, 1'd1, 1'd1, 8'(ASCII_B), 1'd1, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            // ==========
            // RST
            // ==========
            ST_RST_T:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_t: //rst 
                            fsm <= {ST_START, BIOS_ER_UNKNOWN, 1'd1, 1'd1, 8'(ASCII_R), 1'd1, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            // ==========
            // WRITE
            // ==========
            ST_WRITE_R:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_r: //write 
                            fsm <= {ST_WRITE_I, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            ST_WRITE_I:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_i: //write 
                            fsm <= {ST_WRITE_T, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            ST_WRITE_T:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_t: //write 
                            fsm <= {ST_WRITE_E, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            ST_WRITE_E:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_e: //write 
                            fsm <= {ST_WRITE_SIZE0, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            ST_WRITE_SIZE0:
                if(read_en)
                    fsm <= {ST_WRITE_SIZE1, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, {fsm.size[31:8], i_data}};
            ST_WRITE_SIZE1:
                if(read_en)
                    fsm <= {ST_WRITE_SIZE2, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, {fsm.size[31:16], i_data, fsm.size[7:0]}};
            ST_WRITE_SIZE2:
                if(read_en)
                    fsm <= {ST_WRITE_SIZE3, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, {fsm.size[31:25], i_data, fsm.size[15:0]}};
            ST_WRITE_SIZE3:
                if(read_en)
                    fsm <= {ST_WRITE_SIZE2, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, {i_data, fsm.size[24:0]}};
            ST_WRITE_ADDR0:
                if(read_en)
                    fsm <= {ST_WRITE_ADDR1, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, {fsm.addr[31:8], i_data}, 32'd0, fsm.size};
            ST_WRITE_ADDR1:
                if(read_en)
                    fsm <= {ST_WRITE_ADDR2, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, {fsm.addr[31:16], i_data, fsm.addr[7:0]}, 32'd0, fsm.size};
            ST_WRITE_ADDR2:
                if(read_en)
                    fsm <= {ST_WRITE_ADDR3, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, {fsm.addr[31:25], i_data, fsm.addr[15:0]}, 32'd0, fsm.size};
            ST_WRITE_ADDR3:
                if(read_en)
                    fsm <= {ST_WRITE_DATALOOP, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, {i_data, fsm.addr[24:0]}, 32'd0, fsm.size};
            ST_WRITE_DATALOOP:
                if(read_en) begin
                    if (~(|fsm.size)) begin
                        fsm <= {ST_WRITE_DATALOOP, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd1, fsm.addr + 1, {i_data, 24'd0}, fsm.size - 1};
                    end else begin
                        fsm <= {ST_START, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                    end
                end
            // ==========
            // READ
            // ==========
            ST_READ_A:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_a: //read 
                            fsm <= {ST_READ_D, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            ST_READ_D:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_d: //read 
                            fsm <= {ST_START, BIOS_ER_UNKNOWN, 1'd1, 1'd1, 8'(ASCII_R), 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0}; // report bad cmd error
                    endcase
            default:
                fsm <= {ST_START, BIOS_ER_EXCEPTION, 1'd1, 1'd0, 8'd0, 1'd0, 1'd0, 1'd0, 32'd0, 32'd0, 32'd0};
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