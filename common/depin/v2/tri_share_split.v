// SPDX-License-Identifier: Apache-2.0
//
// tri_share_split.v — Cross-chip token reward divider
//
// Part of the NeuronConstant DePIN v2 hardware stack.
// DOI: 10.5281/zenodo.19227877
//
// Copyright 2024 gHashTag / Dmitrii Vasilev
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// R-SI-1: zero standalone `*` operators — case-based lookup only.
// Verilog-2005 compliant.
//
// Inputs:  total_reward[5:0], share_phi[1:0], share_eul[1:0], share_gam[1:0]
//          shares must sum to 3 (e.g. 1+1+1 or 0+1+2)
// Outputs: phi_get, eul_get, gam_get = floor(total_reward * share / 3)
//
// Lookup table for floor(total * share / 3):
//   share=0: 0
//   share=1: floor(total/3)  -- case on total
//   share=2: floor(2*total/3) = total - floor(total/3) -- derived
//   share=3: total            (only possible if other two are 0)

`timescale 1ns/1ps
`default_nettype none

module tri_share_split (
    input  wire [5:0] total_reward,
    input  wire [1:0] share_phi,
    input  wire [1:0] share_eul,
    input  wire [1:0] share_gam,
    output reg  [5:0] phi_get,
    output reg  [5:0] eul_get,
    output reg  [5:0] gam_get
);

    // Function: floor(total / 3) via case lookup (total is 6-bit, 0..63)
    function [5:0] div3;
        input [5:0] t;
        begin
            case (t)
                6'd0:  div3 = 6'd0;
                6'd1:  div3 = 6'd0;
                6'd2:  div3 = 6'd0;
                6'd3:  div3 = 6'd1;
                6'd4:  div3 = 6'd1;
                6'd5:  div3 = 6'd1;
                6'd6:  div3 = 6'd2;
                6'd7:  div3 = 6'd2;
                6'd8:  div3 = 6'd2;
                6'd9:  div3 = 6'd3;
                6'd10: div3 = 6'd3;
                6'd11: div3 = 6'd3;
                6'd12: div3 = 6'd4;
                6'd13: div3 = 6'd4;
                6'd14: div3 = 6'd4;
                6'd15: div3 = 6'd5;
                6'd16: div3 = 6'd5;
                6'd17: div3 = 6'd5;
                6'd18: div3 = 6'd6;
                6'd19: div3 = 6'd6;
                6'd20: div3 = 6'd6;
                6'd21: div3 = 6'd7;
                6'd22: div3 = 6'd7;
                6'd23: div3 = 6'd7;
                6'd24: div3 = 6'd8;
                6'd25: div3 = 6'd8;
                6'd26: div3 = 6'd8;
                6'd27: div3 = 6'd9;
                6'd28: div3 = 6'd9;
                6'd29: div3 = 6'd9;
                6'd30: div3 = 6'd10;
                6'd31: div3 = 6'd10;
                6'd32: div3 = 6'd10;
                6'd33: div3 = 6'd11;
                6'd34: div3 = 6'd11;
                6'd35: div3 = 6'd11;
                6'd36: div3 = 6'd12;
                6'd37: div3 = 6'd12;
                6'd38: div3 = 6'd12;
                6'd39: div3 = 6'd13;
                6'd40: div3 = 6'd13;
                6'd41: div3 = 6'd13;
                6'd42: div3 = 6'd14;
                6'd43: div3 = 6'd14;
                6'd44: div3 = 6'd14;
                6'd45: div3 = 6'd15;
                6'd46: div3 = 6'd15;
                6'd47: div3 = 6'd15;
                6'd48: div3 = 6'd16;
                6'd49: div3 = 6'd16;
                6'd50: div3 = 6'd16;
                6'd51: div3 = 6'd17;
                6'd52: div3 = 6'd17;
                6'd53: div3 = 6'd17;
                6'd54: div3 = 6'd18;
                6'd55: div3 = 6'd18;
                6'd56: div3 = 6'd18;
                6'd57: div3 = 6'd19;
                6'd58: div3 = 6'd19;
                6'd59: div3 = 6'd19;
                6'd60: div3 = 6'd20;
                6'd61: div3 = 6'd20;
                6'd62: div3 = 6'd20;
                6'd63: div3 = 6'd21;
                default: div3 = 6'd0;
            endcase
        end
    endfunction

    // Compute floor(total * share / 3) using case on share
    // share can be 0, 1, 2, or 3
    //   share=0: 0
    //   share=1: floor(total/3)
    //   share=2: total - floor(total/3)  [= floor(2*total/3)]
    //   share=3: total
    function [5:0] reward_for_share;
        input [5:0] total;
        input [1:0] share;
        reg   [5:0] third;
        begin
            third = div3(total);
            case (share)
                2'd0: reward_for_share = 6'd0;
                2'd1: reward_for_share = third;
                2'd2: reward_for_share = total - third;
                2'd3: reward_for_share = total;
                default: reward_for_share = 6'd0;
            endcase
        end
    endfunction

    always @(*) begin
        phi_get = reward_for_share(total_reward, share_phi);
        eul_get = reward_for_share(total_reward, share_eul);
        gam_get = reward_for_share(total_reward, share_gam);
    end

endmodule

`default_nettype wire
