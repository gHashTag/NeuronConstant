// SPDX-License-Identifier: Apache-2.0
//
// tri_token_accumulator.v — On-chip $TRI hardware token accumulator
//
// Part of the NeuronConstant canonical hardware catalog.
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
// R-SI-1: zero standalone `*` operators — shift-and-add only.
// Verilog-2005 compliant.

`timescale 1ns/1ps
`default_nettype none

module tri_token_accumulator #(
    parameter WIDTH       = 16,   // 64K tokens max per session
    parameter REWARD_BITS = 2     // 1-4 tokens per attest pulse (config)
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   attest_pulse,    // 1-cycle pulse: valid job done
    input  wire [REWARD_BITS-1:0] reward_amount,   // tokens per attest (cfg)
    output reg  [WIDTH-1:0]       token_balance,
    output wire                   overflow_flag    // saturates at MAX
);

    // overflow_flag: all bits set = saturated (65535 for WIDTH=16)
    assign overflow_flag = &token_balance;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_balance <= {WIDTH{1'b0}};
        end else if (attest_pulse && !overflow_flag) begin
            token_balance <= token_balance + {{(WIDTH-REWARD_BITS){1'b0}}, reward_amount};
        end
    end

endmodule

`default_nettype wire
