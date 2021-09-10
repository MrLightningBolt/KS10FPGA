////////////////////////////////////////////////////////////////////////////////
//
// KS-10 Processor
//
// Brief
//   MT Maintenance Register (MTMR)
//
// File
//   mtmr.v
//
// Author
//   Rob Doyle - doyle (at) cox (dot) net
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2012-2021 Rob Doyle
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

`timescale 1ns/1ps
`default_nettype none

`include "mtmr.vh"

module MTMR (
      input  wire          clk,                 // Clock
      input  wire          rst,                 // Reset
      input  wire  [35: 0] mtDATAI,             // RH Data In
      input  wire          mtmrWRITE,           // Write to MR
      output logic [15: 0] mtMR                 // mtMR Output
   );

   //
   // MTMR Maintenance Data Field (MDF)
   //

   logic [8:0] mrMDF;

   always_ff @(posedge clk)
     begin
        if (rst)
          mrMDF <= 0;
        else if (mtmrWRITE)
          mrMDF <= `mtMR_MDF(mtDATAI);
     end

   //
   // MTMR BPI Clock (BPICLK)
   //

   wire mrBPICLK = 0;

   //
   // MTMR Maintenance Clock (MC)
   //

   wire mrMC = 0;

   //
   // MTMR Maintenance Opcode (MOP)
   //

   logic [3:0] mrMOP;

   always_ff @(posedge clk)
     begin
        if (rst)
          mrMOP <= 0;
        else if (mtmrWRITE)
          mrMOP <= `mtMR_MOP(mtDATAI);
     end

   //
   // MTMR Maintenance Mode (MM)
   //

   logic mrMM;

   always_ff @(posedge clk)
     begin
        if (rst)
          mrMM <= 0;
        else if (mtmrWRITE)
          mrMM <= `mtMR_MM(mtDATAI);
     end

   //
   // Build MR Register
   //

   assign mtMR = {mrMDF, mrBPICLK, mrMC, mrMOP, mrMM};

endmodule
