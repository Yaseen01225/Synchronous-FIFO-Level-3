`timescale 1ns / 1ps

// ============================================================================
// Project Title   : Parameterized Synchronous FIFO
// Design Level    : Level 3 - Advanced Status Monitoring
// Module Name     : tb_status_fifo
// File Name       : tb_status_fifo.v
// ----------------------------------------------------------------------------
// Developer       : Ghulam Yaseen Nangraj
// Date            : 01 November 2026
// ----------------------------------------------------------------------------
// HDL Language    : Verilog HDL
// HDL Standard    : IEEE 1364 / Verilog-2001
// Development Tool: Xilinx Vivado 2025.2.1
// Simulation Tool : Vivado Simulator (XSim)
// Design Under Test: status_fifo
// ----------------------------------------------------------------------------
// Description:
// This testbench verifies the functionality of a parameterized synchronous
// FIFO with advanced status monitoring features.
//
// The testbench applies different input conditions to the FIFO and checks
// whether the expected outputs and status flags are generated correctly.
//
// ----------------------------------------------------------------------------
// Verification Objectives:
//
//   1. Verify synchronous reset operation.
//   2. Verify normal FIFO write operations.
//   3. Verify FIFO FULL flag.
//   4. Verify ALMOST_FULL flag.
//   5. Verify rejected write operation monitoring.
//   6. Verify normal FIFO read operations.
//   7. Verify FIFO EMPTY flag.
//   8. Verify ALMOST_EMPTY flag.
//   9. Verify rejected read operation monitoring.
//  10. Verify final simulation completion.
//
// ----------------------------------------------------------------------------
// Test Sequence:
//
//   STEP 1 : Apply reset.
//   STEP 2 : Write eight data words into the FIFO.
//   STEP 3 : Verify FULL and ALMOST_FULL flags.
//   STEP 4 : Attempt an additional write when FULL.
//   STEP 5 : Verify rejected write counter.
//   STEP 6 : Read all eight stored data words.
//   STEP 7 : Verify EMPTY and ALMOST_EMPTY flags.
//   STEP 8 : Attempt an additional read when EMPTY.
//   STEP 9 : Verify rejected read counter.
//   STEP 10: Display PASS message.
//
// ----------------------------------------------------------------------------
// Expected Result:
//
//   FIFO Depth          = 8
//   FIFO Data Width     = 8 bits
//   Initial Count       = 0
//   Final Count         = 0
//   Rejected Writes     >= 1
//   Rejected Reads      >= 1
//
//   Expected Simulation Message:
//
//                  LEVEL 3 PASS
//
// ============================================================================


// ============================================================================
// TESTBENCH MODULE
// ============================================================================

module tb_status_fifo;


    // =========================================================================
    // 1. TESTBENCH INPUT SIGNALS
    // =========================================================================

    // Clock signal:
    // Initially LOW and continuously toggles during simulation.
    reg clk = 0;

    // Active-high reset signal:
    // Initially HIGH to initialize the FIFO.
    reg rst = 1;

    // FIFO write enable signal.
    reg wr_en = 0;

    // FIFO read enable signal.
    reg rd_en = 0;

    // 8-bit data input for FIFO write operations.
    reg [7:0] data_in = 0;


    // =========================================================================
    // 2. TESTBENCH OUTPUT SIGNALS
    // =========================================================================

    // Data received from the FIFO during read operations.
    wire [7:0] data_out;

    // FIFO status flags.
    wire full;
    wire empty;
    wire almost_full;
    wire almost_empty;

    // Number of valid data words currently stored in FIFO.
    wire [3:0] count;

    // Rejected write and read operation counters.
    wire [7:0] rejected_writes;
    wire [7:0] rejected_reads;


    // =========================================================================
    // 3. DESIGN UNDER TEST (DUT) INSTANTIATION
    // =========================================================================

    // Instantiate the Level 3 status_fifo module.
    //
    // The testbench uses the default parameter values:
    //
    // DATA_WIDTH         = 8
    // DEPTH              = 8
    // ADDR_WIDTH         = 3
    // COUNT_WIDTH        = 4
    // ALMOST_FULL_LEVEL  = 6
    // ALMOST_EMPTY_LEVEL = 2
    // ERROR_WIDTH        = 8

    status_fifo dut (

        // Clock and reset connections.
        .clk(clk),
        .rst(rst),

        // Write interface connections.
        .wr_en(wr_en),
        .data_in(data_in),

        // Read interface connections.
        .rd_en(rd_en),
        .data_out(data_out),

        // FIFO status flag connections.
        .full(full),
        .empty(empty),
        .almost_full(almost_full),
        .almost_empty(almost_empty),

        // FIFO occupancy counter.
        .count(count),

        // Rejected operation counters.
        .rejected_writes(rejected_writes),
        .rejected_reads(rejected_reads)
    );


    // =========================================================================
    // 4. CLOCK GENERATION
    // =========================================================================

    // Toggle the clock every 5 ns.
    //
    // Complete clock period = 10 ns.
    // Clock frequency = 100 MHz.
    //
    // All FIFO operations are synchronized to the positive clock edge.

    always #5 clk = ~clk;


    // =========================================================================
    // 5. MAIN TEST SEQUENCE
    // =========================================================================

    initial begin


        // =====================================================================
        // STEP 1: RESET OPERATION
        // =====================================================================

        // Keep reset HIGH initially.
        // Wait for 12 ns before releasing reset.
        #12;

        // Release the active-high reset.
        rst = 0;


        // =====================================================================
        // STEP 2: WRITE DATA INTO FIFO
        // =====================================================================

        // Generate eight consecutive write operations.
        //
        // Data sequence:
        //
        //     0, 1, 2, 3, 4, 5, 6, 7
        //
        // Each write request is applied at the negative clock edge.
        // The FIFO accepts and stores data at the next positive clock edge.
        //
        // The eight writes are listed one by one.
        // wr_en is set HIGH with the first word and stays HIGH until STEP 3.

        // Write word 0.
        @(negedge clk);
        wr_en = 1;
        data_in = 0;

        // Write word 1.
        @(negedge clk);
        data_in = 1;

        // Write word 2.
        @(negedge clk);
        data_in = 2;

        // Write word 3.
        @(negedge clk);
        data_in = 3;

        // Write word 4.
        @(negedge clk);
        data_in = 4;

        // Write word 5.
        @(negedge clk);
        data_in = 5;

        // Write word 6.
        @(negedge clk);
        data_in = 6;

        // Write word 7.
        @(negedge clk);
        data_in = 7;


        // =====================================================================
        // STEP 3: VERIFY FULL AND ALMOST_FULL FLAGS
        // =====================================================================

        // Wait for the next negative clock edge.
        @(negedge clk);

        // Disable further write requests.
        wr_en = 0;

        // Verify that the FIFO contains eight data words.
        //
        // Expected conditions:
        //
        //     full         = 1
        //     almost_full  = 1
        //     count        = 8

        if (!full || !almost_full || count != 8)

            // Stop simulation immediately if any condition fails.
            $fatal(1, "Level 3 full flags failed");


        // =====================================================================
        // STEP 4: ATTEMPT WRITE WHEN FIFO IS FULL
        // =====================================================================

        // Enable another write request while FIFO is FULL.
        wr_en = 1;

        // Apply an additional data word.
        // This write should be rejected.
        data_in = 8'hEE;

        // Wait for the next negative clock edge.
        @(negedge clk);

        // Disable write request.
        wr_en = 0;


        // =====================================================================
        // STEP 5: VERIFY REJECTED WRITE COUNTER
        // =====================================================================

        // The rejected write counter must increment.
        //
        // Expected condition:
        //
        //     rejected_writes >= 1

        if (rejected_writes == 0)

            // Stop simulation if rejected write monitoring fails.
            $fatal(1, "Rejected write was not counted");


        // =====================================================================
        // STEP 6: READ ALL DATA FROM FIFO
        // =====================================================================

        // Enable FIFO read operation.
        rd_en = 1;

        // Generate eight consecutive read requests.
        //
        // The FIFO should return the stored data in FIFO order:
        //
        //     0, 1, 2, 3, 4, 5, 6, 7
        //
        // Each read occurs at a positive clock edge.
        // data_out receives the corresponding memory value.
        //
        // rd_en stays HIGH while the eight negative clock edges are counted.

        // Read cycle 1.
        @(negedge clk);

        // Read cycle 2.
        @(negedge clk);

        // Read cycle 3.
        @(negedge clk);

        // Read cycle 4.
        @(negedge clk);

        // Read cycle 5.
        @(negedge clk);

        // Read cycle 6.
        @(negedge clk);

        // Read cycle 7.
        @(negedge clk);

        // Read cycle 8.
        @(negedge clk);

        // Disable FIFO read operation.
        rd_en = 0;

        // Wait for one additional negative clock edge.
        @(negedge clk);


        // =====================================================================
        // STEP 7: VERIFY EMPTY AND ALMOST_EMPTY FLAGS
        // =====================================================================

        // After reading all eight data words:
        //
        //     empty         = 1
        //     almost_empty  = 1
        //     count         = 0

        if (!empty || !almost_empty)

            // Stop simulation if empty status verification fails.
            $fatal(1, "Level 3 empty flags failed");


        // =====================================================================
        // STEP 8: ATTEMPT READ WHEN FIFO IS EMPTY
        // =====================================================================

        // Enable another read request while FIFO is EMPTY.
        // This read operation should be rejected.
        rd_en = 1;

        // Wait for the next negative clock edge.
        @(negedge clk);

        // Disable read request.
        rd_en = 0;


        // =====================================================================
        // STEP 9: VERIFY REJECTED READ COUNTER
        // =====================================================================

        // The rejected read counter must increment.
        //
        // Expected condition:
        //
        //     rejected_reads >= 1

        if (rejected_reads == 0)

            // Stop simulation if rejected read monitoring fails.
            $fatal(1, "Rejected read was not counted");


        // =====================================================================
        // STEP 10: SIMULATION COMPLETION
        // =====================================================================

        // Display PASS message when all verification conditions succeed.
        $display("LEVEL 3 PASS");

        // Terminate simulation successfully.
        $finish;

    end

endmodule


// ============================================================================
// End of Testbench: tb_status_fifo
// ============================================================================