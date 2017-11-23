/* Simple addition */
module add (
    input wire clk,
    input wire rst,

    input wire [254 : 0] add_in_0,
    input wire [254 : 0] add_in_1,

    output reg [255 : 0] add_out
    );

    always @(posedge clk)
        if (rst)
            begin
                add_out <= 256'b0;
			end
		else
            begin
                add_out <= add_in_0 + add_in_1;
			end
endmodule
