module add_512 (
    input wire clk,
    input wire rst,

    input wire [511 : 0] add_in0,
    input wire [511 : 0] add_in1,

    output reg [511 : 0] add_out
    );

    always @(posedge clk)
        if (rst)
            begin
                add_out <= 512'b0;
			end
		else
            begin
                add_out <= add_in0 + add_in1;
			end
endmodule
