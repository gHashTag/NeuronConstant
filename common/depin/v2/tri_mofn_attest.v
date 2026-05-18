// SPDX-License-Identifier: Apache-2.0
//
// tri_mofn_attest.v — 2-of-3 threshold consensus attestation
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
// R-SI-1: zero standalone `*` operators.
// Verilog-2005 compliant.
//
// 16-cycle sliding window per attestor. consensus_ok asserts for 1 cycle
// when >=2 of 3 attestation signals have been seen within the current
// 16-cycle window for the same job_id.

`timescale 1ns/1ps
`default_nettype none

module tri_mofn_attest (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       attest_phi,
    input  wire       attest_eul,
    input  wire       attest_gam,
    input  wire [7:0] job_id,
    output reg        consensus_ok,
    output reg  [2:0] winning_set
);

    // 16-cycle shift registers, one per attestor
    reg [15:0] win_phi;
    reg [15:0] win_eul;
    reg [15:0] win_gam;

    // Job ID latched when first attest arrives in window
    reg [7:0]  window_job_id;
    reg        window_active;

    // OR-reduce: has attestor been seen in current window?
    wire phi_seen = |win_phi;
    wire eul_seen = |win_eul;
    wire gam_seen = |win_gam;

    // Count how many attestors seen
    wire [1:0] attest_count = {1'b0, phi_seen} + {1'b0, eul_seen} + {1'b0, gam_seen};

    // prev cycle consensus to edge-detect and emit 1-cycle pulse
    reg  prev_consensus;
    wire cur_consensus;

    assign cur_consensus = (attest_count >= 2'd2) && window_active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            win_phi      <= 16'h0;
            win_eul      <= 16'h0;
            win_gam      <= 16'h0;
            window_job_id <= 8'h0;
            window_active <= 1'b0;
            consensus_ok  <= 1'b0;
            winning_set   <= 3'b0;
            prev_consensus <= 1'b0;
        end else begin
            // Shift windows (age out old attestations)
            win_phi <= {win_phi[14:0], attest_phi};
            win_eul <= {win_eul[14:0], attest_eul};
            win_gam <= {win_gam[14:0], attest_gam};

            // Track active window job_id: latch on first attest
            if (attest_phi || attest_eul || attest_gam) begin
                if (!window_active) begin
                    window_job_id <= job_id;
                    window_active <= 1'b1;
                end else begin
                    // If job_id changes, reset window
                    if (job_id != window_job_id) begin
                        win_phi       <= {15'h0, attest_phi};
                        win_eul       <= {15'h0, attest_eul};
                        win_gam       <= {15'h0, attest_gam};
                        window_job_id <= job_id;
                    end
                end
            end else begin
                // No attest this cycle; if window empty, deactivate
                if (!(|win_phi) && !(|win_eul) && !(|win_gam)) begin
                    window_active <= 1'b0;
                end
            end

            // consensus_ok: rising edge of cur_consensus (1-cycle pulse)
            if (cur_consensus && !prev_consensus) begin
                consensus_ok <= 1'b1;
                winning_set  <= {gam_seen, eul_seen, phi_seen};
            end else begin
                consensus_ok <= 1'b0;
                winning_set  <= 3'b0;
            end
            prev_consensus <= cur_consensus;
        end
    end

endmodule

`default_nettype wire
