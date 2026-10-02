module ahb_default_slave(
    input logic         HRESETn,
    input logic         HCLK,
    input logic         HSEL,
    input logic [31:0]  HADDR,
    input logic [1:0]   HTRANS,
    input logic         HWRITE,
    input logic [2:0]   HSIZE, 
    input logic [2:0]   HBURST,
    input logic [31:0]  HWDATA,
    output logic [31:0] HRDATA,
    output logic [1:0]  HRESP,
    input logic         HREADYin,
    output logic        HREADYout 
);

    assign HRDATA   = 32'h0;

    typedef enum logic [1:0] {
        STH_IDLE    = 2'b00,
        STH_WRITE = 2'b01,
        STH_READ0 = 2'b10
    } state_t;

    state_t state;

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HRESP       <= 2'b00;
            HREADYout   <= 1'b1;
            state       <= STH_IDLE;
        end else begin
            case (state)
                STH_IDLE: begin
                    if(HSEL && HREADYin) begin
                        case (HTRANS)
                        2'b00, 2'b01: begin
                            HREADYout   <= 1'b1;
                            HRESP       <= 2'b00;
                            state       <= STH_IDLE;
                        end

                        2'b10, 2'b11: begin
                            HREADYout   <= 1'b0;
                            HRESP       <= 2'b01;
                            if  (HWRITE) begin
                                state   <= STH_WRITE;
                            end else begin
                                state   <= STH_READ0;
                            end
                        end
                        endcase  
                    end else begin
                        HREADYout   <= 1'b1;
                        HRESP       <= 2'b00;
                    end
                    
                end
                STH_WRITE: begin
                    HREADYout   <= 1'b1;
                    HRESP       <= 2'b01;
                    state       <= STH_IDLE;
                end
                STH_READ0: begin
                    HREADYout   <= 1'b1;
                    HRESP       <=  2'b01;
                    state       <= STH_IDLE;
                end
            endcase
        end
    end
    
endmodule