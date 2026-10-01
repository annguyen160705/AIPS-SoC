module data_memory(
      input logic     clk
    , input logic     mem_write
    , input logic [2:0] funct3
    , input logic [31:0] address
    , input logic [31:0] write_data

    , output logic [31:0] read_data
);

    logic [31:0] mem [0:255];
    logic [31:0] word_data;
    logic [7:0] byte_data;

    assign word_data    = mem[address[9:2]];

    assign byte_data    = word_data[8*address[1:0] +: 8]; //[start_bit +: width]


    // Write memory
    always_ff @(posedge clk ) begin
        if(mem_write)begin
            case(funct3)
            3'b000:
                mem[address[9:2]][8*address[1:0] +: 8] <= write_data[7:0];
            3'b010:
                mem[address[9:2]]   <= write_data;
            endcase
        end
    end

    always_comb begin
        case(funct3)
            3'b000: //LB (sign extension)
                read_data   = {{24{byte_data[7]}}, byte_data};
            3'b010: //LW
                read_data   = word_data;
            default:
                read_data   = 32'd0;
        endcase
    end
    
endmodule

// address = 0x00000008
// address[9:2] = 2

// → access mem[2]