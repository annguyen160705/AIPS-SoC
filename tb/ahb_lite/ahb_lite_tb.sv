`timescale 1ns/1ps

`ifndef CLK_FREQ
`define CLK_FREQ    50_000_000
`endif 

`ifndef MEM_DELAY
`define MEM_DELAY 0
`endif 

`ifndef SIZE_IN_BYTES
`define SIZE_IN_BYTES 1024
`endif 

module ahb_lite_tb;
    localparam  SIZE_IN_BYTES = `SIZE_IN_BYTES;
    localparam  DELAY = `MEM_DELAY;
    localparam  CLK_FREQ = `CLK_FREQ;
    localparam CLK_PERIOD_HALF = 10; // 10 ns

    // Global Signals
    logic HRESETn = 1'b0;
    logic HCLK    = 1'b0;

    // Master Signals
    logic [31:0]  M_HADDR;
    logic [3:0]   M_HPROT;
    logic [1:0]   M_HTRANS;
    logic         M_HWRITE;
    logic [2:0]   M_HSIZE;
    logic [2:0]   M_HBURST;
    logic [31:0]  M_HWDATA;
    logic         M_HREADY;
    logic [31:0]  M_HRDATA;
    logic [1:0]   M_HRESP;

    // Slave Signals
    logic [31:0]  S_HADDR;
    logic [3:0]   S_HPROT;
    logic [1:0]   S_HTRANS;
    logic         S_HWRITE;
    logic [2:0]   S_HSIZE; 
    logic [2:0]   S_HBURST;
    logic [31:0]  S_HWDATA;
    logic         S_HREADY;
    logic [31:0]  S_HRDATA    [0:2]; 
    logic [1:0]   S_HRESP     [0:2]; 
    logic         S_HREADYout [0:2];
    logic         S_HSEL      [0:2];

    int pass_count;
    int fail_count;

    // AHB-Lite Fabric Interconnect
    ahb_lite_s3 #(  
        .P_HSEL0_START(16'h0000), .P_HSEL0_SIZE(16'h0100),
        .P_HSEL1_START(16'h1000), .P_HSEL1_SIZE(16'h0100),
        .P_HSEL2_START(16'h2000), .P_HSEL2_SIZE(16'h0100)
    ) u_ahb_lite (
        .HRESETn(HRESETn), .HCLK(HCLK),
        //--------------------------------------------------------//
        .M_HADDR    (M_HADDR), 
        .M_HTRANS   (M_HTRANS), 
        .M_HWRITE   (M_HWRITE),
        .M_HSIZE    (M_HSIZE), 
        .M_HBURST   (M_HBURST), 
        .M_HPROT    (M_HPROT),
        .M_HWDATA   (M_HWDATA), 
        .M_HRDATA   (M_HRDATA), 
        .M_HRESP     (M_HRESP), 
        .M_HREADY   (M_HREADY),
        //--------------------------------------------------------//
        .HWRITE (S_HWRITE), 
        .HADDR  (S_HADDR), 
        .HTRANS (S_HTRANS), 
        .HSIZE  (S_HSIZE), 
        .HBURST (S_HBURST), 
        .HPROT  (S_HPROT), 
        .HWDATA (S_HWDATA), 
        .HREADY (S_HREADY),
        //--------------------------------------------------------//
        .HSEL0(S_HSEL[0]), .HRESP0(S_HRESP[0]), .HRDATA0(S_HRDATA[0]), .HREADY0(S_HREADYout[0]),
        .HSEL1(S_HSEL[1]), .HRESP1(S_HRESP[1]), .HRDATA1(S_HRDATA[1]), .HREADY1(S_HREADYout[1]),
        .HSEL2(S_HSEL[2]), .HRESP2(S_HRESP[2]), .HRDATA2(S_HRDATA[2]), .HREADY2(S_HREADYout[2]),
        .REMAP(1'b0)
    );

    // Instantiate 3 Memory Slaves
    generate
        genvar GM;
        for (GM = 0; GM < 3; GM = GM + 1) begin : BM_BLK
            mem_ahb #(
                .SIZE_IN_BYTES(SIZE_IN_BYTES),
                .DELAY((GM == 1) ? DELAY : 0)
            ) u_mem_ahb (
                .HRESETn(HRESETn), .HCLK(HCLK),
                //--------------------------------------------------------//
                .HADDR      (S_HADDR), 
                .HTRANS     (S_HTRANS), 
                .HWRITE     (S_HWRITE),
                .HSIZE      (S_HSIZE), 
                .HBURST     (S_HBURST), 
                .HWDATA     (S_HWDATA),
                .HREADYin   (S_HREADY), 
                .HSEL       (S_HSEL[GM]),
                .HRDATA     (S_HRDATA[GM]), 
                .HRESP      (S_HRESP[GM]), 
                .HREADYout  (S_HREADYout[GM])
            );
        end
    endgenerate

    // Clock Generation
    always #CLK_PERIOD_HALF HCLK <= ~HCLK;

    // =========================================
    // TC8: WAIT-STATE MONITOR
    // =========================================
    bit tc8_monitor = 0;
    bit tc8_prev_stall = 0;
    bit tc8_hold_ok = 1;

    int tc8_stall_cycles = 0;

    logic [69:0] tc8_prev_bus;

    always @(negedge HCLK) begin
        if (!tc8_monitor) begin
            tc8_prev_stall = 0;
        end
        else if (M_HREADY === 1'b0) begin
            tc8_stall_cycles++;

            // Master must hold signals during stalls
            if (tc8_prev_stall &&
                {M_HADDR, M_HTRANS, M_HWRITE,
                M_HSIZE, M_HWDATA} !== tc8_prev_bus)
                tc8_hold_ok = 0;

            tc8_prev_bus = {
                M_HADDR, M_HTRANS, M_HWRITE,
                M_HSIZE, M_HWDATA
            };

            tc8_prev_stall = 1;
        end
        else begin
            tc8_prev_stall = 0;
        end
    end

    // =========================================
    // TC8: AHB WAIT-STATE TEST
    // =========================================
    task automatic tc_wait_state();
        logic [31:0] data;

        $display("\n--- TC8: AHB WAIT-STATE TEST ---");

        @(negedge HCLK);

        tc8_stall_cycles = 0;
        tc8_hold_ok      = 1;
        tc8_prev_stall   = 0;
        tc8_monitor      = 1;

        // Slave 1: Write with wait states
        ahb_write(32'h1000_0040, 32'hCAFE_5678);

        // Slave 1: Read with wait states
        ahb_read(32'h1000_0040, data);

        @(negedge HCLK);
        tc8_monitor = 0;

        // Check readback
        check_data(
            "TC8 Readback",
            data,
            32'hCAFE_5678
        );

        // Confirm HREADY actually went LOW
        check_data(
            "TC8 Stall Detected",
            {31'd0, (tc8_stall_cycles > 0)},
            32'd1
        );

        // Check master held signals during stalls
        check_data(
            "TC8 Stable Signals",
            {31'd0, tc8_hold_ok},
            32'd1
        );

        $display("TC8 Stall Cycles: %0d",
                tc8_stall_cycles);
    endtask

    // =========================================
    // TC7: BYTE WRITE — ALL FOUR LANES
    // =========================================
    task automatic tc_byte_write();
        logic [31:0] data;

        $display("\n--- TC7: BYTE WRITE TEST ---");

        // Initialize memory word
        ahb_write(32'h0000_0060, 32'h1122_3344);

        // Test byte lane 0
        ahb_write_byte(32'h0000_0060, 8'hA1);
        ahb_read(32'h0000_0060, data);
        check_data("TC7 Byte Lane 0", data, 32'h1122_33A1);

        // Test byte lane 1
        ahb_write_byte(32'h0000_0061, 8'hB2);
        ahb_read(32'h0000_0060, data);
        check_data("TC7 Byte Lane 1", data, 32'h1122_B2A1);

        // Test byte lane 2
        ahb_write_byte(32'h0000_0062, 8'hC3);
        ahb_read(32'h0000_0060, data);
        check_data("TC7 Byte Lane 2", data, 32'h11C3_B2A1);

        // Test byte lane 3
        ahb_write_byte(32'h0000_0063, 8'hD4);
        ahb_read(32'h0000_0060, data);
        check_data("TC7 Byte Lane 3", data, 32'hD4C3_B2A1);

    endtask

    // =========================================
    // TC6: WRITE FOLLOWED BY READ
    // =========================================
    task automatic tc_write_read();
        logic [31:0] data;

        $display("\n--- TC6: WRITE FOLLOWED BY READ ---");

        // Cycle 1: Write address phase
        @(negedge HCLK);
        M_HADDR  = 32'h0000_0040;
        M_HTRANS = 2'b10;       // NONSEQ
        M_HWRITE = 1'b1;        // WRITE
        M_HSIZE  = 3'b010;      // WORD

        @(posedge HCLK);
        wait_ready();

        // Cycle 2: Write data + Read address
        @(negedge HCLK);
        M_HWDATA = 32'hCAFE_BABE;
        M_HADDR  = 32'h0000_0040;
        M_HTRANS = 2'b10;       // NONSEQ, no IDLE
        M_HWRITE = 1'b0;        // READ

        @(posedge HCLK);
        wait_ready();

        // Cycle 3: Read data phase
        @(negedge HCLK);
        M_HTRANS = 2'b00;       // IDLE

        @(posedge HCLK);
        wait_ready();

        // Sample read data at completion
        data = M_HRDATA;

        // Verify
        check_data("TC6 Write-Read", data, 32'hCAFE_BABE);

    endtask

    // =========================================
    // TC5: BACK-TO-BACK AHB WRITES
    // =========================================
    task automatic tc_back_to_back();
        logic [31:0] data;

        $display("\n--- TC5: BACK-TO-BACK WRITES ---");

        // Address phase: Write A
        @(negedge HCLK);
        M_HADDR  = 32'h0000_0020;
        M_HTRANS = 2'b10;       // NONSEQ
        M_HWRITE = 1'b1;
        M_HSIZE  = 3'b010;      // WORD

        @(posedge HCLK);
        wait_ready();

        // Data phase A + Address phase B
        @(negedge HCLK);
        M_HWDATA = 32'h1234_5678;  // Data A
        M_HADDR  = 32'h0000_0024;  // Address B
        M_HTRANS = 2'b10;          // NONSEQ, no IDLE

        @(posedge HCLK);
        wait_ready();

        // Data phase B
        @(negedge HCLK);
        M_HWDATA = 32'hABCD_EF01;  // Data B
        M_HTRANS = 2'b00;          // IDLE after B

        @(posedge HCLK);
        wait_ready();

        // Read back both memory locations
        @(negedge HCLK);

        ahb_read(32'h0000_0020, data);
        check_data("TC5 Write A", data, 32'h1234_5678);

        ahb_read(32'h0000_0024, data);
        check_data("TC5 Write B", data, 32'hABCD_EF01);

    endtask

    

    localparam int TIMEOUT_CYCLES = 20;

    task automatic wait_ready();
        int count;

        count = 0;

        while (M_HREADY !== 1'b1) begin
            @(posedge HCLK);
            count++;

            if (count >= TIMEOUT_CYCLES)
                $fatal(1,
                    "[%0t] AHB TIMEOUT: HREADY stuck LOW",
                    $time);
        end
    endtask

    task automatic check_data(
        input string       test_name,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
        if (actual === expected) begin
            pass_count++;
            $display("[%0t] PASS: %s", $time, test_name);
        end
        else begin
            fail_count++;
            $error("[%0t] FAIL: %s | Actual=%08h Expected=%08h",
                $time, test_name, actual, expected);
        end
    endtask

    // --- AHB Master Tasks ---
    task ahb_write(input logic [31:0] addr, input logic [31:0] data);
        begin
            // Address Phase
            @(posedge HCLK);
            wait_ready(); 
            M_HADDR  <= addr;
            M_HTRANS <= 2'b10; // NONSEQ
            M_HWRITE <= 1'b1;
            M_HSIZE  <= 3'b010; // WORD
            
            // Data Phase
            @(posedge HCLK);
            wait_ready();
            M_HTRANS <= 2'b00; // IDLE
            M_HWDATA <= data;
            
            // Wait for transfer completion
            @(posedge HCLK);
            wait_ready();
        end
    endtask

    // =========================================
    // AHB BYTE WRITE TASK
    // =========================================
    task automatic ahb_write_byte(
        input logic [31:0] addr,
        input logic [7:0]  value
    );
        begin
            // Address phase
            @(posedge HCLK);
            wait_ready();

            M_HADDR  <= addr;
            M_HTRANS <= 2'b10;   // NONSEQ
            M_HWRITE <= 1'b1;    // WRITE
            M_HSIZE  <= 3'b000;  // BYTE

            // Data phase
            @(posedge HCLK);
            wait_ready();

            M_HTRANS <= 2'b00;   // IDLE

            // Position byte in correct data lane
            M_HWDATA <= {24'd0, value} << (8 * addr[1:0]);

            // Wait for completion
            @(posedge HCLK);
            wait_ready();
        end
    endtask

    task ahb_read(input logic [31:0] addr, output logic [31:0] data);
        begin
            // Address Phase
            @(posedge HCLK);
            wait_ready();
            M_HADDR  <= addr;
            M_HTRANS <= 2'b10; // NONSEQ
            M_HWRITE <= 1'b0;
            M_HSIZE  <= 3'b010; // WORD
            
            // Data Phase
            @(posedge HCLK);
            wait_ready();
            M_HTRANS <= 2'b00; // IDLE
            
            // FIXED: Wait for transfer completion before sampling data
            @(posedge HCLK); 
            wait_ready();
            data = M_HRDATA;
        end
    endtask

    // --- Main Stimulus ---
    logic [31:0] read_data;

    initial begin
        $timeformat(-9, 0, " ns", 10);
        pass_count = 0;
        fail_count = 0;
        // Initialize Master Defaults
        M_HADDR  <= 32'h0;
        M_HTRANS <= 2'b00; // IDLE
        M_HWRITE <= 1'b0;
        M_HSIZE  <= 3'b000;
        M_HBURST <= 3'b000;
        M_HPROT  <= 4'h0;
        M_HWDATA <= 32'h0;

        // Reset Sequence
        HRESETn <= 1'b0;
        repeat (10) @(posedge HCLK);
        HRESETn <= 1'b1;
        repeat (2) @(posedge HCLK);

        $display("\n--- Starting AHB Transactions ---");

        // 1. Test Slave 0 (Memory maps HADDR[31:16] = 16'h0000)
        $display("Writing to Slave 0...");
        ahb_write(32'h0000_0004, 32'hAAAA_BBBB);
        ahb_read(32'h0000_0004, read_data);
        check_data("Slave 0", read_data, 32'hAAAA_BBBB);
        $display("Read from Slave 0: 0x%08X (Expected: 0xAAAABBBB)", read_data);

        // 2. Test Slave 1 (Memory maps HADDR[31:16] = 16'h1000)
        $display("\nWriting to Slave 1...");
        ahb_write(32'h1000_0008, 32'h1111_2222);
        ahb_read(32'h1000_0008, read_data);
        check_data("Slave 1", read_data, 32'h1111_2222);
        $display("Read from Slave 1: 0x%08X (Expected: 0x11112222)", read_data);

        // 3. Test Slave 2 (Memory maps HADDR[31:16] = 16'h2000)
        $display("\nWriting to Slave 2...");
        ahb_write(32'h2000_000C, 32'hDEAD_BEEF);
        ahb_read(32'h2000_000C, read_data);
        check_data("Slave 2", read_data, 32'hDEAD_BEEF);
        $display("Read from Slave 2: 0x%08X (Expected: 0xDEADBEEF)", read_data);

        // 4. Test Default Slave (Unmapped address, e.g. 16'h3000)
        $display("\nReading from Unmapped Address (Testing Default Slave)...");
        ahb_read(32'h3000_0000, read_data);
        check_data("Default Slave", {30'b0, M_HRESP}, 32'h0000_0001);
        $display("HRESP from Default Slave: 2'b%02b (Expected: 2'b01 ERROR)", M_HRESP);

        // 5. Back to back
        tc_back_to_back();

        // 6. Write follow by read
        tc_write_read();

        // 7. Byte write
        tc_byte_write();   

        // 8. Wait state
        tc_wait_state(); 


        $display("[%0t] AHB Clock = 50 MHz", $time);
        
        
        $display("========================");
        $display("AHB TEST SUMMARY");
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);
        $display("========================");
        
        $display("--- Simulation Complete ---\n");
        $finish;
    end
endmodule