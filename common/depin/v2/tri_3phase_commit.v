// SPDX-License-Identifier: Apache-2.0
//
// tri_3phase_commit.v — Three-phase commit FSM (IDLE/CLAIMED/WORKING/DONE)
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
// State encoding:
//   S_IDLE    = 2'b00
//   S_CLAIMED = 2'b01
//   S_WORKING = 2'b10
//   S_DONE    = 2'b11
//
// Transitions:
//   IDLE    -> CLAIMED  on claim_req
//   CLAIMED -> WORKING  on work_done
//   WORKING -> DONE     on receipt_valid  (settled pulse, then -> IDLE next cycle)
//   WORKING -> IDLE     on timeout        (aborted pulse)

`timescale 1ns/1ps
`default_nettype none

module tri_3phase_commit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       claim_req,
    input  wire       work_done,
    input  wire       receipt_valid,
    input  wire       timeout,
    output reg  [1:0] state,
    output reg        settled,
    output reg        aborted
);

    localparam [1:0] S_IDLE    = 2'b00;
    localparam [1:0] S_CLAIMED = 2'b01;
    localparam [1:0] S_WORKING = 2'b10;
    localparam [1:0] S_DONE    = 2'b11;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= S_IDLE;
            settled <= 1'b0;
            aborted <= 1'b0;
        end else begin
            settled <= 1'b0;
            aborted <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (claim_req)
                        state <= S_CLAIMED;
                end

                S_CLAIMED: begin
                    if (work_done)
                        state <= S_WORKING;
                end

                S_WORKING: begin
                    if (timeout) begin
                        state   <= S_IDLE;
                        aborted <= 1'b1;
                    end else if (receipt_valid) begin
                        state   <= S_DONE;
                        settled <= 1'b1;
                    end
                end

                S_DONE: begin
                    // Auto-return to IDLE next cycle
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
