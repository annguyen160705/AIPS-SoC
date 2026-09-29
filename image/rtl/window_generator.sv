module name #(
    parameter int IMG_WIDTH     = 64,
    parameter int IMG_HEIGHT    = 64
) (
      input logic           clk
    , input logic           rst_n
    
    , input logic           pixel_valid
    , input logic [7:0]     pixel_in

    , output logic          window_valid

    , output logic [7:0]    p00, p01, p02
    , output logic [7:0]    p10, p11, p12
    , output logic [7:0]    p20, p21, p22
);

    //--------------------------------------------------------//
    // Line buffer
    logic [7:0] line1 [0:IMG_WIDTH-1];  // line1 = previous image row
    logic [7:0] line2 [0:IMG_WIDTH-1];  // line2 = row before previous image row

    //--------------------------------------------------------//
    // Horizontal delay registers
    // d1 = previous column
    // d2 = two columns ago
    logic [7:0] top_d1, top_d2;
    logic [7:0] mid_d1, mid_d2;
    logic [7:0] bot_d1, bot_d2;

    integer col_count;
    integer row_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            col_count   <= 0;
            row_count   <= 0;

            top_d1 <= 0;
            top_d2 <= 0;
            mid_d1 <= 0;
            mid_d2 <= 0;
            bot_d1 <= 0; 
            bot_d2 <= 0;

            p00 <= 0;
            p01 <= 0;
            p02 <= 0;
            p10 <= 0;
            p11 <= 0;   
            p12 <= 0;   
            p20 <= 0;
            p21 <= 0;
            p22 <= 0;

            window_valid <= 1'b0;


        end else begin
            // Default: no valid window
            window_valid    <= 1'b0;

            if(pixel_valid) begin
                if((row_count >= 2) && (col_count >= 2)) begin
                    p00 <= top_d2;
                    p01 <= top_d1;
                    p02 <= line2[col_count];

                    p10 <= top_d2;
                    p11 <= top_d1;
                    p12 <= line1[col_count];

                    p20 <= top_d2;
                    p21 <= top_d1;
                    p22 <= pixel_in;

                    window_valid    <= 1'b1;
                end
            end // if(pixel_valid)

            // Horizontal shifting

            if(col_count == 0) begin
                // Start of a new image row
                top_d2  <= 0;
                top_d1  <= line2[col_count];

                mid_d2  <= 0;
                mid_d1  <= line1[col_count];

                bot_d2  <= 0;
                bot_d1  <= pixel_in;
            end else begin
                top_d2  <= top_d1;
                top_d1  <= line2[col_count];

                mid_d2  <= mid_d1;
                mid_d1  <= line1[col_count];

                bot_d2  <= bot_d1;
                bot_d1  <= pixel_in;
            end // if(col_count == 0)

            // Update line buffers
            // old line1 -> line2
            // new pixel -> line1

            line2[col_count]    <= line1[col_count];
            line1[col_count]    <= pixel_in;

            // Pixel coordinate counters

            if(col_count == IMG_WIDTH - 1) begin
                col_count   <= 0;
                if(row_count == IMG_HEIGHT - 1)
                    row_count   <= 0;
                else
                    row_count   <= row_count + 1;
            end else begin
                col_count   <= col_count + 1;
            end

        end // if(!rst_n)
    end
    
endmodule