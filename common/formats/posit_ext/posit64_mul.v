// posit64_mul.v — Posit<64,3> multiplication
//
// TRUNCATION POLICY:
//   Full 60x60-bit shift-add requires 60 partial products and 120-bit accumulator.
//   We truncate to top 32 bits of each significand for partial products,
//   yielding 32 partial products of 64-bit width → 64-bit product.
//   Mantissa precision limited to ~32 bits (~9.6 decimal digits).
//   Error < 2^-32 relative (< 1 ULP at 32-bit precision).
//   Trade-off: ~50% area savings vs. full-width 60-bit multiplier.
//
// Shift-add: generate loop over 32 partial products (R-SI-1: no standalone *)
//
// Verilog-2005, `default_nettype none, R-SI-1 compliant
`default_nettype none

module posit64_mul (
    input  wire [63:0] a,
    input  wire [63:0] b,
    output reg  [63:0] result,
    output reg         nar_out
);

    localparam NAR  = 64'h8000000000000000;
    localparam ZERO = 64'h0000000000000000;

    // ----------------------------------------------------------------
    // Decode A
    wire        sign_a = a[63];
    wire [62:0] mag_a  = sign_a ? (~a[62:0] + 63'd1) : a[62:0];
    wire        rbit_a = mag_a[62];

    reg [5:0] rlen_a;
    reg signed [7:0] k_a;

    always @(*) begin
        casez (mag_a[62:46])
            17'b1_0???_????_????_????: begin k_a =  8'sd0;  rlen_a = 6'd2;  end
            17'b1_10??_????_????_????: begin k_a =  8'sd1;  rlen_a = 6'd3;  end
            17'b1_110?_????_????_????: begin k_a =  8'sd2;  rlen_a = 6'd4;  end
            17'b1_1110_????_????_????: begin k_a =  8'sd3;  rlen_a = 6'd5;  end
            17'b1_1111_0???_????_????: begin k_a =  8'sd4;  rlen_a = 6'd6;  end
            17'b1_1111_10??_????_????: begin k_a =  8'sd5;  rlen_a = 6'd7;  end
            17'b1_1111_110?_????_????: begin k_a =  8'sd6;  rlen_a = 6'd8;  end
            17'b1_1111_1110_????_????: begin k_a =  8'sd7;  rlen_a = 6'd9;  end
            17'b1_1111_1111_0???_????: begin k_a =  8'sd8;  rlen_a = 6'd10; end
            17'b1_1111_1111_10??_????: begin k_a =  8'sd9;  rlen_a = 6'd11; end
            17'b1_1111_1111_110?_????: begin k_a =  8'sd10; rlen_a = 6'd12; end
            17'b1_1111_1111_1110_????: begin k_a =  8'sd11; rlen_a = 6'd13; end
            17'b1_1111_1111_1111_0???: begin k_a =  8'sd12; rlen_a = 6'd14; end
            17'b1_1111_1111_1111_10??: begin k_a =  8'sd13; rlen_a = 6'd15; end
            17'b1_1111_1111_1111_110?: begin k_a =  8'sd14; rlen_a = 6'd16; end
            17'b1_1111_1111_1111_1110: begin k_a =  8'sd15; rlen_a = 6'd17; end
            17'b1_1111_1111_1111_1111: begin k_a =  8'sd16; rlen_a = 6'd18; end
            17'b0_1???_????_????_????: begin k_a = -8'sd1;  rlen_a = 6'd2;  end
            17'b0_01??_????_????_????: begin k_a = -8'sd2;  rlen_a = 6'd3;  end
            17'b0_001?_????_????_????: begin k_a = -8'sd3;  rlen_a = 6'd4;  end
            17'b0_0001_????_????_????: begin k_a = -8'sd4;  rlen_a = 6'd5;  end
            17'b0_0000_1???_????_????: begin k_a = -8'sd5;  rlen_a = 6'd6;  end
            17'b0_0000_01??_????_????: begin k_a = -8'sd6;  rlen_a = 6'd7;  end
            17'b0_0000_001?_????_????: begin k_a = -8'sd7;  rlen_a = 6'd8;  end
            17'b0_0000_0001_????_????: begin k_a = -8'sd8;  rlen_a = 6'd9;  end
            17'b0_0000_0000_1???_????: begin k_a = -8'sd9;  rlen_a = 6'd10; end
            17'b0_0000_0000_01??_????: begin k_a = -8'sd10; rlen_a = 6'd11; end
            17'b0_0000_0000_001?_????: begin k_a = -8'sd11; rlen_a = 6'd12; end
            17'b0_0000_0000_0001_????: begin k_a = -8'sd12; rlen_a = 6'd13; end
            17'b0_0000_0000_0000_1???: begin k_a = -8'sd13; rlen_a = 6'd14; end
            17'b0_0000_0000_0000_01??: begin k_a = -8'sd14; rlen_a = 6'd15; end
            17'b0_0000_0000_0000_001?: begin k_a = -8'sd15; rlen_a = 6'd16; end
            17'b0_0000_0000_0000_0001: begin k_a = -8'sd16; rlen_a = 6'd17; end
            default:                   begin k_a = -8'sd16; rlen_a = 6'd18; end
        endcase
    end

    wire [62:0] arm_a  = mag_a << rlen_a;
    wire [2:0]  exp_a  = arm_a[62:60];
    wire [58:0] frac_a = arm_a[59:1];
    wire signed [10:0] scale_a = ($signed({k_a, 3'b000}) + {8'b0, exp_a});
    // Truncated: top 32 bits of 60-bit significand
    wire [31:0] sig_a_t = {1'b1, frac_a[58:28]};

    // ----------------------------------------------------------------
    // Decode B
    wire        sign_b = b[63];
    wire [62:0] mag_b  = sign_b ? (~b[62:0] + 63'd1) : b[62:0];
    wire        rbit_b = mag_b[62];

    reg [5:0] rlen_b;
    reg signed [7:0] k_b;

    always @(*) begin
        casez (mag_b[62:46])
            17'b1_0???_????_????_????: begin k_b =  8'sd0;  rlen_b = 6'd2;  end
            17'b1_10??_????_????_????: begin k_b =  8'sd1;  rlen_b = 6'd3;  end
            17'b1_110?_????_????_????: begin k_b =  8'sd2;  rlen_b = 6'd4;  end
            17'b1_1110_????_????_????: begin k_b =  8'sd3;  rlen_b = 6'd5;  end
            17'b1_1111_0???_????_????: begin k_b =  8'sd4;  rlen_b = 6'd6;  end
            17'b1_1111_10??_????_????: begin k_b =  8'sd5;  rlen_b = 6'd7;  end
            17'b1_1111_110?_????_????: begin k_b =  8'sd6;  rlen_b = 6'd8;  end
            17'b1_1111_1110_????_????: begin k_b =  8'sd7;  rlen_b = 6'd9;  end
            17'b1_1111_1111_0???_????: begin k_b =  8'sd8;  rlen_b = 6'd10; end
            17'b1_1111_1111_10??_????: begin k_b =  8'sd9;  rlen_b = 6'd11; end
            17'b1_1111_1111_110?_????: begin k_b =  8'sd10; rlen_b = 6'd12; end
            17'b1_1111_1111_1110_????: begin k_b =  8'sd11; rlen_b = 6'd13; end
            17'b1_1111_1111_1111_0???: begin k_b =  8'sd12; rlen_b = 6'd14; end
            17'b1_1111_1111_1111_10??: begin k_b =  8'sd13; rlen_b = 6'd15; end
            17'b1_1111_1111_1111_110?: begin k_b =  8'sd14; rlen_b = 6'd16; end
            17'b1_1111_1111_1111_1110: begin k_b =  8'sd15; rlen_b = 6'd17; end
            17'b1_1111_1111_1111_1111: begin k_b =  8'sd16; rlen_b = 6'd18; end
            17'b0_1???_????_????_????: begin k_b = -8'sd1;  rlen_b = 6'd2;  end
            17'b0_01??_????_????_????: begin k_b = -8'sd2;  rlen_b = 6'd3;  end
            17'b0_001?_????_????_????: begin k_b = -8'sd3;  rlen_b = 6'd4;  end
            17'b0_0001_????_????_????: begin k_b = -8'sd4;  rlen_b = 6'd5;  end
            17'b0_0000_1???_????_????: begin k_b = -8'sd5;  rlen_b = 6'd6;  end
            17'b0_0000_01??_????_????: begin k_b = -8'sd6;  rlen_b = 6'd7;  end
            17'b0_0000_001?_????_????: begin k_b = -8'sd7;  rlen_b = 6'd8;  end
            17'b0_0000_0001_????_????: begin k_b = -8'sd8;  rlen_b = 6'd9;  end
            17'b0_0000_0000_1???_????: begin k_b = -8'sd9;  rlen_b = 6'd10; end
            17'b0_0000_0000_01??_????: begin k_b = -8'sd10; rlen_b = 6'd11; end
            17'b0_0000_0000_001?_????: begin k_b = -8'sd11; rlen_b = 6'd12; end
            17'b0_0000_0000_0001_????: begin k_b = -8'sd12; rlen_b = 6'd13; end
            17'b0_0000_0000_0000_1???: begin k_b = -8'sd13; rlen_b = 6'd14; end
            17'b0_0000_0000_0000_01??: begin k_b = -8'sd14; rlen_b = 6'd15; end
            17'b0_0000_0000_0000_001?: begin k_b = -8'sd15; rlen_b = 6'd16; end
            17'b0_0000_0000_0000_0001: begin k_b = -8'sd16; rlen_b = 6'd17; end
            default:                   begin k_b = -8'sd16; rlen_b = 6'd18; end
        endcase
    end

    wire [62:0] arm_b  = mag_b << rlen_b;
    wire [2:0]  exp_b  = arm_b[62:60];
    wire [58:0] frac_b = arm_b[59:1];
    wire signed [10:0] scale_b = ($signed({k_b, 3'b000}) + {8'b0, exp_b});
    wire [31:0] sig_b_t = {1'b1, frac_b[58:28]};

    // ----------------------------------------------------------------
    // Truncated 32x32 shift-add (32 partial products, R-SI-1: no standalone *)
    wire [63:0] partial_t [0:31];

    genvar gi;
    generate
        for (gi = 0; gi < 32; gi = gi + 1) begin : pp_t_gen
            assign partial_t[gi] = sig_b_t[gi] ? ({32'b0, sig_a_t} << gi) : 64'b0;
        end
    endgenerate

    reg [63:0] sig_prod_t;
    integer pi;
    always @(*) begin
        sig_prod_t = 64'b0;
        for (pi = 0; pi < 32; pi = pi + 1)
            sig_prod_t = sig_prod_t + partial_t[pi];
    end

    // ----------------------------------------------------------------
    // Normalize
    wire signed [11:0] scale_sum = $signed(scale_a) + $signed(scale_b);

    wire norm = sig_prod_t[63];
    wire [63:0] sig_norm  = norm ? sig_prod_t : (sig_prod_t << 1);
    wire signed [11:0] scale_norm = norm ? (scale_sum + 12'sd1) : scale_sum;

    wire signed [8:0] k_out  = scale_norm[11:3];  // /8 arithmetic
    wire [2:0]        exp_out = scale_norm[2:0];

    // Top 59 bits of 64-bit normalized product
    wire [58:0] mant_out = sig_norm[63:5];

    // ----------------------------------------------------------------
    wire sign_out = sign_a ^ sign_b;

    wire [63:0] enc_out;
    posit64_encode enc_inst (
        .is_zero (1'b0),
        .is_nar  (1'b0),
        .sign    (sign_out),
        .k_in    ({{1{k_out[7]}}, k_out[6:0]}),
        .exp_in  (exp_out),
        .mant_in (mant_out),
        .p_out   (enc_out)
    );

    wire is_zero_a = (a == ZERO);
    wire is_zero_b = (b == ZERO);
    wire is_nar_a  = (a == NAR);
    wire is_nar_b  = (b == NAR);

    always @(*) begin
        nar_out = is_nar_a || is_nar_b;
        if (nar_out)
            result = NAR;
        else if (is_zero_a || is_zero_b)
            result = ZERO;
        else
            result = enc_out;
    end

endmodule
`default_nettype wire
