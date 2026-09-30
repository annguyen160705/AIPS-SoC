module immediate_gen(
      input logic [31:0]    instruction
    , output logic [31:0]   immediate
);

    logic [6:0] opcode;

    assign opcode   = instruction[6:0];

    always_comb begin
        case (opcode)

            7'b0010011: //ADDI
                immediate = {{20{instruction[31]}},instruction[31:20]}; // Sign-extend 12-bit immediate to 32 bits
            
            default: begin
                immediate = 32'd0;
            end
        endcase
    end
    
endmodule