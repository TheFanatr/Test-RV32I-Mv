module Mux2 #
(
    parameter BITS = 31
)(
    input [BITS:0] a,
    input [BITS:0] b,

    input s,

    output logic [BITS:0] o
);

always_comb begin : Mux2   
    case (s)
        1'b0:
            o = a; 
        1'b1: 
            o = b;
    endcase
end
    
endmodule