/* Some small DRAM to save intermediate values during scalar multiplication */

module dram (
   input wire clk,

   input wire en_wr,
   input wire [255:0] data_in,
   output wire [255:0] data_out
);

reg [255:0] RAM;

always @(posedge clk) begin
    if (en_wr)
        RAM <= data_in;
end

assign data_out = RAM;

endmodule

