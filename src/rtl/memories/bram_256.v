/* Write first style BRAM */

module bram_256 (
        input wire clk,
        input wire we,
        input wire [1:0] addr,

        input wire [255:0] data_in,
        output reg [255:0] data_out
);

reg [255:0] RAM [3:0];

always @(posedge clk) begin
    if (we) begin
        RAM[addr] <= data_in;
        data_out <= data_in;
    end
    else
        data_out <= RAM[addr];
end
endmodule
