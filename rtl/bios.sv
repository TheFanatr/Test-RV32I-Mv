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
    BIOS_ER_UNKNOWN = ASCII_0,
    BIOS_ER_BADCMD = ASCII_E,
    BIOS_ER_EXCEPTION = ASCII_X
} error_code_t;

typedef struct packed {
    state_t state;
    error_code_t error;
    logic rx_valid;
    logic rx_ready;
    logic [7:0] rx_data;

} fsm_state_t;

module bios(
    input clk,
    input clk_en,
    input rst,

    input [7:0] rx_data,
    input rx_valid,
    input rx_ready,

    input [7:0] tx_data,
    input tx_valid,
    input tx_ready
);

fsm_state_t fsm;

assign tx_valid = fsm.tx_valid; 
assign tx_ready = fsm.tx_ready; 
assign tx_data = fsm.tx_data; 

wire step_en = rx_valid & rx_ready & clk_en;
always_ff @(posedge clk)
    if(step_en)
        case (fsm.state)
            ST_START: 
                case (rx_data)
                    ASCII_LOWER_n: //nop 
                        fsm <= {ST_NOP_O, BIOS_ER_UNKNOWN, 0, 0, 0};
                    ASCII_LOWER_b: //boot
                        fsm <= {ST_BOOT_O1, BIOS_ER_UNKNOWN, 0, 0, 0};
                    ASCII_LOWER_r: //rst
                        fsm <= {ST_RST_S, BIOS_ER_UNKNOWN, 0, 0, 0};
                    ASCII_LOWER_w: //write
                        fsm <= {ST_WRITE_R, BIOS_ER_UNKNOWN, 0, 0, 0};
                    ASCII_LOWER_r: //read
                        fsm <= {ST_READ_E, BIOS_ER_UNKNOWN, 0, 0, 0};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_UNKNOWN, 0, 0, 0}; // report bad cmd error
                endcase
            ST_ERROR:
                fsm <= {ST_NOP_O, fsm.error, 1, 1, fsm.error}; // WRITE BACK ERROR CODE
            // ==========
            // NOP
            // ==========
            ST_NOP_O:
                case (rx_data)
                    ASCII_LOWER_o: //nop 
                        fsm <= {ST_NOP_P, BIOS_ER_UNKNOWN, 0, 0, 0};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            ST_NOP_P:
                case (rx_data)
                    ASCII_LOWER_p: //nop 
                        fsm <= {ST_START, BIOS_ER_UNKNOWN, 1, 1, ASCII_N};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            // ==========
            // BOOT
            // ==========
            ST_BOOT_O1:
                case (rx_data)
                    ASCII_LOWER_o: //boot 
                        fsm <= {ST_BOOT_O2, BIOS_ER_UNKNOWN, 0, 0, 0};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            ST_BOOT_O2:
                case (rx_data)
                    ASCII_LOWER_o: //boot 
                        fsm <= {ST_BOOT_T, BIOS_ER_UNKNOWN, 0, 0, 0};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            ST_BOOT_T:
                case (rx_data)
                    ASCII_LOWER_t: //boot 
                        fsm <= {ST_START, BIOS_ER_UNKNOWN, 1, 1, ASCII_B};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            // ==========
            // RST
            // ==========
            ST_RST_S:
                case (rx_data)
                    ASCII_LOWER_s: //rst 
                        fsm <= {ST_RST_T, BIOS_ER_UNKNOWN, 0, 0, 0};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            ST_RST_T:
                case (rx_data)
                    ASCII_LOWER_t: //rst 
                        fsm <= {ST_START, BIOS_ER_UNKNOWN, 1, 1, ASCII_R};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            // ==========
            // WRITE
            // ==========
            ST_WRITE_R:
                case (rx_data)
                    ASCII_LOWER_r: //write 
                        fsm <= {ST_WRITE_I, BIOS_ER_UNKNOWN, 0, 0, 0};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            ST_WRITE_I:
                case (rx_data)
                    ASCII_LOWER_i: //write 
                        fsm <= {ST_WRITE_T, BIOS_ER_UNKNOWN, 0, 0, 0};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            ST_WRITE_T:
                case (rx_data)
                    ASCII_LOWER_T: //write 
                        fsm <= {ST_WRITE_E, BIOS_ER_UNKNOWN, 0, 0, 0};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            ST_WRITE_E:
                case (rx_data)
                    ASCII_LOWER_E: //write 
                        fsm <= {ST_START, BIOS_ER_UNKNOWN, 1, 1, ASCII_W};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            // ==========
            // READ
            // ==========
            ST_READ_E:
                case (rx_data)
                    ASCII_LOWER_e: //read 
                        fsm <= {ST_READ_A, BIOS_ER_UNKNOWN, 0, 0, 0};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            ST_READ_A:
                case (rx_data)
                    ASCII_LOWER_a: //read 
                        fsm <= {ST_READ_D, BIOS_ER_UNKNOWN, 0, 0, 0};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            ST_READ_D:
                case (rx_data)
                    ASCII_LOWER_D: //read 
                        fsm <= {ST_START, BIOS_ER_UNKNOWN, 1, 1, ASCII_R};
                    default:
                        fsm <= {ST_ERROR, BIOS_ER_BADCMD, 0, 0, 0}; // report bad cmd error
                endcase
            default:
                fsm <= {ST_START, BIOS_ER_EXCEPTION, 0, 0, 0};
        endcase

`ifdef TESTING1
    always @(posedge clk) begin
    $display("clk: ", clk);
    $display("clk_en: ", clk_en);
    $display("rst: ", rst);
    end
`endif

endmodule
