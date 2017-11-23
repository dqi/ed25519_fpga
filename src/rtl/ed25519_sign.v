`timescale 1ns / 1ps
`include "./ed25519_sign_core.v"

module ed25519_sign (
    input wire clk,
    input wire rst,

    input wire cs,
    input wire we,

    input wire [7:0] address,
    input wire [31:0] write_data,
    output wire [31:0] read_data,
    output wire error
);

/*---------------------------INTERNAL CONSTANTS-------------------------------*/

localparam ADDR_NAME0       = 8'h00;
localparam ADDR_NAME1       = 8'h01;
localparam ADDR_VERSION     = 8'h02;

localparam ADDR_CTRL        = 8'h08;
localparam CTRL_ENA_BIT     = 0;

localparam ADDR_STATUS      = 8'h09;
localparam STATUS_READY_BIT = 0;
localparam STATUS_DONE_BIT  = 1;

localparam ADDR_SECRET0     = 8'h10;
localparam ADDR_SECRET1     = 8'h11;
localparam ADDR_SECRET2     = 8'h12;
localparam ADDR_SECRET3     = 8'h13;
localparam ADDR_SECRET4     = 8'h14;
localparam ADDR_SECRET5     = 8'h15;
localparam ADDR_SECRET6     = 8'h16;
localparam ADDR_SECRET7     = 8'h17;

localparam ADDR_PUBLIC0     = 8'h20;
localparam ADDR_PUBLIC1     = 8'h21;
localparam ADDR_PUBLIC2     = 8'h22;
localparam ADDR_PUBLIC3     = 8'h23;
localparam ADDR_PUBLIC4     = 8'h24;
localparam ADDR_PUBLIC5     = 8'h25;
localparam ADDR_PUBLIC6     = 8'h26;
localparam ADDR_PUBLIC7     = 8'h27;

localparam ADDR_MESSAGE0    = 8'h30;
localparam ADDR_MESSAGE1    = 8'h31;
localparam ADDR_MESSAGE2    = 8'h32;
localparam ADDR_MESSAGE3    = 8'h33;
localparam ADDR_MESSAGE4    = 8'h34;
localparam ADDR_MESSAGE5    = 8'h35;
localparam ADDR_MESSAGE6    = 8'h36;
localparam ADDR_MESSAGE7    = 8'h37;

localparam ADDR_R0          = 8'h40;
localparam ADDR_R1          = 8'h41;
localparam ADDR_R2          = 8'h42;
localparam ADDR_R3          = 8'h43;
localparam ADDR_R4          = 8'h44;
localparam ADDR_R5          = 8'h45;
localparam ADDR_R6          = 8'h46;
localparam ADDR_R7          = 8'h47;

localparam ADDR_S0          = 8'h50;
localparam ADDR_S1          = 8'h51;
localparam ADDR_S2          = 8'h52;
localparam ADDR_S3          = 8'h53;
localparam ADDR_S4          = 8'h54;
localparam ADDR_S5          = 8'h55;
localparam ADDR_S6          = 8'h56;
localparam ADDR_S7          = 8'h57;

localparam CORE_NAME0       = 32'h65643235; // "ed25"
localparam CORE_NAME1       = 32'h35313900; // "519 "
localparam CORE_VERSION     = 32'h31333337; // "1337"

/*------------------------------------REGS------------------------------------*/

reg ena_reg;
reg ena_new;
reg ena_we;
reg ena_set;

reg done_reg;
reg done_new;
reg done_we;

reg [31:0] secret_0_reg;
reg secret_0_we;
reg [31:0] secret_1_reg;
reg secret_1_we;
reg [31:0] secret_2_reg;
reg secret_2_we;
reg [31:0] secret_3_reg;
reg secret_3_we;
reg [31:0] secret_4_reg;
reg secret_4_we;
reg [31:0] secret_5_reg;
reg secret_5_we;
reg [31:0] secret_6_reg;
reg secret_6_we;
reg [31:0] secret_7_reg;
reg secret_7_we;

reg [31:0] public_0_reg;
reg public_0_we;
reg [31:0] public_1_reg;
reg public_1_we;
reg [31:0] public_2_reg;
reg public_2_we;
reg [31:0] public_3_reg;
reg public_3_we;
reg [31:0] public_4_reg;
reg public_4_we;
reg [31:0] public_5_reg;
reg public_5_we;
reg [31:0] public_6_reg;
reg public_6_we;
reg [31:0] public_7_reg;
reg public_7_we;

reg [31:0] message_0_reg;
reg message_0_we;
reg [31:0] message_1_reg;
reg message_1_we;
reg [31:0] message_2_reg;
reg message_2_we;
reg [31:0] message_3_reg;
reg message_3_we;
reg [31:0] message_4_reg;
reg message_4_we;
reg [31:0] message_5_reg;
reg message_5_we;
reg [31:0] message_6_reg;
reg message_6_we;
reg [31:0] message_7_reg;
reg message_7_we;

reg r_we;
reg [255:0] r_reg;
reg [255:0] r_new;

reg s_we;
reg [255:0] s_reg;
reg [255:0] s_new;

reg ready_reg;
reg [31:0] tmp_read_data;
reg tmp_error;
/*-----------------------------------WIRES------------------------------------*/

wire core_ena;
wire core_ready;
wire core_comp_done;
wire [255:0] core_sk;
wire [255:0] core_pk;
wire [255:0] core_M;
wire [255:0] core_S;
wire [255:0] core_R;

/*---------------------------------CONNECTIVITY-------------------------------*/

assign read_data = tmp_read_data;

assign error     = tmp_error;

assign core_sk   = {secret_7_reg, secret_6_reg, secret_5_reg, secret_4_reg,
                    secret_3_reg, secret_2_reg, secret_1_reg, secret_0_reg};

assign core_pk   = {public_7_reg, public_6_reg, public_5_reg, public_4_reg,
                    public_3_reg, public_2_reg, public_1_reg, public_0_reg};

assign core_M    = {message_7_reg, message_6_reg, message_5_reg, message_4_reg,
                    message_3_reg, message_2_reg, message_1_reg, message_0_reg};

assign core_ena  = ena_reg;


/*--------------------------------COMPONENTS----------------------------------*/

sign_core core (
    .clk(clk),
    .rst(rst),
    .core_ena(core_ena),
    .core_ready(core_ready),
    .core_comp_done(core_comp_done),
    .core_sk(core_sk),
    .core_pk(core_pk),
    .core_M(core_M),
    .core_S(core_S),
    .core_R(core_R)
    );

/*---------------------------------REG UPDATE---------------------------------*/

always @(posedge clk) begin
    if (rst) begin
        ena_reg       <= 1'b0;
        secret_0_reg  <= 32'h00000000;
        secret_1_reg  <= 32'h00000000;
        secret_2_reg  <= 32'h00000000;
        secret_3_reg  <= 32'h00000000;
        secret_4_reg  <= 32'h00000000;
        secret_5_reg  <= 32'h00000000;
        secret_6_reg  <= 32'h00000000;
        secret_7_reg  <= 32'h00000000;
        public_0_reg  <= 32'h00000000;
        public_1_reg  <= 32'h00000000;
        public_2_reg  <= 32'h00000000;
        public_3_reg  <= 32'h00000000;
        public_4_reg  <= 32'h00000000;
        public_5_reg  <= 32'h00000000;
        public_6_reg  <= 32'h00000000;
        public_7_reg  <= 32'h00000000;
        message_0_reg <= 32'h00000000;
        message_1_reg <= 32'h00000000;
        message_2_reg <= 32'h00000000;
        message_3_reg <= 32'h00000000;
        message_4_reg <= 32'h00000000;
        message_5_reg <= 32'h00000000;
        message_6_reg <= 32'h00000000;
        message_7_reg <= 32'h00000000;
        s_reg         <= 256'b0;
        r_reg         <= 256'b0;
        ready_reg     <= 1'b0;
        done_reg      <= 1'b0;
    end

    else begin
        ready_reg <= core_ready;

        if (ena_we)
            ena_reg      <= ena_new;
        if (secret_0_we)
            secret_0_reg <= write_data;
        if (secret_1_we)
            secret_1_reg <= write_data;
        if (secret_2_we)
            secret_2_reg <= write_data;
        if (secret_3_we)
            secret_3_reg <= write_data;
        if (secret_4_we)
            secret_4_reg <= write_data;
        if (secret_5_we)
            secret_5_reg <= write_data;
        if (secret_6_we)
            secret_6_reg <= write_data;
        if (secret_7_we)
            secret_7_reg <= write_data;

        if (public_0_we)
            public_0_reg <= write_data;
        if (public_1_we)
            public_1_reg <= write_data;
        if (public_2_we)
            public_2_reg <= write_data;
        if (public_3_we)
            public_3_reg <= write_data;
        if (public_4_we)
            public_4_reg <= write_data;
        if (public_5_we)
            public_5_reg <= write_data;
        if (public_6_we)
            public_6_reg <= write_data;
        if (public_7_we)
            public_7_reg <= write_data;

        if (message_0_we)
            message_0_reg <= write_data;
        if (message_1_we)
            message_1_reg <= write_data;
        if (message_2_we)
            message_2_reg <= write_data;
        if (message_3_we)
            message_3_reg <= write_data;
        if (message_4_we)
            message_4_reg <= write_data;
        if (message_5_we)
            message_5_reg <= write_data;
        if (message_6_we)
            message_6_reg <= write_data;
        if (message_7_we)
            message_7_reg <= write_data;

        if (done_we)
            done_reg <= done_new;
        if (r_we)
            r_reg <= r_new;
        if (s_we)
            s_reg <= s_new;
    end
end

always @* begin
    ena_new = 1'b0;
    ena_we = 1'b0;

    r_we = 1'b0;
    s_we = 1'b0;
    done_we = 1'b0;
    s_new = 256'b0;
    r_new = 256'b0;
    done_new = 1'b0;

    if (ena_set & ready_reg) begin
        ena_new = 1'b1;
        ena_we  = 1'b1;

        /* Clear these registers on new computation start */
        r_we = 1'b1;
        s_we = 1'b1;
        done_we = 1'b1;
    end
    else if (ena_reg) begin
        ena_new = 1'b0;
        ena_we  = 1'b1;
    end

    if (core_comp_done) begin
        /* Save results */
        r_we = 1'b1;
        s_we = 1'b1;
        done_we = 1'b1;
        r_new = core_R;
        s_new = core_S;
        done_new = 1'b1;
    end
end

always @* begin
end

always @* begin
    ena_set      = 1'b0;

    secret_0_we   = 1'b0;
    secret_1_we   = 1'b0;
    secret_2_we   = 1'b0;
    secret_3_we   = 1'b0;
    secret_4_we   = 1'b0;
    secret_5_we   = 1'b0;
    secret_6_we   = 1'b0;
    secret_7_we   = 1'b0;
    public_0_we   = 1'b0;
    public_1_we   = 1'b0;
    public_2_we   = 1'b0;
    public_3_we   = 1'b0;
    public_4_we   = 1'b0;
    public_5_we   = 1'b0;
    public_6_we   = 1'b0;
    public_7_we   = 1'b0;
    message_0_we  = 1'b0;
    message_1_we  = 1'b0;
    message_2_we  = 1'b0;
    message_3_we  = 1'b0;
    message_4_we  = 1'b0;
    message_5_we  = 1'b0;
    message_6_we  = 1'b0;
    message_7_we  = 1'b0;
    tmp_read_data = 32'h00000000;
    tmp_error     = 1'b0;

    if (cs) begin
        if (we) begin
            /* Enable write */
            case (address)
                ADDR_CTRL:
                    ena_set     = write_data[CTRL_ENA_BIT];
                ADDR_SECRET0:
                    secret_0_we = 1'b1;
                ADDR_SECRET1:
                    secret_1_we = 1'b1;
                ADDR_SECRET2:
                    secret_2_we = 1'b1;
                ADDR_SECRET3:
                    secret_3_we = 1'b1;
                ADDR_SECRET4:
                    secret_4_we = 1'b1;
                ADDR_SECRET5:
                    secret_5_we = 1'b1;
                ADDR_SECRET6:
                    secret_6_we = 1'b1;
                ADDR_SECRET7:
                    secret_7_we = 1'b1;

                ADDR_PUBLIC0:
                    public_0_we = 1'b1;
                ADDR_PUBLIC1:
                    public_1_we = 1'b1;
                ADDR_PUBLIC2:
                    public_2_we = 1'b1;
                ADDR_PUBLIC3:
                    public_3_we = 1'b1;
                ADDR_PUBLIC4:
                    public_4_we = 1'b1;
                ADDR_PUBLIC5:
                    public_5_we = 1'b1;
                ADDR_PUBLIC6:
                    public_6_we = 1'b1;
                ADDR_PUBLIC7:
                    public_7_we = 1'b1;

                ADDR_MESSAGE0:
                    message_0_we = 1'b1;
                ADDR_MESSAGE1:
                    message_1_we = 1'b1;
                ADDR_MESSAGE2:
                    message_2_we = 1'b1;
                ADDR_MESSAGE3:
                    message_3_we = 1'b1;
                ADDR_MESSAGE4:
                    message_4_we = 1'b1;
                ADDR_MESSAGE5:
                    message_5_we = 1'b1;
                ADDR_MESSAGE6:
                    message_6_we = 1'b1;
                ADDR_MESSAGE7:
                    message_7_we = 1'b1;
                default:
                    tmp_error = 1'b1;
            endcase
        end
        else begin
            /* Read operations */
            case (address)
                ADDR_NAME0:
                    tmp_read_data = CORE_NAME0;
                ADDR_NAME1:
                    tmp_read_data = CORE_NAME1;
                ADDR_VERSION:
                    tmp_read_data = CORE_VERSION;
                ADDR_CTRL:
                    tmp_read_data = {31'b0, ena_reg};
                ADDR_STATUS:
                    tmp_read_data = {30'b0, done_reg, ready_reg};
                ADDR_R0:
                    tmp_read_data = r_reg[31:0];
                ADDR_R1:
                    tmp_read_data = r_reg[63:32];
                ADDR_R2:
                    tmp_read_data = r_reg[95:64];
                ADDR_R3:
                    tmp_read_data = r_reg[127:96];
                ADDR_R4:
                    tmp_read_data = r_reg[159:128];
                ADDR_R5:
                    tmp_read_data = r_reg[191:160];
                ADDR_R6:
                    tmp_read_data = r_reg[223:192];
                ADDR_R7:
                    tmp_read_data = r_reg[255:224];
                ADDR_S0:
                    tmp_read_data = s_reg[31:0];
                ADDR_S1:
                    tmp_read_data = s_reg[63:32];
                ADDR_S2:
                    tmp_read_data = s_reg[95:64];
                ADDR_S3:
                    tmp_read_data = s_reg[127:96];
                ADDR_S4:
                    tmp_read_data = s_reg[159:128];
                ADDR_S5:
                    tmp_read_data = s_reg[191:160];
                ADDR_S6:
                    tmp_read_data = s_reg[223:192];
                ADDR_S7:
                    tmp_read_data = s_reg[255:224];
                default:
                    tmp_error = 1'b1;
            endcase
        end
    end
end

endmodule

