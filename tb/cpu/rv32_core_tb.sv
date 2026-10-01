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
    int pass_count;
    int fail_count;

    pass_count = 0;
    fail_count = 0;

    $timeformat(-9, 0, " ns", 10);
    rst_n = 0;

    // TEST 1: ADD / ADDI / SUB
    load_program("firmware/hex/tc1_alu.hex");
    repeat (4) @(posedge clk);
    #1;

    if ((dut.u_regfile.regs[1] === 32'd10) &&
        (dut.u_regfile.regs[2] === 32'd20) &&
        (dut.u_regfile.regs[3] === 32'd30) &&
        (dut.u_regfile.regs[4] === 32'd20)) begin
        pass_count++;
        $display("[%0t] TC1 ALU PASSED", $time);
    end
    else begin
        fail_count++;
        $error("TC1 ALU FAILED");
    end

    // TEST 2: LW / SW
    load_program("firmware/hex/tc2_lw_sw.hex");
    repeat (3) @(posedge clk);
    #1;

    if ((dut.u_regfile.regs[5] === 32'd99) &&
        (dut.u_regfile.regs[6] === 32'd99)) begin
        pass_count++;
        $display("[%0t] TC2 LW/SW PASSED", $time);
    end
    else begin
        fail_count++;
        $error("TC2 LW/SW FAILED");
    end

    // TEST 3: LB / SB
    load_program("firmware/hex/tc3_lb_sb.hex");
    repeat (6) @(posedge clk);
    #1;

    if ((dut.u_regfile.regs[8] === 32'd127) &&
        (dut.u_regfile.regs[10] === 32'hFFFFFFFF)) begin
        pass_count++;
        $display("[%0t] TC3 LB/SB PASSED", $time);
    end
    else begin
        fail_count++;
        $error("TC3 LB/SB FAILED");
    end

    // TEST 4: BEQ / BNE
    load_program("firmware/hex/tc4_branch.hex");
    repeat (6) @(posedge clk);
    #1;

    if ((dut.u_regfile.regs[3] === 32'd20) &&
        (dut.u_regfile.regs[4] === 32'd7)) begin
        pass_count++;
        $display("[%0t] TC4 BRANCH PASSED", $time);
    end
    else begin
        fail_count++;
        $error("TC4 BRANCH FAILED");
    end

    // TEST 5: LUI
    load_program("firmware/hex/tc5_lui.hex");
    repeat (1) @(posedge clk);
    #1;

    if (dut.u_regfile.regs[11] === 32'h10000000) begin
        pass_count++;
        $display("[%0t] TC5 LUI PASSED", $time);
    end
    else begin
        fail_count++;
        $error("TC5 LUI FAILED");
    end

    // TEST 6: JAL / JALR
    load_program("firmware/hex/jump_test.hex");
    repeat (5) @(posedge clk);
    #1;

    if ((dut.u_regfile.regs[1] === 32'd8) &&
        (dut.u_regfile.regs[2] === 32'd20) &&
        (dut.u_regfile.regs[6] === 32'd0) &&
        (dut.u_regfile.regs[7] === 32'd7) &&
        (dut.u_regfile.regs[8] === 32'd0) &&
        (dut.u_regfile.regs[9] === 32'd9)) begin
        pass_count++;
        $display("[%0t] TC6 JAL/JALR PASSED", $time);
    end
    else begin
        fail_count++;
        $error("TC6 JAL/JALR FAILED");
    end

    // FINAL SUMMARY
    $display("================================");
    $display("        CPU TEST SUMMARY        ");
    $display("================================");
    $display("PASS : %0d", pass_count);
    $display("FAIL : %0d", fail_count);
    $display("TIME : %0t", $time);
    $display("================================");

    if (fail_count != 0)
        $fatal(1, "CPU TESTS FAILED");

    $finish;
end


    task automatic load_program(input string filename);

    @(negedge clk);
    rst_n = 0; // Reset CPU and PC

    // Clear instruction ROM
    for (int i = 0; i < 256; i++)
        u_rom.mem[i] = 32'h00000013; // NOP

    // Clear data memory
    for (int i = 0; i < 256; i++)
        dut.u_data_memory.mem[i] = 32'd0;

    // Load selected program
    $readmemh(filename, u_rom.mem);

    repeat (2) @(negedge clk);
    rst_n = 1;

    endtask

endmodule