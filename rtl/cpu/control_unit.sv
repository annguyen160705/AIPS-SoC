module control_unit(
      input logic [6:0] opcode
    , input logic [2:0] funct3
    , input logic [6:0] funct7

    , output logic      reg_write
    , output logic      alu_src_b
    , output logic [2:0] alu_op 
    
    , output logic      mem_write
    , output logic      mem_to_reg

    , output logic      branch

    , output logic      lui_sel 

    , output logic      jump
    , output logic      jalr
);

    always_comb begin
        mem_write   = 1'b0;
        mem_to_reg  = 1'b0;

        reg_write   = 1'b0;
        alu_src_b   = 1'b0;
        alu_op      = 3'b000;

        branch      = 1'b0;

        lui_sel     = 1'b0;

        jump        = 1'b0;
        jalr        = 1'b0;

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

            7'b0000011: begin           // LW
                reg_write   = 1'b1;
                alu_src_b   = 1'b1;     // ALU B = immediate
                alu_op      = 3'b000;   // ADD address
                mem_write   = 1'b0;
                mem_to_reg  = 1'b1;     // Write memory data to rd
            end

            7'b0100011: begin           // SW
                reg_write   = 1'b0;
                alu_src_b   = 1'b1;     // ALU B = immediate
                alu_op      = 3'b000;   // ADD address
                mem_write   = 1'b1;
                mem_to_reg  = 1'b0;
            end

            7'b1100011: begin           // BEQ / BNE
                branch      = 1'b1;
                reg_write   = 1'b0;
                alu_src_b   = 1'b0;
                alu_op      = 3'b001;   // SUB to compare registers
            end

            7'b0110111: begin
                reg_write   = 1'b1;
                lui_sel     = 1'b1;
            end

            7'b1101111: begin
                reg_write   = 1'b1;
                jump        = 1'b1;
            end

            7'b1100111: begin
                reg_write   = 1'b1;
                jalr        = 1'b1;
                alu_src_b   = 1'b1;
                alu_op      = 3'b000; // ADD
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