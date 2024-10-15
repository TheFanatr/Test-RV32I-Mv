`ifndef TYPES_SVH
`define TYPES_SVH

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

`endif // TYPES_SVH