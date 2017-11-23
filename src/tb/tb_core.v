module tb_core;

    always begin
        #1 clk = ~clk;
    end

    integer i = 0;

	// Inputs
	reg clk;
	reg rst;
	reg core_ena;
	reg [255:0] core_sk;
	reg [255:0] core_pk;
	reg [255:0] core_M;

	// Outputs
	wire core_ready;
	wire core_comp_done;
    wire [255:0] core_R;
    wire [255:0] core_S;

	// Instantiate the Unit Under Test (UUT)
	sign_core uut (
		.clk(clk),
		.rst(rst),
		.core_ena(core_ena),
		.core_ready(core_ready),
		.core_comp_done(core_comp_done),
		.core_sk(core_sk),
		.core_pk(core_pk),
		.core_M(core_M),
        .core_R(core_R),
        .core_S(core_S)
	);

    reg [255:0] sk_mem [0:100];
    reg [255:0] pk_mem [0:100];
    reg [255:0] m_mem [0:100];
    reg [255:0] r_mem [0:100];
    reg [255:0] s_mem [0:100];

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
		core_ena = 0;
		core_sk = 0;
		core_pk = 0;
		core_M = 0;

        // Read test vectors into memories
        $readmemh("./src/model/skfile.dat", sk_mem);
        $readmemh("./src/model/pkfile.dat", pk_mem);
        $readmemh("./src/model/mfile.dat", m_mem);
        $readmemh("./src/model/rfile.dat", r_mem);
        $readmemh("./src/model/sfile.dat", s_mem);

		// Wait 100 ns for global reset to finish
		#100;
		rst = 0;
	end

    /* Give input and enable core */
    always @* begin
        core_sk = sk_mem[i];
        core_pk = pk_mem[i];
        core_M = m_mem[i];
        core_ena = 1'b0;
        if (core_ready) begin
            core_ena = 1'b1;
        end
    end

    /* Verification of result */
    always @* begin
        if (core_comp_done) begin
            #2;
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
                i = i + 1;
            end
        end
    end

endmodule

