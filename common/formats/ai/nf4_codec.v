// nf4_codec.v — NormalFloat 4-bit (NF4) encode / decode
// Canonical QLoRA quantization format (Tim Dettmers et al.)
// Non-uniform 16-entry LUT sampling the normal distribution in [-1, 1].
//
// LUT values (x127, int8):
//   index  0: -127  (-1.0000)
//   index  1:  -88  (-0.6962)
//   index  2:  -67  (-0.5251)
//   index  3:  -50  (-0.3946)
//   index  4:  -36  (-0.2844)
//   index  5:  -23  (-0.1846)
//   index  6:  -12  (-0.0911)
//   index  7:    0  ( 0.0000)
//   index  8:   10  ( 0.0796)
//   index  9:   20  ( 0.1609)
//   index 10:   31  ( 0.2461)
//   index 11:   43  ( 0.3379)
//   index 12:   56  ( 0.4407)
//   index 13:   71  ( 0.5626)
//   index 14:   92  ( 0.7230)
//   index 15:  127  ( 1.0000)
//
// Verilog-2005, R-SI-1 compliant (no standalone *)
`default_nettype none

module nf4_codec (
    // --- Decode path ---
    input  wire [3:0]  dec_idx,    // 4-bit NF4 index
    output reg  [7:0]  dec_val,    // signed int8 decoded value (2's complement)

    // --- Encode path ---
    // Simplified: input is an 8-bit signed value; find nearest LUT entry.
    // Nearest-index search via combinational comparisons.
    input  wire [7:0]  enc_in,     // signed int8 input (range −127..127)
    output reg  [3:0]  enc_idx     // 4-bit NF4 index
);

    // ----------------------------------------------------------------
    // Decode: index → int8 value
    // ----------------------------------------------------------------
    always @(*) begin
        case (dec_idx)
            4'd0:  dec_val = 8'sh81; // -127
            4'd1:  dec_val = 8'shA8; // -88
            4'd2:  dec_val = 8'shBD; // -67
            4'd3:  dec_val = 8'shCE; // -50
            4'd4:  dec_val = 8'shDC; // -36
            4'd5:  dec_val = 8'shE9; // -23
            4'd6:  dec_val = 8'shF4; // -12
            4'd7:  dec_val = 8'sh00; //   0
            4'd8:  dec_val = 8'sh0A; //  10
            4'd9:  dec_val = 8'sh14; //  20
            4'd10: dec_val = 8'sh1F; //  31
            4'd11: dec_val = 8'sh2B; //  43
            4'd12: dec_val = 8'sh38; //  56
            4'd13: dec_val = 8'sh47; //  71
            4'd14: dec_val = 8'sh5C; //  92
            4'd15: dec_val = 8'sh7F; // 127
            default: dec_val = 8'sh00;
        endcase
    end

    // ----------------------------------------------------------------
    // Encode: nearest-neighbour search (combinational)
    // LUT thresholds are midpoints between consecutive values:
    //   mid(0,1)=(-127+-88)/2=-107  mid(1,2)=(-88+-67)/2=-77
    //   mid(2,3)=-58  mid(3,4)=-43  mid(4,5)=-29  mid(5,6)=-17
    //   mid(6,7)=-6   mid(7,8)=5    mid(8,9)=15   mid(9,10)=25
    //   mid(10,11)=37 mid(11,12)=49 mid(12,13)=63 mid(13,14)=81
    //   mid(14,15)=109
    // ----------------------------------------------------------------
    wire signed [7:0] sv = $signed(enc_in);

    always @(*) begin
        if      (sv <= -8'sd107) enc_idx = 4'd0;
        else if (sv <= -8'sd77)  enc_idx = 4'd1;
        else if (sv <= -8'sd58)  enc_idx = 4'd2;
        else if (sv <= -8'sd43)  enc_idx = 4'd3;
        else if (sv <= -8'sd29)  enc_idx = 4'd4;
        else if (sv <= -8'sd17)  enc_idx = 4'd5;
        else if (sv <= -8'sd6)   enc_idx = 4'd6;
        else if (sv <=  8'sd5)   enc_idx = 4'd7;
        else if (sv <=  8'sd15)  enc_idx = 4'd8;
        else if (sv <=  8'sd25)  enc_idx = 4'd9;
        else if (sv <=  8'sd37)  enc_idx = 4'd10;
        else if (sv <=  8'sd49)  enc_idx = 4'd11;
        else if (sv <=  8'sd63)  enc_idx = 4'd12;
        else if (sv <=  8'sd81)  enc_idx = 4'd13;
        else if (sv <=  8'sd109) enc_idx = 4'd14;
        else                     enc_idx = 4'd15;
    end

endmodule
`default_nettype wire
