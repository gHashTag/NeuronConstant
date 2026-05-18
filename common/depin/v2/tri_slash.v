// SPDX-License-Identifier: Apache-2.0
//
// tri_slash.v — Slashing penalty on invalid receipt (combinational)
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
// R-SI-1: zero standalone `*` operators — shift only.
// Verilog-2005 compliant.
//
// Combinational penalty: balance_out = balance_in - (balance_in >> 4) on
// invalid_pulse (6.25% penalty). Otherwise balance_out = balance_in.
// clk/rst_n present for interface consistency; logic is purely combinational.

`timescale 1ns/1ps
`default_nettype none

module tri_slash (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] balance_in,
    input  wire        invalid_pulse,
    output wire [15:0] balance_out
);

    // penalty = balance_in >> 4  (6.25%)
    wire [15:0] penalty;
    assign penalty = {4'h0, balance_in[15:4]};

    // Combinational: apply slash when invalid_pulse asserted
    assign balance_out = invalid_pulse ? (balance_in - penalty) : balance_in;

    // Suppress unused input warnings (clk/rst_n for interface completeness)
    // synthesis translate_off
    wire _unused = clk & rst_n;
    // synthesis translate_on

endmodule

`default_nettype wire
