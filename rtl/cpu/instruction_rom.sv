module instruction_rom(
      input logic [31:0] pc
    , output logic [31:0] instruction
);

    logic [31:0] mem [0:255];

    initial begin
        $readmemh("firmware/hex/cpu_test.hex", mem); // load program
    end

    assign instruction  = mem[pc[9:2]]; // PC / 4
    
endmodule

// PC = 0x00000008
// pc[9:2] = 2
// instruction = mem[2] = 002081B3
// → add x3, x1, x2