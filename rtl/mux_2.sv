module mux_2 #
(
    parameter BITS = 32
)(
    input [BITS-1:0] a,
    input [BITS-1:0] b,

    input s,

    output logic [BITS-1:0] o
);

always_comb begin   
    case (s)
        1'b0:
            o = a; 
        1'b1: 
            o = b;
    endcase
end
    
endmodule