`ifndef TYPES_SVH
`define TYPES_SVH
  typedef enum logic [2:0] {
    ERROR,
    R,
    I,
    S,
    B,
    U,
    J
  } inst_type_e;

    typedef enum logic [1:0] {
    Byte,
    Half,
    Word
    } mem_size_e;

`endif // TYPES_SVH