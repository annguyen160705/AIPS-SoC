module ahb_decoder_s3 #(
    parameter P_NUM = 3,
    parameter P_ADDR_START0 = 'h0000, P_ADDR_SIZE0  = 'h0010,
    parameter P_ADDR_START1 = 'h0010, P_ADDR_SIZE1  = 'h0010,
    parameter P_ADDR_START2 = 'h0020, P_ADDR_SIZE2  = 'h0010
) (
    input logic [31:0] HADDR,
    output logic HSELd, // default slave
    output logic HSEL0, // slave 1
    output logic HSEL1, // slave 2
    output logic HSEL2, // slave 3
    input logic REMAP
);
    
    localparam P_ADDR_END0 = P_ADDR_START0 + P_ADDR_SIZE0 - 1;
    localparam P_ADDR_END1 = P_ADDR_START1 + P_ADDR_SIZE1 - 1;
    localparam P_ADDR_END2 = P_ADDR_START2 + P_ADDR_SIZE2 - 1;

    logic ihseld, ihsel0, ihsel1, ihsel2;
    assign HSELd = ihseld;
    assign HSEL0 = (REMAP) ? ihsel1 : ihsel0;
    assign HSEL1 = (REMAP) ? ihsel0 : ihsel1;
    assign HSEL2 = ihsel2;

    logic [15:0] thaddr ;
    assign thaddr = HADDR[31:16];

    always_comb begin
        if((P_NUM>0) && (thaddr >= P_ADDR_START0) && (thaddr <= P_ADDR_END0))
            ihsel0  = 1'b1;
        else 
            ihsel0  = 1'b0;
        if((P_NUM>1) && (thaddr >= P_ADDR_START1) && (thaddr <= P_ADDR_END1))
            ihsel1  = 1'b1;
        else 
            ihsel1  = 1'b0;
        if((P_NUM>2) && (thaddr >= P_ADDR_START2) && (thaddr <= P_ADDR_END2))
            ihsel2  = 1'b1;
        else 
            ihsel2  = 1'b0;

        if( (P_NUM>0) && (thaddr >= P_ADDR_START0) && (thaddr <= P_ADDR_END0) || 
            (P_NUM>1) && (thaddr >= P_ADDR_START1) && (thaddr <= P_ADDR_END1) ||
            (P_NUM>2) && (thaddr >= P_ADDR_START2) && (thaddr <= P_ADDR_END2))

            ihseld = 1'b0;
        else 
            ihseld = 1'b1;

    end
endmodule