`include "./memories/bram_255.v"

module invert (
    input wire clk,
    input wire rst,

    /* We will invert z and output (x*inv(z), y*inv(z)) */
    input wire [254:0] inv_x,
    input wire [254:0] inv_y,
    input wire [254:0] inv_z,

    /* Control signals */
    input wire inv_ena,
    output reg inv_ready,
    output reg inv_comp_done,

    /* Results from the dedicated multiplier */
    input wire [254 : 0] inv_mult_out,

    /* To the multiplier */
    output reg [255 : 0] inv_mult_in_0,
    output reg [255 : 0] inv_mult_in_1,

    /* Output point x and y */
    output reg [254:0] inv_x_out,
    output reg [254:0] inv_y_out
    );

/*---------------------------INTERNAL CONSTANTS-------------------------------*/

localparam [3:0] ADDR_Z        = 4'd0;
localparam [3:0] ADDR_Z2       = 4'd1;
localparam [3:0] ADDR_Z9       = 4'd2;
localparam [3:0] ADDR_Z11      = 4'd3;
localparam [3:0] ADDR_Z2_5_0   = 4'd4;
localparam [3:0] ADDR_Z2_10_0  = 4'd5;
localparam [3:0] ADDR_Z2_20_0  = 4'd6;
localparam [3:0] ADDR_Z2_50_0  = 4'd7;
localparam [3:0] ADDR_Z2_100_0 = 4'd8;
localparam [3:0] ADDR_INVZ     = 4'd9;
localparam [3:0] ADDR_INVX     = 4'd10;

/*-----------------------------------SIGNALS----------------------------------*/

reg [5:0] inv_state_reg, inv_state_new;
reg [3:0] n_counter, n_counter_next;
reg [6:0] r_counter, r_counter_next;

reg [3:0] addr_in_bram;
reg [3:0] addr_out_bram;

wire we_bram;
wire [254:0] data_out_bram;
/*--------------------------------COMPONENTS----------------------------------*/

bram_255 bram (
    .clk(clk),
    .we(we_bram),
    .addr_in(addr_in_bram),
    .addr_out(addr_out_bram),
    .data_in(inv_mult_out),
    .data_out(data_out_bram)
    );

/*------------------------------------PARAM-----------------------------------*/

localparam [254:0] p          =
    255'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;
localparam [5:0] idle         = 6'd0;
localparam [5:0] s_z2         = 6'd1;
localparam [5:0] s_z4         = 6'd2;
localparam [5:0] s_z8         = 6'd3;
localparam [5:0] s_z9         = 6'd4;
localparam [5:0] s_z11        = 6'd5;
localparam [5:0] s_z22        = 6'd6;
localparam [5:0] s_z2_5_0     = 6'd7;
localparam [5:0] s_z2_6_1     = 6'd8;
localparam [5:0] s_z2_10_5    = 6'd9;
localparam [5:0] s_z2_10_0    = 6'd10;
localparam [5:0] s_z2_11_1    = 6'd11;
localparam [5:0] s_z2_20_10   = 6'd12;
localparam [5:0] s_z2_20_0    = 6'd13;
localparam [5:0] s_z2_21_1    = 6'd14;
localparam [5:0] s_z2_40_20   = 6'd15;
localparam [5:0] s_z2_40_0    = 6'd16;
localparam [5:0] s_z2_41_1    = 6'd17;
localparam [5:0] s_z2_50_10   = 6'd18;
localparam [5:0] s_z2_50_0    = 6'd19;
localparam [5:0] s_z2_51_1    = 6'd20;
localparam [5:0] s_z2_100_50  = 6'd21;
localparam [5:0] s_z2_100_0   = 6'd22;
localparam [5:0] s_z2_101_1   = 6'd23;
localparam [5:0] s_z2_200_100 = 6'd24;
localparam [5:0] s_z2_200_0   = 6'd25;
localparam [5:0] s_z2_201_1   = 6'd26;
localparam [5:0] s_z2_250_50  = 6'd27;
localparam [5:0] s_z2_250_0   = 6'd28;
localparam [5:0] s_z2_251_1   = 6'd29;
localparam [5:0] s_z2_252_2   = 6'd30;
localparam [5:0] s_z2_253_3   = 6'd31;
localparam [5:0] s_z2_254_4   = 6'd32;
localparam [5:0] s_z2_255_5   = 6'd33;
localparam [5:0] s_z2_255_21  = 6'd34;
localparam [5:0] s_invert_x   = 6'd35;
localparam [5:0] s_invert_y   = 6'd36;
localparam [5:0] s_output     = 6'd37;  // output

/*------------------------------------MATHS-----------------------------------*/

/* Invert z */
always @* begin
    /* Defaults */
    inv_mult_in_0 = 256'bx;
    inv_mult_in_1 = 256'bx;
    inv_mult_in_0 = 256'bx;
    inv_mult_in_1 = 256'bx;
    /* Compute x^(2^255 - 21) following the addition chain in the reference
    * implementation */
    if  (inv_state_reg == s_z2) begin
        inv_mult_in_0 = inv_z;                       // z
        inv_mult_in_1 = inv_z;                       // z
    end
    /* Squarings */
    else if  ((inv_state_reg == s_z4)
                || (inv_state_reg == s_z8)
                || (inv_state_reg == s_z22)
                || (inv_state_reg == s_z2_6_1)
                || (inv_state_reg == s_z2_10_5)
                || (inv_state_reg == s_z2_11_1)
                || (inv_state_reg == s_z2_20_10)
                || (inv_state_reg == s_z2_21_1)
                || (inv_state_reg == s_z2_40_20)
                || (inv_state_reg == s_z2_41_1)
                || (inv_state_reg == s_z2_50_10)
                || (inv_state_reg == s_z2_51_1)
                || (inv_state_reg == s_z2_100_50)
                || (inv_state_reg == s_z2_101_1)
                || (inv_state_reg == s_z2_200_100)
                || (inv_state_reg == s_z2_201_1)
                || (inv_state_reg == s_z2_250_50)
                || (inv_state_reg == s_z2_251_1)
                || (inv_state_reg == s_z2_252_2)
                || (inv_state_reg == s_z2_253_3)
                || (inv_state_reg == s_z2_254_4)
                || (inv_state_reg == s_z2_255_5)) begin
        inv_mult_in_0 = inv_mult_out;
        inv_mult_in_1 = inv_mult_out;
    end
    else if  (inv_state_reg == s_z9) begin
        inv_mult_in_0 = inv_mult_out;         // z8
        inv_mult_in_1 = inv_z;                // z
    end
    else if  (inv_state_reg == s_z11) begin
        inv_mult_in_0 = inv_mult_out;         // z9
        inv_mult_in_1 = data_out_bram;        // z2
    end
    else if  (inv_state_reg == s_z2_5_0) begin
        inv_mult_in_0 = inv_mult_out;         // z22
        inv_mult_in_1 = data_out_bram;        // z9
    end
    else if  (inv_state_reg == s_z2_10_0) begin
        inv_mult_in_0 = inv_mult_out;         // z2_10_5
        inv_mult_in_1 = data_out_bram;        // z2_5_0
    end
    else if  (inv_state_reg == s_z2_20_0) begin
        inv_mult_in_0 = inv_mult_out;         // z2_20_10
        inv_mult_in_1 = data_out_bram;        // z2_10_0
    end
    else if  (inv_state_reg == s_z2_40_0) begin
        inv_mult_in_0 = inv_mult_out;         // z2_40_20
        inv_mult_in_1 = data_out_bram;        // z2_20_0
    end
    else if  (inv_state_reg == s_z2_50_0) begin
        inv_mult_in_0 = inv_mult_out;         // z2_50_10
        inv_mult_in_1 = data_out_bram;        // z2_10_0
    end
    else if  (inv_state_reg == s_z2_100_0) begin
        inv_mult_in_0 = inv_mult_out;         // z2_100_50
        inv_mult_in_1 = data_out_bram;        // z2_50_0
    end
    else if  (inv_state_reg == s_z2_200_0) begin
        inv_mult_in_0 = inv_mult_out;         // z2_200_100
        inv_mult_in_1 = data_out_bram;        // z2_100_0
    end
    else if  (inv_state_reg == s_z2_250_0) begin
        inv_mult_in_0 = inv_mult_out;         // z2_250_50
        inv_mult_in_1 = data_out_bram;        // z2_50_0
    end
    else if  (inv_state_reg == s_z2_255_21) begin
        inv_mult_in_0 = inv_mult_out;         // z2_255_5
        inv_mult_in_1 = data_out_bram;        // z11
    end
    else if  (inv_state_reg == s_invert_x) begin
        inv_mult_in_0 = inv_mult_out;         // inv(z)
        inv_mult_in_1 = inv_x;                // x
    end
    else if  (inv_state_reg == s_invert_y) begin
        inv_mult_in_0 = data_out_bram;        // inv(z)
        inv_mult_in_1 = inv_y;                // y
    end
end

/*-------------------------------------FSM------------------------------------*/

/* Synchronous state update */
always @(posedge clk) begin
    if (rst) begin
        n_counter <= 4'd0;
        inv_state_reg <= idle;
    end
    else begin
        n_counter <= n_counter_next;
        r_counter <= r_counter_next;
        inv_state_reg <= inv_state_new;
    end
end

/* Asynchronous next state logic */
always @* begin
    /* No change is the default */
    inv_state_new = inv_state_reg;
    r_counter_next = r_counter;
    /* It takes 13 cycles for a mult result to be available */
    n_counter_next = (n_counter == 4'd0) ? 4'd12 : n_counter - 1'b1;

    /* Only ready when idle */
    inv_ready = 1'b0;

    addr_in_bram = 4'b0;
    addr_out_bram = 4'b0;

    case (inv_state_reg)
    idle:
        begin
            inv_ready = 1'b1;
            if (inv_ena)
                begin
                    inv_state_new = s_z2;
                    n_counter_next = 4'd13;
                end
        end
    s_z2:
        begin
            if (n_counter == 4'b0) begin
                inv_state_new = s_z4;
            end
        end
    s_z4:
        begin
            addr_in_bram = ADDR_Z2;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z8;
            end
        end
    s_z8:
        begin
            if (n_counter == 4'b0) begin
                inv_state_new = s_z9;
            end
        end
    s_z9:
        begin
            if (n_counter == 4'b0) begin
                inv_state_new = s_z11;
                addr_out_bram = ADDR_Z2;
            end
        end
    s_z11:
        begin
            addr_in_bram = ADDR_Z9;
            addr_out_bram = ADDR_Z2;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z22;
            end
        end
    s_z22:
        begin
            addr_in_bram = ADDR_Z11;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_5_0;
                addr_out_bram = ADDR_Z9;
            end
        end
    s_z2_5_0:
        begin
            addr_out_bram = ADDR_Z9;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_6_1;
            end
        end
    s_z2_6_1:
        begin
            addr_in_bram = ADDR_Z2_5_0;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_10_5;
                r_counter_next = 7'd3;
            end
        end
    s_z2_10_5:
        begin
            if (n_counter == 4'b0) begin
                r_counter_next = r_counter - 1'b1;
                if (r_counter == 7'd0) begin
                    inv_state_new = s_z2_10_0;
                    addr_out_bram = ADDR_Z2_5_0;
                end
            end
        end
    s_z2_10_0:
        begin
            addr_out_bram = ADDR_Z2_5_0;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_11_1;
            end
        end
    s_z2_11_1:
        begin
            addr_in_bram = ADDR_Z2_10_0;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_20_10;
                r_counter_next = 7'd8;
            end
        end
    s_z2_20_10:
        begin
            if (n_counter == 4'b0) begin
                r_counter_next = r_counter - 1'b1;
                if (r_counter == 7'd0) begin
                    inv_state_new = s_z2_20_0;
                    addr_out_bram = ADDR_Z2_10_0;
                end
            end
        end
    s_z2_20_0:
        begin
            addr_out_bram = ADDR_Z2_10_0;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_21_1;
            end
        end
    s_z2_21_1:
        begin
            addr_in_bram = ADDR_Z2_20_0;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_40_20;
                r_counter_next = 7'd18;
            end
        end
    s_z2_40_20:
        begin
            if (n_counter == 4'b0) begin
                r_counter_next = r_counter - 1'b1;
                if (r_counter == 7'd0) begin
                    inv_state_new = s_z2_40_0;
                    addr_out_bram = ADDR_Z2_20_0;
                end
            end
        end
    s_z2_40_0:
        begin
            addr_out_bram = ADDR_Z2_20_0;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_41_1;
            end
        end
    s_z2_41_1:
        begin
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_50_10;
                r_counter_next = 7'd8;
            end
        end
    s_z2_50_10:
        begin
            if (n_counter == 4'b0) begin
                r_counter_next = r_counter - 1'b1;
                if (r_counter == 7'd0) begin
                    inv_state_new = s_z2_50_0;
                    addr_out_bram = ADDR_Z2_10_0;
                end
            end
        end
    s_z2_50_0:
        begin
            addr_out_bram = ADDR_Z2_10_0;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_51_1;
            end
        end
    s_z2_51_1:
        begin
            addr_in_bram = ADDR_Z2_50_0;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_100_50;
                r_counter_next = 7'd48;
            end
        end
    s_z2_100_50:
        begin
            if (n_counter == 4'b0) begin
                r_counter_next = r_counter - 1'b1;
                if (r_counter == 7'd0) begin
                    inv_state_new = s_z2_100_0;
                    addr_out_bram = ADDR_Z2_50_0;
                end
            end
        end
    s_z2_100_0:
        begin
            addr_out_bram = ADDR_Z2_50_0;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_101_1;
            end
        end
    s_z2_101_1:
        begin
            addr_in_bram = ADDR_Z2_100_0;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_200_100;
                r_counter_next = 7'd98;
            end
        end
    s_z2_200_100:
        begin
            if (n_counter == 4'b0) begin
                r_counter_next = r_counter - 1'b1;
                if (r_counter == 7'd0) begin
                    inv_state_new = s_z2_200_0;
                    addr_out_bram = ADDR_Z2_100_0;
                end
            end
        end
    s_z2_200_0:
        begin
            addr_out_bram = ADDR_Z2_100_0;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_201_1;
            end
        end
    s_z2_201_1:
        begin
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_250_50;
                r_counter_next = 7'd48;
            end
        end
    s_z2_250_50:
        begin
            if (n_counter == 4'b0) begin
                r_counter_next = r_counter - 1'b1;
                if (r_counter == 7'd0) begin
                    inv_state_new = s_z2_250_0;
                    addr_out_bram = ADDR_Z2_50_0;
                end
            end
        end
    s_z2_250_0:
        begin
            addr_out_bram = ADDR_Z2_50_0;
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_251_1;
            end
        end
    s_z2_251_1:
        begin
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_252_2;
            end
        end
    s_z2_252_2:
        begin
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_253_3;
            end
        end
    s_z2_253_3:
        begin
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_254_4;
            end
        end
    s_z2_254_4:
        begin
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_255_5;
            end
        end
    s_z2_255_5:
        begin
            if (n_counter == 4'b0) begin
                inv_state_new = s_z2_255_21;
                addr_out_bram = ADDR_Z11;
            end
        end
    s_z2_255_21:
        begin
            addr_out_bram = ADDR_Z11;
            if (n_counter == 4'b0) begin
                inv_state_new = s_invert_x;
            end
        end
    s_invert_x:
        begin
            addr_in_bram = ADDR_INVZ;
            if (n_counter == 4'b0) begin
                inv_state_new = s_invert_y;
                addr_out_bram = ADDR_INVZ;
            end
        end
    s_invert_y:
        begin
            addr_in_bram = ADDR_INVX;
            addr_out_bram = ADDR_INVZ;
            if (n_counter == 4'b0) begin
                inv_state_new = s_output;
                addr_out_bram = ADDR_INVX;
            end
        end
    s_output:
        begin
            inv_state_new = idle;
        end
    default:
        begin
            inv_state_new = idle;
        end
    endcase
end

/*---------------------------------REG UPDATE---------------------------------*/

assign we_bram = (inv_state_reg == s_z4)
               | (inv_state_reg == s_z11)
               | (inv_state_reg == s_z22)
               | (inv_state_reg == s_z2_6_1)
               | (inv_state_reg == s_z2_11_1)
               | (inv_state_reg == s_z2_21_1)
               | (inv_state_reg == s_z2_51_1)
               | (inv_state_reg == s_z2_101_1)
               | (inv_state_reg == s_invert_x)
               | (inv_state_reg == s_invert_y);

/*-----------------------------------OUTPUT-----------------------------------*/

/* Output the affine coordinates */
always @* begin
    inv_x_out = 255'bx;
    inv_y_out = 255'bx;
    inv_comp_done = 1'b0;
    if (inv_state_reg == s_output) begin
        inv_comp_done = 1'b1;
        // TODO Optimize conditional output (need this fully reduced)
        inv_x_out = data_out_bram < p ? data_out_bram :
            data_out_bram - p;
        inv_y_out = inv_mult_out < p ? inv_mult_out :
            inv_mult_out - p;
    end
end

endmodule
