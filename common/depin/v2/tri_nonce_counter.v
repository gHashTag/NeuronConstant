// SPDX-License-Identifier: Apache-2.0
//
// tri_nonce_counter.v — Monotonic replay-protection nonce counter
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
// Counts up on advance pulse. Wraps at 0xFFFF asserting wrap_flag for 1 cycle.

`timescale 1ns/1ps
`default_nettype none

module tri_nonce_counter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        advance,
    output reg  [15:0] nonce,
    output reg         wrap_flag
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nonce     <= 16'h0000;
            wrap_flag <= 1'b0;
        end else begin
            wrap_flag <= 1'b0;
            if (advance) begin
                if (nonce == 16'hFFFF) begin
                    nonce     <= 16'h0000;
                    wrap_flag <= 1'b1;
                end else begin
                    nonce <= nonce + 16'h0001;
                end
            end
        end
    end

endmodule

`default_nettype wire
