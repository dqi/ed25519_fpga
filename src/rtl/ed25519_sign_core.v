`include "./memories/bram_256.v"
`include "./memories/bram_512.v"
`include "./multiplier/mult_units_512.v"
`include "./scalar_mult/scalar_mult.v"
`include "./modular_inversion/invert.v"
`include "./modular_reduce/barrett.v"
`include "./hashing/hash_wrap.v"

module sign_core (
    input wire clk,
    input wire rst,

    /* Control signals */
    input wire core_ena,
    output reg core_ready,
    output reg core_comp_done,

    /* Secret key */
    input wire [255:0] core_sk,
    /* Public key */
    input wire [255:0] core_pk,
    /* Message, 256 bits only. */
    input wire [255:0] core_M,

    /* A signature is a pair (R,S) */
    output reg [255:0] core_S,
    output reg [255:0] core_R
    );


/*----------------------------------FUNCTIONS---------------------------------*/

function [255:0] changeEndian_256;
    input [255:0] value;
    changeEndian_256 = {value[7:0], value[15:8], value[23:16], value[31:24],
        value[39:32], value[47:40], value[55:48], value[63:56], value[71:64],
        value[79:72], value[87:80], value[95:88], value[103:96], value[111:104],
        value[119:112], value[127:120], value[135:128], value[143:136],
        value[151:144], value[159:152], value[167:160], value[175:168],
        value[183:176], value[191:184], value[199:192], value[207:200],
        value[215:208], value[223:216], value[231:224], value[239:232],
        value[247:240], value[255:248]};
endfunction

function [511:0] changeEndian_512;
    input [511:0] value;
    changeEndian_512 = {value[7:0], value[15:8], value[23:16], value[31:24],
        value[39:32], value[47:40], value[55:48], value[63:56], value[71:64],
        value[79:72], value[87:80], value[95:88], value[103:96], value[111:104],
        value[119:112], value[127:120], value[135:128], value[143:136],
        value[151:144], value[159:152], value[167:160], value[175:168],
        value[183:176], value[191:184], value[199:192], value[207:200],
        value[215:208], value[223:216], value[231:224], value[239:232],
        value[247:240], value[255:248], value[263:256], value[271:264],
        value[279:272], value[287:280], value[295:288], value[303:296],
        value[311:304], value[319:312], value[327:320], value[335:328],
        value[343:336], value[351:344], value[359:352], value[367:360],
        value[375:368], value[383:376], value[391:384], value[399:392],
        value[407:400], value[415:408], value[423:416], value[431:424],
        value[439:432], value[447:440], value[455:448], value[463:456],
        value[471:464], value[479:472], value[487:480], value[495:488],
        value[503:496], value[511:504]};
endfunction

/*---------------------------INTERNAL CONSTANTS-------------------------------*/

localparam [3:0] STATE_IDLE             = 4'd0;
localparam [3:0] STATE_HASH_KEY         = 4'd1;
localparam [3:0] STATE_HASH_SM          = 4'd2;
localparam [3:0] STATE_REDUCE_R         = 4'd3;
localparam [3:0] STATE_SCALAR_MULT      = 4'd4;
localparam [3:0] STATE_INVERT           = 4'd5;
localparam [3:0] STATE_HASH_RAM         = 4'd6;
localparam [3:0] STATE_REDUCE_HRAM      = 4'd7;
localparam [3:0] STATE_MULT_HRAM_A      = 4'd8;
localparam [3:0] STATE_REDUCE_HRAM_A    = 4'd9;
localparam [3:0] STATE_ADD_R_HRAMA      = 4'd10;
localparam [3:0] STATE_REDUCE_FINAL     = 4'd11;
localparam [3:0] STATE_OUTPUT           = 4'd12;

localparam [2:0] ADDR_SCALAR_MULTS      = 3'd0;

localparam [2:0] ADDR_INVERSES          = 3'd1;
localparam [2:0] ADDR_RED_FINAL         = 3'd1;

localparam [2:0] ADDR_RED_R             = 3'd2;
localparam [2:0] ADDR_RED_HRAM_A        = 3'd2;
localparam [2:0] ADDR_HASH_HM           = 3'd2;

localparam [2:0] ADDR_HASH_KEY          = 3'd3;
localparam [2:0] ADDR_RED_HRAM          = 3'd3;
localparam [2:0] ADDR_ADD_R_HRAMA       = 3'd3;

localparam [2:0] ADDR_HASH_RAM          = 3'd4;

localparam [2:0] ADDR_HRAM_A            = 3'd5;

/*-----------------------------------WIRES------------------------------------*/

/* Raw results */
wire [511 : 0] mult_1_out_512;
/* Results modulo 2^255 - 19 */
wire [254 : 0] mult_1_out;

wire hw_ena;
wire hw_ready;
wire [511:0] hw_digest;
wire hw_digest_valid;

wire red_ena;
wire red_ready;
wire [252:0] red_out;
wire red_comp_done;
wire [255:0] red_mult_in_0;
wire [255:0] red_mult_in_1;

wire sm_ena;
wire sm_ready;
wire [254:0] sm_x_out;
wire [254:0] sm_y_out;
wire [254:0] sm_z_out;
wire sm_comp_done;
wire [255:0] sm_mult_in_0;
wire [255:0] sm_mult_in_1;

wire inv_ena;
wire inv_ready;
wire [254:0] inv_x_out;
wire [254:0] inv_y_out;
wire inv_comp_done;
wire [255:0] inv_mult_in_0;
wire [255:0] inv_mult_in_1;

wire bram_1_we;
wire bram_2_we;
wire bram_3_we;

wire [511:0] bram_1_data_out;
wire [255:0] bram_2_data_out;
wire [255:0] bram_3_data_out;

/*------------------------------------REGS------------------------------------*/

reg [3:0] core_state_reg;
reg [3:0] core_state_new;

reg [255 : 0] mult_1_in_0;
reg [255 : 0] mult_1_in_1;

reg [1:0] hw_mode;
reg [255:0] hw_sk;
reg [255:0] hw_h;
reg [255:0] hw_A;
reg [255:0] hw_R;
reg [255:0] hw_M;

reg [511:0] red_in;

reg [511:0] red_mult_out_512;

reg [255:0] sm_scalar;
reg [254:0] sm_mult_out;

reg [254:0] inv_x;
reg [254:0] inv_y;
reg [254:0] inv_z;
reg [254:0] inv_mult_out;

reg [3:0] mult_counter_reg;
reg [3:0] mult_counter_new;

reg [2:0] bram_addr_reg;
reg [2:0] bram_addr_new;

reg [511:0] bram_1_data_in;
reg [255:0] bram_2_data_in;
reg [255:0] bram_3_data_in;

/*--------------------------------COMPONENTS----------------------------------*/

mult_units_512 mult (
    .clk(clk),
    .rst(rst),
    .mult_1_in_0(mult_1_in_0),
    .mult_1_in_1(mult_1_in_1),
    .mult_1_out_512(mult_1_out_512),
    .mult_1_out(mult_1_out)
    );

hash_wrap hw (
    .clk(clk),
    .rst(rst),
    .hw_ena(hw_ena),
    .hw_ready(hw_ready),
    .hw_error(hw_error),
    .hw_digest_valid(hw_digest_valid),
    .hw_digest(hw_digest),
    .hw_mode(hw_mode),
    .hw_sk(hw_sk),
    .hw_h(hw_h),
    .hw_R(hw_R),
    .hw_A(hw_A),
    .hw_M(hw_M)
    );

barrett_reduce red (
    .clk(clk),
    .rst(rst),
    .red_in(red_in),
    .red_ena(red_ena),
    .red_ready(red_ready),
    .red_comp_done(red_comp_done),
    .red_mult_out_512(red_mult_out_512),
    .red_mult_in_0(red_mult_in_0),
    .red_mult_in_1(red_mult_in_1),
    .red_out(red_out)
    );

scalar_mult sm (
    .clk(clk),
    .rst(rst),
    .sm_ena(sm_ena),
    .scalar(sm_scalar),
    .sm_ready(sm_ready),
    .sm_error(sm_error),
    .sm_comp_done(sm_comp_done),
    .sm_mult_out(sm_mult_out),
    .sm_mult_in_0(sm_mult_in_0),
    .sm_mult_in_1(sm_mult_in_1),
    .sm_x_out(sm_x_out),
    .sm_y_out(sm_y_out),
    .sm_z_out(sm_z_out)
    );

invert inv (
    .clk(clk),
    .rst(rst),
    .inv_x(inv_x),
    .inv_y(inv_y),
    .inv_z(inv_z),
    .inv_ena(inv_ena),
    .inv_ready(inv_ready),
    .inv_comp_done(inv_comp_done),
    .inv_mult_out(inv_mult_out),
    .inv_mult_in_0(inv_mult_in_0),
    .inv_mult_in_1(inv_mult_in_1),
    .inv_x_out(inv_x_out),
    .inv_y_out(inv_y_out)
    );

bram_512 bram_1 (
    .clk(clk),
    .we(bram_1_we),
    .addr(bram_addr_new),
    .data_in(bram_1_data_in),
    .data_out(bram_1_data_out)
    );

bram_256 bram_2 (
    .clk(clk),
    .we(bram_2_we),
    .addr(bram_addr_new),
    .data_in(bram_2_data_in),
    .data_out(bram_2_data_out)
    );

bram_256 bram_3 (
    .clk(clk),
    .we(bram_3_we),
    .addr(bram_addr_new),
    .data_in(bram_3_data_in),
    .data_out(bram_3_data_out)
    );

/*---------------------------------CONNECTIVITY-------------------------------*/

/* Multipliers */
always @* begin
    mult_1_in_0 = 256'bx;
    mult_1_in_1 = 256'bx;

    red_mult_out_512 = 511'bx;

    sm_mult_out = 255'bx;

    inv_mult_out = 255'bx;

    /* Connect the reduction unit */
    if (core_state_reg == STATE_REDUCE_R
        | core_state_reg == STATE_REDUCE_FINAL
        | core_state_reg == STATE_REDUCE_HRAM
        | core_state_reg == STATE_REDUCE_HRAM_A) begin
            mult_1_in_0 = red_mult_in_0;
            mult_1_in_1 = red_mult_in_1;

            red_mult_out_512 = mult_1_out_512;
    end
    if (core_state_reg == STATE_SCALAR_MULT) begin
            mult_1_in_0 = sm_mult_in_0;
            mult_1_in_1 = sm_mult_in_1;

            sm_mult_out = mult_1_out;
    end
    if (core_state_reg == STATE_INVERT) begin
            mult_1_in_0 = inv_mult_in_0;
            mult_1_in_1 = inv_mult_in_1;

            inv_mult_out = mult_1_out;
    end
    if (core_state_reg == STATE_MULT_HRAM_A) begin
            mult_1_in_0 = bram_2_data_out;
            mult_1_in_1 = changeEndian_256({bram_1_data_out[511:507], 3'b0, bram_1_data_out[503:264],
                2'b01, bram_1_data_out[261:256]});
    end

end

/*-----------------------------------INPUT------------------------------------*/

always @* begin
    hw_mode = 2'bx;
    hw_sk = 0;
    hw_h = 0;
    hw_A = 0;
    hw_R = 0;
    hw_M = 0;
    red_in = 512'b0;
    sm_scalar = 256'b0;
    inv_x = 255'b0;
    inv_y = 255'b0;
    inv_z = 255'b0;
    if (core_state_reg == STATE_HASH_KEY) begin
        hw_sk = core_sk;
        hw_mode = 2'b0;
    end
    if (core_state_reg == STATE_HASH_SM) begin
        hw_h = bram_1_data_out[255:0];
        hw_M = core_M;
        hw_mode = 2'b1;
    end
    if (core_state_reg == STATE_REDUCE_R) begin
        red_in = bram_1_data_out;
    end
    if (core_state_reg == STATE_SCALAR_MULT) begin
        sm_scalar = bram_2_data_out;
    end
    if (core_state_reg == STATE_INVERT) begin
        inv_x = bram_1_data_out;
        inv_y = bram_2_data_out;
        inv_z = bram_3_data_out;
    end
    if (core_state_reg == STATE_HASH_RAM) begin
        hw_R = changeEndian_256({bram_1_data_out[0], bram_2_data_out[254:0]});
        hw_A = core_pk;
        hw_M = core_M;
        hw_mode = 2'b10;
    end
    if (core_state_reg == STATE_REDUCE_HRAM) begin
        red_in = (bram_1_data_out);
    end
    if (core_state_reg == STATE_REDUCE_HRAM_A) begin
        red_in = bram_1_data_out;
    end
    if (core_state_reg == STATE_REDUCE_FINAL) begin
        red_in = bram_3_data_out;
    end
end

/*------------------------------------RAM-------------------------------------*/

assign bram_1_we = hw_digest_valid | sm_comp_done | inv_comp_done
                                   | (mult_counter_reg == 4'h0);

assign bram_2_we = (red_comp_done &&
                   (core_state_reg == STATE_REDUCE_R ||
                    core_state_reg == STATE_REDUCE_HRAM))
                 | sm_comp_done | inv_comp_done;
assign bram_3_we = (red_comp_done &&
                   (core_state_reg == STATE_REDUCE_FINAL ||
                    core_state_reg == STATE_REDUCE_HRAM_A))
                 | (core_state_reg == STATE_ADD_R_HRAMA)
                 | sm_comp_done | inv_comp_done;

always @(posedge clk) begin
    if (rst) begin
        bram_addr_reg <= 3'b0;
    end
    else begin
        bram_addr_reg <= bram_addr_new;
    end
end

// Manage the addresses.
always @* begin
    /* Default is no change */
    bram_addr_new = bram_addr_reg;
    if (core_state_reg == STATE_HASH_KEY && hw_digest_valid)
        bram_addr_new = ADDR_HASH_KEY;
    else if (core_state_reg == STATE_HASH_SM && hw_digest_valid)
        bram_addr_new = ADDR_HASH_HM;
    else if (core_state_reg == STATE_REDUCE_R && red_comp_done)
        bram_addr_new = ADDR_RED_R;
    else if (core_state_reg == STATE_SCALAR_MULT && sm_comp_done)
        bram_addr_new = ADDR_SCALAR_MULTS;
    else if (core_state_reg == STATE_INVERT && inv_comp_done)
        bram_addr_new = ADDR_INVERSES;
    else if (core_state_reg == STATE_HASH_RAM && hw_digest_valid)
        bram_addr_new = ADDR_HASH_RAM;
    else if (core_state_reg == STATE_REDUCE_HRAM && red_comp_done)
        bram_addr_new = ADDR_RED_HRAM;
    else if (core_state_reg == STATE_MULT_HRAM_A && mult_counter_reg == 4'b0)
        bram_addr_new = ADDR_HRAM_A;
    else if (core_state_reg == STATE_REDUCE_HRAM_A && red_comp_done)
        bram_addr_new = ADDR_RED_HRAM_A;
    else if (core_state_reg == STATE_ADD_R_HRAMA)
        bram_addr_new = ADDR_ADD_R_HRAMA;
    else if (core_state_reg == STATE_REDUCE_FINAL && red_comp_done)
        bram_addr_new = ADDR_RED_FINAL;
end

// Write to BRAM_1
always @* begin
    bram_1_data_in = 512'bx;
    if (core_state_reg == STATE_HASH_KEY) begin
        bram_1_data_in = hw_digest;
    end
    else if (core_state_reg == STATE_HASH_SM) begin
        bram_1_data_in = changeEndian_512(hw_digest);
    end
    else if (core_state_reg == STATE_HASH_RAM) begin
        bram_1_data_in = changeEndian_512(hw_digest);
    end
    else if (core_state_reg == STATE_MULT_HRAM_A) begin
        bram_1_data_in = mult_1_out_512;
    end
    else if (core_state_reg == STATE_SCALAR_MULT) begin
        bram_1_data_in = sm_x_out;
    end
    else if (core_state_reg == STATE_INVERT) begin
        bram_1_data_in = inv_x_out;
    end
end

// Write to BRAM_2
always @* begin
    bram_2_data_in = 256'bx;
    if (core_state_reg == STATE_REDUCE_R) begin
        bram_2_data_in = red_out;
    end
    else if (core_state_reg == STATE_REDUCE_HRAM) begin
        bram_2_data_in = red_out;
    end
    else if (core_state_reg == STATE_SCALAR_MULT) begin
        bram_2_data_in = sm_y_out;
    end
    else if (core_state_reg == STATE_INVERT) begin
        bram_2_data_in = inv_y_out;
    end
end

// Write to BRAM_3
always @* begin
    bram_3_data_in = 256'bx;
    if (core_state_reg == STATE_REDUCE_FINAL) begin
        bram_3_data_in = red_out;
    end
    else if (core_state_reg == STATE_REDUCE_HRAM_A) begin
        bram_3_data_in = red_out;
    end
    else if (core_state_reg == STATE_SCALAR_MULT) begin
        bram_3_data_in = sm_z_out;
    end
    else if (core_state_reg == STATE_ADD_R_HRAMA) begin
        bram_3_data_in = bram_2_data_out + bram_3_data_out;
    end
end

/* Enable hash unit */
assign hw_ena = (core_state_reg == STATE_HASH_KEY & hw_ready)
              | (core_state_reg == STATE_HASH_SM & hw_ready)
              | (core_state_reg == STATE_HASH_RAM & hw_ready)
              | (core_state_reg == STATE_HASH_RAM & hw_ready);
/* Enable reduction unit */
assign red_ena = (core_state_reg == STATE_REDUCE_R && red_ready)
               | (core_state_reg == STATE_REDUCE_HRAM && red_ready)
               | (core_state_reg == STATE_REDUCE_HRAM_A && red_ready)
               | (core_state_reg == STATE_REDUCE_FINAL && red_ready);
/* Enable scalar multiplication unit */
assign sm_ena = (core_state_reg == STATE_SCALAR_MULT && sm_ready);
/* Enable inversion unit */
assign inv_ena = (core_state_reg == STATE_INVERT && inv_ready);

/*-------------------------------------FSM------------------------------------*/

always @(posedge clk) begin
    if (rst) begin
        core_state_reg   <= STATE_IDLE;
        mult_counter_reg <= 4'hf;
    end
    else begin
        core_state_reg   <= core_state_new;
        mult_counter_reg <= mult_counter_new;
    end
end

always @* begin
    core_state_new   = core_state_reg;
    mult_counter_new = mult_counter_reg;
    core_ready       = 1'b0;

    case (core_state_reg)
        STATE_IDLE:
            begin
                core_ready = 1'b1;
                if (core_ena) begin
                    core_state_new = STATE_HASH_KEY;
                end
            end
        STATE_HASH_KEY:
            begin
                if (hw_digest_valid) begin
                    core_state_new = STATE_HASH_SM;
                end
            end
        STATE_HASH_SM:
            begin
                if (hw_digest_valid) begin
                    core_state_new = STATE_REDUCE_R;
                end
            end
        STATE_REDUCE_R:
            begin
                if (red_comp_done) begin
                    core_state_new = STATE_SCALAR_MULT;
                end
            end
        STATE_SCALAR_MULT:
            begin
                if (sm_comp_done) begin
                    core_state_new = STATE_INVERT;
                end
            end
        STATE_INVERT:
            begin
                if (inv_comp_done) begin
                    core_state_new = STATE_HASH_RAM;
                end
            end
        STATE_HASH_RAM:
            begin
                if (hw_digest_valid) begin
                    core_state_new = STATE_REDUCE_HRAM;
                end
            end
        STATE_REDUCE_HRAM:
            begin
                if (red_comp_done) begin
                    core_state_new = STATE_MULT_HRAM_A;
                    mult_counter_new = 4'd10;
                end
            end
        STATE_MULT_HRAM_A:
            begin
                mult_counter_new = mult_counter_reg - 1'b1;
                if (mult_counter_reg == 4'b0) begin
                    core_state_new = STATE_REDUCE_HRAM_A;
                end
            end
        STATE_REDUCE_HRAM_A:
            begin
                if (red_comp_done) begin
                    core_state_new = STATE_ADD_R_HRAMA;
                end
            end
        STATE_ADD_R_HRAMA:
            begin
                core_state_new = STATE_REDUCE_FINAL;
            end
        STATE_REDUCE_FINAL:
            begin
                if (red_comp_done) begin
                    core_state_new = STATE_OUTPUT;
                end
            end
        STATE_OUTPUT:
            begin
                core_state_new = STATE_IDLE;
            end
        default:
            core_state_new = STATE_IDLE;
    endcase
end

/*-----------------------------------OUTPUT-----------------------------------*/

always @* begin
    core_comp_done = 1'b0;
    core_S = 256'bx;
    core_R = 256'bx;
    if (core_state_reg == STATE_OUTPUT) begin
        core_comp_done = 1'b1;
        core_S = changeEndian_256({3'b0, bram_3_data_out[252:0]});
        core_R = changeEndian_256({bram_1_data_out[0], bram_2_data_out[254:0]});
    end
end

endmodule

