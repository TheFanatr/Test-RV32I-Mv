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
    logic o_in_ready; // i can read data atm sure
    logic o_valid;    // the data im sending is good to go
    logic [7:0] o_data; // the data it self
} fsm_state_t;

module bios(
    input clk,
    input clk_en,
    input rst,

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

wire read_en = i_valid & fsm.o_in_ready;
always_ff @(posedge clk)
    if(clk_en)
        case (fsm.state)
            ST_START: begin
                 fsm.o_in_ready <= 1; 
                 fsm.o_valid <= 0; 
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_n: //nop 
                            fsm <= {ST_NOP_O, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        ASCII_LOWER_b: //boot
                            fsm <= {ST_BOOT_O1, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        ASCII_LOWER_w: //write
                            fsm <= {ST_WRITE_R, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        ASCII_LOWER_r: //read or rst
                            fsm <= {ST_R_BRANCH, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_UNKNOWN, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            end
            ST_ERROR:
                fsm <= {ST_START, fsm.error, 1'd0, 1'd1, fsm.error}; // WRITE BACK ERROR CODE
            ST_R_BRANCH:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_s: //rst 
                            fsm <= {ST_RST_T, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        ASCII_LOWER_e: //read 
                            fsm <= {ST_READ_A, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            // ==========
            // NOP
            // ==========
            ST_NOP_O:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_o: //nop 
                            fsm <= {ST_NOP_P, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            ST_NOP_P:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_p: //nop 
                            fsm <= {ST_START, BIOS_ER_UNKNOWN, 1'd1, 1'd1, 8'(ASCII_N)};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            // ==========
            // BOOT
            // ==========
            ST_BOOT_O1:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_o: //boot 
                            fsm <= {ST_BOOT_O2, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            ST_BOOT_O2:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_o: //boot 
                            fsm <= {ST_BOOT_T, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            ST_BOOT_T:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_t: //boot 
                            fsm <= {ST_START, BIOS_ER_UNKNOWN, 1'd1, 1'd1, 8'(ASCII_B)};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            // ==========
            // RST
            // ==========
            ST_RST_T:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_t: //rst 
                            fsm <= {ST_START, BIOS_ER_UNKNOWN, 1'd1, 1'd1, 8'(ASCII_R)};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            // ==========
            // WRITE
            // ==========
            ST_WRITE_R:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_r: //write 
                            fsm <= {ST_WRITE_I, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            ST_WRITE_I:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_i: //write 
                            fsm <= {ST_WRITE_T, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            ST_WRITE_T:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_t: //write 
                            fsm <= {ST_WRITE_E, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            ST_WRITE_E:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_e: //write 
                            fsm <= {ST_START, BIOS_ER_UNKNOWN, 1'd1, 1'd1, 8'(ASCII_W)};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            // ==========
            // READ
            // ==========
            ST_READ_A:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_a: //read 
                            fsm <= {ST_READ_D, BIOS_ER_UNKNOWN, 1'd1, 1'd0, 8'd0};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            ST_READ_D:
                if(read_en)
                    case (i_data)
                        ASCII_LOWER_d: //read 
                            fsm <= {ST_START, BIOS_ER_UNKNOWN, 1'd1, 1'd1, 8'(ASCII_R)};
                        default:
                            fsm <= {ST_ERROR, BIOS_ER_BADCMD, 1'd0, 1'd0, 8'd0}; // report bad cmd error
                    endcase
            default:
                fsm <= {ST_START, BIOS_ER_EXCEPTION, 1'd1, 1'd0, 8'd0};
        endcase

`ifdef TESTING1
    always @(posedge clk) begin
    $display("clk: ", clk);
    $display("clk_en: ", clk_en);
    $display("rst: ", rst);
    end
`endif

endmodule