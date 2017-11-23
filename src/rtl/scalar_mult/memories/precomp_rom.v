module precomp_rom (
        input clk,
        input [12:0] addr,  // 5 bit for round 8 bit for value
        output reg [254:0] data_out
);

reg [254:0] ram[8191:0];

// Initialize RAM from file
parameter MEM_INIT_FILE = "";

initial begin
  if (MEM_INIT_FILE != "") begin
    $readmemh(MEM_INIT_FILE, ram);
  end
end

always @(posedge clk) begin
    // Place data from RAM
    data_out <= ram[addr];
end

endmodule

