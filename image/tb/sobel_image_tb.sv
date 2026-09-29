`timescale 1ns/1ps

module sobel_image_tb;

    localparam int IMG_WIDTH  = 64;
    localparam int IMG_HEIGHT = 64;
    localparam int NUM_PIXELS = IMG_WIDTH * IMG_HEIGHT;

    // ---------------------------------------------------------
    // Image memories loaded from MATLAB
    // ---------------------------------------------------------

    logic [7:0] image_mem  [0:NUM_PIXELS-1];
    logic       golden_mem [0:NUM_PIXELS-1];


    // ---------------------------------------------------------
    // Sobel 3x3 window
    // ---------------------------------------------------------

    logic [7:0] p00, p01, p02;
    logic [7:0] p10, p11, p12;
    logic [7:0] p20, p21, p22;

    logic [10:0] threshold;
    logic        edge_out;


    // ---------------------------------------------------------
    // DUT
    // ---------------------------------------------------------

    sobel_core dut (
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),

        .threshold(threshold),
        .edge_out(edge_out)
    );


    // ---------------------------------------------------------
    // Test
    // ---------------------------------------------------------

    initial begin

        int x;
        int y;
        int index;

        int pass_count;
        int fail_count;

        pass_count = 0;
        fail_count = 0;

        threshold = 11'd200;


        // -----------------------------------------------------
        // Load MATLAB files
        // Change paths if necessary
        // -----------------------------------------------------

        $readmemh("../MATLAB/output/input.hex",  image_mem);
        $readmemh("../MATLAB/output/golden.hex", golden_mem);

        $display("");
        $display("========================================");
        $display(" AIPS-SoC Sobel Image Verification");
        $display("========================================");
        $display("Image size : %0d x %0d",
                 IMG_WIDTH, IMG_HEIGHT);
        $display("Threshold  : %0d", threshold);
        $display("");


        // -----------------------------------------------------
        // Process complete image
        // -----------------------------------------------------

        for (y = 0; y < IMG_HEIGHT; y++) begin

            for (x = 0; x < IMG_WIDTH; x++) begin

                index = y * IMG_WIDTH + x;


                // -------------------------------------------------
                // Border pixels
                //
                // MATLAB leaves the border equal to zero because
                // Sobel is only calculated from pixel 1..62.
                // -------------------------------------------------

                if ((x == 0) ||
                    (x == IMG_WIDTH-1) ||
                    (y == 0) ||
                    (y == IMG_HEIGHT-1)) begin

                    if (golden_mem[index] === 1'b0)
                        pass_count++;
                    else begin
                        fail_count++;

                        $display(
                            "FAIL border: x=%0d y=%0d expected=%0d",
                            x,
                            y,
                            golden_mem[index]
                        );
                    end

                end

                else begin

                    // ---------------------------------------------
                    // Construct 3x3 window
                    // ---------------------------------------------

                    p00 = image_mem[(y-1)*IMG_WIDTH + (x-1)];
                    p01 = image_mem[(y-1)*IMG_WIDTH +  x   ];
                    p02 = image_mem[(y-1)*IMG_WIDTH + (x+1)];

                    p10 = image_mem[ y   *IMG_WIDTH + (x-1)];
                    p11 = image_mem[ y   *IMG_WIDTH +  x   ];
                    p12 = image_mem[ y   *IMG_WIDTH + (x+1)];

                    p20 = image_mem[(y+1)*IMG_WIDTH + (x-1)];
                    p21 = image_mem[(y+1)*IMG_WIDTH +  x   ];
                    p22 = image_mem[(y+1)*IMG_WIDTH + (x+1)];


                    // Allow combinational Sobel logic to settle
                    #1;


                    // ---------------------------------------------
                    // Compare RTL against MATLAB golden result
                    // ---------------------------------------------

                    if (edge_out === golden_mem[index]) begin

                        pass_count++;

                    end
                    else begin

                        fail_count++;

                        // Only print first few failures
                        if (fail_count <= 20) begin

                            $display(
                                "FAIL x=%0d y=%0d RTL=%0d GOLDEN=%0d",
                                x,
                                y,
                                edge_out,
                                golden_mem[index]
                            );

                        end

                    end

                end

            end

        end


        // -----------------------------------------------------
        // Final result
        // -----------------------------------------------------

        $display("");
        $display("========================================");
        $display(" RESULTS");
        $display("========================================");
        $display("PASS : %0d", pass_count);
        $display("FAIL : %0d", fail_count);
        $display("TOTAL: %0d", NUM_PIXELS);

        if (fail_count == 0)
            $display("SOBEL IMAGE TEST PASSED");
        else
            $display("SOBEL IMAGE TEST FAILED");

        $display("========================================");

        $finish;

    end

endmodule