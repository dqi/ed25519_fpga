/* Simple subtraction */
module sub (
    input wire clk,
    input wire rst,

    input wire [254 : 0] sub_in_0,
    input wire [254 : 0] sub_in_1,

    output reg [255 : 0] sub_out
    );

    always @(posedge clk)
        if (rst)
            begin
                sub_out <= 256'b0;
			end
		else
            begin
                // Add the modulus to the first operand to prevent negative values
                sub_out <= 255'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed + sub_in_0 - sub_in_1;
			end
endmodule
