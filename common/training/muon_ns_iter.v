// SPDX-License-Identifier: MIT
// muon_ns_iter.v — One Newton-Schulz iteration for 3x3 GF16 matrix
//
// Quintic NS5 polynomial (Keller Jordan arXiv:2604.01472):
//   X_{k+1} = a*X + b*(X*X^T)*X + c*(X*X^T)^2*X
//   Coefficients: a=3.4445, b=-4.7750, c=2.0315
//
// For a 3x3 matrix:
//   X is indexed as x[r*3+c] for row r, col c (r,c in 0..2)
//   We compute: A = X*X^T (3x3), B = A*X (3x3), C = A*A (3x3), D = C*X (3x3)
//   Result: a*X + b*B + c*D
//
// All multiplications use gf16_mul from common/formats/goldenfloat/gf16_mul.v
// R-SI-1 clean: no standalone * operator.
// Verilog-2005, `default_nettype none.

`default_nettype none

module muon_ns_iter (
    input  wire [15:0] x0, x1, x2,   // row 0
    input  wire [15:0] x3, x4, x5,   // row 1
    input  wire [15:0] x6, x7, x8,   // row 2
    output wire [15:0] y0, y1, y2,   // row 0 out
    output wire [15:0] y3, y4, y5,   // row 1 out
    output wire [15:0] y6, y7, y8    // row 2 out
);

    // NS5 coefficients in GF16
    // a = 3.4445  -> 0x4172
    // b = -4.7750 -> 0xC263
    // c = 2.0315  -> 0x4008
    localparam [15:0] NS_A = 16'h4172;
    localparam [15:0] NS_B = 16'hC263;
    localparam [15:0] NS_C = 16'h4008;

    // Collect X elements into arrays for indexed access
    wire [15:0] X [0:8];
    assign X[0]=x0; assign X[1]=x1; assign X[2]=x2;
    assign X[3]=x3; assign X[4]=x4; assign X[5]=x5;
    assign X[6]=x6; assign X[7]=x7; assign X[8]=x8;

    // =========================================================
    // Step 1: Compute A = X * X^T  (3x3 * 3x3^T = 3x3)
    // A[i][j] = sum_k X[i][k] * X[j][k]
    // =========================================================
    // We need 9 elements of A: A[i][j] for i,j in {0,1,2}
    // Each element needs 3 multiplies + 2 adds
    // Total: 27 multiplies

    // Intermediate muls for A = X * X^T
    // A[i,j] = X[i,0]*X[j,0] + X[i,1]*X[j,1] + X[i,2]*X[j,2]

    genvar gi, gj, gk;

    // mul results for A[i][j][k] = X[i*3+k] * X[j*3+k]
    wire [15:0] a_mul [0:8][0:2];

    generate
        for (gi = 0; gi < 3; gi = gi + 1) begin : a_row
            for (gj = 0; gj < 3; gj = gj + 1) begin : a_col
                for (gk = 0; gk < 3; gk = gk + 1) begin : a_k
                    wire ov, uv;
                    gf16_mul u_amul (
                        .a(X[gi*3+gk]),
                        .b(X[gj*3+gk]),
                        .result(a_mul[gi*3+gj][gk]),
                        .overflow(ov),
                        .underflow(uv)
                    );
                end
            end
        end
    endgenerate

    // GF16 addition helper — parametric sign-magnitude add
    // GF16: S(1)|E(6)|M(9), bias=31
    // For full correctness we need a proper adder. We use a simple
    // sign-magnitude adder with 1-bit guard.
    // a_sum[i][j] = A[i][j] accumulated over k=0..2

    wire [15:0] a_sum [0:8];

    generate
        for (gi = 0; gi < 9; gi = gi + 1) begin : a_acc
            wire [15:0] tmp;
            gf16_add u_a0 ( .a(a_mul[gi][0]), .b(a_mul[gi][1]), .result(tmp) );
            gf16_add u_a1 ( .a(tmp),           .b(a_mul[gi][2]), .result(a_sum[gi]) );
        end
    endgenerate

    // =========================================================
    // Step 2: Compute B = A * X  (3x3 * 3x3 = 3x3)
    // B[i][j] = sum_k A[i][k] * X[k][j]
    // =========================================================
    wire [15:0] b_mul [0:8][0:2];

    generate
        for (gi = 0; gi < 3; gi = gi + 1) begin : b_row
            for (gj = 0; gj < 3; gj = gj + 1) begin : b_col
                for (gk = 0; gk < 3; gk = gk + 1) begin : b_k
                    wire ov, uv;
                    gf16_mul u_bmul (
                        .a(a_sum[gi*3+gk]),
                        .b(X[gk*3+gj]),
                        .result(b_mul[gi*3+gj][gk]),
                        .overflow(ov),
                        .underflow(uv)
                    );
                end
            end
        end
    endgenerate

    wire [15:0] b_sum [0:8];

    generate
        for (gi = 0; gi < 9; gi = gi + 1) begin : b_acc
            wire [15:0] tmp;
            gf16_add u_b0 ( .a(b_mul[gi][0]), .b(b_mul[gi][1]), .result(tmp) );
            gf16_add u_b1 ( .a(tmp),           .b(b_mul[gi][2]), .result(b_sum[gi]) );
        end
    endgenerate

    // =========================================================
    // Step 3: Compute C = A * A  (3x3 * 3x3)
    // C[i][j] = sum_k A[i][k] * A[k][j]
    // =========================================================
    wire [15:0] c_mul [0:8][0:2];

    generate
        for (gi = 0; gi < 3; gi = gi + 1) begin : c_row
            for (gj = 0; gj < 3; gj = gj + 1) begin : c_col
                for (gk = 0; gk < 3; gk = gk + 1) begin : c_k
                    wire ov, uv;
                    gf16_mul u_cmul (
                        .a(a_sum[gi*3+gk]),
                        .b(a_sum[gk*3+gj]),
                        .result(c_mul[gi*3+gj][gk]),
                        .overflow(ov),
                        .underflow(uv)
                    );
                end
            end
        end
    endgenerate

    wire [15:0] c_sum [0:8];

    generate
        for (gi = 0; gi < 9; gi = gi + 1) begin : c_acc
            wire [15:0] tmp;
            gf16_add u_c0 ( .a(c_mul[gi][0]), .b(c_mul[gi][1]), .result(tmp) );
            gf16_add u_c1 ( .a(tmp),           .b(c_mul[gi][2]), .result(c_sum[gi]) );
        end
    endgenerate

    // =========================================================
    // Step 4: Compute D = C * X  (3x3 * 3x3)
    // D[i][j] = sum_k C[i][k] * X[k][j]
    // =========================================================
    wire [15:0] d_mul [0:8][0:2];

    generate
        for (gi = 0; gi < 3; gi = gi + 1) begin : d_row
            for (gj = 0; gj < 3; gj = gj + 1) begin : d_col
                for (gk = 0; gk < 3; gk = gk + 1) begin : d_k
                    wire ov, uv;
                    gf16_mul u_dmul (
                        .a(c_sum[gi*3+gk]),
                        .b(X[gk*3+gj]),
                        .result(d_mul[gi*3+gj][gk]),
                        .overflow(ov),
                        .underflow(uv)
                    );
                end
            end
        end
    endgenerate

    wire [15:0] d_sum [0:8];

    generate
        for (gi = 0; gi < 9; gi = gi + 1) begin : d_acc
            wire [15:0] tmp;
            gf16_add u_d0 ( .a(d_mul[gi][0]), .b(d_mul[gi][1]), .result(tmp) );
            gf16_add u_d1 ( .a(tmp),           .b(d_mul[gi][2]), .result(d_sum[gi]) );
        end
    endgenerate

    // =========================================================
    // Step 5: Result = a*X + b*B + c*D
    // =========================================================
    wire [15:0] ax [0:8];
    wire [15:0] bB [0:8];
    wire [15:0] cD [0:8];
    wire [15:0] Y  [0:8];

    generate
        for (gi = 0; gi < 9; gi = gi + 1) begin : final_combine
            wire ov_ax, uv_ax, ov_bB, uv_bB, ov_cD, uv_cD;
            wire [15:0] ax_plus_bB;
            gf16_mul u_ax  ( .a(NS_A),     .b(X[gi]),     .result(ax[gi]),  .overflow(ov_ax), .underflow(uv_ax) );
            gf16_mul u_bB  ( .a(NS_B),     .b(b_sum[gi]), .result(bB[gi]),  .overflow(ov_bB), .underflow(uv_bB) );
            gf16_mul u_cD  ( .a(NS_C),     .b(d_sum[gi]), .result(cD[gi]),  .overflow(ov_cD), .underflow(uv_cD) );
            gf16_add u_sum0( .a(ax[gi]),   .b(bB[gi]),    .result(ax_plus_bB) );
            gf16_add u_sum1( .a(ax_plus_bB),.b(cD[gi]),   .result(Y[gi]) );
        end
    endgenerate

    assign y0=Y[0]; assign y1=Y[1]; assign y2=Y[2];
    assign y3=Y[3]; assign y4=Y[4]; assign y5=Y[5];
    assign y6=Y[6]; assign y7=Y[7]; assign y8=Y[8];

endmodule

// =========================================================
// gf16_add — GF16 sign-magnitude adder with full normalization
// GF16: S(1)|E(6)|M(9), bias=31
// =========================================================
module gf16_add (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output reg  [15:0] result
);
    wire        sa = a[15];
    wire [5:0]  ea = a[14:9];
    wire [8:0]  ma = a[8:0];
    wire        sb = b[15];
    wire [5:0]  eb = b[14:9];
    wire [8:0]  mb = b[8:0];

    wire [9:0] fa = {1'b1, ma};
    wire [9:0] fb = {1'b1, mb};

    wire za = (ea == 6'd0) && (ma == 9'd0);
    wire zb = (eb == 6'd0) && (mb == 9'd0);

    wire a_larger = (ea > eb) || (ea == eb && fa >= fb);
    wire [5:0] exp_big = a_larger ? ea : eb;
    wire [5:0] exp_sml = a_larger ? eb : ea;
    wire [9:0] man_big = a_larger ? fa : fb;
    wire [9:0] man_sml = a_larger ? fb : fa;
    wire       sgn_big = a_larger ? sa : sb;
    wire       sgn_sml = a_larger ? sb : sa;

    wire [5:0] shift_amt = exp_big - exp_sml;
    wire [9:0] man_sml_sh = (shift_amt >= 6'd10) ? 10'd0 : (man_sml >> shift_amt);

    wire same_sign = (sgn_big == sgn_sml);
    wire [10:0] man_sum = same_sign ? ({1'b0,man_big} + {1'b0,man_sml_sh})
                                    : ({1'b0,man_big} - {1'b0,man_sml_sh});

    wire sign_out = sgn_big;

    reg [5:0] nexp;
    reg [8:0] nman;

    always @(*) begin
        nexp = 6'd0;
        nman = 9'd0;

        if (za && zb) begin
            result = 16'h0000;
        end else if (za) begin
            result = b;
        end else if (zb) begin
            result = a;
        end else if (man_sum == 11'd0) begin
            result = 16'h0000;
        end else begin
            if (man_sum[10]) begin
                nexp = (exp_big < 6'd62) ? exp_big + 6'd1 : 6'd62;
                nman = man_sum[9:1];
            end else if (man_sum[9]) begin
                nexp = exp_big;
                nman = man_sum[8:0];
            end else if (man_sum[8]) begin
                nexp = (exp_big >= 6'd1) ? exp_big - 6'd1 : 6'd0;
                nman = {man_sum[7:0], 1'b0};
            end else if (man_sum[7]) begin
                nexp = (exp_big >= 6'd2) ? exp_big - 6'd2 : 6'd0;
                nman = {man_sum[6:0], 2'b0};
            end else if (man_sum[6]) begin
                nexp = (exp_big >= 6'd3) ? exp_big - 6'd3 : 6'd0;
                nman = {man_sum[5:0], 3'b0};
            end else if (man_sum[5]) begin
                nexp = (exp_big >= 6'd4) ? exp_big - 6'd4 : 6'd0;
                nman = {man_sum[4:0], 4'b0};
            end else if (man_sum[4]) begin
                nexp = (exp_big >= 6'd5) ? exp_big - 6'd5 : 6'd0;
                nman = {man_sum[3:0], 5'b0};
            end else if (man_sum[3]) begin
                nexp = (exp_big >= 6'd6) ? exp_big - 6'd6 : 6'd0;
                nman = {man_sum[2:0], 6'b0};
            end else if (man_sum[2]) begin
                nexp = (exp_big >= 6'd7) ? exp_big - 6'd7 : 6'd0;
                nman = {man_sum[1:0], 7'b0};
            end else if (man_sum[1]) begin
                nexp = (exp_big >= 6'd8) ? exp_big - 6'd8 : 6'd0;
                nman = {man_sum[0], 8'b0};
            end else begin
                nexp = (exp_big >= 6'd9) ? exp_big - 6'd9 : 6'd0;
                nman = 9'd0;
            end

            if (nexp >= 6'd63) begin
                result = {sign_out, 6'h3F, 9'd0};
            end else begin
                result = {sign_out, nexp, nman};
            end
        end
    end
endmodule

`default_nettype wire
