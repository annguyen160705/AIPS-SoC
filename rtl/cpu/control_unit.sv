module control_unit(
      input logic [6:0] opcode
    , input logic [2:0] funct3
    , input logic [6:0] funct7

    , output logic      reg_write
    , output logic      alu_src_b
    , output logic [2:0] alu_op 
);

    always_comb begin
        reg_write   = 1'b0;
        alu_src_b   = 1'b0;
        alu_op      = 3'b000;

        case (opcode)

            7'b0110011: begin
                reg_write   = 1'b1;
                alu_src_b   = 1'b0;

                if((funct3  == 3'b000) && (funct7 == 7'b0100000))
                    alu_op  = 3'b001;   //SUB
                else
                    alu_op  = 3'b000;   //ADD
            end

            7'b0010011: begin
                reg_write   = 1'b1;
                alu_src_b   = 1'b1;
                alu_op      = 3'b000;   //ADD
            end
        endcase
    end
    
endmodule

// Example 1:
// add x3, x1, x2
//
// opcode = 0110011
// funct3 = 000
// funct7 = 0000000
//
// Control output:
// reg_write = 1   -> write result to x3
// alu_src_b = 0   -> ALU B uses rs2
// alu_op    = 000 -> ADD


// Example 2:
// sub x3, x1, x2
//
// opcode = 0110011
// funct3 = 000
// funct7 = 0100000
//
// Control output:
// reg_write = 1   -> write result to x3
// alu_src_b = 0   -> ALU B uses rs2
// alu_op    = 001 -> SUB


// Example 3:
// addi x3, x1, 10
//
// opcode = 0010011
//
// Control output:
// reg_write = 1   -> write result to x3
// alu_src_b = 1   -> ALU B uses immediate
// alu_op    = 000 -> ADD