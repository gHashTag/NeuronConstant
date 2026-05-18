// tb_trinity_d2d_bus.v — Self-checking testbench for trinity_d2d_bus
// NeuronConstant canonical hardware catalog
//
// Tests:
//   1. Reset sequence
//   2. compute_request → bus_load_mode high for LOAD_HOLD_CYCLES
//   3. bus_sync_strobe pulses for SYNC_PULSE_CYCLES after LOAD phase
//   4. ACK aggregation: both slaves high → bus_ack high
//   5. ACK aggregation: either slave low → bus_ack low
//   6. Token forwarding: phi_token → euler_token
//   7. D2D forwarding: euler_result → gamma_d2d_rx
//   8. Spike return: gamma_spike_e_tx → phi_spike_in
//
// Elaborated with: iverilog -g2005-sv -Wall
// DOI: 10.5281/zenodo.19227877
// Apache-2.0 license

`timescale 1ns / 1ps

module tb_trinity_d2d_bus;

    // -----------------------------------------------------------------------
    // DUT parameters — must match defaults in trinity_d2d_bus
    // -----------------------------------------------------------------------
    localparam DATA_WIDTH        = 8;
    localparam SYNC_PULSE_CYCLES = 2;
    localparam LOAD_HOLD_CYCLES  = 4;

    // -----------------------------------------------------------------------
    // DUT ports
    // -----------------------------------------------------------------------
    reg             clk;
    reg             rst_n;
    reg             compute_request;
    wire            bus_load_mode;
    wire            bus_sync_strobe;
    reg             bus_ack_euler;
    reg             bus_ack_gamma;
    wire            bus_ack;
    reg  [6:0]      phi_token;
    wire [6:0]      euler_token;
    reg  [DATA_WIDTH-1:0] euler_result;
    wire [DATA_WIDTH-1:0] gamma_d2d_rx;
    reg             gamma_spike_e_tx;
    wire            phi_spike_in;

    // -----------------------------------------------------------------------
    // Instantiate DUT
    // -----------------------------------------------------------------------
    trinity_d2d_bus #(
        .DATA_WIDTH       (DATA_WIDTH),
        .SYNC_PULSE_CYCLES(SYNC_PULSE_CYCLES),
        .LOAD_HOLD_CYCLES (LOAD_HOLD_CYCLES)
    ) dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .compute_request  (compute_request),
        .bus_load_mode    (bus_load_mode),
        .bus_sync_strobe  (bus_sync_strobe),
        .bus_ack_euler    (bus_ack_euler),
        .bus_ack_gamma    (bus_ack_gamma),
        .bus_ack          (bus_ack),
        .phi_token        (phi_token),
        .euler_token      (euler_token),
        .euler_result     (euler_result),
        .gamma_d2d_rx     (gamma_d2d_rx),
        .gamma_spike_e_tx (gamma_spike_e_tx),
        .phi_spike_in     (phi_spike_in)
    );

    // -----------------------------------------------------------------------
    // Clock: 20 ns period (50 MHz)
    // -----------------------------------------------------------------------
    initial clk = 1'b0;
    always #10 clk = ~clk;

    // -----------------------------------------------------------------------
    // Test infrastructure
    // -----------------------------------------------------------------------
    integer fail_count;
    integer load_high_count;
    integer sync_high_count;
    integer i;

    // -----------------------------------------------------------------------
    // Helper task: release reset cleanly (drive on negedge, stable at posedge)
    // -----------------------------------------------------------------------
    task do_reset;
        begin
            @(negedge clk); rst_n = 1'b0;
            @(negedge clk); rst_n = 1'b0;
            @(negedge clk); rst_n = 1'b0;
            @(negedge clk); rst_n = 1'b0;
            @(negedge clk); rst_n = 1'b1;
            @(posedge clk); // let first valid posedge pass
        end
    endtask

    initial begin
        // ---------------------------------------------------------------
        // Initialise
        // ---------------------------------------------------------------
        fail_count       = 0;
        rst_n            = 1'b0;
        compute_request  = 1'b0;
        bus_ack_euler    = 1'b0;
        bus_ack_gamma    = 1'b0;
        phi_token        = 7'h00;
        euler_result     = 8'h00;
        gamma_spike_e_tx = 1'b0;

        // ---------------------------------------------------------------
        // TEST 1: Reset sequence — outputs must be zero during reset
        // ---------------------------------------------------------------
        do_reset;
        #1; // 1 ns after posedge
        if (bus_load_mode !== 1'b0) begin
            $display("FAIL T1: bus_load_mode not 0 after reset");
            fail_count = fail_count + 1;
        end
        if (bus_sync_strobe !== 1'b0) begin
            $display("FAIL T1: bus_sync_strobe not 0 after reset");
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 2: bus_load_mode stays high for exactly LOAD_HOLD_CYCLES
        // Assert compute_request on negedge so it is sampled on the next
        // posedge, then count posedges where bus_load_mode is high.
        // ---------------------------------------------------------------
        @(negedge clk);
        compute_request = 1'b1;

        load_high_count = 0;
        // Window: LOAD_HOLD_CYCLES + SYNC_PULSE_CYCLES + 4 guard cycles
        for (i = 0; i < (LOAD_HOLD_CYCLES + SYNC_PULSE_CYCLES + 4); i = i + 1) begin
            @(posedge clk);
            #1;
            if (bus_load_mode === 1'b1)
                load_high_count = load_high_count + 1;
        end

        if (load_high_count !== LOAD_HOLD_CYCLES) begin
            $display("FAIL T2: bus_load_mode high for %0d cycles, expected %0d",
                     load_high_count, LOAD_HOLD_CYCLES);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 3: bus_sync_strobe pulses for SYNC_PULSE_CYCLES
        // (already measured in the same window above)
        // Re-run with a fresh reset to measure strobe independently.
        // ---------------------------------------------------------------
        compute_request = 1'b0;
        @(negedge clk); rst_n = 1'b0;
        @(negedge clk); rst_n = 1'b0;
        @(negedge clk); rst_n = 1'b1;
        @(posedge clk);

        @(negedge clk);
        compute_request = 1'b1;

        sync_high_count = 0;
        for (i = 0; i < (LOAD_HOLD_CYCLES + SYNC_PULSE_CYCLES + 4); i = i + 1) begin
            @(posedge clk);
            #1;
            if (bus_sync_strobe === 1'b1)
                sync_high_count = sync_high_count + 1;
        end

        if (sync_high_count !== SYNC_PULSE_CYCLES) begin
            $display("FAIL T3: bus_sync_strobe high for %0d cycles, expected %0d",
                     sync_high_count, SYNC_PULSE_CYCLES);
            fail_count = fail_count + 1;
        end

        // Deassert compute_request; let FSM return to IDLE
        compute_request = 1'b0;
        repeat(4) @(posedge clk);

        // ---------------------------------------------------------------
        // TEST 4: ACK aggregation — both slaves high → bus_ack high
        // ---------------------------------------------------------------
        bus_ack_euler = 1'b1;
        bus_ack_gamma = 1'b1;
        #1;
        if (bus_ack !== 1'b1) begin
            $display("FAIL T4: bus_ack should be 1 when both slaves high");
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 5a: ACK aggregation — Euler low → bus_ack low
        // ---------------------------------------------------------------
        bus_ack_euler = 1'b0;
        bus_ack_gamma = 1'b1;
        #1;
        if (bus_ack !== 1'b0) begin
            $display("FAIL T5a: bus_ack should be 0 when Euler low");
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 5b: ACK aggregation — Gamma low → bus_ack low
        // ---------------------------------------------------------------
        bus_ack_euler = 1'b1;
        bus_ack_gamma = 1'b0;
        #1;
        if (bus_ack !== 1'b0) begin
            $display("FAIL T5b: bus_ack should be 0 when Gamma low");
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 6: Token forwarding phi_token → euler_token
        // ---------------------------------------------------------------
        phi_token = 7'h3A;
        #1;
        if (euler_token !== 7'h3A) begin
            $display("FAIL T6: euler_token=%h expected 3A", euler_token);
            fail_count = fail_count + 1;
        end
        phi_token = 7'h00;

        // ---------------------------------------------------------------
        // TEST 7: D2D forwarding euler_result → gamma_d2d_rx
        // ---------------------------------------------------------------
        euler_result = 8'hC3;
        #1;
        if (gamma_d2d_rx !== 8'hC3) begin
            $display("FAIL T7: gamma_d2d_rx=%h expected C3", gamma_d2d_rx);
            fail_count = fail_count + 1;
        end
        euler_result = 8'h00;

        // ---------------------------------------------------------------
        // TEST 8: Spike return gamma_spike_e_tx → phi_spike_in
        // ---------------------------------------------------------------
        gamma_spike_e_tx = 1'b1;
        #1;
        if (phi_spike_in !== 1'b1) begin
            $display("FAIL T8: phi_spike_in should be 1");
            fail_count = fail_count + 1;
        end
        gamma_spike_e_tx = 1'b0;
        #1;
        if (phi_spike_in !== 1'b0) begin
            $display("FAIL T8: phi_spike_in should be 0");
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // RESULT
        // ---------------------------------------------------------------
        if (fail_count === 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d error(s) detected", fail_count);
        end

        $finish;
    end

    // Safety timeout
    initial begin
        #20000;
        $display("FAIL: simulation timeout");
        $finish;
    end

endmodule
