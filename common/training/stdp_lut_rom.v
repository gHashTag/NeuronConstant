// stdp_lut_rom.v — 64-entry signed 8-bit STDP LUT ROM
// LUT[0..31]  = A_plus(dt)  = round(127 * exp(-dt/20)), dt=1..32  (LTP, positive)
// LUT[32..63] = A_minus(dt) = -round(120 * exp(-dt/20)), dt=1..32 (LTD, negative)
// Generated values: tau_plus=20, tau_minus=20
// R-SI-1 CLEAN: no standalone multiplications in RTL
// Verilog-2005
`default_nettype none

module stdp_lut_rom #(
    parameter LUT_DEPTH = 64
) (
    input  wire        clk,
    input  wire [5:0]  addr,
    input  wire [7:0]  wdata,
    input  wire        we,
    output reg  [7:0]  rdata
);

    // RAM backing (programmable LUT for runtime override)
    reg [7:0] mem [0:LUT_DEPTH-1];

    // Initialise with exponential STDP function
    // (Python: A_plus[i] = round(127*exp(-(i+1)/20)), A_minus[i] = -round(120*exp(-(i+1)/20)))
    integer i;
    initial begin
        // A_plus entries (indices 0..31), dt=1..32
        mem[ 0] = 8'h79; // dt= 1:  121
        mem[ 1] = 8'h73; // dt= 2:  115
        mem[ 2] = 8'h6D; // dt= 3:  109
        mem[ 3] = 8'h68; // dt= 4:  104
        mem[ 4] = 8'h63; // dt= 5:   99
        mem[ 5] = 8'h5E; // dt= 6:   94
        mem[ 6] = 8'h59; // dt= 7:   89
        mem[ 7] = 8'h55; // dt= 8:   85
        mem[ 8] = 8'h51; // dt= 9:   81
        mem[ 9] = 8'h4D; // dt=10:   77
        mem[10] = 8'h49; // dt=11:   73
        mem[11] = 8'h46; // dt=12:   70
        mem[12] = 8'h42; // dt=13:   66
        mem[13] = 8'h3F; // dt=14:   63
        mem[14] = 8'h3C; // dt=15:   60
        mem[15] = 8'h39; // dt=16:   57
        mem[16] = 8'h36; // dt=17:   54
        mem[17] = 8'h34; // dt=18:   52
        mem[18] = 8'h31; // dt=19:   49
        mem[19] = 8'h2F; // dt=20:   47
        mem[20] = 8'h2C; // dt=21:   44
        mem[21] = 8'h2A; // dt=22:   42
        mem[22] = 8'h28; // dt=23:   40
        mem[23] = 8'h26; // dt=24:   38
        mem[24] = 8'h24; // dt=25:   36
        mem[25] = 8'h23; // dt=26:   35
        mem[26] = 8'h21; // dt=27:   33
        mem[27] = 8'h1F; // dt=28:   31
        mem[28] = 8'h1E; // dt=29:   30
        mem[29] = 8'h1C; // dt=30:   28
        mem[30] = 8'h1B; // dt=31:   27
        mem[31] = 8'h1A; // dt=32:   26
        // A_minus entries (indices 32..63), dt=1..32
        mem[32] = 8'h8E; // dt= 1: -114
        mem[33] = 8'h93; // dt= 2: -109
        mem[34] = 8'h99; // dt= 3: -103
        mem[35] = 8'h9E; // dt= 4:  -98
        mem[36] = 8'hA3; // dt= 5:  -93
        mem[37] = 8'hA7; // dt= 6:  -89
        mem[38] = 8'hAB; // dt= 7:  -85
        mem[39] = 8'hB0; // dt= 8:  -80
        mem[40] = 8'hB3; // dt= 9:  -77
        mem[41] = 8'hB7; // dt=10:  -73
        mem[42] = 8'hBB; // dt=11:  -69
        mem[43] = 8'hBE; // dt=12:  -66
        mem[44] = 8'hC1; // dt=13:  -63
        mem[45] = 8'hC4; // dt=14:  -60
        mem[46] = 8'hC7; // dt=15:  -57
        mem[47] = 8'hCA; // dt=16:  -54
        mem[48] = 8'hCD; // dt=17:  -51
        mem[49] = 8'hCF; // dt=18:  -49
        mem[50] = 8'hD2; // dt=19:  -46
        mem[51] = 8'hD4; // dt=20:  -44
        mem[52] = 8'hD6; // dt=21:  -42
        mem[53] = 8'hD8; // dt=22:  -40
        mem[54] = 8'hDA; // dt=23:  -38
        mem[55] = 8'hDC; // dt=24:  -36
        mem[56] = 8'hDE; // dt=25:  -34
        mem[57] = 8'hDF; // dt=26:  -33
        mem[58] = 8'hE1; // dt=27:  -31
        mem[59] = 8'hE2; // dt=28:  -30
        mem[60] = 8'hE4; // dt=29:  -28
        mem[61] = 8'hE5; // dt=30:  -27
        mem[62] = 8'hE7; // dt=31:  -25
        mem[63] = 8'hE8; // dt=32:  -24
    end

    // Synchronous write (SPI-style programmable LUT)
    always @(posedge clk) begin
        if (we)
            mem[addr] <= wdata;
    end

    // Asynchronous read
    always @(*) begin
        rdata = mem[addr];
    end

endmodule
`default_nettype wire
