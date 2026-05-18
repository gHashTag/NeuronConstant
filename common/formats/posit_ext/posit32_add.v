// posit32_add.v — Posit<32,2> addition
//
// Algorithm:
//   1. Decode both posits to (sign, scale, significand)
//      scale = 4*k + exp  (ES=2, useed=16)
//   2. Convert to Q32.30 signed fixed-point (62 bits + sign = 63 bits)
//   3. Add fixed-point values
//   4. Normalize: find leading 1, compute output scale
//   5. Encode to Posit<32,2>
//
// Verilog-2005, `default_nettype none, R-SI-1 compliant
`default_nettype none

module posit32_add (
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

    wire [30:0] arm_a   = mag_a << rlen_a;
    wire [1:0]  exp_a   = arm_a[30:29];
    wire [28:0] frac_a  = arm_a[28:0];
    // scale_a = 4*k + exp
    wire signed [8:0] scale_a = ($signed({k_a, 2'b00}) + {7'b0, exp_a});
    wire [29:0] sig_a  = {1'b1, frac_a};

    // Fixed-point: place sig_a into 60-bit field at bit position 30 (= 2^0)
    // sig_a has implicit leading 1 at bit 29 (= 2^0 of significand)
    // To put sig_a[29]=2^0 at bit 30 of the 60-bit field:
    //   shift = scale_a + 1  (bit 30 + scale_a represents 2^scale_a)
    // For 1.0: scale=0, shift=1 → sig_a<<1 puts bit29 at bit30 ✓
    wire signed [8:0] shift_a = scale_a + 9'sd1;
    wire [8:0] rshift_a = shift_a[8] ? (~shift_a + 9'd1) : 9'd0;

    reg [59:0] fixed_a_mag;
    always @(*) begin
        if (shift_a >= 9'sd58)       fixed_a_mag = 60'hFFFFFFFFFFFFFFF;
        else if (shift_a >= 9'sd0)   fixed_a_mag = {30'b0, sig_a} << shift_a[5:0];
        else if (shift_a >= -9'sd29) fixed_a_mag = {30'b0, sig_a} >> rshift_a[5:0];
        else                          fixed_a_mag = 60'b0;
    end

    wire signed [60:0] fixed_a = sign_a ? (~{1'b0, fixed_a_mag} + 61'b1) : {1'b0, fixed_a_mag};

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

    wire [30:0] arm_b   = mag_b << rlen_b;
    wire [1:0]  exp_b   = arm_b[30:29];
    wire [28:0] frac_b  = arm_b[28:0];
    wire signed [8:0] scale_b = ($signed({k_b, 2'b00}) + {7'b0, exp_b});
    wire [29:0] sig_b  = {1'b1, frac_b};
    wire signed [8:0] shift_b = scale_b + 9'sd1;
    wire [8:0] rshift_b = shift_b[8] ? (~shift_b + 9'd1) : 9'd0;

    reg [59:0] fixed_b_mag;
    always @(*) begin
        if (shift_b >= 9'sd58)       fixed_b_mag = 60'hFFFFFFFFFFFFFFF;
        else if (shift_b >= 9'sd0)   fixed_b_mag = {30'b0, sig_b} << shift_b[5:0];
        else if (shift_b >= -9'sd29) fixed_b_mag = {30'b0, sig_b} >> rshift_b[5:0];
        else                          fixed_b_mag = 60'b0;
    end

    wire signed [60:0] fixed_b = sign_b ? (~{1'b0, fixed_b_mag} + 61'b1) : {1'b0, fixed_b_mag};

    // ----------------------------------------------------------------
    // Add
    wire signed [60:0] sum_fixed = fixed_a + fixed_b;
    wire        sum_sign = sum_fixed[60];
    wire [59:0] sum_mag  = sum_sign ? (~sum_fixed[59:0] + 60'd1) : sum_fixed[59:0];

    // ----------------------------------------------------------------
    // Find leading-1 in sum_mag[59:0]
    reg [5:0] lead_pos;
    always @(*) begin
        casez (sum_mag[59:30])
            30'b1???_????_????_????_????_????_????_??: lead_pos = 6'd59;
            30'b01??_????_????_????_????_????_????_??: lead_pos = 6'd58;
            30'b001?_????_????_????_????_????_????_??: lead_pos = 6'd57;
            30'b0001_????_????_????_????_????_????_??: lead_pos = 6'd56;
            30'b0000_1???_????_????_????_????_????_??: lead_pos = 6'd55;
            30'b0000_01??_????_????_????_????_????_??: lead_pos = 6'd54;
            30'b0000_001?_????_????_????_????_????_??: lead_pos = 6'd53;
            30'b0000_0001_????_????_????_????_????_??: lead_pos = 6'd52;
            30'b0000_0000_1???_????_????_????_????_??: lead_pos = 6'd51;
            30'b0000_0000_01??_????_????_????_????_??: lead_pos = 6'd50;
            30'b0000_0000_001?_????_????_????_????_??: lead_pos = 6'd49;
            30'b0000_0000_0001_????_????_????_????_??: lead_pos = 6'd48;
            30'b0000_0000_0000_1???_????_????_????_??: lead_pos = 6'd47;
            30'b0000_0000_0000_01??_????_????_????_??: lead_pos = 6'd46;
            30'b0000_0000_0000_001?_????_????_????_??: lead_pos = 6'd45;
            30'b0000_0000_0000_0001_????_????_????_??: lead_pos = 6'd44;
            30'b0000_0000_0000_0000_1???_????_????_??: lead_pos = 6'd43;
            30'b0000_0000_0000_0000_01??_????_????_??: lead_pos = 6'd42;
            30'b0000_0000_0000_0000_001?_????_????_??: lead_pos = 6'd41;
            30'b0000_0000_0000_0000_0001_????_????_??: lead_pos = 6'd40;
            30'b0000_0000_0000_0000_0000_1???_????_??: lead_pos = 6'd39;
            30'b0000_0000_0000_0000_0000_01??_????_??: lead_pos = 6'd38;
            30'b0000_0000_0000_0000_0000_001?_????_??: lead_pos = 6'd37;
            30'b0000_0000_0000_0000_0000_0001_????_??: lead_pos = 6'd36;
            30'b0000_0000_0000_0000_0000_0000_1???_??: lead_pos = 6'd35;
            30'b0000_0000_0000_0000_0000_0000_01??_??: lead_pos = 6'd34;
            30'b0000_0000_0000_0000_0000_0000_001?_??: lead_pos = 6'd33;
            30'b0000_0000_0000_0000_0000_0000_0001_??: lead_pos = 6'd32;
            30'b0000_0000_0000_0000_0000_0000_0000_1?: lead_pos = 6'd31;
            30'b0000_0000_0000_0000_0000_0000_0000_01: lead_pos = 6'd30;
            default: lead_pos = 6'd30;
        endcase
    end

    // scale_out = lead_pos - 30 (since bit 30 = 2^0 in our Q.30 representation)
    wire signed [7:0] scale_out = {2'b00, lead_pos} - 8'sd30;

    // k_out = scale_out / 4, exp_out = scale_out % 4
    // Arithmetic: for positive scale: k=scale>>2, exp=scale&3
    // For negative scale: need proper floor division
    // Use: k = scale_out >>> 2 (arithmetic), exp = scale_out - 4*k
    wire signed [5:0] k_out  = scale_out[7:2];   // arithmetic right shift /4
    wire [1:0]        exp_out = scale_out[1:0];

    // Mantissa: 29 bits below leading 1
    reg [28:0] mant_out;
    always @(*) begin
        if (lead_pos >= 6'd29)
            mant_out = sum_mag[lead_pos-1 -: 29];
        else
            mant_out = {sum_mag[28:0], {1{1'b0}}} >> (6'd30 - lead_pos);
    end

    // Encode
    wire [31:0] enc_out;
    posit32_encode enc_inst (
        .is_zero (sum_mag == 60'b0),
        .is_nar  (1'b0),
        .sign    (sum_sign),
        .k_in    ({{1{k_out[5]}}, k_out}),
        .exp_in  (exp_out),
        .mant_in (mant_out),
        .p_out   (enc_out)
    );

    always @(*) begin
        nar_out = (a == NAR) || (b == NAR);
        if (nar_out)
            result = NAR;
        else if (a == ZERO)
            result = b;
        else if (b == ZERO)
            result = a;
        else if (sum_mag == 60'b0)
            result = ZERO;
        else
            result = enc_out;
    end

endmodule
`default_nettype wire
