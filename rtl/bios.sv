
// 2 STATES: BOOT; RUN
// BOOT = listening for commands
// RUN = stops listening for commands and simply forwards rx and tx directly to cpu gpio system

// BOOT MODE COMMANDS
// ===========================
// nop; does nothing will be zero
// boot; enters into boot mode
// rst; triger internal reset of cpu
// echo; writes back a simple ping responce
// write; write to ram
//      writesize writeaddr data
// read; read from ram
//      readsize readaddr

 // 2^6 = 64 max states
typedef enum logic [5:0] {  
    ST_START
} state_t;

typedef enum logic [3:0] {  
    BIOS_ER_UNKNOWN
} error_code_t;

typedef struct packed {
    state_t state;
    error_code_t error;
} fsm_state_t;

`include "types.svh"

module bios(
    input clk,
    input clk_en,
    input rst
);

fsm_state_t fsm;

always_ff @(posedge clk)
    if(clk_en)
        case (fsm.state)
            ST_START: 
                fsm <= {ST_START, BIOS_ER_UNKNOWN};
            default:
                fsm <= {ST_START, BIOS_ER_UNKNOWN};
        endcase

`ifdef TESTING1
    always @(posedge clk) begin
    $display("clk: ", clk);
    $display("clk_en: ", clk_en);
    $display("rst: ", rst);
    end
`endif

endmodule
