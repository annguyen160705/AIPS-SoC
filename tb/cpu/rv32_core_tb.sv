`timescale 1ns/1ps

module rv32_core_tb;

    logic clk;
    logic rst_n;

    logic [31:0] pc;
    logic [31:0] instruction;

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // CPU
    rv32_core dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .instruction (instruction),
        .pc_out      (pc)
    );

    // Instruction ROM
    instruction_rom u_rom (
        .pc          (pc),
        .instruction (instruction)
    );

    initial begin

        rst_n = 0;
        #20;
        rst_n = 1;

        // Run program
        repeat (5)
            @(posedge clk);

        $display("x1 = %0d", dut.u_regfile.regs[1]);
        $display("x2 = %0d", dut.u_regfile.regs[2]);
        $display("x3 = %0d", dut.u_regfile.regs[3]);

        if ((dut.u_regfile.regs[1] == 10) &&
            (dut.u_regfile.regs[2] == 20) &&
            (dut.u_regfile.regs[3] == 30))
            $display("CPU TEST PASSED");
        else
            $display("CPU TEST FAILED");

        $finish;

    end

endmodule