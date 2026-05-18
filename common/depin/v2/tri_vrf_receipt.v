// SPDX-License-Identifier: Apache-2.0
//
// tri_vrf_receipt.v — VRF-style chained receipt hash
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
// R-SI-1: zero standalone `*` operators — XOR/shift only.
// Verilog-2005 compliant.
//
// Davies-Meyer style hash:
//   receipt_hash = prev_receipt_hash XOR (job_id<<24) XOR (result_hash<<8) XOR nonce
// valid pulses for 1 cycle on commit.

`timescale 1ns/1ps
`default_nettype none

module tri_vrf_receipt (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  job_id,
    input  wire [31:0] result_hash,
    input  wire [31:0] prev_receipt_hash,
    input  wire [15:0] nonce,
    input  wire        commit,
    output reg  [31:0] receipt_hash,
    output reg         valid
);

    wire [31:0] job_id_shifted;
    wire [31:0] result_shifted;
    wire [31:0] nonce_extended;
    wire [31:0] combined;

    // shift job_id[7:0] to bits [31:24]
    assign job_id_shifted = {job_id, 24'h000000};
    // shift result_hash left by 8: drop top 8 bits, shift up
    assign result_shifted = {result_hash[23:0], 8'h00};
    // zero-extend nonce to 32 bits
    assign nonce_extended = {16'h0000, nonce};

    // Davies-Meyer combination
    assign combined = prev_receipt_hash
                    ^ job_id_shifted
                    ^ result_shifted
                    ^ nonce_extended;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            receipt_hash <= 32'h0;
            valid        <= 1'b0;
        end else begin
            valid <= 1'b0;
            if (commit) begin
                receipt_hash <= combined;
                valid        <= 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
