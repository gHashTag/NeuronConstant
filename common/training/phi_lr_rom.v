// SPDX-License-Identifier: MIT
// phi_lr_rom.v — φ-LR schedule ROM
//
// 54-entry pre-computed φ-LR schedule matching trios_phi_schedule::lr_schedule_54.
// Layout: 27 warmup steps (linear ramp), 27 decay steps (φ^(-n/27) decay).
// Base LR = alpha_phi = 1/phi^3 ≈ 0.2361
//
// Input:  step_idx [5:0]  (0..53)
// Output: lr_val  [15:0] GF16
//
// R-SI-1 clean: no standalone * operators (ROM only).
// Verilog-2005, `default_nettype none.

`default_nettype none

module phi_lr_rom (
    input  wire [5:0]  step_idx,
    output reg  [15:0] lr_val
);

    always @(*) begin
        case (step_idx)
            6'd0:  lr_val = 16'h303D;  // lr=0.008743
            6'd1:  lr_val = 16'h323D;  // lr=0.017487
            6'd2:  lr_val = 16'h335B;  // lr=0.026230
            6'd3:  lr_val = 16'h343D;  // lr=0.034973
            6'd4:  lr_val = 16'h34CC;  // lr=0.043716
            6'd5:  lr_val = 16'h355B;  // lr=0.052460
            6'd6:  lr_val = 16'h35EB;  // lr=0.061203
            6'd7:  lr_val = 16'h363D;  // lr=0.069946
            6'd8:  lr_val = 16'h3685;  // lr=0.078689
            6'd9:  lr_val = 16'h36CC;  // lr=0.087433
            6'd10: lr_val = 16'h3714;  // lr=0.096176
            6'd11: lr_val = 16'h375B;  // lr=0.104919
            6'd12: lr_val = 16'h37A3;  // lr=0.113662
            6'd13: lr_val = 16'h37EB;  // lr=0.122406
            6'd14: lr_val = 16'h3819;  // lr=0.131149
            6'd15: lr_val = 16'h383D;  // lr=0.139892
            6'd16: lr_val = 16'h3861;  // lr=0.148635
            6'd17: lr_val = 16'h3885;  // lr=0.157379
            6'd18: lr_val = 16'h38A8;  // lr=0.166122
            6'd19: lr_val = 16'h38CC;  // lr=0.174865
            6'd20: lr_val = 16'h38F0;  // lr=0.183608
            6'd21: lr_val = 16'h3914;  // lr=0.192352
            6'd22: lr_val = 16'h3938;  // lr=0.201095
            6'd23: lr_val = 16'h395B;  // lr=0.209838
            6'd24: lr_val = 16'h397F;  // lr=0.218581
            6'd25: lr_val = 16'h39A3;  // lr=0.227325
            6'd26: lr_val = 16'h39C7;  // lr=0.236068 (peak = base_lr)
            6'd27: lr_val = 16'h39C7;  // lr=0.236068 (step27=peak)
            6'd28: lr_val = 16'h39B6;  // lr=0.231898
            6'd29: lr_val = 16'h39A5;  // lr=0.227801
            6'd30: lr_val = 16'h3995;  // lr=0.223777
            6'd31: lr_val = 16'h3984;  // lr=0.219824
            6'd32: lr_val = 16'h3974;  // lr=0.215941
            6'd33: lr_val = 16'h3965;  // lr=0.212127
            6'd34: lr_val = 16'h3956;  // lr=0.208380
            6'd35: lr_val = 16'h3946;  // lr=0.204699
            6'd36: lr_val = 16'h3938;  // lr=0.201083
            6'd37: lr_val = 16'h3929;  // lr=0.197531
            6'd38: lr_val = 16'h391B;  // lr=0.194041
            6'd39: lr_val = 16'h390D;  // lr=0.190614
            6'd40: lr_val = 16'h38FF;  // lr=0.187246
            6'd41: lr_val = 16'h38F1;  // lr=0.183939
            6'd42: lr_val = 16'h38E4;  // lr=0.180689
            6'd43: lr_val = 16'h38D7;  // lr=0.177498
            6'd44: lr_val = 16'h38CA;  // lr=0.174362
            6'd45: lr_val = 16'h38BE;  // lr=0.171282
            6'd46: lr_val = 16'h38B1;  // lr=0.168256
            6'd47: lr_val = 16'h38A5;  // lr=0.165284
            6'd48: lr_val = 16'h3899;  // lr=0.162365
            6'd49: lr_val = 16'h388D;  // lr=0.159496
            6'd50: lr_val = 16'h3882;  // lr=0.156679
            6'd51: lr_val = 16'h3876;  // lr=0.153911
            6'd52: lr_val = 16'h386B;  // lr=0.151192
            6'd53: lr_val = 16'h3860;  // lr=0.148522 (min)
            default: lr_val = 16'h3860; // clamp to min
        endcase
    end

endmodule

`default_nettype wire
