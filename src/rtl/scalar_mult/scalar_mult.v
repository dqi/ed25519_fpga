`include "./addsub/sub.v"
`include "./addsub/add.v"
`include "./memories/dram.v"
`include "./memories/precomp_rom.v"

/* Multiply a point by a scalar. In practice the scalar is 253 bits but upto 256
* is possible.*/

module scalar_mult (
    input wire clk,
    input wire rst,

    /* To enable this modules computation */
    input wire sm_ena,

    /* Scalar */
    input wire [255 : 0] scalar,

    /* Ready to start */
    output wire sm_ready,
    output wire sm_error,
    output reg sm_comp_done,

    /* Results from the dedicated multipliers */
    input wire [254 : 0] sm_mult_out,

    /* To the multipliers */
    output reg [255 : 0] sm_mult_in_0,
    output reg [255 : 0] sm_mult_in_1,

    /* Output (x, y, z) */
    output reg [254 : 0] sm_x_out,
    output reg [254 : 0] sm_y_out,
    output reg [254 : 0] sm_z_out
    );


/*---------------------------INTERNAL CONSTANTS-------------------------------*/

localparam STATE_IDLE = 0;
localparam STATE_INIT = 1;
localparam STATE_PHA1 = 2;
localparam STATE_PHA2 = 3;
localparam STATE_PHA3 = 4;
localparam STATE_PHA4 = 5;
localparam STATE_NEXT = 6;
localparam STATE_OUTP = 7;

/*------------------------------------REGS------------------------------------*/

reg [254 : 0] x1;
reg [254 : 0] y1;
reg [254 : 0] t1;
reg [254 : 0] z1;
reg [254 : 0] t1_pipeline;
reg [254 : 0] z1_pipeline;

reg [254 : 0] proc_1_sub_in_0;
reg [254 : 0] proc_1_sub_in_1;

reg [254 : 0] proc_2_sub_in_0;
reg [254 : 0] proc_2_sub_in_1;

reg [254 : 0] proc_3_add_in_0;
reg [254 : 0] proc_3_add_in_1;

reg [254 : 0] proc_4_add_in_0;
reg [254 : 0] proc_4_add_in_1;

reg [255 : 0] proc_1_mult_in_0;
reg [255 : 0] proc_1_mult_in_1;
reg [255 : 0] proc_2_mult_in_0;
reg [255 : 0] proc_2_mult_in_1;
reg [255 : 0] proc_3_mult_in_0;
reg [255 : 0] proc_3_mult_in_1;
reg [255 : 0] proc_4_mult_in_0;
reg [255 : 0] proc_4_mult_in_1;

reg [255 : 0] data_in_dram_proc_1;
reg [255 : 0] data_in_dram_proc_2;
reg [255 : 0] data_in_dram_proc_3;
reg [255 : 0] data_in_dram_proc_4;

reg ready_flag;
reg error_flag;

reg [3:0] sm_state_reg;
reg [3:0] sm_state_new;

reg [4:0] sm_round_reg;
reg [4:0] sm_round_new;

reg [4:0] sm_dur_reg;
reg [4:0] sm_dur_new;

reg [7:0] idx_reg;

/*---------------------------------CONNECTIVITY-------------------------------*/

assign sm_ready = ready_flag;
assign sm_error = error_flag;

/*-----------------------------------WIRES------------------------------------*/

wire [255 : 0] proc_1_sub_out;
wire [255 : 0] proc_2_sub_out;
wire [255 : 0] proc_3_add_out;
wire [255 : 0] proc_4_add_out;

wire [12 : 0] addr;

wire [254 : 0] x_data_out;
wire [254 : 0] y_data_out;
wire [254 : 0] t_data_out;

wire en_wr_dram_proc_1;
wire en_wr_dram_proc_2;
wire en_wr_dram_proc_3;
wire en_wr_dram_proc_4;

wire [255 : 0] data_out_dram_proc_1;
wire [255 : 0] data_out_dram_proc_2;
wire [255 : 0] data_out_dram_proc_3;
wire [255 : 0] data_out_dram_proc_4;
/*---------------------------------COMPONENTS---------------------------------*/

dram dram_proc_1 (
    .clk(clk),
    .en_wr(en_wr_dram_proc_1),
    .data_in(data_in_dram_proc_1),
    .data_out(data_out_dram_proc_1)
    );

dram dram_proc_2 (
    .clk(clk),
    .en_wr(en_wr_dram_proc_2),
    .data_in(data_in_dram_proc_2),
    .data_out(data_out_dram_proc_2)
    );

dram dram_proc_3 (
    .clk(clk),
    .en_wr(en_wr_dram_proc_3),
    .data_in(data_in_dram_proc_3),
    .data_out(data_out_dram_proc_3)
    );

dram dram_proc_4 (
    .clk(clk),
    .en_wr(en_wr_dram_proc_4),
    .data_in(data_in_dram_proc_4),
    .data_out(data_out_dram_proc_4)
    );

precomp_rom #("./src/rtl/scalar_mult/memories/x_precomp.dat") x_mem (
    .clk(clk),
    .addr(addr),
    .data_out(x_data_out)
);

precomp_rom #("./src/rtl/scalar_mult/memories/y_precomp.dat") y_mem (
    .clk(clk),
    .addr(addr),
    .data_out(y_data_out)
);

precomp_rom #("./src/rtl/scalar_mult/memories/t_precomp.dat") t_mem (
    .clk(clk),
    .addr(addr),
    .data_out(t_data_out)
);


sub proc_1_sub (
    .clk(clk),
    .rst(rst),
    .sub_in_0(proc_1_sub_in_0),
    .sub_in_1(proc_1_sub_in_1),
    .sub_out(proc_1_sub_out)
);

sub proc_2_sub (
    .clk(clk),
    .rst(rst),
    .sub_in_0(proc_2_sub_in_0),
    .sub_in_1(proc_2_sub_in_1),
    .sub_out(proc_2_sub_out)
);

add proc_3_add (
    .clk(clk),
    .rst(rst),
    .add_in_0(proc_3_add_in_0),
    .add_in_1(proc_3_add_in_1),
    .add_out(proc_3_add_out)
);

add proc_4_add (
    .clk(clk),
    .rst(rst),
    .add_in_0(proc_4_add_in_0),
    .add_in_1(proc_4_add_in_1),
    .add_out(proc_4_add_out)
);

/*------------------------------------MATH------------------------------------*/

/* Processor 1 parallel unified addition. */
always @* begin
    proc_1_sub_in_0 = 255'bx;
    proc_1_sub_in_1 = 255'bx;
    proc_1_mult_in_0 = 256'bx;
    proc_1_mult_in_1 = 256'bx;

    if (sm_state_reg == STATE_PHA1) begin
            /* R_1 = Y_1 - X_1 */
            proc_1_sub_in_0 = y1;
            proc_1_sub_in_1 = x1;
    end
    else if (sm_state_reg == STATE_PHA2) begin
            /* R_5 = R_1 * R_2 */
            proc_1_mult_in_0 = proc_1_sub_out;
            proc_1_mult_in_1 = proc_2_sub_out;
    end
    else if (sm_state_reg == STATE_PHA3) begin
            /* R_1 = R_6 - R_5 */
            proc_1_sub_in_0 = data_out_dram_proc_2;
            proc_1_sub_in_1 = data_out_dram_proc_1;
    end
    else if (sm_state_reg == STATE_PHA4) begin
            /* X_1 = R_1 * R_2 */
            proc_1_mult_in_0 = proc_1_sub_out;
            proc_1_mult_in_1 = proc_2_sub_out;
    end
end

// Processor 2
always @* begin
    proc_2_sub_in_0 = 255'bx;
    proc_2_sub_in_1 = 255'bx;
    proc_2_mult_in_0 = 256'bx;
    proc_2_mult_in_1 = 256'bx;
    if (sm_state_reg == STATE_PHA1) begin
            /* R_2 = Y_2 - X_2 */
            proc_2_sub_in_0 = y_data_out;
            proc_2_sub_in_1 = x_data_out;
    end
    else if (sm_state_reg == STATE_PHA2) begin
            /* R_6 = R_3 * R_4 */
            proc_2_mult_in_0 = data_out_dram_proc_3;
            proc_2_mult_in_1 = data_out_dram_proc_4;
    end
    else if (sm_state_reg == STATE_PHA3) begin
            /* R_2 = R_8 - R_7 */
            proc_2_sub_in_0 = data_out_dram_proc_4;
            proc_2_sub_in_1 = data_out_dram_proc_3;
    end
    else if (sm_state_reg == STATE_PHA4) begin
            /* Y_1 = R_3 * R_4 */
            proc_2_mult_in_0 = data_out_dram_proc_3;
            proc_2_mult_in_1 = data_out_dram_proc_4;
    end
end

// Processor 3
always @* begin
    proc_3_add_in_0 = 255'bx;
    proc_3_add_in_1 = 255'bx;
    proc_3_mult_in_0 = 256'bx;
    proc_3_mult_in_1 = 256'bx;
    if (sm_state_reg == STATE_PHA1) begin
            /* R_3 = Y_1 + X_1 */
            proc_3_add_in_0 = y1;
            proc_3_add_in_1 = x1;
	end
    else if (sm_state_reg == STATE_PHA2) begin
            /* R_7 = T_1 * T_2 */
            proc_3_mult_in_0 = t1_pipeline;
            proc_3_mult_in_1 = t_data_out;
    end
    else if (sm_state_reg == STATE_PHA3) begin
            /* R_3 = R_8 + R_7 */
            proc_3_add_in_0 = data_out_dram_proc_4;
            proc_3_add_in_1 = data_out_dram_proc_3;
    end
    else if (sm_state_reg == STATE_PHA4) begin
            /* T_1 = R_1 * R_4 */
            proc_3_mult_in_0 = data_out_dram_proc_1;
            proc_3_mult_in_1 = data_out_dram_proc_4;
    end
end

// Processor 4
always @* begin
    proc_4_add_in_0 = 255'bx;
    proc_4_add_in_1 = 255'bx;
    proc_4_mult_in_0 = 256'bx;
    proc_4_mult_in_1 = 256'bx;
    if (sm_state_reg == STATE_PHA1) begin
            /* R_4 = Y_2 + X_2 */
            proc_4_add_in_0 = y_data_out;
            proc_4_add_in_1 = x_data_out;
    end
    else if (sm_state_reg == STATE_PHA2) begin
            /* R_8 = Z_1 * Z_2 */
            proc_4_mult_in_0 = z1_pipeline;
            proc_4_mult_in_1 = 256'b10;
    end
    else if (sm_state_reg == STATE_PHA3) begin
            /* R_4 = R_6 + R_5 */
            proc_4_add_in_0 = data_out_dram_proc_2;
            proc_4_add_in_1 = data_out_dram_proc_1;
    end
    else if (sm_state_reg == STATE_PHA4) begin
            proc_4_mult_in_0 = data_out_dram_proc_2;
            proc_4_mult_in_1 = data_out_dram_proc_3;
    end
end

/*----------------------------------PIPELINE----------------------------------*/

/* Assign the right values to x1, y1 and t1 */
always @(posedge clk) begin
    if (rst) begin
        x1 <= 255'b0;
        y1 <= 255'b0;
        t1 <= 255'b0;
    end
    else if (sm_state_reg == STATE_INIT) begin
        x1 <= x_data_out;
        y1 <= y_data_out;
        t1 <= t_data_out;
        z1 <= 255'b1;
        t1_pipeline <= 255'bx;
        z1_pipeline <= 255'bx;
    end
    else if (sm_state_reg == STATE_PHA1) begin
        x1 <= 255'bx;
        y1 <= 255'bx;
        t1 <= 255'bx;
        z1 <= 255'b1;
        t1_pipeline <= t1;
        z1_pipeline <= z1;
    end
    else if (sm_state_reg == STATE_NEXT) begin
        x1 <= data_out_dram_proc_1;
        y1 <= data_out_dram_proc_2;
        t1 <= data_out_dram_proc_3;
        z1 <= sm_mult_out;
        t1_pipeline <= 255'bx;
        z1_pipeline <= 255'bx;
    end
end


/*----------------------------------ROUTING-----------------------------------*/

always @* begin
    sm_mult_in_0 = 256'bx;
    sm_mult_in_1 = 256'bx;
    if (sm_dur_reg == 16) begin
        sm_mult_in_0 = proc_1_mult_in_0;
        sm_mult_in_1 = proc_1_mult_in_1;
    end
    if (sm_dur_reg == 15) begin
        sm_mult_in_0 = proc_2_mult_in_0;
        sm_mult_in_1 = proc_2_mult_in_1;
    end
    if (sm_dur_reg == 14) begin
        sm_mult_in_0 = proc_3_mult_in_0;
        sm_mult_in_1 = proc_3_mult_in_1;
    end
    if (sm_dur_reg == 13) begin
        sm_mult_in_0 = proc_4_mult_in_0;
        sm_mult_in_1 = proc_4_mult_in_1;
    end
end

/*------------------------------------RAM-------------------------------------*/

assign addr = {sm_round_reg, idx_reg};

/* This implicitly only happens during phase 2 and 4 */
assign en_wr_dram_proc_1 = (sm_dur_reg == 16 | sm_dur_reg == 3);
assign en_wr_dram_proc_2 = (sm_dur_reg == 16 | sm_dur_reg == 2);
assign en_wr_dram_proc_3 = (sm_dur_reg == 16 | sm_dur_reg == 1);
assign en_wr_dram_proc_4 = (sm_dur_reg == 16 | sm_dur_reg == 0);

always @* begin
    data_in_dram_proc_1 = 256'bx;
    data_in_dram_proc_2 = 256'bx;
    data_in_dram_proc_3 = 256'bx;
    data_in_dram_proc_4 = 256'bx;
    if (sm_dur_reg == 16) begin
        data_in_dram_proc_1 = proc_1_sub_out;
        data_in_dram_proc_2 = proc_2_sub_out;
        data_in_dram_proc_3 = proc_3_add_out;
        data_in_dram_proc_4 = proc_4_add_out;
    end
    else if (sm_dur_reg == 3)
        data_in_dram_proc_1 = sm_mult_out;
    else if (sm_dur_reg == 2)
        data_in_dram_proc_2 = sm_mult_out;
    else if (sm_dur_reg == 1)
        data_in_dram_proc_3 = sm_mult_out;
    else if (sm_dur_reg == 0)
        data_in_dram_proc_4 = sm_mult_out;
end

/*-------------------------------------FSM------------------------------------*/

/* Synchronous state update */
always @(posedge clk) begin
    if (rst) begin
        sm_state_reg <= STATE_IDLE;
        sm_round_reg <= 0;
        sm_dur_reg <= 0;
    end
    else begin
        sm_state_reg <= sm_state_new;
        sm_round_reg <= sm_round_new;
        sm_dur_reg <= sm_dur_new;
    end
end

/* Asynchronous next state logic */
always @* begin
    sm_state_new = sm_state_reg;
    sm_round_new = sm_round_reg;
    sm_dur_new = sm_dur_reg - 1'b1;
    idx_reg = 0;

    ready_flag = 0;
    error_flag = 0;

    case (sm_state_reg)
        STATE_IDLE:
            begin
                ready_flag = 1;

                if (sm_ena) begin
                    sm_state_new = STATE_INIT;
                    sm_round_new = sm_round_reg + 1;
                    sm_dur_new = 31;  // just so it's non-zero (then dram4 would we)
                end
            end
        STATE_INIT:
            /* 1 clk */
            begin
                begin
                    sm_state_new = STATE_PHA1;
                end
            end
        STATE_PHA1:
            /* 1 clk */
            begin
                begin
                    sm_state_new = STATE_PHA2;
                    sm_dur_new = 16;
                end
            end
        STATE_PHA2:
            /* 16 clk */
            begin
                if (sm_dur_reg == 0) begin
                    sm_state_new = STATE_PHA3;
                end
            end
        STATE_PHA3:
            /* 1 clk */
            begin
                begin
                    sm_state_new = STATE_PHA4;
                    sm_dur_new = 16;
                end
            end
        STATE_PHA4:
            /* 16 clk */
            begin
                if (sm_dur_reg == 0) begin
                    sm_state_new = STATE_NEXT;
                    sm_round_new = sm_round_reg + 1'b1;
                end
            end
        STATE_NEXT:
            /* 1 clk */
            begin
                if (sm_round_new == 0) begin
                    sm_state_new = STATE_OUTP;
                    sm_dur_new = 16;
                end
                else begin
                    sm_state_new = STATE_PHA1;
                end
            end
        STATE_OUTP:
            /* 1 clk */
            begin
                sm_state_new = STATE_IDLE;
            end
    endcase

    case (sm_round_reg)
        0:  idx_reg = scalar[7:0];
        1:  idx_reg = scalar[15:8];
        2:  idx_reg = scalar[23:16];
        3:  idx_reg = scalar[31:24];
        4:  idx_reg = scalar[39:32];
        5:  idx_reg = scalar[47:40];
        6:  idx_reg = scalar[55:48];
        7:  idx_reg = scalar[63:56];
        8:  idx_reg = scalar[71:64];
        9:  idx_reg = scalar[79:72];
        10: idx_reg = scalar[87:80];
        11: idx_reg = scalar[95:88];
        12: idx_reg = scalar[103:96];
        13: idx_reg = scalar[111:104];
        14: idx_reg = scalar[119:112];
        15: idx_reg = scalar[127:120];
        16: idx_reg = scalar[135:128];
        17: idx_reg = scalar[143:136];
        18: idx_reg = scalar[151:144];
        19: idx_reg = scalar[159:152];
        20: idx_reg = scalar[167:160];
        21: idx_reg = scalar[175:168];
        22: idx_reg = scalar[183:176];
        23: idx_reg = scalar[191:184];
        24: idx_reg = scalar[199:192];
        25: idx_reg = scalar[207:200];
        26: idx_reg = scalar[215:208];
        27: idx_reg = scalar[223:216];
        28: idx_reg = scalar[231:224];
        29: idx_reg = scalar[239:232];
        30: idx_reg = scalar[247:240];
        31: idx_reg = scalar[255:248];
    endcase

end

/*-----------------------------------OUTPUT-----------------------------------*/

always @* begin
    sm_x_out = 255'bx;
    sm_y_out = 255'bx;
    sm_z_out = 255'bx;
    sm_comp_done = 1'b0;
    if (sm_state_reg == STATE_OUTP) begin
        sm_comp_done = 1'b1;
        sm_x_out = data_out_dram_proc_1[254:0];
        sm_y_out = data_out_dram_proc_2[254:0];
        sm_z_out = sm_mult_out;
    end
end

endmodule

