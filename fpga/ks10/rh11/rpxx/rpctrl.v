////////////////////////////////////////////////////////////////////////////////
//
// KS-10 Processor
//
// Brief
//   RPxx State Machine
//
// File
//   rpctrl.v
//
// Author
//   Rob Doyle - doyle (at) cox (dot) net
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2012-2015 Rob Doyle
//
// This source file may be used and distributed without restriction provided
// that this copyright statement is not removed from the file and that any
// derivative work contains the original copyright notice and the associated
// disclaimer.
//
// This source file is free software; you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as published by the
// Free Software Foundation; version 2.1 of the License.
//
// This source is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
// for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this source; if not, download it from
// http://www.gnu.org/licenses/lgpl.txt
//
////////////////////////////////////////////////////////////////////////////////

`default_nettype none
`timescale 1ns/1ps

`include "rpda.vh"
`include "rpla.vh"
`include "rpmr.vh"
`include "rpcc.vh"
`include "rpdc.vh"
`include "rpcs1.vh"
`include "../sd/sd.vh"
`include "../../ks10.vh"

`define RPXX_SKI                                // Required to pass DSRPA test
`define RPXX_OPI                                // Required to pass DSRPA test

module RPCTRL (
      input  wire         clk,                  // Clock
      input  wire         rst,                  // Reset
      input  wire         clr,                  // Clr
      input  wire [35: 0] rpDATAI,              // Data input
      input  wire         rpcs1WRITE,           // CS1 write
      input  wire [ 9: 0] rpCYLNUM,             // Number of cylinders
      input  wire [15: 0] rpLA,                 // Lookahead register
      input  wire [15: 0] rpDA,                 // Disk address
      input  wire [15: 0] rpDC,                 // Desired cylinder
      output reg  [15: 0] rpCC,                 // Current cylinder
      input  wire         rpDMD,                // Diagnostic Mode
      input  wire         rpDSCK,               // Diagnostic sector clock
      input  wire         rpDIND,               // Diagnostic index pulse
      input  wire         rpPAT,                // Parity test
      output reg          rpPIP,                // Positioning-in-progress
      output reg          rpDRY,                // Drive ready
      output reg          rpECE,                // ECC envelope
      output reg          rpDFE,                // Data field envelope
      input  wire         rpFMT22,              // 22 sector format (16-bit)
      input  wire         rpSETAOE,             // Set address overflow error
      input  wire         rpSETIAE,             // Set invalid address error
      input  wire         rpSETWLE,             // Set write lock error
      output reg          rpSETATA,             // Set attenation
      output wire         rpSETOPI,             // Set operation incomplete
      output reg          rpSETSKI,             // Set seek incomplete
      output reg          rpADRSTRT,            // Address calculation start
      input  wire         rpADRBUSY,            // Address calculation busy
      output reg  [ 2: 0] rpSDOP,               // SD operation
      output wire         rpSDREQ,              // SD request
      input  wire         rpSDACK               // SD acknowledge
   );

   //
   // Timing Parameters
   //

   parameter  simSEEK   = 1'b0;                 // Simulate seek accurately
   parameter  simSEARCH = 1'b1;                 // Simulate search accurately
   localparam CLKFRQ    = `CLKFRQ;              // Clock frequency
   localparam OFFDELAY  = 0.005000 * `CLKFRQ;   // Offset delay (5 ms)
   localparam FIXDELAY  = 0.000100 * `CLKFRQ;   // Fixed delay (100 us)

   //
   // Function to calculate disk seek delay.  This is psudeo exponential.
   // The RP06 has 815 cyclinders
   //

   function [24:0] seekDELAY;
      input [9:0] newCYL;                       // New Cylinder
      input [9:0] oldCYL;                       // Old Cylinder
      reg   [9:0] diffCYL;                      // Distance between Cylinders
      begin
         diffCYL = (newCYL > oldCYL) ? newCYL - oldCYL : oldCYL - newCYL;
         if (diffCYL[9])
           seekDELAY = $rtoi(0.05000 * CLKFRQ); // 50 ms (more than 512 cylinders away)
         else if (diffCYL[8])
           seekDELAY = $rtoi(0.04500 * CLKFRQ); // 45 ms (more than 256 cylinders away)
         else if (diffCYL[7])
           seekDELAY = $rtoi(0.04000 * CLKFRQ); // 40 ms (more than 128 cylinders away)
         else if (diffCYL[6])
           seekDELAY = $rtoi(0.03500 * CLKFRQ); // 35 ms (more than  64 cylinders away)
         else if (diffCYL[5])
           seekDELAY = $rtoi(0.03000 * CLKFRQ); // 30 ms (more than  32 cylinders away)
         else if (diffCYL[4])
           seekDELAY = $rtoi(0.02500 * CLKFRQ); // 25 ms (more than  16 cylinders away)
         else if (diffCYL[3])
           seekDELAY = $rtoi(0.02000 * CLKFRQ); // 20 ms (more than   8 cylinders away)
         else if (diffCYL[2])
           seekDELAY = $rtoi(0.01500 * CLKFRQ); // 15 ms (more than   4 cylinders away)
         else if (diffCYL[1])
           seekDELAY = $rtoi(0.01000 * CLKFRQ); // 10 ms (more than   2 cylinders away)
         else if (diffCYL[0])
           seekDELAY = $rtoi(0.00500 * CLKFRQ); //  5 ms (more than   1 cylinders away)
         else
           seekDELAY = $rtoi(0.000010 * CLKFRQ);//  10 us (same cylinder)
      end
   endfunction

   //
   // rpDCA
   //

   wire [9:0] rpDCA = `rpDC_DCA(rpDC);

   //
   // rpCCA
   //

   wire [9:0] rpCCA = `rpCC_CCA(rpCC);

   //
   // Head position (cylinder)
   //
   // The head position can be unsynchronized from the DCA/CCA if a seek is
   // performed in maintenance mode: the DCA/CCA moves but the head does not.
   //

   reg  [9:0] head_pos;

   //
   // Desired Sector
   //

   wire [5:0] rpSA = `rpDA_SA(rpDA);

   //
   // RPLA Sector
   //

   wire [5:0] rpLAS = `rpLA_LAS(rpLA);

   //
   // rpGO
   //
   // Commands are ignored with incorrect parity.
   //

   wire rpGO = !rpPAT & rpcs1WRITE & `rpCS1_GO(rpDATAI);

   //
   // State Definition
   //

   localparam [2:0] stateIDLE       = 0,        // Idle
                    stateSEEKDONE   = 1,        // Seek then done
                    stateSEEKSEARCH = 2,        // Seek then search
                    stateSEARCH     = 3,        // Searching for sector
                    stateDATA       = 4,        // Reading/writing data
                    stateDONE       = 7;        // Done

   //
   // Disk Motion Simlation State Machine
   //

   reg ata;                                     // Do ATA at end
   reg busy;                                    // Drive busy
   reg [24: 0] delay;                           // RPxx Delay Simulation
   reg [15: 0] tempCC;                          // rpCC value when command completes
   reg [ 2: 0] state;                           // State

   always @(posedge clk or posedge rst)
     begin
        if (rst)
          begin
             ata      <= 0;
             busy     <= 0;
             rpCC     <= 0;
             head_pos <= 0;
             rpPIP    <= 0;
             rpSETATA <= 0;
             rpSETSKI <= 0;
             rpSDOP   <= `sdopNOP;
             delay    <= 0;
             tempCC   <= 0;
             state    <= stateIDLE;
          end
        else
          begin
             if (clr)
               begin
                  ata      <= 0;
                  busy     <= 0;
                  rpCC     <= rpDC;
                  rpPIP    <= 0;
                  rpSETATA <= 0;
                  rpSETSKI <= 0;
                  rpSDOP   <= `sdopNOP;
                  delay    <= 0;
                  tempCC   <= 0;
                  state    <= stateIDLE;
               end
             else
               begin

                  rpADRSTRT <= 0;
                  rpSETSKI  <= 0;

                  case (state)

                    //
                    // stateIDLE
                    //
                    // Look for a function (command) to go process
                    //

                    stateIDLE:
                      begin
                         ata      <= 0;
                         busy     <= 0;
                         rpPIP    <= 0;
                         rpSETATA <= 0;
                         tempCC   <= 0;

                         //
                         // Wait for a GO command
                         //

                         if (rpGO)

                           //
                           // Decode Command (Function)
                           //

                           case (`rpCS1_FUN(rpDATAI))

                             //
                             // Unload Command
                             //
                             // On an RPxx disk, the unload command would unload
                             // the heads, spin-down the disk, off-line the
                             // disk, allow the operator to change the disk
                             // pack, on-line the disk, spin-up the disk, and
                             // reload the heads.
                             //

                             `funUNLOAD:
                               begin
                                  ata    <= 1;
                                  busy   <= 1;
                                  rpPIP  <= 1;
                                  rpSDOP <= `sdopNOP;
                                  tempCC <= rpDC;
                                  if (simSEEK)
                                    delay <= seekDELAY(0, rpCCA);
                                  else
                                    delay <= $rtoi(FIXDELAY);
                                  state <= stateSEEKDONE;
                               end

                             //
                             // Seek Command
                             //
                             // On an RPxx disk, the seek command causes the
                             // heads to move to the cylinder specified by the
                             // RPDC register.
                             //
                             // This command simulates head motion to the new
                             // cylinder specified by the RPDC register
                             //
                             // The disk will not seek to an invalid address.
                             //

                             `funSEEK:
                               begin
                                  if (!rpSETIAE)
                                    begin
                                       ata    <= 1;
                                       busy   <= 1;
                                       rpPIP  <= 1;
                                       rpSDOP <= `sdopNOP;
                                       tempCC <= rpDC;
                                       if (simSEEK)
                                         delay <= seekDELAY(rpDCA, rpCCA);
                                       else
                                         delay <= $rtoi(FIXDELAY);

                                       //
                                       // Check for RPER3[SKI] error. A  SKI
                                       // error occurs when you seek off the
                                       // edge of the disk.
                                       //
                                       // Force the disk to recalibrate (zero
                                       // rpCC) on a SKI error.
                                       //

`ifdef RPXX_SKI
                                       if (rpDCA > rpCCA)
                                         begin
                                            if (rpDCA - rpCCA > rpCYLNUM - head_pos)
                                              begin
                                                 tempCC   <= 0;
                                                 rpSETSKI <= 1;
                                              end
                                         end
                                       else
                                         begin
                                            if (rpCCA - rpDCA > head_pos)
                                              begin
                                                 tempCC   <= 0;
                                                 rpSETSKI <= 1;
                                              end
                                         end
`endif

                                       state <= stateSEEKDONE;
                                    end
                               end

                             //
                             // Recalibrate Command
                             //
                             // The recalibrate command causes the heads to move
                             // to cylinder 0.
                             //

                             `funRECAL:
                               begin
                                  ata    <= 1;
                                  busy   <= 1;
                                  rpPIP  <= 1;
                                  rpSDOP <= `sdopNOP;
                                  tempCC <= 0;
                                  if (simSEEK)
                                    delay  <= seekDELAY(0, rpCCA);
                                  else
                                    delay <= $rtoi(FIXDELAY);
                                  state <= stateSEEKDONE;
                               end

                             //
                             // Search Command
                             //
                             // A search command may have to perform an implied
                             // seek before before performing the search
                             // operation.
                             //
                             // The disk will not seek to an invalid address.
                             //

                             `funSEARCH:
                               begin
                                  if (!rpSETIAE)
                                    begin
                                       ata    <= 1;
                                       busy   <= 1;
                                       rpPIP  <= 0;
                                       rpSDOP <= `sdopNOP;
                                       tempCC <= rpDC;
                                       if (simSEEK)
                                         delay <= seekDELAY(rpDCA, rpCCA);
                                       else
                                         delay <= $rtoi(FIXDELAY);
                                       state <= stateSEEKSEARCH;
                                    end
                               end

                             //
                             // Offset Command
                             //
                             // This command would offset the head from the
                             // centerline of the track.
                             //

                             `funOFFSET:
                               begin
                                  ata    <= 1;
                                  busy   <= 1;
                                  rpPIP  <= 1;
                                  rpSDOP <= `sdopNOP;
                                  tempCC <= rpCC;
                                  if (simSEEK)
                                    delay <= $rtoi(OFFDELAY);
                                  else
                                    delay <= $rtoi(FIXDELAY);
                                  state <= stateSEEKDONE;
                               end

                             //
                             // Return-to-center command
                             //
                             // This command would return the head to the
                             // centerline of the track.
                             //

                             `funCENTER:
                               begin
                                  ata    <= 1;
                                  busy   <= 1;
                                  rpPIP  <= 1;
                                  rpSDOP <= `sdopNOP;
                                  tempCC <= rpCC;
                                  if (simSEEK)
                                    delay <= $rtoi(OFFDELAY);
                                  else
                                    delay <= $rtoi(FIXDELAY);
                                  state <= stateSEEKDONE;
                               end

                             //
                             // Write check data command
                             //
                             // A write check command may have to perform an
                             // implied seek before before performing the write
                             // check operation.
                             //
                             // The disk will not seek to an invalid address.
                             //

                             `funWRCHK:
                               begin
                                  if (!rpSETIAE)
                                    begin
                                       ata    <= 0;
                                       busy   <= 1;
                                       rpPIP  <= 0;
                                       rpSDOP <= `sdopWRCHK;
                                       tempCC <= rpDC;
                                       rpADRSTRT <= 1;
                                       if (simSEEK)
                                         delay <= seekDELAY(rpDCA, rpCCA);
                                       else
                                         delay <= $rtoi(FIXDELAY);
                                       state <= stateSEEKSEARCH;
                                    end
                               end

                             //
                             // Write check header and data command
                             //

                             `funWRCHKH:
                               begin
                                  if (!rpSETIAE)
                                    begin
                                       ata    <= 0;
                                       busy   <= 1;
                                       rpPIP  <= 0;
                                       rpSDOP <= `sdopWRCHKH;
                                       tempCC <= rpDC;
                                       rpADRSTRT <= 1;
                                       if (simSEEK)
                                         delay <= seekDELAY(rpDCA, rpCCA);
                                       else
                                         delay <= $rtoi(FIXDELAY);
                                       state <= stateSEEKSEARCH;
                                    end
                               end

                             //
                             // Write data command
                             //
                             // A write command may have to perform an implied
                             // seek before before performing the write
                             // operation.
                             //
                             // The disk will not seek to an invalid address.
                             //

                             `funWRITE:
                               begin
                                  if (!rpSETIAE & !rpSETWLE)
                                    begin
                                       ata    <= 0;
                                       busy   <= 1;
                                       rpPIP  <= 0;
                                       rpSDOP <= `sdopWR;
                                       tempCC <= rpDC;
                                       rpADRSTRT <= 1;
                                       if (simSEEK)
                                         delay <= seekDELAY(rpDCA, rpCCA);
                                       else
                                         delay <= $rtoi(FIXDELAY);
                                       state <= stateSEEKSEARCH;
                                    end
                               end

                             //
                             // Write header and data command
                             //

                             `funWRITEH:
                               begin
                                  if (!rpSETIAE)
                                    begin
                                       ata    <= 0;
                                       busy   <= 1;
                                       rpPIP  <= 0;
                                       rpSDOP <= `sdopWRH;
                                       tempCC <= rpDC;
                                       rpADRSTRT <= 1;
                                       if (simSEEK)
                                         delay <= seekDELAY(rpDCA, rpCCA);
                                       else
                                         delay <= $rtoi(FIXDELAY);
                                       state <= stateSEEKSEARCH;
                                    end
                               end

                             //
                             // Read data command
                             //
                             // A read command may have to perform an implied
                             // seek before before performing the read
                             // operation.
                             //
                             // The disk will not seek to an invalid address.
                             //

                             `funREAD:
                               begin
                                  if (!rpSETIAE)
                                    begin
                                       ata    <= 0;
                                       busy   <= 1;
                                       rpPIP  <= 0;
                                       rpSDOP <= `sdopRD;
                                       tempCC <= rpDC;
                                       rpADRSTRT <= 1;
                                       if (simSEEK)
                                         delay <= seekDELAY(rpDCA, rpCCA);
                                       else
                                         delay <= $rtoi(FIXDELAY);
                                       state <= stateSEEKSEARCH;
                                    end
                               end

                             //
                             // Read header and data command
                             //

                             `funREADH:
                               begin
                                  if (!rpSETIAE)
                                    begin
                                       ata    <= 0;
                                       busy   <= 1;
                                       rpPIP  <= 0;
                                       rpSDOP <= `sdopRDH;
                                       tempCC <= rpDC;
                                       rpADRSTRT <= 1;
                                       if (simSEEK)
                                         delay <= seekDELAY(rpDCA, rpCCA);
                                       else
                                         delay <= $rtoi(FIXDELAY);
                                       state <= stateSEEKSEARCH;
                                    end
                               end

                           endcase

                      end

                    //
                    // stateSEEKDONE
                    //
                    // Simulate seek timing for:
                    //  - Seek command
                    //  - Recalibrate command
                    //  - Offset command
                    //  - Return-to-center command
                    //  - Unload command
                    //
                    // These commands are done once the seek is completed
                    //

                    stateSEEKDONE:
                      begin
                         if (!rpDMD)
                           if (delay == 0)
                             begin
                                head_pos <= tempCC;
                                rpCC     <= tempCC;
                                state    <= stateDONE;
                             end
                           else
                             delay <= delay - 1'b1;
                      end

                    //
                    // stateSEEKSEARCH
                    //
                    // Simulate seek timing for:
                    //  - Search command
                    //  - Read commands
                    //  - Write commands
                    //  - Write check commands
                    //
                    // These commands will do a sector search once the seek has
                    // completed.
                    //

                    stateSEEKSEARCH:
                      begin
                         if (!rpDMD)
                           if (delay == 0)
                             begin
                                head_pos <= tempCC;
                                rpCC     <= tempCC;
                                delay    <= $rtoi(FIXDELAY);
                                state    <= stateSEARCH;
                             end
                           else
                             delay <= delay - 1'b1;
                      end

                    //
                    // stateSEARCH
                    //
                    // Simulate timining for sector search
                    //  - Search command
                    //  - Read commands
                    //  - Write commands
                    //  - Write check commands
                    //
                    // If accurate search is required for diagnostics (see DSRPA
                    // TEST-302), the search completes when the sector under
                    // the head (visbile in the RPLA register) is the same as
                    // the desired sector.
                    //
                    // Wait for SD sector address calculation to complete before
                    // moving to a data transfer state.
                    //

                    stateSEARCH:
                      begin
                         if (simSEARCH ? (rpSA == rpLAS) : (delay == 0))
                           begin
                              if (rpSDOP == `sdopNOP)
                                state <= stateDONE;
                              else if (!rpADRBUSY)
                                state <= stateDATA;
                           end
                         else
                           delay <= delay - 1'b1;
                      end

                    //
                    // stateDATA:
                    //
                    // Wait for SD to complete Read/Write operaton
                    //
                    // The controller should abort on a invalid address when it
                    // occurs on a mid-transfer seek.  Keep rpCC updated on mid-
                    // transfer seeks.
                    //

                    stateDATA:
                      begin
                         if (rpSETAOE | rpSDACK)
                           state <= stateDONE;
                         else
                           rpCC <= rpDC;
                      end

                    //
                    // stateDONE:
                    //
                    // Update the visible disk state
                    //

                    stateDONE:
                      begin
                         ata      <= 0;
                         busy     <= 0;
                         rpPIP    <= 0;
                         rpSETATA <= ata;
                         rpSDOP   <= `sdopNOP;
                         state    <= stateIDLE;
                      end

                    //
                    // Everything else
                    //

                    default:
                      state <= stateIDLE;

                  endcase
               end

          end

     end

   //
   // rpDRY
   //  Don't negate rpDRY while rpGO is asserted otherwise it will create a
   //  RHCS1[PGE] error.
   //

   always @(posedge clk or posedge rst)
     begin
        if (rst)
          rpDRY <= 1;
        else
          rpDRY <= !busy | rpGO;
     end

`ifdef RPXX_OPI

   //
   // Diagnostic index pulse.  Triggerd on falling edge of maintenance
   // register signal.
   //

   wire diag_index;
   EDGETRIG uDIAGIND(clk, rst, 1'b1, 1'b0, rpDIND, diag_index);

   //
   // Index pulse counter for testing OPI
   //
   // This should set RPER1[OPI] on the third index pulse in maintenance mode.
   // This is required to pass DSRPA TEST-273.
   //
   // Trace
   //  M7786/SS0/E57
   //  M7786/SS0/E58
   //  M7786/SS0/E53
   //

   reg [1:0] index_cnt;

   always @(posedge clk or posedge rst)
     begin
        if (rst)
          index_cnt <= 0;
        else
          if (rpDMD)
            begin
               if (diag_index)
                 index_cnt <= {index_cnt[0], 1'b1};
            end
          else
            index_cnt <= 0;
     end

   assign rpSETOPI = rpDMD & rpDIND & index_cnt[1];

`else

   assign rpSETOPI = 0;

`endif

   //
   // State Definition
   //

   localparam [2:0] asdfIDLE   = 0,
                    asdfHEADER = 1,
                    asdfDATA   = 2,
                    asdfECC    = 3,
                    asdfGAP    = 4,
                    asdfEBL    = 5;


   //
   // Data envelope, ECC envelope, and end-of-block (ebl)
   // simulation
   //

   reg ebl;
   reg [ 2:0] asdf;
   reg [11:0] bit_cnt;

   always @(posedge clk or posedge rst)
     begin
        if (rst)

          begin
             rpDFE   <= 0;
             rpECE   <= 0;
             ebl     <= 0;
             bit_cnt <= 0;
             asdf    <= asdfIDLE;
          end

        else

          begin

             if (!rpDMD)
               begin
                  rpDFE    <= 0;
                  rpECE    <= 0;
                  ebl      <= 0;
                  bit_cnt  <= 0;
                  asdf     <= asdfIDLE;
               end

             else

               case (asdf)

                 //
                 // Header: 496 bits
                 //

                 asdfHEADER:
                   if (rpDSCK)
                     begin
                        if (bit_cnt == 495)
                          begin
                             bit_cnt <= 0;
                             asdf    <= asdfDATA;
                          end
                        else
                          bit_cnt <= bit_cnt + 1;
                     end

                 //
                 // Data: 4608 bits = 256 words (18-bit mode)
                 //       4096 bits = 256 words (16-bit mode)
                 //

                 asdfDATA:
                   if (rpDSCK)
                     begin
                        rpDFE <= 1;
                        rpECE <= 0;
                        ebl   <= 0;
                        if (( rpFMT22 & (bit_cnt == 4095)) |
                            (!rpFMT22 & (bit_cnt == 4607)))
                          begin
                             bit_cnt <= 0;
                             asdf    <= asdfECC;
                          end
                        else
                          bit_cnt <= bit_cnt + 1;
                     end

                 //
                 // ECC: 32 bits
                 //

                 asdfECC:
                   if (rpDSCK)
                     begin
                        rpDFE <= 0;
                        rpECE <= 1;
                        ebl   <= 0;
                        if (bit_cnt == 31)
                          begin
                             bit_cnt <= 0;
                             asdf    <= asdfGAP;
                          end
                        else
                          bit_cnt <= bit_cnt + 1;
                     end

                 //
                 // Gap: 16 bits.
                 //

                 asdfGAP:
                   if (rpDSCK)
                     begin
                        rpDFE <= 0;
                        rpECE <= 0;
                        ebl   <= 0;
                        if (bit_cnt == 15)
                          begin
                             bit_cnt <= 0;
                             asdf    <= asdfEBL;
                          end
                        else
                          bit_cnt <= bit_cnt + 1;
                     end

                 //
                 // EBL: (after GAP)
                 //

                 asdfEBL:
                   if (rpDSCK)
                     begin
                        rpDFE <= 0;
                        rpECE <= 0;
                        ebl   <= 1;
                     end

                 endcase
          end
     end

   //
   // State decode
   //

   assign rpSDREQ = (state == stateDATA);

endmodule
