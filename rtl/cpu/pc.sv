module pc(
      input logic           clk
    , input logic           rst_n
    , input logic           pc_write
    , input logic [31:0]    pc_next

    , output logic [31:0]   pc
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc  <= 32'd0;
        end else if (pc_write) begin
            pc  <= pc_next;  // Load next instruction address
        end
        
    end
    
endmodule