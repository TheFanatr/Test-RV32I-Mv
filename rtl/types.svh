`ifndef TYPES_SVH
`define TYPES_SVH
`define SYSFLAGS_COUNT 1

typedef enum bit { 
  __SYSFLAGS_COUNT = 1
} name;

typedef enum bit [2:0] {
  ERROR,
  R,
  I,
  S,
  B,
  U,
  J
} inst_type_e;

typedef enum bit [1:0] {
  JM_NEXT,
  JM_RELATIVE,
  JM_ABSOLUTE
} jump_mode_e;

typedef enum reg [1:0] { 
  RM_RAM_READ_WAIT,
  RM_ACT,
  RM_RAM_WRITE_WAIT // prefetches
} run_mode_e;

typedef enum logic [__SYSFLAGS_COUNT-1:0] {
  SYSFLAGS_KEEPALIVE = 1
} sysflags_e;

`endif // TYPES_SVH