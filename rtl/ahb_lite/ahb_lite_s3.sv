module ahb_lite_s3 #(
    parameter P_HSEL0_START = 16'h0000, P_HSEL0_SIZE = 16'h0100,
    parameter P_HSEL1_START = 16'h1000, P_HSEL1_SIZE = 16'h0100,
    parameter P_HSEL2_START = 16'h2000, P_HSEL2_SIZE = 16'h0100
) (
    input logic         HRESETn,
    input logic         HCLK,

    //--------------------------------------------------------//
    input logic [31:0]  M_HADDR,
    input logic [1:0]   M_HTRANS,
    input logic         M_HWRITE,
    input logic [2:0]   M_HSIZE, 
    input logic [2:0]   M_HBURST,
    input logic [3:0]   M_HPROT,
    input logic [31:0]  M_HWDATA,
    output logic [31:0] M_HRDATA,
    output logic [1:0]  M_HRESP,
    output logic        M_HREADY,
    //--------------------------------------------------------//
    output logic        HWRITE,
    output logic [31:0] HADDR,
    output logic [1:0]  HTRANS,
    output logic [2:0]  HSIZE,
    output logic [2:0]  HBURST,
    output logic [3:0]  HPROT,
    output logic [31:0] HWDATA,
    output logic        HREADY,
    //--------------------------------------------------------//
    output logic        HSEL0,
    input logic [1:0]   HRESP0,
    input logic [31:0]  HRDATA0,
    input logic         HREADY0,
    //--------------------------------------------------------//
    output logic        HSEL1,
    input logic [1:0]   HRESP1,
    input logic [31:0]  HRDATA1,
    input logic         HREADY1,
    //--------------------------------------------------------//
    output logic        HSEL2,
    input logic [1:0]   HRESP2,
    input logic [31:0]  HRDATA2,
    input logic         HREADY2,
    //--------------------------------------------------------//
    input logic         REMAP
);

    //--------------------------------------------------------//
    logic           HSELd; // default slave
    logic [31:0]    HRDATAd;
    logic [1:0]     HRESPd;
    logic           HREADYd;
    //--------------------------------------------------------//

    always_comb begin
        HADDR   = M_HADDR;
        HTRANS  = M_HTRANS;
        HSIZE   = M_HSIZE;
        HBURST  = M_HBURST;
        HWRITE  = M_HWRITE;
        HPROT   = M_HPROT;
        HWDATA  = M_HWDATA;
        HREADY  = M_HREADY;
    end

    //--------------------------------------------------------//
    ahb_decoder_s3  #(  .P_NUM (3),
                        .P_ADDR_START0  (P_HSEL0_START),
                        .P_ADDR_SIZE0   (P_HSEL0_SIZE),
                        .P_ADDR_START1  (P_HSEL1_START),
                        .P_ADDR_SIZE1   (P_HSEL1_SIZE), 
                        .P_ADDR_START2  (P_HSEL2_START),
                        .P_ADDR_SIZE2   (P_HSEL2_SIZE)  
    ) Uahb_decoder_s3 (
                    .HADDR(M_HADDR),
                    .HSELd(HSELd),
                    .HSEL0(HSEL0),
                    .HSEL1(HSEL1),
                    .HSEL2(HSEL2),
                    .REMAP(REMAP)
    );

    //--------------------------------------------------------//
    ahb_s2m_s3  Uahb_s2m    (
                .HRESETn(HRESETn),
                .HCLK   (HCLK),
                .HSEL0  (HSEL0),
                .HSEL1  (HSEL1),
                .HSEL2  (HSEL2),
                .HSELd  (HSELd),
                .HRDATA (M_HRDATA),
                .HRESP  (M_HRESP),
                .HREADY (M_HREADY),
                .HRDATA0    (HRDATA0),
                .HRESP0 (HRESP0),
                .HREADY0(HREADY0),
                .HRDATA1    (HRDATA1),
                .HRESP1 (HRESP1),
                .HREADY1(HREADY1),
                .HRDATA2    (HRDATA2),
                .HRESP2 (HRESP2),
                .HREADY2(HREADY2),
                .HRDATAd    (HRDATAd),
                .HRESPd (HRESPd),
                .HREADYd(HREADYd)
    );

    //--------------------------------------------------------//
    ahb_default_slave   Uahb_default_slave (
                        .HRESETn(HRESETn),
                        .HCLK   (HCLK),
                        .HSEL   (HSELd),
                        .HADDR  (HADDR),
                        .HTRANS (HTRANS),
                        .HWRITE (HWRITE),
                        .HSIZE  (HSIZE),
                        .HBURST (HBURST),
                        .HWDATA (HWDATA),
                        .HRDATA (HRDATAd),
                        .HRESP  (HRESPd),
                        .HREADYin   (HREADY),
                        .HREADYout  (HREADYd)
    );
    
endmodule