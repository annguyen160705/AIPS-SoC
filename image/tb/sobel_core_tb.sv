`timescale 1ns/1ps

module sobel_core_tb;

    logic [7:0] p00, p01, p02;
    logic [7:0] p10, p11, p12;
    logic [7:0] p20, p21, p22;

    logic [10:0] threshold;
    logic edge_out;

    sobel_core dut (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),

        .threshold(threshold),
        .edge_out(edge_out)
    );


    initial begin

        threshold = 200;


        // ============================================
        // TEST 1: Uniform image
        //
        // 100 100 100
        // 100 100 100
        // 100 100 100
        //
        // Gx = 0
        // Gy = 0
        // gradient = 0
        // edge_out = 0
        // ============================================

        p00 = 100; p01 = 100; p02 = 100;
        p10 = 100; p11 = 100; p12 = 100;
        p20 = 100; p21 = 100; p22 = 100;

        #10;

        $display("TEST 1");
        $display("Gx       = %0d", dut.gx);
        $display("Gy       = %0d", dut.gy);
        $display("Gradient = %0d", dut.gradient);
        $display("Edge_out     = %0d", edge_out);

        if (edge_out !== 1'b0)
            $error("TEST 1 FAILED");


        // ============================================
        // TEST 2: Strong vertical edge_out
        //
        //   0   0 255
        //   0   0 255
        //   0   0 255
        //
        // Gx = 1020
        // Gy = 0
        // gradient = 1020
        // edge_out = 1
        // ============================================

        p00 = 0; p01 = 0; p02 = 255;
        p10 = 0; p11 = 0; p12 = 255;
        p20 = 0; p21 = 0; p22 = 255;

        #10;

        $display("");
        $display("TEST 2");
        $display("Gx       = %0d", dut.gx);
        $display("Gy       = %0d", dut.gy);
        $display("Gradient = %0d", dut.gradient);
        $display("Edge_out     = %0d", edge_out);

        if (dut.gx !== 1020)
            $error("Wrong Gx");

        if (dut.gy !== 0)
            $error("Wrong Gy");

        if (dut.gradient !== 1020)
            $error("Wrong gradient");

        if (edge_out !== 1'b1)
            $error("TEST 2 FAILED");


        $display("");
        $display("SOBEL CORE TEST COMPLETE");

        // TEST 3: Reverse vertical edge
        //
        // 255   0   0
        // 255   0   0
        // 255   0   0
        //
        // Gx = -1020
        // Gy = 0
        // Gradient = 1020
        // Edge = 1

        p00 = 255; p01 = 0; p02 = 0;
        p10 = 255; p11 = 0; p12 = 0;
        p20 = 255; p21 = 0; p22 = 0;

        #10;

        $display("");
        $display("TEST 3");
        $display("Gx       = %0d", dut.gx);
        $display("Gy       = %0d", dut.gy);
        $display("Gradient = %0d", dut.gradient);
        $display("Edge_out = %0d", edge_out);

        // TEST 4: for Gy
        //
        // 0        0       0
        // 0        0       0
        // 255      255     255
        //
        // Gx = 0
        // Gy = 1020
        // Gradient = 1020
        // Edge = 1

        p00 = 0; p01 = 0; p02 = 0;
        p10 = 0; p11 = 0; p12 = 0;
        p20 = 255; p21 = 255; p22 = 255;

        #10;

        $display("");
        $display("TEST 4");
        $display("Gx       = %0d", dut.gx);
        $display("Gy       = %0d", dut.gy);
        $display("Gradient = %0d", dut.gradient);
        $display("Edge_out = %0d", edge_out);

        $finish;

    end

endmodule