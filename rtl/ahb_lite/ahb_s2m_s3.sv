module ahb_s2m_s3(
    input logic HRESETn,
    input logic HCLK,
    input logic HSEL0,
    input logic HSEL1,
    input logic HSEL2,
    input logic HSELd,
    output logic [31:0] HRDATA,
    output logic [1:0]  HRESP,
    output logic        HREADY,
    input logic [31:0]  HRDATA0,
    input logic [1:0]   HRESP0,
    input logic         HREADY0,
    input logic [31:0]  HRDATA1,
    input logic [1:0]   HRESP1,
    input logic         HREADY1,
    input logic [31:0]  HRDATA2,
    input logic [1:0]   HRESP2,
    input logic         HREADY2,
    input logic [31:0]  HRDATAd,
    input logic [1:0]   HRESPd,
    input logic         HREADYd
);

    localparam D_HSEL0  = 4'b0001;
    localparam D_HSEL1  = 4'b0010;
    localparam D_HSEL2  = 4'b0100;
    localparam D_HSELd  = 4'b1000;

    logic [3:0] _hsel;
    assign _hsel = {HSELd,HSEL2,HSEL1,HSEL0};
    logic [3:0] _hsel_reg;

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)  begin
            _hsel_reg   <= 'h0;
        end else if (HREADY) begin
            _hsel_reg   <= _hsel;
        end
    end

    always @(_hsel_reg or HREADY0 or HREADY1 or HREADY2 or HREADYd) begin
              case (_hsel_reg)
                D_HSEL0: HREADY = HREADY0;
                D_HSEL1: HREADY = HREADY1;
                D_HSEL2: HREADY = HREADY2;
                D_HSELd: HREADY = HREADYd;
                default: begin
                    HREADY = 1'b1;
                end
              endcase      
    end

    always @(_hsel_reg or HRDATA0 or HRDATA1 or HRDATA2 or HRDATAd) begin
              case (_hsel_reg)
                D_HSEL0: HRDATA = HRDATA0;
                D_HSEL1: HRDATA = HRDATA1;
                D_HSEL2: HRDATA = HRDATA2;
                D_HSELd: HRDATA = HRDATAd;
                default: begin
                    HRDATA = 32'b0;
                end
              endcase      
    end

    always @(_hsel_reg or HRESP0 or HRESP1 or HRESP2 or HRESPd) begin
              case (_hsel_reg)
                D_HSEL0: HRESP = HRESP0;
                D_HSEL1: HRESP = HRESP1;
                D_HSEL2: HRESP = HRESP2;
                D_HSELd: HRESP = HRESPd;
                default: begin
                    HRESP = 2'b01;
                end
              endcase      
    end

    
endmodule