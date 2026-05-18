// posit32_mul.v — Posit<32,2> multiplication
//
// Algorithm:
//   1. sign_out = sign_a XOR sign_b
//   2. scale_out = scale_a + scale_b = (4*k_a + exp_a) + (4*k_b + exp_b)
//   3. sig_out = sig_a * sig_b via 30x30 shift-add (R-SI-1: no standalone *)
//      Using generate loop: 30 partial products, each 60-bit
//   4. Normalize: if product bit 59 set → shift right 1, increment scale
//   5. Encode
//
// Verilog-2005, `default_nettype none, R-SI-1 compliant
`default_nettype none

module posit32_mul (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result,
    output reg         nar_out
);

    localparam NAR  = 32'h80000000;
    localparam ZERO = 32'h00000000;

    // ----------------------------------------------------------------
    // Decode A
    wire        sign_a = a[31];
    wire [30:0] mag_a  = sign_a ? (~a[30:0] + 31'd1) : a[30:0];
    wire        rbit_a = mag_a[30];

    reg [4:0] rlen_a;
    reg signed [6:0] k_a;

    always @(*) begin
        casez ({rbit_a, mag_a[29:15]})
            16'b1_0??_????_????_????: begin k_a =  7'sd0;  rlen_a = 5'd2;  end
            16'b1_10?_????_????_????: begin k_a =  7'sd1;  rlen_a = 5'd3;  end
            16'b1_110_????_????_????: begin k_a =  7'sd2;  rlen_a = 5'd4;  end
            16'b1_111_0???_????_????: begin k_a =  7'sd3;  rlen_a = 5'd5;  end
            16'b1_111_10??_????_????: begin k_a =  7'sd4;  rlen_a = 5'd6;  end
            16'b1_111_110?_????_????: begin k_a =  7'sd5;  rlen_a = 5'd7;  end
            16'b1_111_1110_????_????: begin k_a =  7'sd6;  rlen_a = 5'd8;  end
            16'b1_111_1111_0???_????: begin k_a =  7'sd7;  rlen_a = 5'd9;  end
            16'b1_111_1111_10??_????: begin k_a =  7'sd8;  rlen_a = 5'd10; end
            16'b1_111_1111_110?_????: begin k_a =  7'sd9;  rlen_a = 5'd11; end
            16'b1_111_1111_1110_????: begin k_a =  7'sd10; rlen_a = 5'd12; end
            16'b1_111_1111_1111_0???: begin k_a =  7'sd11; rlen_a = 5'd13; end
            16'b1_111_1111_1111_10??: begin k_a =  7'sd12; rlen_a = 5'd14; end
            16'b1_111_1111_1111_110?: begin k_a =  7'sd13; rlen_a = 5'd15; end
            16'b1_111_1111_1111_1110: begin k_a =  7'sd14; rlen_a = 5'd16; end
            16'b1_111_1111_1111_1111: begin k_a =  7'sd15; rlen_a = 5'd17; end
            16'b0_1??_????_????_????: begin k_a = -7'sd1;  rlen_a = 5'd2;  end
            16'b0_01?_????_????_????: begin k_a = -7'sd2;  rlen_a = 5'd3;  end
            16'b0_001_????_????_????: begin k_a = -7'sd3;  rlen_a = 5'd4;  end
            16'b0_000_1???_????_????: begin k_a = -7'sd4;  rlen_a = 5'd5;  end
            16'b0_000_01??_????_????: begin k_a = -7'sd5;  rlen_a = 5'd6;  end
            16'b0_000_001?_????_????: begin k_a = -7'sd6;  rlen_a = 5'd7;  end
            16'b0_000_0001_????_????: begin k_a = -7'sd7;  rlen_a = 5'd8;  end
            16'b0_000_0000_1???_????: begin k_a = -7'sd8;  rlen_a = 5'd9;  end
            16'b0_000_0000_01??_????: begin k_a = -7'sd9;  rlen_a = 5'd10; end
            16'b0_000_0000_001?_????: begin k_a = -7'sd10; rlen_a = 5'd11; end
            16'b0_000_0000_0001_????: begin k_a = -7'sd11; rlen_a = 5'd12; end
            16'b0_000_0000_0000_1???: begin k_a = -7'sd12; rlen_a = 5'd13; end
            16'b0_000_0000_0000_01??: begin k_a = -7'sd13; rlen_a = 5'd14; end
            16'b0_000_0000_0000_001?: begin k_a = -7'sd14; rlen_a = 5'd15; end
            16'b0_000_0000_0000_0001: begin k_a = -7'sd15; rlen_a = 5'd16; end
            default:                  begin k_a = -7'sd15; rlen_a = 5'd17; end
        endcase
    end

    wire [30:0] arm_a  = mag_a << rlen_a;
    wire [1:0]  exp_a  = arm_a[30:29];
    wire [28:0] frac_a = arm_a[28:0];
    wire signed [8:0] scale_a = ($signed({k_a, 2'b00}) + {7'b0, exp_a});
    wire [29:0] sig_a  = {1'b1, frac_a};

    // ----------------------------------------------------------------
    // Decode B
    wire        sign_b = b[31];
    wire [30:0] mag_b  = sign_b ? (~b[30:0] + 31'd1) : b[30:0];
    wire        rbit_b = mag_b[30];

    reg [4:0] rlen_b;
    reg signed [6:0] k_b;

    always @(*) begin
        casez ({rbit_b, mag_b[29:15]})
            16'b1_0??_????_????_????: begin k_b =  7'sd0;  rlen_b = 5'd2;  end
            16'b1_10?_????_????_????: begin k_b =  7'sd1;  rlen_b = 5'd3;  end
            16'b1_110_????_????_????: begin k_b =  7'sd2;  rlen_b = 5'd4;  end
            16'b1_111_0???_????_????: begin k_b =  7'sd3;  rlen_b = 5'd5;  end
            16'b1_111_10??_????_????: begin k_b =  7'sd4;  rlen_b = 5'd6;  end
            16'b1_111_110?_????_????: begin k_b =  7'sd5;  rlen_b = 5'd7;  end
            16'b1_111_1110_????_????: begin k_b =  7'sd6;  rlen_b = 5'd8;  end
            16'b1_111_1111_0???_????: begin k_b =  7'sd7;  rlen_b = 5'd9;  end
            16'b1_111_1111_10??_????: begin k_b =  7'sd8;  rlen_b = 5'd10; end
            16'b1_111_1111_110?_????: begin k_b =  7'sd9;  rlen_b = 5'd11; end
            16'b1_111_1111_1110_????: begin k_b =  7'sd10; rlen_b = 5'd12; end
            16'b1_111_1111_1111_0???: begin k_b =  7'sd11; rlen_b = 5'd13; end
            16'b1_111_1111_1111_10??: begin k_b =  7'sd12; rlen_b = 5'd14; end
            16'b1_111_1111_1111_110?: begin k_b =  7'sd13; rlen_b = 5'd15; end
            16'b1_111_1111_1111_1110: begin k_b =  7'sd14; rlen_b = 5'd16; end
            16'b1_111_1111_1111_1111: begin k_b =  7'sd15; rlen_b = 5'd17; end
            16'b0_1??_????_????_????: begin k_b = -7'sd1;  rlen_b = 5'd2;  end
            16'b0_01?_????_????_????: begin k_b = -7'sd2;  rlen_b = 5'd3;  end
            16'b0_001_????_????_????: begin k_b = -7'sd3;  rlen_b = 5'd4;  end
            16'b0_000_1???_????_????: begin k_b = -7'sd4;  rlen_b = 5'd5;  end
            16'b0_000_01??_????_????: begin k_b = -7'sd5;  rlen_b = 5'd6;  end
            16'b0_000_001?_????_????: begin k_b = -7'sd6;  rlen_b = 5'd7;  end
            16'b0_000_0001_????_????: begin k_b = -7'sd7;  rlen_b = 5'd8;  end
            16'b0_000_0000_1???_????: begin k_b = -7'sd8;  rlen_b = 5'd9;  end
            16'b0_000_0000_01??_????: begin k_b = -7'sd9;  rlen_b = 5'd10; end
            16'b0_000_0000_001?_????: begin k_b = -7'sd10; rlen_b = 5'd11; end
            16'b0_000_0000_0001_????: begin k_b = -7'sd11; rlen_b = 5'd12; end
            16'b0_000_0000_0000_1???: begin k_b = -7'sd12; rlen_b = 5'd13; end
            16'b0_000_0000_0000_01??: begin k_b = -7'sd13; rlen_b = 5'd14; end
            16'b0_000_0000_0000_001?: begin k_b = -7'sd14; rlen_b = 5'd15; end
            16'b0_000_0000_0000_0001: begin k_b = -7'sd15; rlen_b = 5'd16; end
            default:                  begin k_b = -7'sd15; rlen_b = 5'd17; end
        endcase
    end

    wire [30:0] arm_b  = mag_b << rlen_b;
    wire [1:0]  exp_b  = arm_b[30:29];
    wire [28:0] frac_b = arm_b[28:0];
    wire signed [8:0] scale_b = ($signed({k_b, 2'b00}) + {7'b0, exp_b});
    wire [29:0] sig_b  = {1'b1, frac_b};

    // ----------------------------------------------------------------
    // 30x30 shift-add (R-SI-1: no standalone *)
    // 30 partial products, each 60-bit, accumulated
    wire [59:0] partial [0:29];

    genvar gi;
    generate
        for (gi = 0; gi < 30; gi = gi + 1) begin : pp_gen
            assign partial[gi] = sig_b[gi] ? ({30'b0, sig_a} << gi) : 60'b0;
        end
    endgenerate

    reg [59:0] sig_prod;
    integer pi;
    always @(*) begin
        sig_prod = 60'b0;
        for (pi = 0; pi < 30; pi = pi + 1)
            sig_prod = sig_prod + partial[pi];
    end

    // ----------------------------------------------------------------
    // Normalize
    wire signed [9:0] scale_sum = $signed(scale_a) + $signed(scale_b);

    // sig_prod: 30-bit * 30-bit unsigned → 60-bit
    // Both inputs have implicit leading 1, so product range: [1.0, ~4.0)
    // Leading 1 at bit 58 (= 1.0*1.0) or bit 59 (= ~2.0*~2.0)
    wire norm = sig_prod[59]; // if 1, product >= 2.0, shift right
    wire [59:0] sig_norm = norm ? sig_prod : (sig_prod << 1);
    wire signed [9:0] scale_norm = norm ? (scale_sum + 10'sd1) : scale_sum;

    // k_out = scale_norm / 4 (arithmetic), exp_out = scale_norm mod 4
    wire signed [7:0] k_out  = scale_norm[9:2]; // arithmetic /4
    wire [1:0]        exp_out = scale_norm[1:0];

    // Top 29 mantissa bits
    wire [28:0] mant_out = sig_norm[58:30];

    // ----------------------------------------------------------------
    wire sign_out = sign_a ^ sign_b;

    wire [31:0] enc_out;
    posit32_encode enc_inst (
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
