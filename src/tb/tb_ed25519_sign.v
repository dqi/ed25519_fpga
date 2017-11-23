`timescale 1ns / 1ps

module tb_ed25519_sign;

    integer i = 0;
    localparam DEBUG = 0;

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
    localparam CORE_NAME1       = 32'h35313920; // "519 "
    localparam CORE_VERSION     = 32'h31333337; // "1337"

    always begin
        #1 clk = ~clk;
    end

	// Inputs
	reg clk;
	reg rst;
	reg core_cs;
	reg core_we;
	reg [7:0] core_address;
	reg [31:0] core_write_data;

	// Outputs
	wire [31:0] core_read_data;
	wire core_error;

	// Instantiate the Unit Under Test (UUT)
	ed25519_sign uut (
		.clk(clk),
		.rst(rst),
		.cs(core_cs),
		.we(core_we),
		.address(core_address),
		.write_data(core_write_data),
		.read_data(core_read_data),
		.error(core_error)
	);

    reg [255:0] sk_mem [9:0];
    reg [255:0] pk_mem [9:0];
    reg [255:0] m_mem [9:0];
    reg [255:0] r_mem [9:0];
    reg [255:0] s_mem [9:0];

    reg [31:0] read_data;
    reg done = 0;
    reg ready = 0;

    reg [31:0] r_result [7:0];
    wire [255:0] core_R;
    assign core_R = {r_result[7], r_result[6], r_result[5], r_result[4],
                     r_result[3], r_result[2], r_result[1], r_result[0]};
    reg [31:0] s_result [7:0];
    wire [255:0] core_S;
    assign core_S = {s_result[7], s_result[6], s_result[5], s_result[4],
                     s_result[3], s_result[2], s_result[1], s_result[0]};

    //----------------------------------------------------------------
    // write_word()
    //
    // Write the given word to the DUT using the DUT interface.
    //----------------------------------------------------------------
    task write_word(input [7 : 0]  address,
                    input [31 : 0] word);
      begin
        if (DEBUG)
          begin
            $display("*** Writing 0x%08x to 0x%02x.", word, address);
            $display("");
          end

        core_address = address;
        core_write_data = word;
        core_cs = 1;
        core_we = 1;
        #2;
        core_cs = 0;
        core_we = 0;
      end
    endtask // write_word

    //----------------------------------------------------------------
    // read_word()
    //
    // Read a data word from the given address in the DUT.
    // the word read will be available in the global variable
    // read_data.
    //----------------------------------------------------------------
    task read_word(input [7 : 0]  address);
      begin
        core_address = address;
        core_cs = 1;
        core_we = 0;
        #2;
        read_data = core_read_data;
        core_cs = 0;

        if (DEBUG)
          begin
            $display("*** Reading 0x%08x from 0x%02x.", read_data, address);
            $display("");
          end
      end
    endtask // read_word


	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
		core_cs = 0;
		core_we = 0;
		core_address = 0;
		core_write_data = 0;

        // Read test vectors into memories
        $readmemh("./src/model/skfile.dat", sk_mem);
        $readmemh("./src/model/pkfile.dat", pk_mem);
        $readmemh("./src/model/mfile.dat", m_mem);
        $readmemh("./src/model/rfile.dat", r_mem);
        $readmemh("./src/model/sfile.dat", s_mem);

		// Wait 100 ns for global reset to finish
		#100;
        rst = 0;

        // Verify all the test vectors
        for (i=0; i<100;i=i+1) begin

            ready = 0;
            while (ready == 0) begin
                read_word(ADDR_STATUS);
                ready = read_data[0];
            end

            write_word(ADDR_SECRET0, sk_mem[i][31:0]);
            write_word(ADDR_SECRET1, sk_mem[i][63:32]);
            write_word(ADDR_SECRET2, sk_mem[i][95:64]);
            write_word(ADDR_SECRET3, sk_mem[i][127:96]);
            write_word(ADDR_SECRET4, sk_mem[i][159:128]);
            write_word(ADDR_SECRET5, sk_mem[i][191:160]);
            write_word(ADDR_SECRET6, sk_mem[i][223:192]);
            write_word(ADDR_SECRET7, sk_mem[i][255:224]);

            write_word(ADDR_PUBLIC0, pk_mem[i][31:0]);
            write_word(ADDR_PUBLIC1, pk_mem[i][63:32]);
            write_word(ADDR_PUBLIC2, pk_mem[i][95:64]);
            write_word(ADDR_PUBLIC3, pk_mem[i][127:96]);
            write_word(ADDR_PUBLIC4, pk_mem[i][159:128]);
            write_word(ADDR_PUBLIC5, pk_mem[i][191:160]);
            write_word(ADDR_PUBLIC6, pk_mem[i][223:192]);
            write_word(ADDR_PUBLIC7, pk_mem[i][255:224]);

            write_word(ADDR_MESSAGE0, m_mem[i][31:0]);
            write_word(ADDR_MESSAGE1, m_mem[i][63:32]);
            write_word(ADDR_MESSAGE2, m_mem[i][95:64]);
            write_word(ADDR_MESSAGE3, m_mem[i][127:96]);
            write_word(ADDR_MESSAGE4, m_mem[i][159:128]);
            write_word(ADDR_MESSAGE5, m_mem[i][191:160]);
            write_word(ADDR_MESSAGE6, m_mem[i][223:192]);
            write_word(ADDR_MESSAGE7, m_mem[i][255:224]);

            write_word(ADDR_CTRL, 32'h1);

            done = 0;
            while (done == 0) begin
                read_word(ADDR_STATUS);
                done = read_data[1];
            end

            read_word(ADDR_R0); r_result[0] = read_data;
            read_word(ADDR_R1); r_result[1] = read_data;
            read_word(ADDR_R2); r_result[2] = read_data;
            read_word(ADDR_R3); r_result[3] = read_data;
            read_word(ADDR_R4); r_result[4] = read_data;
            read_word(ADDR_R5); r_result[5] = read_data;
            read_word(ADDR_R6); r_result[6] = read_data;
            read_word(ADDR_R7); r_result[7] = read_data;

            read_word(ADDR_S0); s_result[0] = read_data;
            read_word(ADDR_S1); s_result[1] = read_data;
            read_word(ADDR_S2); s_result[2] = read_data;
            read_word(ADDR_S3); s_result[3] = read_data;
            read_word(ADDR_S4); s_result[4] = read_data;
            read_word(ADDR_S5); s_result[5] = read_data;
            read_word(ADDR_S6); s_result[6] = read_data;
            read_word(ADDR_S7); s_result[7] = read_data; #2;

            $display("R: %064x", core_R);
            $display("S: %064x", core_S);
            if (core_R != r_mem[i] || core_S != s_mem[i]) begin
                $display("ERROR");
                $display("sk: %x", sk_mem[i]);
                $display("pk: %x", pk_mem[i]);
                $display("m: %x", m_mem[i]);
                $display("R: %x", r_mem[i]);
                $display("S: %x", s_mem[i]);
                $stop;
            end
            else begin
                $display("%d passed", i);
            end
        end
        $stop;
    end

endmodule

