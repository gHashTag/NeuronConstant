// SPDX-License-Identifier: Apache-2.0
//
// tri_energy_weight.v — Energy-weighted reward multiplier
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
// R-SI-1: zero standalone `*` operators — shift-by-literal only.
// Verilog-2005 compliant.
//
// weighted_reward = base_reward         when idle_state
//                 = base_reward << 1    when active_state
//                 = base_reward << 2    when fbb_active
// Priority: fbb_active > active_state > idle_state.
// clk/rst_n present for interface consistency; output is combinational.

`timescale 1ns/1ps
`default_nettype none

module tri_energy_weight (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] base_reward,
    input  wire       active_state,
    input  wire       idle_state,
    input  wire       fbb_active,
    output reg  [5:0] weighted_reward
);

    // Suppress unused input warnings (clk/rst_n for interface completeness)
    // synthesis translate_off
    wire _unused = clk & rst_n;
    // synthesis translate_on

    always @(*) begin
        if (fbb_active)
            weighted_reward = {base_reward, 2'b00};   // << 2, zero-extend to 6 bits
        else if (active_state)
            weighted_reward = {1'b0, base_reward, 1'b0}; // << 1, zero-extend to 6 bits
        else
            weighted_reward = {2'b00, base_reward};   // << 0, zero-extend to 6 bits
    end

endmodule

`default_nettype wire
