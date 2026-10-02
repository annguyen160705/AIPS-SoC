module mem_ahb #(
    parameter SIZE_IN_BYTES = 1024,
    parameter DELAY = 0,
    parameter INIT = 0
) (
    input logic HRESETn,
    input logic HCLK,
    input logic HSEL,
    input logic [31:0] HADDR,
    input logic [1:0] HTRANS,
    input logic HWRITE,
    input logic [2:0] HSIZE,
    input logic [2:0] HBURST,
    input logic [31:0] HWDATA,
    output logic [31:0] HRDATA,
    output logic [1:0] HRESP,
    input logic HREADYin,
    output logic HREADYout
);

assign HRESP = 2'b00;

localparam ADD_WIDTH = $clog2(SIZE_IN_BYTES);
localparam NUM_WORDS = SIZE_IN_BYTES/4;

logic [31:0] mem [0: NUM_WORDS-1];
logic [ADD_WIDTH-1:0] T_ADDR, T_ADDRw;
logic [31:0] T_DATA;
logic [3:0] T_BE, T_BE_D;
logic T_WR, T_WR_D;
logic T_ENABLED;
assign T_ENABLED = HSEL && HREADYin && HTRANS[1];

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRDATA    <= ~32'h0;
            T_ADDR    <= ~'h0;
            T_ADDRw   <= ~'h0;
            T_DATA    <= ~32'h0;
            T_BE      <= 4'h0;
            T_WR      <= 1'b0;
            T_BE_D    <= 4'h0;
            T_WR_D    <= 1'b0;
        end else begin
            if(T_ENABLED) begin
                T_ADDR <= HADDR[ADD_WIDTH-1:0];
                T_BE    <= byte_enable(HADDR[1:0], HSIZE);
                T_WR    <= HWRITE;
                // Forward a pending full-word write to the following read
                if (!HWRITE && T_WR &&
                    (HADDR[ADD_WIDTH-1:2] == T_ADDR[ADD_WIDTH-1:2]) &&
                    (T_BE == 4'b1111))
                    HRDATA <= HWDATA;
                else
                    HRDATA <= mem[HADDR[ADD_WIDTH-1:2]];
            end else begin
                T_BE    <= 4'h0;
                T_WR    <= 1'b0;
            end
            if  (T_WR) begin
                T_DATA [7:0] <= (T_BE[0]) ? HWDATA[7:0] : HRDATA[7:0];
                T_DATA [15:8] <= (T_BE[1]) ? HWDATA[15:8] : HRDATA[15:8];
                T_DATA [23:16] <= (T_BE[2]) ? HWDATA[23:16] : HRDATA[23:16];
                T_DATA [31:24] <= (T_BE[3]) ? HWDATA[31:24] : HRDATA[31:24];

                T_BE_D  <= T_BE; 
                T_WR_D  <= T_WR;
            end else begin
                T_BE_D  <= 4'h0;
                T_WR_D  <= 1'h0;
            end
            if  (T_WR_D) begin
                mem[T_ADDRw[ADD_WIDTH-1:2]] <= T_DATA;
            end
            T_ADDRw <= T_ADDR;
        end
    end

    `ifdef RIGOR
    initial begin
        if(DELAY>5'h1F) begin
            $display("%m ERROR: DELAY parameter should be less than 0x1F, but 0x%x", DELAY);
        end
    end
    `endif

    logic [5:0] count;
    typedef enum logic {
        IDLE = 1'b0,
        WAIT = 1'b1
    } state_t;

    state_t state;

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(HRESETn == 0) begin
            HREADYout   <= 1'b1;
            count       <= 'h0;
            state       <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if  (T_ENABLED && (DELAY != 0)) begin
                        HREADYout   <= 1'b0;
                        count       <= 'h1;
                        state       <= WAIT;
                    end
                end
                WAIT: begin
                    if  ((DELAY == count) || (count == 'h0)) begin
                        HREADYout   <= 1'b1;
                        count       <= 'h0;
                        state       <= IDLE;
                    end else begin
                        count   <=  count + 1;
                    end
                end
            endcase
        end
    end


    function automatic logic [3:0] byte_enable(
        input logic [1:0] add,
        input logic [2:0] size
    );
        logic [3:0] be;

        case ({size,add})
            
            `ifdef ENDIAN_BIG
                5'b010_00: be = 4'b1111;    // word
                5'b001_00: be = 4'b1100;    // halfword
                5'b001_10: be = 4'b0011;    // halfword
                5'b000_00: be = 4'b1000;    // byte
                5'b000_01: be = 4'b0100;    // byte
                5'b000_10: be = 4'b0010;    // byte
                5'b000_11: be = 4'b0001;    // byte
            `else // little-endian -- default
                5'b010_00: be = 4'b1111;    // word
                5'b001_00: be = 4'b0011;    // halfword
                5'b001_10: be = 4'b1100;    // halfword
                5'b000_00: be = 4'b0001;    // byte
                5'b000_01: be = 4'b0010;    // byte
                5'b000_10: be = 4'b0100;    // byte
                5'b000_11: be = 4'b1000;    // byte
            `endif // MACRO_NAME

            default: begin
                be = 4'b0;
                    `ifdef RIGOR
                    // synopsys translate_off
                    $display($time,, "%m ERROR: undefined combination of HSIZE(%x) and HADDR[1:0](%x)",
                                                        size, add);
                    // synopsys translate_on
                    `endif
            end
            
        endcase
        byte_enable = be;
    endfunction
    
endmodule