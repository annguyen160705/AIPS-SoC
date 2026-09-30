module decoder(
      input logic [31:0] instruction
    , output logic [6:0] opcode
    , output logic [4:0] rd
    , output logic [2:0] funct3
    , output logic [4:0] rs1
    , output logic [4:0] rs2
    , output logic [6:0] funct7
);

    assign opcode   = instruction[6:0];   // Instruction type
    assign rd       = instruction[11:7];  // Destination register
    assign funct3   = instruction[14:12]; // Function field
    assign rs1      = instruction[19:15]; // Source register 1
    assign rs2      = instruction[24:20]; // Source register 2
    assign funct7   = instruction[31:25]; // Function field

    // Example instruction:
    // add x3, x1, x2
    //
    // Meaning:
    // x3 = x1 + x2
    //
    // Machine code:
    // 32'h002081B3
    // opcode = 7'b0110011;   R-type instruction
    // rd     = 5'd3;         Destination register = x3
    // funct3 = 3'b000;       ADD/SUB function code
    // rs1    = 5'd1;         Source register 1 = x1
    // rs2    = 5'd2;         Source register 2 = x2
    // funct7 = 7'b0000000;   funct7 = 0 selects ADD

endmodule