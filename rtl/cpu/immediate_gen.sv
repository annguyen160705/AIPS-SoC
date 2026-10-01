module immediate_gen(
      input logic [31:0]    instruction
    , output logic [31:0]   immediate
);

    logic [6:0] opcode;

    assign opcode   = instruction[6:0];

    always_comb begin
        case (opcode)

            7'b0010011:begin
                immediate = {{20{instruction[31]}},instruction[31:20]}; // Sign-extend 12-bit immediate to 32 bits
            end // ADDI - I-type immediate

            7'b0000011: begin
                immediate   = {{20{instruction[31]}},instruction[31:20]};
            end // LW - I-type immediate

            7'b0100011: begin
                immediate   = {{20{instruction[31]}},instruction[31:25],instruction[11:7]};
            end // SW - S-type immediate

            7'b1100011: begin
                immediate   = {{19{instruction[31]}},instruction[31],instruction[7],instruction[30:25],instruction[11:8],1'b0};
            end // BEQ / BNE

            7'b0110111: begin
                immediate   = {instruction[31:12], 12'b0};
            end

            7'b1101111: begin
                immediate   = {{11{instruction[31]}},
                                instruction[31],
                                instruction[19:12],
                                instruction[20],
                                instruction[30:21],
                                1'b0};
            end

            7'b1100111: begin
                immediate   = {{20{instruction[31]}},
                                instruction[31:20]};
            end


            default: begin
                immediate = 32'd0;
            end
        endcase
    end
    
endmodule

// Example 1: ADDI (I-Type)
// addi x1, x0, 10
// instruction = 32'h00A00093
// instruction[31:20] = 000000001010
// immediate = 10

// Example 2: LW (I-Type)
// lw x3, 8(x1)
// instruction = 32'h0080A183
// instruction[31:20] = 000000001000
// immediate = 8
// Address = x1 + 8

// Example 3: SW (S-Type)
// sw x2, 12(x1)
// instruction = 32'h0020A623
// instruction[31:25] = 0000000
// instruction[11:7]  = 01100
// immediate = 12
// Address = x1 + 12