`include "./mult_512_part.v"
`include "./addition_layer_512.v"

module mult_512 (
    input wire clk,
    input wire CE,
    input wire rst,

    input wire [255 : 0] mult_in0,
    input wire [255 : 0] mult_in1,
    output reg [511 : 0] mult_out_512,
    output reg [254 : 0] mult_out
    );

    wire [511 : 0] part_prod_out_00;
    wire [511 : 0] part_prod_out_01;
    wire [511 : 0] part_prod_out_02;
    wire [511 : 0] part_prod_out_03;
    wire [511 : 0] part_prod_out_04;
    wire [511 : 0] part_prod_out_05;
    wire [511 : 0] part_prod_out_06;
    wire [511 : 0] part_prod_out_07;
    wire [511 : 0] part_prod_out_08;
    wire [511 : 0] part_prod_out_09;
    wire [511 : 0] part_prod_out_10;
    wire [511 : 0] part_prod_out_11;
    wire [511 : 0] part_prod_out_12;
    wire [511 : 0] part_prod_out_13;
    wire [511 : 0] part_prod_out_14;
    wire [511 : 0] part_prod_out_15;
    wire [511 : 0] part_prod_out_16;
    wire [511 : 0] part_prod_out_17;
    wire [511 : 0] part_prod_out_18;
    wire [511 : 0] part_prod_out_19;
    wire [511 : 0] part_prod_out_20;
    wire [511 : 0] part_prod_out_21;
    wire [511 : 0] part_prod_out_22;
    wire [511 : 0] part_prod_out_23;
    wire [511 : 0] part_prod_out_24;
    wire [511 : 0] part_prod_out_25;

    reg [258 : 0] reduc_1_2;
    reg [260 : 0] reduc_16_o;
    reg [261 : 0] reduc_19_o;
    reg [255 : 0] phase_2;

    mult_512_part mult (
        .clk(clk),
        .CE(CE),
        .rst(rst),
        .mult_part_in0(mult_in0),
        .mult_part_in1(mult_in1),
        .mult_part_out00(part_prod_out_00),
        .mult_part_out01(part_prod_out_01),
        .mult_part_out02(part_prod_out_02),
        .mult_part_out03(part_prod_out_03),
        .mult_part_out04(part_prod_out_04),
        .mult_part_out05(part_prod_out_05),
        .mult_part_out06(part_prod_out_06),
        .mult_part_out07(part_prod_out_07),
        .mult_part_out08(part_prod_out_08),
        .mult_part_out09(part_prod_out_09),
        .mult_part_out10(part_prod_out_10),
        .mult_part_out11(part_prod_out_11),
        .mult_part_out12(part_prod_out_12),
        .mult_part_out13(part_prod_out_13),
        .mult_part_out14(part_prod_out_14),
        .mult_part_out15(part_prod_out_15),
        .mult_part_out16(part_prod_out_16),
        .mult_part_out17(part_prod_out_17),
        .mult_part_out18(part_prod_out_18),
        .mult_part_out19(part_prod_out_19),
        .mult_part_out20(part_prod_out_20),
        .mult_part_out21(part_prod_out_21),
        .mult_part_out22(part_prod_out_22),
        .mult_part_out23(part_prod_out_23),
        .mult_part_out24(part_prod_out_24),
        .mult_part_out25(part_prod_out_25)
    );

    wire [511 : 0] add_out;

    addition_layer_512 add (
        .clk(clk),
        .rst(rst),
        .layer_0_wire_00(part_prod_out_00),
        .layer_0_wire_01(part_prod_out_01),
        .layer_0_wire_02(part_prod_out_02),
        .layer_0_wire_03(part_prod_out_03),
        .layer_0_wire_04(part_prod_out_04),
        .layer_0_wire_05(part_prod_out_05),
        .layer_0_wire_06(part_prod_out_06),
        .layer_0_wire_07(part_prod_out_07),
        .layer_0_wire_08(part_prod_out_08),
        .layer_0_wire_09(part_prod_out_09),
        .layer_0_wire_10(part_prod_out_10),
        .layer_0_wire_11(part_prod_out_11),
        .layer_0_wire_12(part_prod_out_12),
        .layer_0_wire_13(part_prod_out_13),
        .layer_0_wire_14(part_prod_out_14),
        .layer_0_wire_15(part_prod_out_15),
        .layer_0_wire_16(part_prod_out_16),
        .layer_0_wire_17(part_prod_out_17),
        .layer_0_wire_18(part_prod_out_18),
        .layer_0_wire_19(part_prod_out_19),
        .layer_0_wire_20(part_prod_out_20),
        .layer_0_wire_21(part_prod_out_21),
        .layer_0_wire_22(part_prod_out_22),
        .layer_0_wire_23(part_prod_out_23),
        .layer_0_wire_24(part_prod_out_24),
        .layer_0_wire_25(part_prod_out_25),
        .add_layer_out(add_out)
    );

always @(posedge clk)
    if (rst)
        begin
            mult_out_512 <= 512'b0;
            reduc_1_2    <= 259'b0;
            reduc_16_o   <= 261'b0;
            phase_2      <= 256'b0;
            mult_out     <= 255'b0;
        end
    else
        begin
            /* We first output the raw value, needed for reduction mod l */
            mult_out_512 <= add_out;

            /* Reduce a 512 bit value mod 2^255 - 19, using shifts and adds */
            /* (19 * add_out[511:255]) + add_out[254:0] */
            reduc_1_2  <= add_out[511:255] + {add_out[511:255], 1'b0};       // 1 + 2
            reduc_16_o <= add_out[254:  0] + {add_out[511:255], 4'b0000};    // o + 16
            reduc_19_o <= reduc_1_2 + reduc_16_o;                            // 19 + o
            /* reduc_19_o is 261 bits, small enough to do lookup based */
            case (reduc_19_o[261:255])
                7'b0000000 : phase_2 <= reduc_19_o[254 : 0] + 12'b000000000000;
                7'b0000001 : phase_2 <= reduc_19_o[254 : 0] + 12'b000000010011;
                7'b0000010 : phase_2 <= reduc_19_o[254 : 0] + 12'b000000100110;
                7'b0000011 : phase_2 <= reduc_19_o[254 : 0] + 12'b000000111001;
                7'b0000100 : phase_2 <= reduc_19_o[254 : 0] + 12'b000001001100;
                7'b0000101 : phase_2 <= reduc_19_o[254 : 0] + 12'b000001011111;
                7'b0000110 : phase_2 <= reduc_19_o[254 : 0] + 12'b000001110010;
                7'b0000111 : phase_2 <= reduc_19_o[254 : 0] + 12'b000010000101;
                7'b0001000 : phase_2 <= reduc_19_o[254 : 0] + 12'b000010011000;
                7'b0001001 : phase_2 <= reduc_19_o[254 : 0] + 12'b000010101011;
                7'b0001010 : phase_2 <= reduc_19_o[254 : 0] + 12'b000010111110;
                7'b0001011 : phase_2 <= reduc_19_o[254 : 0] + 12'b000011010001;
                7'b0001100 : phase_2 <= reduc_19_o[254 : 0] + 12'b000011100100;
                7'b0001101 : phase_2 <= reduc_19_o[254 : 0] + 12'b000011110111;
                7'b0001110 : phase_2 <= reduc_19_o[254 : 0] + 12'b000100001010;
                7'b0001111 : phase_2 <= reduc_19_o[254 : 0] + 12'b000100011101;
                7'b0010000 : phase_2 <= reduc_19_o[254 : 0] + 12'b000100110000;
                7'b0010001 : phase_2 <= reduc_19_o[254 : 0] + 12'b000101000011;
                7'b0010010 : phase_2 <= reduc_19_o[254 : 0] + 12'b000101010110;
                7'b0010011 : phase_2 <= reduc_19_o[254 : 0] + 12'b000101101001;
                7'b0010100 : phase_2 <= reduc_19_o[254 : 0] + 12'b000101111100;
                7'b0010101 : phase_2 <= reduc_19_o[254 : 0] + 12'b000110001111;
                7'b0010110 : phase_2 <= reduc_19_o[254 : 0] + 12'b000110100010;
                7'b0010111 : phase_2 <= reduc_19_o[254 : 0] + 12'b000110110101;
                7'b0011000 : phase_2 <= reduc_19_o[254 : 0] + 12'b000111001000;
                7'b0011001 : phase_2 <= reduc_19_o[254 : 0] + 12'b000111011011;
                7'b0011010 : phase_2 <= reduc_19_o[254 : 0] + 12'b000111101110;
                7'b0011011 : phase_2 <= reduc_19_o[254 : 0] + 12'b001000000001;
                7'b0011100 : phase_2 <= reduc_19_o[254 : 0] + 12'b001000010100;
                7'b0011101 : phase_2 <= reduc_19_o[254 : 0] + 12'b001000100111;
                7'b0011110 : phase_2 <= reduc_19_o[254 : 0] + 12'b001000111010;
                7'b0011111 : phase_2 <= reduc_19_o[254 : 0] + 12'b001001001101;
                7'b0100000 : phase_2 <= reduc_19_o[254 : 0] + 12'b001001100000;
                7'b0100001 : phase_2 <= reduc_19_o[254 : 0] + 12'b001001110011;
                7'b0100010 : phase_2 <= reduc_19_o[254 : 0] + 12'b001010000110;
                7'b0100011 : phase_2 <= reduc_19_o[254 : 0] + 12'b001010011001;
                7'b0100100 : phase_2 <= reduc_19_o[254 : 0] + 12'b001010101100;
                7'b0100101 : phase_2 <= reduc_19_o[254 : 0] + 12'b001010111111;
                7'b0100110 : phase_2 <= reduc_19_o[254 : 0] + 12'b001011010010;
                7'b0100111 : phase_2 <= reduc_19_o[254 : 0] + 12'b001011100101;
                7'b0101000 : phase_2 <= reduc_19_o[254 : 0] + 12'b001011111000;
                7'b0101001 : phase_2 <= reduc_19_o[254 : 0] + 12'b001100001011;
                7'b0101010 : phase_2 <= reduc_19_o[254 : 0] + 12'b001100011110;
                7'b0101011 : phase_2 <= reduc_19_o[254 : 0] + 12'b001100110001;
                7'b0101100 : phase_2 <= reduc_19_o[254 : 0] + 12'b001101000100;
                7'b0101101 : phase_2 <= reduc_19_o[254 : 0] + 12'b001101010111;
                7'b0101110 : phase_2 <= reduc_19_o[254 : 0] + 12'b001101101010;
                7'b0101111 : phase_2 <= reduc_19_o[254 : 0] + 12'b001101111101;
                7'b0110000 : phase_2 <= reduc_19_o[254 : 0] + 12'b001110010000;
                7'b0110001 : phase_2 <= reduc_19_o[254 : 0] + 12'b001110100011;
                7'b0110010 : phase_2 <= reduc_19_o[254 : 0] + 12'b001110110110;
                7'b0110011 : phase_2 <= reduc_19_o[254 : 0] + 12'b001111001001;
                7'b0110100 : phase_2 <= reduc_19_o[254 : 0] + 12'b001111011100;
                7'b0110101 : phase_2 <= reduc_19_o[254 : 0] + 12'b001111101111;
                7'b0110110 : phase_2 <= reduc_19_o[254 : 0] + 12'b010000000010;
                7'b0110111 : phase_2 <= reduc_19_o[254 : 0] + 12'b010000010101;
                7'b0111000 : phase_2 <= reduc_19_o[254 : 0] + 12'b010000101000;
                7'b0111001 : phase_2 <= reduc_19_o[254 : 0] + 12'b010000111011;
                7'b0111010 : phase_2 <= reduc_19_o[254 : 0] + 12'b010001001110;
                7'b0111011 : phase_2 <= reduc_19_o[254 : 0] + 12'b010001100001;
                7'b0111100 : phase_2 <= reduc_19_o[254 : 0] + 12'b010001110100;
                7'b0111101 : phase_2 <= reduc_19_o[254 : 0] + 12'b010010000111;
                7'b0111110 : phase_2 <= reduc_19_o[254 : 0] + 12'b010010011010;
                7'b0111111 : phase_2 <= reduc_19_o[254 : 0] + 12'b010010101101;
                7'b1000000 : phase_2 <= reduc_19_o[254 : 0] + 12'b010011000000;
                7'b1000001 : phase_2 <= reduc_19_o[254 : 0] + 12'b010011010011;
                7'b1000010 : phase_2 <= reduc_19_o[254 : 0] + 12'b010011100110;
                7'b1000011 : phase_2 <= reduc_19_o[254 : 0] + 12'b010011111001;
                7'b1000100 : phase_2 <= reduc_19_o[254 : 0] + 12'b010100001100;
                7'b1000101 : phase_2 <= reduc_19_o[254 : 0] + 12'b010100011111;
                7'b1000110 : phase_2 <= reduc_19_o[254 : 0] + 12'b010100110010;
                7'b1000111 : phase_2 <= reduc_19_o[254 : 0] + 12'b010101000101;
                7'b1001000 : phase_2 <= reduc_19_o[254 : 0] + 12'b010101011000;
                7'b1001001 : phase_2 <= reduc_19_o[254 : 0] + 12'b010101101011;
                7'b1001010 : phase_2 <= reduc_19_o[254 : 0] + 12'b010101111110;
                7'b1001011 : phase_2 <= reduc_19_o[254 : 0] + 12'b010110010001;
                7'b1001100 : phase_2 <= reduc_19_o[254 : 0] + 12'b010110100100;
                7'b1001101 : phase_2 <= reduc_19_o[254 : 0] + 12'b010110110111;
                7'b1001110 : phase_2 <= reduc_19_o[254 : 0] + 12'b010111001010;
                7'b1001111 : phase_2 <= reduc_19_o[254 : 0] + 12'b010111011101;
                7'b1010000 : phase_2 <= reduc_19_o[254 : 0] + 12'b010111110000;
                7'b1010001 : phase_2 <= reduc_19_o[254 : 0] + 12'b011000000011;
                7'b1010010 : phase_2 <= reduc_19_o[254 : 0] + 12'b011000010110;
                7'b1010011 : phase_2 <= reduc_19_o[254 : 0] + 12'b011000101001;
                7'b1010100 : phase_2 <= reduc_19_o[254 : 0] + 12'b011000111100;
                7'b1010101 : phase_2 <= reduc_19_o[254 : 0] + 12'b011001001111;
                7'b1010110 : phase_2 <= reduc_19_o[254 : 0] + 12'b011001100010;
                7'b1010111 : phase_2 <= reduc_19_o[254 : 0] + 12'b011001110101;
                7'b1011000 : phase_2 <= reduc_19_o[254 : 0] + 12'b011010001000;
                7'b1011001 : phase_2 <= reduc_19_o[254 : 0] + 12'b011010011011;
                7'b1011010 : phase_2 <= reduc_19_o[254 : 0] + 12'b011010101110;
                7'b1011011 : phase_2 <= reduc_19_o[254 : 0] + 12'b011011000001;
                7'b1011100 : phase_2 <= reduc_19_o[254 : 0] + 12'b011011010100;
                7'b1011101 : phase_2 <= reduc_19_o[254 : 0] + 12'b011011100111;
                7'b1011110 : phase_2 <= reduc_19_o[254 : 0] + 12'b011011111010;
                7'b1011111 : phase_2 <= reduc_19_o[254 : 0] + 12'b011100001101;
                7'b1100000 : phase_2 <= reduc_19_o[254 : 0] + 12'b011100100000;
                7'b1100001 : phase_2 <= reduc_19_o[254 : 0] + 12'b011100110011;
                7'b1100010 : phase_2 <= reduc_19_o[254 : 0] + 12'b011101000110;
                7'b1100011 : phase_2 <= reduc_19_o[254 : 0] + 12'b011101011001;
                7'b1100100 : phase_2 <= reduc_19_o[254 : 0] + 12'b011101101100;
                7'b1100101 : phase_2 <= reduc_19_o[254 : 0] + 12'b011101111111;
                7'b1100110 : phase_2 <= reduc_19_o[254 : 0] + 12'b011110010010;
                7'b1100111 : phase_2 <= reduc_19_o[254 : 0] + 12'b011110100101;
                7'b1101000 : phase_2 <= reduc_19_o[254 : 0] + 12'b011110111000;
                7'b1101001 : phase_2 <= reduc_19_o[254 : 0] + 12'b011111001011;
                7'b1101010 : phase_2 <= reduc_19_o[254 : 0] + 12'b011111011110;
                7'b1101011 : phase_2 <= reduc_19_o[254 : 0] + 12'b011111110001;
                7'b1101100 : phase_2 <= reduc_19_o[254 : 0] + 12'b100000000100;
                7'b1101101 : phase_2 <= reduc_19_o[254 : 0] + 12'b100000010111;
                7'b1101110 : phase_2 <= reduc_19_o[254 : 0] + 12'b100000101010;
                7'b1101111 : phase_2 <= reduc_19_o[254 : 0] + 12'b100000111101;
                7'b1110000 : phase_2 <= reduc_19_o[254 : 0] + 12'b100001010000;
                7'b1110001 : phase_2 <= reduc_19_o[254 : 0] + 12'b100001100011;
                7'b1110010 : phase_2 <= reduc_19_o[254 : 0] + 12'b100001110110;
                7'b1110011 : phase_2 <= reduc_19_o[254 : 0] + 12'b100010001001;
                7'b1110100 : phase_2 <= reduc_19_o[254 : 0] + 12'b100010011100;
                7'b1110101 : phase_2 <= reduc_19_o[254 : 0] + 12'b100010101111;
                7'b1110110 : phase_2 <= reduc_19_o[254 : 0] + 12'b100011000010;
                7'b1110111 : phase_2 <= reduc_19_o[254 : 0] + 12'b100011010101;
                7'b1111000 : phase_2 <= reduc_19_o[254 : 0] + 12'b100011101000;
                7'b1111001 : phase_2 <= reduc_19_o[254 : 0] + 12'b100011111011;
                7'b1111010 : phase_2 <= reduc_19_o[254 : 0] + 12'b100100001110;
                7'b1111011 : phase_2 <= reduc_19_o[254 : 0] + 12'b100100100001;
                7'b1111100 : phase_2 <= reduc_19_o[254 : 0] + 12'b100100110100;
                7'b1111101 : phase_2 <= reduc_19_o[254 : 0] + 12'b100101000111;
                7'b1111110 : phase_2 <= reduc_19_o[254 : 0] + 12'b100101011010;
                7'b1111111 : phase_2 <= reduc_19_o[254 : 0] + 12'b100101101101;
            endcase
            /* phase2 is 256 bits */
            case (phase_2[255])
                1'b0 : mult_out <= phase_2[254 : 0];
                1'b1 : mult_out <= phase_2[254 : 0] + 5'b10011;
            endcase
        end
endmodule

