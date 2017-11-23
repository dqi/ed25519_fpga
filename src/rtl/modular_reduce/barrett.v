`include "./addsub/sub_254.v"
`include "./addsub/add_516.v"
`include "./memories/bram_253.v"

/* Reduce a 512 bit number mod 2**252
*                               + 27742317777372353535851937790883648493 */

module barrett_reduce (
    input wire clk,
    input wire rst,

    /* We will take a 512 bit number and reduce it modulo l */
    input wire [511:0] red_in,

    /* Control signals */
    input wire red_ena,
    output reg red_ready,
    output reg red_comp_done,

    /* Results from the dedicated multipliers */
    input wire [511 : 0] red_mult_out_512,

    /* To the multipliers */
    output reg [255 : 0] red_mult_in_0,
    output reg [255 : 0] red_mult_in_1,

    /* It is done */
    output reg [252:0] red_out
    );

/*---------------------------INTERNAL CONSTANTS-------------------------------*/

/* For barrett reduction */
/* 2**252 + 27742317777372353535851937790883648493 */
localparam m =
    253'h1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed;
/* 4**256 / m */
localparam mu =
    260'hfffffffffffffffffffffffffffffffeb2106215d086329a7ed9ce5a30a2c131b;

localparam [3:0] STATE_IDLE         = 4'd0;
localparam [3:0] STATE_LONG_MULT_1  = 4'd1;
localparam [3:0] STATE_LONG_MULT_2  = 4'd2;
localparam [3:0] STATE_LONG_MULT_3  = 4'd3;
localparam [3:0] STATE_LONG_MULT_4  = 4'd4;
localparam [3:0] STATE_ADD          = 4'd5;
localparam [3:0] STATE_SHORT_MULT   = 4'd6;
localparam [3:0] STATE_SUB          = 4'd7;
localparam [3:0] STATE_SAVE_SUB     = 4'd8;
localparam [3:0] STATE_SAVE_COMPARE = 4'd9;
localparam [3:0] STATE_OUTPUT       = 4'd10;
localparam [3:0] STATE_DONE         = 4'd11;

/*------------------------------------REGS------------------------------------*/

reg [3:0] red_state_reg;
reg [3:0] red_state_new;

reg [3:0] n_counter_reg;
reg [3:0] n_counter_new;

reg compare_flag_reg;
reg compare_flag_new;

reg [515:0] layer_0_reg_00;
reg [515:0] layer_0_reg_01;
reg [515:0] layer_0_reg_02;
reg [515:0] layer_0_reg_03;
reg [253:0] sub_in_0;
reg [253:0] sub_in_1;

/*-----------------------------------WIRES------------------------------------*/

wire [515:0] layer_1_wire_00;
wire [515:0] layer_1_wire_01;
wire [515:0] layer_2_wire_00;
wire [252:0] sub_out;

wire en_wr_bram_1;
wire en_wr_bram_2;
wire en_wr_bram_3;

wire we_bram_c1;
wire we_bram_c2;

wire [511:0] data_in_bram_1;
wire [511:0] data_in_bram_2;
wire [511:0] data_in_bram_3;

wire [511:0] data_out_bram_1;
wire [511:0] data_out_bram_2;
wire [511:0] data_out_bram_3;
wire [252:0] data_out_bram_c1;
wire [252:0] data_out_bram_c2;

/*--------------------------------COMPONENTS----------------------------------*/

add_516 layer_1_0 (
    .clk(clk),
    .rst(rst),
    .add_in0(layer_0_reg_00),
    .add_in1(layer_0_reg_01),
    .add_out(layer_1_wire_00)
);

add_516 layer_1_1 (
    .clk(clk),
    .rst(rst),
    .add_in0(layer_0_reg_02),
    .add_in1(layer_0_reg_03),
    .add_out(layer_1_wire_01)
);

add_516 layer_2_1 (
    .clk(clk),
    .rst(rst),
    .add_in0(layer_1_wire_00),
    .add_in1(layer_1_wire_01),
    .add_out(layer_2_wire_00)
);

sub_254 sub_0 (
    .clk(clk),
    .rst(rst),
    .sub_in0(sub_in_0),
    .sub_in1(sub_in_1),
    .sub_out(sub_out)
);

bram_512 bram_1 (
    .clk(clk),
    .we(en_wr_bram_1),
    .addr(3'b0),
    .data_in(data_in_bram_1),
    .data_out(data_out_bram_1)
    );

bram_512 bram_2 (
    .clk(clk),
    .we(en_wr_bram_2),
    .addr(3'b0),
    .data_in(data_in_bram_2),
    .data_out(data_out_bram_2)
    );

bram_512 bram_3 (
    .clk(clk),
    .we(en_wr_bram_3),
    .addr(3'b0),
    .data_in(data_in_bram_3),
    .data_out(data_out_bram_3)
    );

bram_253 bram_c1 (
    .clk(clk),
    .we(we_bram_c1),
    .addr(1'b0),
    .data_in(sub_out),
    .data_out(data_out_bram_c1)
    );

bram_253 bram_c2 (
    .clk(clk),
    .we(we_bram_c2),
    .addr(1'b0),
    .data_in(sub_out),
    .data_out(data_out_bram_c2)
    );

/*------------------------------------MATH------------------------------------*/

always @* begin
    red_mult_in_0 = 256'b0;
    red_mult_in_1 = 256'b0;

    layer_0_reg_00 = 516'b0;
    layer_0_reg_01 = 516'b0;
    layer_0_reg_02 = 516'b0;
    layer_0_reg_03 = 516'b0;

    sub_in_0 = 254'b0;
    sub_in_1 = 254'b0;

    /* t = x - ((x*mu) >> (2*k)) * n */
    /* x:  512 bit */
    /* mu: 260 bit */
    /* n:  253 bit */
    /* We can split x*mu over 4 multiplications */
    if (red_state_reg == STATE_LONG_MULT_1) begin
        red_mult_in_0 = red_in[255:0];
        red_mult_in_1 = mu[255:0];
    end

    if (red_state_reg == STATE_LONG_MULT_2) begin
        red_mult_in_0 = red_in[511:256];
        red_mult_in_1 = mu[255:0];
    end

    if (red_state_reg == STATE_LONG_MULT_3) begin
        red_mult_in_0 = red_in[255:0];
        red_mult_in_1 = mu[259:256];
    end

    if (red_state_reg == STATE_LONG_MULT_4) begin
        red_mult_in_0 = red_in[511:256];
        red_mult_in_1 = mu[259:256];
    end

    /* x*mu fits in 772 bits, we do not need the bottom 256 bits */
    if (red_state_reg == STATE_ADD) begin
        /* Already throw out the 256 lsb */
        layer_0_reg_00 = data_out_bram_1[511:256];
        layer_0_reg_01 = data_out_bram_2;

        layer_0_reg_02 = data_out_bram_3;
        layer_0_reg_03 = {red_mult_out_512[259:0], 256'b0};
    end
    if (red_state_reg == STATE_SHORT_MULT) begin
        /* We have 260 bits on layer2, but we only need the the bottom 254 of
        * the result so it's ok */
        red_mult_in_0 = layer_2_wire_00[511:256];
        red_mult_in_1 = m;
    end
    if (red_state_reg == STATE_SUB) begin
        /* We only need to subtract the 254 lsb */
        sub_in_0 = red_in[253:0];
        sub_in_1 = red_mult_out_512[253:0];
    end
    /* save result 1 and start second substraction */
    if (red_state_reg == STATE_SAVE_SUB) begin
        sub_in_0 = sub_out;
        sub_in_1 = m;
    end
    /* Compare result 1 and save result 2 */
    if (red_state_reg == STATE_SAVE_COMPARE) begin
    end
    /* Conditionally output one of the results */
    if (red_state_reg == STATE_OUTPUT) begin
    end
end
/*-------------------------------------FSM------------------------------------*/

/* Synchronous state update */
always @(posedge clk) begin
    if (rst) begin
        red_state_reg <= STATE_IDLE;
        n_counter_reg <= 4'b0;
    end
    else begin
        red_state_reg <= red_state_new;
        n_counter_reg <= n_counter_new;
    end
end

/* Asynchronous next state logic */
always @* begin
    /* No change is the default */
    red_state_new = red_state_reg;
    /* Only ready when idle */
    red_ready = 1'b0;
    n_counter_new = (n_counter_reg - 1'b1);

    case (red_state_reg)
        STATE_IDLE:
            begin
                red_ready = 1'b1;
                if (red_ena)
                    begin
                        red_state_new = STATE_LONG_MULT_1;
                        n_counter_new = 4'd9;
                    end
            end
        STATE_LONG_MULT_1:
            begin
                if (n_counter_reg == 4'b0) begin
                    red_state_new = STATE_LONG_MULT_2;
                    n_counter_new = 4'd9;
                end
            end
        STATE_LONG_MULT_2:
            begin
                if (n_counter_reg == 4'b0) begin
                    red_state_new = STATE_LONG_MULT_3;
                    n_counter_new = 4'd9;
                end
            end
        STATE_LONG_MULT_3:
            begin
                if (n_counter_reg == 4'b0) begin
                    red_state_new = STATE_LONG_MULT_4;
                    n_counter_new = 4'd9;
                end
            end
        STATE_LONG_MULT_4:
            begin
                if (n_counter_reg == 4'b0) begin
                    red_state_new = STATE_ADD;
                    n_counter_new = 4'd1;
                end
            end
        STATE_ADD:
            begin
                if (n_counter_reg == 4'b0) begin
                    red_state_new = STATE_SHORT_MULT;
                    n_counter_new = 4'd9;
                end
            end
        STATE_SHORT_MULT:
            begin
                if (n_counter_reg == 4'b0) begin
                    red_state_new = STATE_SUB;
                end
            end
        STATE_SUB:
            begin
                red_state_new = STATE_SAVE_SUB;
            end
        STATE_SAVE_SUB:
            begin
                red_state_new = STATE_SAVE_COMPARE;
            end
        STATE_SAVE_COMPARE:
            begin
                red_state_new = STATE_OUTPUT;
            end
        STATE_OUTPUT:
            begin
                red_state_new = STATE_IDLE;
            end
        default:
            red_state_new = STATE_IDLE;
    endcase
end

/*------------------------------------RAM-------------------------------------*/

assign en_wr_bram_1 = (red_state_reg == STATE_LONG_MULT_2);
assign en_wr_bram_2 = (red_state_reg == STATE_LONG_MULT_3);
assign en_wr_bram_3 = (red_state_reg == STATE_LONG_MULT_4);
assign we_bram_c1 = (red_state_reg == STATE_SAVE_SUB);
assign we_bram_c2 = (red_state_reg == STATE_SAVE_COMPARE);

assign data_in_bram_1 = red_mult_out_512;
assign data_in_bram_2 = red_mult_out_512;
assign data_in_bram_3 = red_mult_out_512;

always @(posedge clk) begin
    if (rst) begin
        compare_flag_reg <= 1'b0;
    end
    else begin
        compare_flag_reg <= compare_flag_new;
    end
end

always @* begin
    compare_flag_new = compare_flag_reg;

    if (red_state_reg == STATE_SAVE_COMPARE) begin
        compare_flag_new = (data_out_bram_c1 > m);
    end
end

/*-----------------------------------OUTPUT-----------------------------------*/
always @* begin
    red_out = 253'bx;
    red_comp_done = 1'b0;
    if (red_state_reg == STATE_OUTPUT) begin
        red_comp_done = 1'b1;
        red_out = compare_flag_reg ? data_out_bram_c2 : data_out_bram_c1;
    end
end

endmodule
