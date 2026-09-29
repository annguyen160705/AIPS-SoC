module sobel_core (
    input  logic [7:0] p00, p01, p02,
    input  logic [7:0] p10, p11, p12,
    input  logic [7:0] p20, p21, p22,

    input  logic [10:0] threshold,
    output logic edge_out
);

    // Sobel gradients
    logic signed [11:0] gx;
    logic signed [11:0] gy;

    // Absolute gradient values
    logic [11:0] abs_gx;
    logic [11:0] abs_gy;

    // Combined gradient
    logic [12:0] gradient;


    always_comb begin

        // -----------------------------------------------------
        // Gx kernel:
        //
        // -1   0   1
        // -2   0   2
        // -1   0   1
        //
        // Gx = right side - left side
        // -----------------------------------------------------

        gx = $signed({4'b0000, p02})
            + ($signed({4'b0000, p12}) <<< 1)
            + $signed({4'b0000, p22})
            - $signed({4'b0000, p00})
            - ($signed({4'b0000, p10}) <<< 1)
            - $signed({4'b0000, p20});


        // -----------------------------------------------------
        // Gy kernel:
        //
        // -1  -2  -1
        //  0   0   0
        //  1   2   1
        //
        // Gy = bottom side - top side
        // -----------------------------------------------------

        gy = $signed({4'b0000, p20})
            + ($signed({4'b0000, p21}) <<< 1)
            + $signed({4'b0000, p22})
            - $signed({4'b0000, p00})
            - ($signed({4'b0000, p01}) <<< 1)
            - $signed({4'b0000, p02});


        // Absolute values
        if (gx < 0)
            abs_gx = -gx;
        else
            abs_gx = gx;

        if (gy < 0)
            abs_gy = -gy;
        else
            abs_gy = gy;


        // Same formula as MATLAB:
        // G = abs(Gx) + abs(Gy)
        gradient = abs_gx + abs_gy;


        // Threshold comparison
        // MATLAB: edge_out_img = gradient > THRESHOLD
        if (gradient > threshold)
            edge_out = 1'b1;
        else
            edge_out = 1'b0;

    end

endmodule