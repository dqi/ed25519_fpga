`include "./mult_512.v"

module mult_units_512 (
    /* The usual */
    input wire clk,
    input wire rst,

    /* Inputs */
    input wire [255 : 0] mult_1_in_0,
    input wire [255 : 0] mult_1_in_1,

    /* Outputs */
    output wire [511: 0] mult_1_out_512,
    output wire [254: 0] mult_1_out
);

mult_512 mult_unit_1 (
    .clk(clk),
    .rst(rst),
    .CE(1'b1),
    .mult_in0(mult_1_in_0),
    .mult_in1(mult_1_in_1),
    .mult_out_512(mult_1_out_512),
    .mult_out(mult_1_out)
);

endmodule

