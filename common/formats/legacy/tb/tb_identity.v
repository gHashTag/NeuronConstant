// tb_identity.v — Round-trip testbench for identity/unsupported_in_f32 formats:
//   decimal64, decimal128, fp80, binary128, binary256, ibm_hfp_long (already tested)
//   vax_d, vax_g, vax_h, minifloat, legacy_pack
`timescale 1ns/1ps
`default_nettype none

module tb_identity;
    integer fail_count;
    reg clk, rst_n;

    // --- decimal64 ---
    reg  [63:0] d64_din;  reg d64_load;  wire [63:0] d64_dout;
    decimal64 u_d64 (.clk(clk),.rst_n(rst_n),.din(d64_din),.load(d64_load),.dout(d64_dout),
                     .sign(),.biased_exp(),.trailing_sig());

    // --- decimal128 ---
    reg  [127:0] d128_din;  reg d128_load;  wire [127:0] d128_dout;
    decimal128 u_d128 (.clk(clk),.rst_n(rst_n),.din(d128_din),.load(d128_load),.dout(d128_dout));

    // --- fp80 ---
    reg  [79:0]  fp80_din;  reg fp80_load;  wire [79:0] fp80_dout;
    fp80 u_fp80 (.clk(clk),.rst_n(rst_n),.din(fp80_din),.load(fp80_load),.dout(fp80_dout),
                 .sign(),.biased_exp(),.integer_bit(),.mantissa());

    // --- binary128 ---
    reg  [127:0] b128_din;  reg b128_load;  wire [127:0] b128_dout;
    binary128 u_b128 (.clk(clk),.rst_n(rst_n),.din(b128_din),.load(b128_load),.dout(b128_dout),
                      .sign(),.biased_exp(),.mantissa());

    // --- binary256 ---
    reg  [255:0] b256_din;  reg b256_load;  wire [255:0] b256_dout;
    binary256 u_b256 (.clk(clk),.rst_n(rst_n),.din(b256_din),.load(b256_load),.dout(b256_dout),
                      .sign(),.biased_exp(),.mantissa());

    // --- minifloat (E4M3, 8-bit) ---
    reg  [7:0]  mf_din;  reg mf_load;  wire [7:0] mf_dout;
    minifloat #(.S_BITS(1),.E_BITS(4),.M_BITS(3),.BIAS(7)) u_mf (
        .clk(clk),.rst_n(rst_n),.din(mf_din),.load(mf_load),.dout(mf_dout),
        .sign_out(),.exp_out(),.mant_out(),.encoded());

    // --- legacy_pack ---
    reg  [4:0]   lp_fid;
    reg  [255:0] lp_din;  reg lp_load;  wire [255:0] lp_dout;  wire lp_valid;
    legacy_pack u_lp (.clk(clk),.rst_n(rst_n),.format_id(lp_fid),
                      .din(lp_din),.load(lp_load),.dout(lp_dout),.valid(lp_valid));

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; fail_count = 0;
        d64_din = 0; d64_load = 0;
        d128_din = 0; d128_load = 0;
        fp80_din = 0; fp80_load = 0;
        b128_din = 0; b128_load = 0;
        b256_din = 0; b256_load = 0;
        mf_din = 0; mf_load = 0;
        lp_fid = 0; lp_din = 0; lp_load = 0;
        #12; rst_n = 1;

        // decimal64 round-trip
        d64_din = 64'hDEADBEEFCAFEBABE; d64_load = 1'b1; @(posedge clk); #1; d64_load = 0;
        if (d64_dout !== 64'hDEADBEEFCAFEBABE) begin
            $display("FAIL decimal64 round-trip: %h", d64_dout); fail_count = fail_count + 1;
        end

        // decimal128 round-trip
        d128_din = 128'hDEADBEEFCAFEBABE0123456789ABCDEF; d128_load = 1'b1;
        @(posedge clk); #1; d128_load = 0;
        if (d128_dout !== 128'hDEADBEEFCAFEBABE0123456789ABCDEF) begin
            $display("FAIL decimal128 round-trip: %h", d128_dout); fail_count = fail_count + 1;
        end

        // fp80 round-trip (x87 1.0 = 0x3FFF8000000000000000)
        fp80_din = 80'h3FFF8000000000000000; fp80_load = 1'b1; @(posedge clk); #1; fp80_load = 0;
        if (fp80_dout !== 80'h3FFF8000000000000000) begin
            $display("FAIL fp80 round-trip: %h", fp80_dout); fail_count = fail_count + 1;
        end

        // binary128 round-trip
        b128_din = 128'h3FFF0000000000000000000000000000; b128_load = 1'b1;
        @(posedge clk); #1; b128_load = 0;
        if (b128_dout !== 128'h3FFF0000000000000000000000000000) begin
            $display("FAIL binary128 round-trip: %h", b128_dout); fail_count = fail_count + 1;
        end

        // binary256 round-trip
        b256_din = 256'hDEADBEEFCAFEBABE0123456789ABCDEFDEADBEEFCAFEBABE0123456789ABCDEF;
        b256_load = 1'b1; @(posedge clk); #1; b256_load = 0;
        if (b256_dout !== 256'hDEADBEEFCAFEBABE0123456789ABCDEFDEADBEEFCAFEBABE0123456789ABCDEF) begin
            $display("FAIL binary256 round-trip: %h", b256_dout); fail_count = fail_count + 1;
        end

        // minifloat round-trip
        mf_din = 8'hAB; mf_load = 1'b1; @(posedge clk); #1; mf_load = 0;
        if (mf_dout !== 8'hAB) begin
            $display("FAIL minifloat round-trip: %h", mf_dout); fail_count = fail_count + 1;
        end

        // legacy_pack round-trip (format_id=0, decimal32)
        lp_fid = 5'd0; lp_din = 256'hDEAD; lp_load = 1'b1; @(posedge clk); #1; lp_load = 0;
        if (lp_dout !== 256'hDEAD) begin
            $display("FAIL legacy_pack round-trip: %h", lp_dout); fail_count = fail_count + 1;
        end
        if (lp_valid !== 1'b1) begin
            $display("FAIL legacy_pack valid: %b", lp_valid); fail_count = fail_count + 1;
        end

        if (fail_count == 0)
            $display("PASS identity formats (decimal64/128, fp80, binary128/256, minifloat, legacy_pack)");
        else
            $display("FAIL identity formats (%0d failures)", fail_count);
        $finish;
    end
endmodule
`default_nettype wire
