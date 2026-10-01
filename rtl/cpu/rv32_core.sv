module rv32_core(
      input logic           clk
    , input logic           rst_n
    , input logic [31:0]    instruction
    , output logic [31:0]   pc_out
);

//--------------------------------------------------------//

//--------------------------------------------------------//
logic [31:0] pc_next;        // PC: next instruction address

logic [6:0]  opcode;         // Decoder -> Control Unit
logic [4:0]  rd;             // Decoder -> Register File
logic [2:0]  funct3;         // Decoder -> Control Unit
logic [4:0]  rs1;            // Decoder -> Register File
logic [4:0]  rs2;            // Decoder -> Register File
logic [6:0]  funct7;        // Decoder -> Control Unit

logic [31:0] immediate;      // Immediate Generator -> ALU B MUX

logic        reg_write;      // Control Unit -> Register File
logic        alu_src_b;      // Control Unit -> ALU B MUX
logic [2:0]  alu_op;         // Control Unit -> ALU

logic        mem_write;      // Control Unit -> Data Memory
logic        mem_to_reg;     // Control Unit -> Writeback MUX

logic [31:0] alu_result;     // ALU -> Data Memory / Writeback MUX
logic [31:0] rs1_data;       // Register File -> ALU A
logic [31:0] rs2_data;       // Register File -> ALU B MUX / Data Memory

logic [31:0] alu_b;          // ALU B MUX -> ALU
logic        zero;           // ALU -> Branch Control (future)

logic [31:0] mem_read_data;  // Data Memory -> Writeback MUX
logic [31:0] writeback_data; // Writeback MUX -> Register File

logic branch;
logic branch_taken;

logic lui_sel;

logic jump;
logic jalr;

assign branch_taken = branch && ((funct3 == 3'b000 && zero) ||
                                  funct3 == 3'b001 && !zero);

assign pc_next  = jalr          ? (alu_result & 32'hFFFF_FFFE)
                : jump          ? pc_out + immediate 
                : branch_taken  ? pc_out + immediate 
                : pc_out + 32'd4;

assign alu_b = alu_src_b    ? immediate         // Select immediate
                            : rs2_data;         // Select register data

assign writeback_data = (jump || jalr)  ? pc_out + 32'd4    : 
                        lui_sel         ? immediate         :
                        mem_to_reg      ? mem_read_data     :
                        alu_result;
       

//--------------------------------------------------------//

//--------------------------------------------------------//

pc u_pc (
    .clk        (clk)
    ,.rst_n     (rst_n)
    ,.pc_write  (1'b1)
    ,.pc_next   (pc_next)
    ,.pc        (pc_out)
);
//--------------------------------------------------------//

//--------------------------------------------------------//


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



immediate_gen u_imm(
    .instruction    (instruction)
    ,.immediate     (immediate)
);

//--------------------------------------------------------//

//--------------------------------------------------------//


control_unit u_control(
    .opcode     (opcode)
    ,.funct3    (funct3)
    ,.funct7    (funct7)
    
    ,.reg_write (reg_write)
    ,.alu_src_b (alu_src_b)
    ,.alu_op    (alu_op)

    ,.mem_write (mem_write)
    ,.mem_to_reg(mem_to_reg)

    ,.branch    (branch)

    ,.lui_sel   (lui_sel)

    ,.jump      (jump)
    ,.jalr      (jalr)
);

//--------------------------------------------------------//

//--------------------------------------------------------//



regfile u_regfile(
    .clk    (clk)
    ,.rst_n (rst_n)

    ,.rs1_addr  (rs1)
    ,.rs2_addr  (rs2)
    ,.rd_addr   (rd)

    ,.rd_data   (writeback_data)
    ,.reg_write (reg_write)

    ,.rs1_data  (rs1_data)
    ,.rs2_data  (rs2_data)
);

//--------------------------------------------------------//

//--------------------------------------------------------//



alu u_alu (
    .a          (rs1_data)
    ,.b         (alu_b)
    ,.alu_op    (alu_op)

    ,.result    (alu_result)
    ,.zero      (zero)
);

//--------------------------------------------------------//

//--------------------------------------------------------//


data_memory u_data_memory(
    .clk    (clk)
    ,.funct3    (funct3)
    ,.mem_write (mem_write)
    ,.address   (alu_result)    //rs1 + immediate
    ,.write_data(rs2_data)      // Data for SW
    ,.read_data (mem_read_data) // Data for LW
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