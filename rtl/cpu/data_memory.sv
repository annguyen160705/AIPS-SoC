module data_memory(
      input logic     clk
    , input logic     mem_write
    , input logic [31:0] address
    , input logic [31:0] write_data

    , output logic [31:0] read_data
);

    logic [31:0] mem [0:255];

    always_ff @(posedge clk ) begin
        if(mem_write)
            mem[address[9:2]]   <= write_data;
    end

    assign read_data    = mem[address[9:2]];
    
endmodule

// address = 0x00000008
// address[9:2] = 2

// → access mem[2]