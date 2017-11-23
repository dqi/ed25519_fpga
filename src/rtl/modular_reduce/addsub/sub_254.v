module sub_254 (
    input wire clk,
    input wire rst,

    input wire [253 : 0] sub_in0,
    input wire [253 : 0] sub_in1,

    output reg [253 : 0] sub_out
    );

    always @(posedge clk)
        if (rst)
            begin
                sub_out <= 254'b0;
			end
		else
            begin
                sub_out <= sub_in0 - sub_in1;
			end
endmodule

