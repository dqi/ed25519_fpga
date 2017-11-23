`include "./sha512/sha512_core.v"
`include "./sha512/sha512_w_mem.v"
`include "./sha512/sha512_k_constants.v"
`include "./sha512/sha512_h_constants.v"

/* This module computes H(k), H(hM) or H(R,A,M), only 256 bit M are supported */

module hash_wrap (
    input wire clk,
    input wire rst,

    input wire hw_ena,

    output wire hw_ready,
    output wire hw_error,
    output wire hw_digest_valid,
    output wire [511:0] hw_digest,

    input wire [1:0] hw_mode,
    /* Mode 1, H(sk); hash the secret key */
    input wire [255:0] hw_sk,
    /* Mode 2, H(h_b,...,h_{2b-1},M); hash the randomizer and the message. */
    input wire [255:0] hw_h,
    /* Mode 3, H(R,A,M); Bind R, the compressed point. A, the public key. And M,
    * the message. */
    input wire [255:0] hw_R,
    input wire [255:0] hw_A,
    /* The message for mode 2 & 3; 256 bits. */
    input wire [255:0] hw_M
    );


/*---------------------------INTERNAL CONSTANTS-------------------------------*/

/*  The hash always fits in one block. */
localparam STATE_IDLE = 0;
localparam STATE_INIT = 1;
localparam STATE_BUSY = 2;

/*------------------------------------REGS------------------------------------*/
reg [1023:0] sha_block_reg;
reg [1023:0] sha_block_new;

reg ready_flag;
reg error_flag;

reg [1:0] hash_wrap_state_reg;
reg [1:0] hash_wrap_state_new;

reg sha_init;
reg sha_next;

reg hw_comp_done;
/*------------------------------------WIRES-----------------------------------*/

wire [1:0] sha_mode;
wire [1023:0] sha_block;
wire sha_ready;
wire [511:0] sha_digest;
wire sha_digest_valid;

/*--------------------------------COMPONENTS----------------------------------*/

sha512_core sha512 (
    .clk(clk),
    .reset_n(!rst),
    .init(sha_init),
    .next(sha_next),
    .mode(sha_mode),
    /* .work_factor(work_factor), */
    /* .work_factor_num(work_factor_num), */
    .block(sha_block),
    .ready(sha_ready),
    /* .state_wr_data(state_wr_data), */
    .digest(sha_digest),
    .digest_valid(sha_digest_valid)
    );
/*---------------------------------CONNECTIVITY-------------------------------*/

assign hw_ready = ready_flag;
assign hw_error = error_flag;
assign sha_block = sha_block_reg;

assign sha_mode = 3;  // Always SHA-512
assign hw_digest = sha_digest;
assign hw_digest_valid = hw_comp_done;

/*-------------------------------------FSM------------------------------------*/

/* Synchronous state update */
always @(posedge clk) begin
    if (rst) begin
        hash_wrap_state_reg <= STATE_IDLE;
        sha_block_reg <= 1024'b0;
    end
    else begin
        hash_wrap_state_reg <= hash_wrap_state_new;
        sha_block_reg <= sha_block_new;
    end
end

/* Asynchronous next state logic */
always @* begin
    hash_wrap_state_new = STATE_IDLE;

    ready_flag = 0;
    error_flag = 0;

    sha_init = 0;
    sha_next = 0;
    sha_block_new = sha_block_reg;
    hw_comp_done = 1'b0;

    case (hash_wrap_state_reg)
        STATE_IDLE:
            begin
                ready_flag = 1;

                if (hw_ena & sha_ready) begin
                    hash_wrap_state_new = STATE_INIT;
                end
                else if (hw_ena) begin
                    error_flag = 1;
                end
            end
        STATE_INIT:
            begin
                hash_wrap_state_new = STATE_BUSY;
                sha_init = 1;
            end
        STATE_BUSY:
            begin
                hash_wrap_state_new = STATE_BUSY;
                if (sha_digest_valid) begin
                    hw_comp_done = 1'b1;
                    hash_wrap_state_new = STATE_IDLE;
                end
            end
    endcase

    /* A hash will be one block, either 256, 384 or 768 bits.
    * This also preforms the required input padding. */
    case (hw_mode)
        // H(k)
        0 : sha_block_new = {hw_sk, 1'b1, 639'b0, 128'd256};
        // H(hM)
        1 : sha_block_new = {hw_h, hw_M, 1'b1, 383'b0, 128'd512};
        // H(R,A,M)
        2 : sha_block_new = {hw_R, hw_A, hw_M, 1'b1, 127'b0, 128'd768};
        3 :
            begin
                error_flag = 1;
                hash_wrap_state_new = STATE_IDLE;
            end
    endcase
end

endmodule

