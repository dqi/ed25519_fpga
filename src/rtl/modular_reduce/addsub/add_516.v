module add_516 (
    input wire clk,
    input wire rst,

    input wire [515 : 0] add_in0,
    input wire [515 : 0] add_in1,

    output reg [515 : 0] add_out
    );

    always @(posedge clk)
        if (rst)
            begin
                add_out <= 516'b0;
			end
		else
            begin
                add_out <= add_in0 + add_in1;
			end
endmodule
