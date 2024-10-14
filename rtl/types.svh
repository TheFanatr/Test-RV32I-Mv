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

`endif // TYPES_SVH