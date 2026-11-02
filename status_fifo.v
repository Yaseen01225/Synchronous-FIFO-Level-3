`timescale 1ns / 1ps
// ============================================================================
// Project Title   : Parameterized Synchronous FIFO
// Design Level    : Level 3 - FIFO with Advanced Status Monitoring
// Module Name     : status_fifo
// File Name       : status_fifo.v
// ----------------------------------------------------------------------------
// Developer       : Ghulam Yaseen Nangraj
// Date            : 01 November 2026
// ----------------------------------------------------------------------------
// HDL Language    : Verilog HDL
// HDL Standard    : IEEE 1364 / Verilog-2001
// Development Tool: Xilinx Vivado 2025.2.1
// Target Platform : FPGA / Digital Logic Systems
// ----------------------------------------------------------------------------
// Description:
// This module implements a fully parameterized synchronous First-In-First-Out
// (FIFO) buffer with configurable data width and storage depth.
//
// All FIFO operations use a single clock domain, making the design suitable
// for synchronous digital systems and FPGA implementations.
//
// This Level 3 FIFO provides:
//   - FULL and EMPTY status flags
//   - ALMOST_FULL and ALMOST_EMPTY warning flags
//   - FIFO occupancy tracking
//   - Rejected write monitoring
//   - Rejected read monitoring
//   - Saturating error counters
//   - Explicit pointer wraparound
//   - Simultaneous read/write operation support
//
// ----------------------------------------------------------------------------
// Key Parameters:
//
//   DATA_WIDTH          : Number of bits in each FIFO data word.
//   DEPTH               : Number of storage locations.
//   ADDR_WIDTH          : Width of read/write pointers.
//   COUNT_WIDTH         : Width of FIFO occupancy counter.
//   ALMOST_FULL_LEVEL   : Occupancy threshold for almost_full.
//   ALMOST_EMPTY_LEVEL  : Occupancy threshold for almost_empty.
//   ERROR_WIDTH         : Width of rejected-operation counters.
//
// ----------------------------------------------------------------------------
// FIFO Operation:
//
//   WRITE:
//       Accepted when: wr_en = 1 and full = 0
//
//       data_in is stored at memory[wr_ptr]
//       wr_ptr advances to the next location.
//
//   READ:
//       Accepted when: rd_en = 1 and empty = 0
//
//       memory[rd_ptr] is transferred to data_out
//       rd_ptr advances to the next location.
//
// ----------------------------------------------------------------------------
// Occupancy Counter:
//
//       Write Only       -> count + 1
//       Read Only        -> count - 1
//       Write + Read     -> count unchanged
//       No Operation     -> count unchanged
//
// ----------------------------------------------------------------------------
// Status Flags:
//
//       full         = (count == DEPTH)
//       empty        = (count == 0)
//       almost_full  = (count >= ALMOST_FULL_LEVEL)
//       almost_empty = (count <= ALMOST_EMPTY_LEVEL)
//
// ----------------------------------------------------------------------------
// Pointer Wraparound:
//
// When a pointer reaches DEPTH-1, it returns to zero:
//
//       0 -> 1 -> 2 -> ... -> DEPTH-1 -> 0
//
// This explicit implementation supports both power-of-two and non-power-of-two
// FIFO depths.
//
// ----------------------------------------------------------------------------
// Rejected Operation Counters:
//
// Rejected writes and reads are counted using saturating counters.
//
// Once a counter reaches:
//
//       {ERROR_WIDTH{1'b1}}
//
// it stops incrementing and remains at its maximum value.
//
// ----------------------------------------------------------------------------
// Reset Behavior:
//
//       wr_ptr          = 0
//       rd_ptr          = 0
//       count           = 0
//       data_out        = 0
//       rejected_writes = 0
//       rejected_reads  = 0
//
// ----------------------------------------------------------------------------
// Typical Applications:
//
//   - FPGA data buffering
//   - Digital communication systems
//   - Streaming interfaces
//   - Pipeline buffering
//   - Producer-consumer systems
//   - Digital signal processing
//   - Embedded digital systems
//
// ============================================================================

module status_fifo #(

    // Width of each FIFO data word.
    parameter DATA_WIDTH = 8,

    // Number of storage locations in the FIFO.
    parameter DEPTH = 8,

    // Width of the read and write address pointers.
    parameter ADDR_WIDTH = 3,

    // Width of the FIFO occupancy counter.
    // Must be large enough to represent values from 0 to DEPTH.
    parameter COUNT_WIDTH = 4,

    // Occupancy level at which almost_full becomes HIGH.
    parameter ALMOST_FULL_LEVEL = 6,

    // Occupancy level at which almost_empty becomes HIGH.
    parameter ALMOST_EMPTY_LEVEL = 2,

    // Width of rejected operation counters.
    parameter ERROR_WIDTH = 8

)(

    // ========================================================================
    // CLOCK AND RESET
    // ========================================================================

    // Common clock for all FIFO operations.
    input wire clk,

    // Active-high synchronous reset.
    input wire rst,


    // ========================================================================
    // WRITE INTERFACE
    // ========================================================================

    // Write request signal.
    input wire wr_en,

    // Input data to be written into the FIFO.
    input wire [DATA_WIDTH-1:0] data_in,


    // ========================================================================
    // READ INTERFACE
    // ========================================================================

    // Read request signal.
    input wire rd_en,

    // Output data read from the FIFO.
    output reg [DATA_WIDTH-1:0] data_out,


    // ========================================================================
    // STATUS FLAGS
    // ========================================================================

    // HIGH when the FIFO is completely full.
    output wire full,

    // HIGH when the FIFO contains no valid data.
    output wire empty,

    // HIGH when FIFO occupancy reaches the almost-full threshold.
    output wire almost_full,

    // HIGH when FIFO occupancy is at or below the almost-empty threshold.
    output wire almost_empty,


    // ========================================================================
    // FIFO OCCUPANCY AND ERROR MONITORING
    // ========================================================================

    // Number of valid data words currently stored in the FIFO.
    output reg [COUNT_WIDTH-1:0] count,

    // Counts rejected write requests.
    output reg [ERROR_WIDTH-1:0] rejected_writes,

    // Counts rejected read requests.
    output reg [ERROR_WIDTH-1:0] rejected_reads
);


    // =========================================================================
    // INTERNAL FIFO MEMORY
    // =========================================================================

    // Storage array containing DEPTH locations.
    // Each location stores DATA_WIDTH bits.
    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];


    // =========================================================================
    // READ AND WRITE POINTERS
    // =========================================================================

    // Points to the location where the next accepted write occurs.
    reg [ADDR_WIDTH-1:0] wr_ptr;

    // Points to the location from which the next accepted read occurs.
    reg [ADDR_WIDTH-1:0] rd_ptr;


    // =========================================================================
    // STATUS FLAG GENERATION
    // =========================================================================

    // FIFO is FULL when occupancy reaches DEPTH.
    assign full = (count == DEPTH);

    // FIFO is EMPTY when occupancy is zero.
    assign empty = (count == 0);

    // FIFO is ALMOST_FULL when occupancy reaches the configured threshold.
    assign almost_full = (count >= ALMOST_FULL_LEVEL);

    // FIFO is ALMOST_EMPTY when occupancy is at or below the threshold.
    assign almost_empty = (count <= ALMOST_EMPTY_LEVEL);


    // =========================================================================
    // ACCEPTED READ AND WRITE OPERATIONS
    // =========================================================================

    // A write request is accepted only when FIFO is not FULL.
    wire wr_accept = wr_en && !full;

    // A read request is accepted only when FIFO is not EMPTY.
    wire rd_accept = rd_en && !empty;


    // =========================================================================
    // WRITE CONTROL LOGIC
    // =========================================================================

    always @(posedge clk) begin

        // ---------------------------------------------------------------------
        // SYNCHRONOUS RESET
        // ---------------------------------------------------------------------
        if (rst) begin

            // Initialize write pointer to the first memory location.
            wr_ptr <= 0;

            // Clear the rejected write counter.
            rejected_writes <= 0;
        end

        else begin

            // -----------------------------------------------------------------
            // REJECTED WRITE DETECTION
            // -----------------------------------------------------------------
            //
            // A write is rejected when:
            //
            //     wr_en = 1
            //     FIFO is FULL
            //
            // A simultaneous valid read is excluded from the error condition.
            if (wr_en && full && !(rd_en && !empty)) begin

                // Increment the counter only if it has not reached
                // its maximum value.
                if (rejected_writes != {ERROR_WIDTH{1'b1}})
                    rejected_writes <= rejected_writes + 1'b1;
            end


            // -----------------------------------------------------------------
            // ACCEPTED WRITE OPERATION
            // -----------------------------------------------------------------
            if (wr_accept) begin

                // Store input data at the current write pointer location.
                memory[wr_ptr] <= data_in;

                // -------------------------------------------------------------
                // WRITE POINTER WRAPAROUND
                // -------------------------------------------------------------

                // Return to location zero after reaching the last location.
                if (wr_ptr == DEPTH - 1)
                    wr_ptr <= 0;

                // Otherwise move to the next location.
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end


    // =========================================================================
    // READ CONTROL LOGIC
    // =========================================================================

    always @(posedge clk) begin

        // ---------------------------------------------------------------------
        // SYNCHRONOUS RESET
        // ---------------------------------------------------------------------
        if (rst) begin

            // Initialize read pointer to the first memory location.
            rd_ptr <= 0;

            // Clear output data.
            data_out <= 0;

            // Clear the rejected read counter.
            rejected_reads <= 0;
        end

        else begin

            // -----------------------------------------------------------------
            // REJECTED READ DETECTION
            // -----------------------------------------------------------------
            //
            // A read is rejected when:
            //
            //     rd_en = 1
            //     FIFO is EMPTY
            //
            // A simultaneous valid write is excluded from the error condition.
            if (rd_en && empty && !(wr_en && !full)) begin

                // Increment the counter only if it has not reached
                // its maximum value.
                if (rejected_reads != {ERROR_WIDTH{1'b1}})
                    rejected_reads <= rejected_reads + 1'b1;
            end


            // -----------------------------------------------------------------
            // ACCEPTED READ OPERATION
            // -----------------------------------------------------------------
            if (rd_accept) begin

                // Transfer the current FIFO memory location to data_out.
                data_out <= memory[rd_ptr];

                // -------------------------------------------------------------
                // READ POINTER WRAPAROUND
                // -------------------------------------------------------------

                // Return to location zero after reaching the final location.
                if (rd_ptr == DEPTH - 1)
                    rd_ptr <= 0;

                // Otherwise move to the next location.
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end


    // =========================================================================
    // FIFO OCCUPANCY COUNTER
    // =========================================================================

    always @(posedge clk) begin

        // ---------------------------------------------------------------------
        // SYNCHRONOUS RESET
        // ---------------------------------------------------------------------
        if (rst)

            // FIFO starts empty.
            count <= 0;

        else begin

            // Determine which FIFO operations were accepted.
            case ({wr_accept, rd_accept})

                // -------------------------------------------------------------
                // WRITE ONLY
                // -------------------------------------------------------------
                //
                // One new word enters the FIFO.
                2'b10:
                    count <= count + 1'b1;


                // -------------------------------------------------------------
                // READ ONLY
                // -------------------------------------------------------------
                //
                // One word leaves the FIFO.
                2'b01:
                    count <= count - 1'b1;


                // -------------------------------------------------------------
                // SIMULTANEOUS READ AND WRITE
                // -------------------------------------------------------------
                //
                // One word enters and one word leaves.
                // Therefore, FIFO occupancy does not change.
                2'b11:
                    count <= count;


                // -------------------------------------------------------------
                // NO ACCEPTED OPERATION
                // -------------------------------------------------------------
                //
                // FIFO occupancy remains unchanged.
                2'b00:
                    count <= count;


                // Default condition for safe simulation behavior.
                default:
                    count <= count;

            endcase
        end
    end

endmodule

// ============================================================================
// End of Module: status_fifo
// ============================================================================