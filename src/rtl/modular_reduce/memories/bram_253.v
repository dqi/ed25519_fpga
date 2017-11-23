/* Write first style BRAM */

module bram_253 (
        input wire clk,
        input wire we,
        input wire addr,

        input wire [252:0] data_in,
        output reg [252:0] data_out
);

reg [252:0] RAM [1:0];

always @(posedge clk) begin
    if (we) begin
        RAM[addr] <= data_in;
        data_out <= data_in;
    end
    else
        data_out <= RAM[addr];
end
endmodule
