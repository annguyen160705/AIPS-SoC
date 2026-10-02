module sram(
    input logic     clk
    , input logic [31:0]    address
    , input logic [31:0]    write_data
    , input logic           mem_write
    , input logic [2:0]     funct3
    , output logic [31:0]   read_data
);

    localparam logic [31:0] BASE_ADDR   = 32'h1000_0000;
    localparam int          MEM_SIZE    = 12288; // 12KB

    // Byte-addressable SRAM
    logic [7:0]     mem [0:MEM_SIZE-1];

    logic [31:0]    offset;
    logic           valid_addr;

    // Convert physical address to SRAM offset
    assign offset = address - BASE_ADDR;

    // Check SRAM address range
    assign valid_addr   = (address >= BASE_ADDR) && (address < BASE_ADDR + MEM_SIZE);

    // Write operation
    always_ff @(posedge clk) begin
        if(mem_write && valid_addr) begin
            case (funct3)
                3'b000: begin
                    mem[offset] <= write_data[7:0];
                end

                3'b010:begin
                    if(offset <= MEM_SIZE - 4) begin
                        mem[offset]     <= write_data[7:0];
                        mem[offset + 1] <= write_data[15:8];
                        mem[offset + 2] <= write_data[23:16];
                        mem[offset + 3] <= write_data[31:24];
                    end
                end                
            endcase
        end
    end

    always_comb begin
        read_data   = 32'd0;

        if (valid_addr) begin
            case (funct3)
                3'b000: begin // LB (signed)
                    read_data   = {{24{mem[offset][7]}},mem[offset]};
                end
                
                3'b010: begin
                    if(offset <= MEM_SIZE - 4)
                        read_data   = { mem[offset+3],
                                        mem[offset+2],
                                        mem[offset+1],
                                        mem[offset]};
                end
            endcase
        end
    end
    
endmodule