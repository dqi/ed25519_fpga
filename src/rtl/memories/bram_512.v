/* Write first style BRAM */

module bram_512 (
        input wire clk,
        input wire we,
        input wire [2:0] addr,

        input wire [511:0] data_in,
        output reg [511:0] data_out
);

reg [511:0] RAM [5:0];

always @(posedge clk) begin
    if (we) begin
        RAM[addr] <= data_in;
        data_out <= data_in;
    end
    else
        data_out <= RAM[addr];
end
endmodule
