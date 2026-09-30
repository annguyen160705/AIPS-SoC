module rv32_core(
      input logic           clk
    , input logic           rst_n
    , input logic [31:0]    instruction
    , output logic [31:0]   pc_out
);

//--------------------------------------------------------//

//--------------------------------------------------------//
logic [31:0] pc_next;

assign  pc_next = pc_out + 32'd4;

pc u_pc (
    .clk        (clk)
    ,.rst_n     (rst_n)
    ,.pc_write  (1'b1)
    ,.pc_next   (pc_next)
    ,.pc        (pc_out)
);
//--------------------------------------------------------//

//--------------------------------------------------------//

logic [6:0]     opcode;
logic [4:0]     rd;
logic [2:0]     funct3;
logic [4:0]     rs1;
logic [4:0]     rs2;
logic [6:0]     funct7;



decoder u_decoder(
    .instruction    (instruction)
    ,.opcode        (opcode)
    ,.rd            (rd)
    ,.funct3        (funct3)
    ,.rs1           (rs1)
    ,.rs2           (rs2)
    ,.funct7        (funct7)
);

//--------------------------------------------------------//

//--------------------------------------------------------//

logic [31:0] immediate;

immediate_gen u_imm(
    .instruction    (instruction)
    ,.immediate     (immediate)
);

//--------------------------------------------------------//

//--------------------------------------------------------//

logic       reg_write;
logic       alu_src_b;
logic [2:0] alu_op;

control_unit u_control(
    .opcode     (opcode)
    ,.funct3    (funct3)
    ,.funct7    (funct7)
    
    ,.reg_write (reg_write)
    ,.alu_src_b (alu_src_b)
    ,.alu_op    (alu_op)
);

//--------------------------------------------------------//

//--------------------------------------------------------//

logic [31:0]    alu_result;
logic [31:0]    rs1_data;
logic [31:0]    rs2_data;

regfile u_regfile(
    .clk    (clk)
    ,.rst_n (rst_n)

    ,.rs1_addr  (rs1)
    ,.rs2_addr  (rs2)
    ,.rd_addr   (rd)

    ,.rd_data   (alu_result)
    ,.reg_write (reg_write)

    ,.rs1_data  (rs1_data)
    ,.rs2_data  (rs2_data)
);

//--------------------------------------------------------//

//--------------------------------------------------------//

logic [31:0]    alu_b;
logic           zero;


assign  alu_b = alu_src_b ? immediate : rs2_data;

alu u_alu (
    .a          (rs1_data)
    ,.b         (alu_b)
    ,.alu_op    (alu_op)

    ,.result    (alu_result)
    ,.zero      (zero)
);


endmodule

// Example:
// addi x1, x0, 10
//
// instruction = 32'h00A00093
//
// Decoder:
// rs1    = x0
// rd     = x1
// opcode = 0010011
//
// Immediate:
// immediate = 10
//
// Control:
// reg_write = 1
// alu_src_b = 1       // Use immediate
// alu_op    = ADD
//
// ALU:
// 0 + 10 = 10
//
// Writeback:
// x1 = 10
//
// PC:
// PC = PC + 4