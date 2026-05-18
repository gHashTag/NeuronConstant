// tb_ibm_hfp.v — Testbench for IBM HFP short + long
// Known vectors:
//   IBM HFP 1.0 = 0x41100000 (S=0, E=0x41=65, hex_mant=0x100000 → 0.0625 * 16^1 = 1.0)
//   IBM HFP 2.0 = 0x41200000 (mant=0x200000 → 0.125 * 16 = 2.0)
`timescale 1ns/1ps
`default_nettype none

module tb_ibm_hfp;
    integer fail_count;

    reg        clk, rst_n;
    reg [31:0] short_din;
    reg        short_load;
    wire [31:0] short_dout;
    wire        short_sign;
    wire [6:0]  short_exp;
    wire [23:0] short_mant;
    wire [27:0] short_mx16;
    wire [31:0] short_mx256;

    ibm_hfp_short u_short (
        .clk(clk), .rst_n(rst_n),
        .din(short_din), .load(short_load), .dout(short_dout),
        .sign(short_sign), .exp_base16(short_exp),
        .hex_mant(short_mant), .mant_x16(short_mx16), .mant_x256(short_mx256)
    );

    // ibm_hfp_long (identity round-trip)
    reg [63:0]  long_din;
    reg         long_load;
    wire [63:0] long_dout;

    ibm_hfp_long u_long (
        .clk(clk), .rst_n(rst_n),
        .din(long_din), .load(long_load), .dout(long_dout),
        .sign(), .exp_base16(), .hex_mant()
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; fail_count = 0;
        short_din = 0; short_load = 0;
        long_din = 0;  long_load = 0;
        #12; rst_n = 1;

        // --- IBM HFP Short: 1.0 = 0x41100000 ---
        short_din = 32'h41100000; short_load = 1'b1;
        @(posedge clk); #1; short_load = 1'b0;
        if (short_dout !== 32'h41100000) begin
            $display("FAIL ibm_hfp_short round-trip 1.0: got %h", short_dout);
            fail_count = fail_count + 1;
        end
        if (short_sign !== 1'b0) begin
            $display("FAIL ibm_hfp_short sign for 1.0: got %b", short_sign);
            fail_count = fail_count + 1;
        end
        if (short_exp !== 7'h41) begin
            $display("FAIL ibm_hfp_short exp for 1.0: got %h (expected 41)", short_exp);
            fail_count = fail_count + 1;
        end
        if (short_mant !== 24'h100000) begin
            $display("FAIL ibm_hfp_short mant for 1.0: got %h (expected 100000)", short_mant);
            fail_count = fail_count + 1;
        end
        // mant_x16 = mant<<4 = 24'h100000 << 4 = 28'h1000000
        if (short_mx16 !== 28'h1000000) begin
            $display("FAIL ibm_hfp_short mant_x16 for 1.0: got %h (expected 1000000)", short_mx16);
            fail_count = fail_count + 1;
        end

        // --- IBM HFP Short: 2.0 = 0x41200000 ---
        short_din = 32'h41200000; short_load = 1'b1;
        @(posedge clk); #1; short_load = 1'b0;
        if (short_dout !== 32'h41200000) begin
            $display("FAIL ibm_hfp_short round-trip 2.0: got %h", short_dout);
            fail_count = fail_count + 1;
        end
        if (short_mant !== 24'h200000) begin
            $display("FAIL ibm_hfp_short mant for 2.0: got %h (expected 200000)", short_mant);
            fail_count = fail_count + 1;
        end

        // --- IBM HFP Long: round-trip ---
        long_din = 64'h4110000000000000; long_load = 1'b1;
        @(posedge clk); #1; long_load = 1'b0;
        if (long_dout !== 64'h4110000000000000) begin
            $display("FAIL ibm_hfp_long round-trip: got %h", long_dout);
            fail_count = fail_count + 1;
        end

        if (fail_count == 0)
            $display("PASS ibm_hfp (short 1.0/2.0 + long round-trip)");
        else
            $display("FAIL ibm_hfp (%0d failures)", fail_count);
        $finish;
    end
endmodule
`default_nettype wire
