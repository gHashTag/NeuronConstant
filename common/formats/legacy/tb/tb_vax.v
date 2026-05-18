// tb_vax.v — Testbench for VAX F/D/G/H float modules
// Known vector: VAX F 1.0 = 0x00004080
//   Physical storage: {W0=0x0000, W1=0x4080}
//   W1[15]=0 (sign), W1[14:7]=0x81=129 (exp, bias=128, true_exp=1)
//   W1[6:0]=0 + W0=0x0000 → mantissa = 0
//   Value = 1.0 * 2^(129-128) * 0.1_binary = 1.0 ✓
`timescale 1ns/1ps
`default_nettype none

module tb_vax;
    integer fail_count;
    reg clk, rst_n;

    // VAX F
    reg [31:0]  vf_din;
    reg         vf_load;
    wire [31:0] vf_dout, vf_enc;
    wire        vf_sign;
    wire [7:0]  vf_exp;
    wire [22:0] vf_mant;

    vax_f u_vf (
        .clk(clk), .rst_n(rst_n),
        .din(vf_din), .load(vf_load), .dout(vf_dout),
        .sign(vf_sign), .biased_exp(vf_exp), .mantissa(vf_mant), .encoded(vf_enc)
    );

    // VAX D (identity)
    reg [63:0]  vd_din;
    reg         vd_load;
    wire [63:0] vd_dout;

    vax_d u_vd (
        .clk(clk), .rst_n(rst_n),
        .din(vd_din), .load(vd_load), .dout(vd_dout),
        .sign(), .biased_exp(), .mantissa()
    );

    // VAX G (identity)
    reg [63:0]  vg_din;
    reg         vg_load;
    wire [63:0] vg_dout;

    vax_g u_vg (
        .clk(clk), .rst_n(rst_n),
        .din(vg_din), .load(vg_load), .dout(vg_dout),
        .sign(), .biased_exp(), .mantissa()
    );

    // VAX H (identity)
    reg [127:0] vh_din;
    reg         vh_load;
    wire [127:0] vh_dout;

    vax_h u_vh (
        .clk(clk), .rst_n(rst_n),
        .din(vh_din), .load(vh_load), .dout(vh_dout),
        .sign(), .biased_exp(), .mantissa()
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; fail_count = 0;
        vf_din = 0; vf_load = 0;
        vd_din = 0; vd_load = 0;
        vg_din = 0; vg_load = 0;
        vh_din = 0; vh_load = 0;
        #12; rst_n = 1;

        // --- VAX F: 1.0 = 0x00004080 ---
        vf_din = 32'h00004080; vf_load = 1'b1;
        @(posedge clk); #1; vf_load = 1'b0;

        if (vf_dout !== 32'h00004080) begin
            $display("FAIL vax_f round-trip 1.0: got %h", vf_dout);
            fail_count = fail_count + 1;
        end
        // sign = storage_r[15] = 0x4080[15] = 0
        if (vf_sign !== 1'b0) begin
            $display("FAIL vax_f sign for 1.0: got %b", vf_sign);
            fail_count = fail_count + 1;
        end
        // biased_exp = storage_r[14:7] = bits[14:7] of 16'h4080 = 0b_1000001_0 >> 0 = 0x81
        if (vf_exp !== 8'h81) begin
            $display("FAIL vax_f exp for 1.0: got %h (expected 81)", vf_exp);
            fail_count = fail_count + 1;
        end
        // encoded == din
        if (vf_enc !== 32'h00004080) begin
            $display("FAIL vax_f encode 1.0: got %h", vf_enc);
            fail_count = fail_count + 1;
        end

        // Additional pattern
        vf_din = 32'hDEADBEEF; vf_load = 1'b1;
        @(posedge clk); #1; vf_load = 1'b0;
        if (vf_dout !== 32'hDEADBEEF) begin
            $display("FAIL vax_f round-trip arbitrary: got %h", vf_dout);
            fail_count = fail_count + 1;
        end

        // --- VAX D round-trip (identity) ---
        vd_din = 64'h00004080_00000000; vd_load = 1'b1;
        @(posedge clk); #1; vd_load = 1'b0;
        if (vd_dout !== 64'h00004080_00000000) begin
            $display("FAIL vax_d round-trip: got %h", vd_dout);
            fail_count = fail_count + 1;
        end

        // --- VAX G round-trip (identity) ---
        vg_din = 64'hABCDEF0123456789; vg_load = 1'b1;
        @(posedge clk); #1; vg_load = 1'b0;
        if (vg_dout !== 64'hABCDEF0123456789) begin
            $display("FAIL vax_g round-trip: got %h", vg_dout);
            fail_count = fail_count + 1;
        end

        // --- VAX H round-trip (identity) ---
        vh_din = 128'hDEADBEEFCAFEBABE0123456789ABCDEF; vh_load = 1'b1;
        @(posedge clk); #1; vh_load = 1'b0;
        if (vh_dout !== 128'hDEADBEEFCAFEBABE0123456789ABCDEF) begin
            $display("FAIL vax_h round-trip: got %h", vh_dout);
            fail_count = fail_count + 1;
        end

        if (fail_count == 0)
            $display("PASS vax (F/D/G/H) - 1.0=0x00004080 verified");
        else
            $display("FAIL vax (%0d failures)", fail_count);
        $finish;
    end
endmodule
`default_nettype wire
