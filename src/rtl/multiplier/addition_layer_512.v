/* Adds all the inputs in a binary tree. */
`include "./adder/add_512.v"

module addition_layer_512 (
    input wire clk,
    input wire rst,

    input wire [511 : 0] layer_0_wire_00,
    input wire [511 : 0] layer_0_wire_01,
    input wire [511 : 0] layer_0_wire_02,
    input wire [511 : 0] layer_0_wire_03,
    input wire [511 : 0] layer_0_wire_04,
    input wire [511 : 0] layer_0_wire_05,
    input wire [511 : 0] layer_0_wire_06,
    input wire [511 : 0] layer_0_wire_07,
    input wire [511 : 0] layer_0_wire_08,
    input wire [511 : 0] layer_0_wire_09,
    input wire [511 : 0] layer_0_wire_10,
    input wire [511 : 0] layer_0_wire_11,
    input wire [511 : 0] layer_0_wire_12,
    input wire [511 : 0] layer_0_wire_13,
    input wire [511 : 0] layer_0_wire_14,
    input wire [511 : 0] layer_0_wire_15,
    input wire [511 : 0] layer_0_wire_16,
    input wire [511 : 0] layer_0_wire_17,
    input wire [511 : 0] layer_0_wire_18,
    input wire [511 : 0] layer_0_wire_19,
    input wire [511 : 0] layer_0_wire_20,
    input wire [511 : 0] layer_0_wire_21,
    input wire [511 : 0] layer_0_wire_22,
    input wire [511 : 0] layer_0_wire_23,
    input wire [511 : 0] layer_0_wire_24,
    input wire [511 : 0] layer_0_wire_25,

    output wire [511 : 0] add_layer_out
    );

        wire [511 : 0] layer_1_wire_00;

        add_512 layer_1_0_1 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_00),
            .add_in1(layer_0_wire_01),
            .add_out(layer_1_wire_00)
        );

        wire [511 : 0] layer_1_wire_01;

        add_512 layer_1_2_3 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_02),
            .add_in1(layer_0_wire_03),
            .add_out(layer_1_wire_01)
        );

        wire [511 : 0] layer_1_wire_02;

        add_512 layer_1_4_5 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_04),
            .add_in1(layer_0_wire_05),
            .add_out(layer_1_wire_02)
        );

        wire [511 : 0] layer_1_wire_03;

        add_512 layer_1_6_7 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_06),
            .add_in1(layer_0_wire_07),
            .add_out(layer_1_wire_03)
        );

        wire [511 : 0] layer_1_wire_04;

        add_512 layer_1_8_9 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_08),
            .add_in1(layer_0_wire_09),
            .add_out(layer_1_wire_04)
        );

        wire [511 : 0] layer_1_wire_05;

        add_512 layer_1_10_11 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_10),
            .add_in1(layer_0_wire_11),
            .add_out(layer_1_wire_05)
        );

        wire [511 : 0] layer_1_wire_06;

        add_512 layer_1_12_13 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_12),
            .add_in1(layer_0_wire_13),
            .add_out(layer_1_wire_06)
        );

        wire [511 : 0] layer_1_wire_07;

        add_512 layer_1_14_15 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_14),
            .add_in1(layer_0_wire_15),
            .add_out(layer_1_wire_07)
        );

        wire [511 : 0] layer_1_wire_08;

        add_512 layer_1_16_17 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_16),
            .add_in1(layer_0_wire_17),
            .add_out(layer_1_wire_08)
        );

        wire [511 : 0] layer_1_wire_09;

        add_512 layer_1_18_19 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_18),
            .add_in1(layer_0_wire_19),
            .add_out(layer_1_wire_09)
        );

        wire [511 : 0] layer_1_wire_10;

        add_512 layer_1_20_21 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_20),
            .add_in1(layer_0_wire_21),
            .add_out(layer_1_wire_10)
        );

        wire [511 : 0] layer_1_wire_11;

        add_512 layer_1_22_23 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_22),
            .add_in1(layer_0_wire_23),
            .add_out(layer_1_wire_11)
        );

        wire [511 : 0] layer_1_wire_12;

        add_512 layer_1_24_25 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_0_wire_24),
            .add_in1(layer_0_wire_25),
            .add_out(layer_1_wire_12)
        );

        wire [511 : 0] layer_2_wire_00;

        add_512 layer_2_0_1 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_1_wire_00),
            .add_in1(layer_1_wire_01),
            .add_out(layer_2_wire_00)
        );

        wire [511 : 0] layer_2_wire_01;

        add_512 layer_2_2_3 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_1_wire_02),
            .add_in1(layer_1_wire_03),
            .add_out(layer_2_wire_01)
        );

        wire [511 : 0] layer_2_wire_02;

        add_512 layer_2_4_5 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_1_wire_04),
            .add_in1(layer_1_wire_05),
            .add_out(layer_2_wire_02)
        );

        wire [511 : 0] layer_2_wire_03;

        add_512 layer_2_6_7 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_1_wire_06),
            .add_in1(layer_1_wire_07),
            .add_out(layer_2_wire_03)
        );

        wire [511 : 0] layer_2_wire_04;

        add_512 layer_2_8_9 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_1_wire_08),
            .add_in1(layer_1_wire_09),
            .add_out(layer_2_wire_04)
        );

        wire [511 : 0] layer_2_wire_05;

        add_512 layer_2_10_11 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_1_wire_10),
            .add_in1(layer_1_wire_11),
            .add_out(layer_2_wire_05)
        );
        reg [511 : 0] layer_2_wire_06;

        wire [511 : 0] layer_3_wire_00;

        add_512 layer_3_0_1 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_2_wire_00),
            .add_in1(layer_2_wire_01),
            .add_out(layer_3_wire_00)
        );

        wire [511 : 0] layer_3_wire_01;

        add_512 layer_3_2_3 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_2_wire_02),
            .add_in1(layer_2_wire_03),
            .add_out(layer_3_wire_01)
        );

        wire [511 : 0] layer_3_wire_02;

        add_512 layer_3_4_5 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_2_wire_04),
            .add_in1(layer_2_wire_05),
            .add_out(layer_3_wire_02)
        );
        reg [511 : 0] layer_3_wire_03;

        wire [511 : 0] layer_4_wire_00;

        add_512 layer_4_0_1 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_3_wire_00),
            .add_in1(layer_3_wire_01),
            .add_out(layer_4_wire_00)
        );

        wire [511 : 0] layer_4_wire_01;

        add_512 layer_4_2_3 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_3_wire_02),
            .add_in1(layer_3_wire_03),
            .add_out(layer_4_wire_01)
        );

        add_512 layer_5_0_1 (
            .clk(clk),
            .rst(rst),
            .add_in0(layer_4_wire_00),
            .add_in1(layer_4_wire_01),
            .add_out(add_layer_out)
        );

always @(posedge clk)
    if (rst)
        begin
            layer_2_wire_06 <= 512'b0;
            layer_3_wire_03 <= 512'b0;
         end
    else
        begin
            layer_2_wire_06 <= layer_1_wire_12;
            layer_3_wire_03 <= layer_2_wire_06;
         end
endmodule
