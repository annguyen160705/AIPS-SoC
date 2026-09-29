module alu(
      input logic [31:0]    a
    , input logic [31:0]    b
    , input logic [2:0]     alu_op

    , output logic [31:0]   result
    , output logic          zero
);


    always_comb begin
        case (alu_op)

            3'b000: result = a + b;
            3'b001: result = a - b;

            default: result = 32'd0;
        endcase
    end

    assign  zero = (result == 32'd0);
    
endmodule