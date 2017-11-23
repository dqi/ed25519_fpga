/* Read first style BRAM */

module bram_255 (
        input wire clk,
        input wire we,
        input wire [3:0] addr_in,
        input wire [3:0] addr_out,

        input wire [254:0] data_in,
        output reg [254:0] data_out
);

reg [254:0] RAM [10:0];

always @(posedge clk) begin
    if (we) begin
        RAM[addr_in] <= data_in;
    end
    data_out <= RAM[addr_out];
end
endmodule
