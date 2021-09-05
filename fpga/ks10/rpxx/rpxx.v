////////////////////////////////////////////////////////////////////////////////
//
// KS-10 Processor
//
// Brief
//   RPxx Style Massbus Disk Drive
//
// Details
//
// Notes
//   Regarding endian-ness:
//     The KS10 backplane bus is 36-bit big-endian and uses [0:35] notation.
//     The IO Device are 36-bit little-endian (after Unibus) and uses [35:0]
//     notation.
//
//     Whereas the 'Unibus' is 18-bit data and 16-bit address, I've implemented
//     the IO bus as 36-bit address and 36-bit data just to keep things simple.
//
// File
//   rpxx.v
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

`default_nettype none
`timescale 1ns/1ps

`include "rpxx.vh"
`include "rpas.vh"
`include "rpda.vh"
`include "rpcc.vh"
`include "rpdc.vh"
`include "rpds.vh"
`include "rpof.vh"
`include "rpmr.vh"
`include "rpcs1.vh"
`include "rper1.vh"
`include "sd/sd.vh"
`include "../rh11/rh11.vh"
`include "../uba/ubabus.vh"

module RPXX (
      input  wire         clk,                  // Clock
      input  wire         rst,                  // Reset
      input  wire         devRESET,             // Device reset
      input  wire [ 0:35] devDATAI,             // Device Data In
      input  wire [ 2: 0] rhUNIT,               // Unit select
      input  wire [ 2: 0] rpNUM,                // Unit number
      input  wire         rpPAT,                // Parity Test
      input  wire         rpMOL,                // Media On-line
      input  wire         rpWRL,                // Write Lock
      input  wire         rpDPR,                // Drive Present
      input  wire         rpINCRSECT,           // Increment Sector
      input  wire [18:35] rpADDR,               // Massbus Address
      input  wire         rpREAD,               // Massbus Read
      input  wire         rpWRITE,              // Massbus Write
      output wire [15: 0] rpCS1,                // CS1 Register
      output wire [15: 0] rpDA,                 // DA  Register
      output wire [15: 0] rpDS,                 // DS  Register
      output wire [15: 0] rpER1,                // ER1 Register
      output wire [15: 0] rpLA,                 // LA  Register
      output wire [15: 0] rpMR,                 // MR  Register
      output wire [15: 0] rpDT,                 // DT  Register
      output wire [15: 0] rpSN,                 // SN  Register
      output wire [15: 0] rpOF,                 // OF  Register
      output wire [15: 0] rpDC,                 // DC  Register
      output wire [15: 0] rpCC,                 // CC  Register
      output wire [15: 0] rpER2,                // ER2 Register
      output wire [15: 0] rpER3,                // ER3 Register
      output wire [15: 0] rpEC1,                // EC1 Register
      output wire [15: 0] rpEC2,                // EC2 Register
      output wire [ 2: 0] rpSDOP,               // SD Operation
      output wire         rpSDREQ,              // SD Request
      input  wire         rpSDACK,              // SD Complete Acknowledge
      output wire [20: 0] rpSDLSA,              // SD Linear Sector Address
      output wire         rpACTIVE              // RP is active
   );

   //
   // RH Parameters
   //

   parameter [15: 0] rpDRVTYP  = `rpRP06;       // Drive type
   parameter [15: 0] rpDRVSN   = `rpSN0;        // Drive serial number

   //
   // Lookup Drive Geometries
   //

   localparam [5:0] rpSECN16 = `getLAST_SECT16(rpDRVTYP);       // Sectors in 16-bit mode
   localparam [5:0] rpSECN18 = `getLAST_SECT18(rpDRVTYP);       // Sectors in 18-bit mode
   localparam [5:0] rpTRKNUM = `getLAST_TRACK(rpDRVTYP);        // Tracks (or surfaces or heads)
   localparam [9:0] rpCYLNUM = `getLAST_CYL (rpDRVTYP);         // Cylinder

   //
   // Addressing
   //

   localparam [18:35] rpADDRCS1 = 18'o776700,                   // Control/Status Register
                      rpADDRDA  = 18'o776706,                   // Disk Address Register
                      rpADDRER1 = 18'o776714,                   // Error Register #1
                      rpADDRAS  = 18'o776716,                   // Attention Summary Register
                      rpADDRMR  = 18'o776724,                   // Maintenance Register
                      rpADDROF  = 18'o776732,                   // Offset Register
                      rpADDRDC  = 18'o776734,                   // Desired Cylinder Register
                      rpADDRER2 = 18'o776740,                   // Error Register #2
                      rpADDRER3 = 18'o776742;                   // Error Register #3

   //
   // Unit select
   //

   wire rpSELECT = (rhUNIT == rpNUM);

   //
   // Register Decode
   //

   wire rpWRCS1 = rpWRITE & (rpADDR == rpADDRCS1) & rpSELECT;   // RPCS1
   wire rpWRDA  = rpWRITE & (rpADDR == rpADDRDA ) & rpSELECT;   // RPDA
   wire rpWRER1 = rpWRITE & (rpADDR == rpADDRER1) & rpSELECT;   // RPER1
   wire rpWRAS  = rpWRITE & (rpADDR == rpADDRAS );              // RPAS
   wire rpWRMR  = rpWRITE & (rpADDR == rpADDRMR ) & rpSELECT;   // RPMR
   wire rpWROF  = rpWRITE & (rpADDR == rpADDROF ) & rpSELECT;   // RPOF
   wire rpWRDC  = rpWRITE & (rpADDR == rpADDRDC ) & rpSELECT;   // RPDC
   wire rpWRER2 = rpWRITE & (rpADDR == rpADDRER2) & rpSELECT;   // RPER1
   wire rpWRER3 = rpWRITE & (rpADDR == rpADDRER3) & rpSELECT;   // RPER2

   //
   // Big-endian to little-endian data bus swap
   //

   wire [35:0] rpDATAI = devDATAI[0:35];

   //
   // Function Decoder
   //
   // Commands are ignored if they have incorrect parity.
   //
   // Trace
   //  M7774/RG4/E60
   //

   wire rpFUN_GO      = rpWRCS1 &                                        `rpCS1_GO(rpDATAI) & !rpPAT;   // Go command
// wire rpFUN_UNLOAD  = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funUNLOAD ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Unload command
   wire rpFUN_SEEK    = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funSEEK   ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Seek command
   wire rpFUN_RECAL   = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funRECAL  ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Recalibrate command
   wire rpFUN_DRVCLR  = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funCLEAR  ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Drive clear command
// wire rpFUN_RELEASE = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funRELEASE) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Release command
// wire rpFUN_OFFSET  = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funOFFSET ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Offset command
   wire rpFUN_CENTER  = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funCENTER ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Return to center command
   wire rpFUN_PRESET  = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funPRESET ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Read-in preset command
   wire rpFUN_PAKACK  = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funPAKACK ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Pack acknowledge command
// wire rpFUN_SEARCH  = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funSEARCH ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Search command
// wire rpFUN_WRCHK   = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funWRCHK  ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Write check command
// wire rpFUN_WRCHKH  = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funWRCHKH ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Write check header command
   wire rpFUN_WRITE   = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funWRITE  ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Write command
   wire rpFUN_WRITEH  = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funWRITEH ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Write header command
// wire rpFUN_READ    = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funREAD   ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Read command
// wire rpFUN_READH   = rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funREADH  ) & `rpCS1_GO(rpDATAI) & !rpPAT;   // Read header command

   //
   // Illegal Function Decoder
   //
   // Commands are ignored if they have incorrect parity.
   //
   // Trace
   //  M7774/RG4/E54
   //  M7774/RG4/E65
   //  M7774/RG4/E78
   //

   wire rpSETILF   = ((rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o12) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o13) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o15) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o16) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o17) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o20) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o21) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o22) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o23) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o26) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o27) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o32) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o33) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o36) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                      (rpWRCS1 & (`rpCS1_FUN(rpDATAI) == 5'o37) & `rpCS1_GO(rpDATAI) & !rpPAT));

   //
   // RPxx Control Status Register #1 (RPCS1)
   //

   wire [5:1] rpFUN = `rpCS1_FUN(rpCS1);

   //
   // RPxx Disk Status Register (RPDS)
   //

   wire rpERR = `rpDS_ERR(rpDS);

   //
   // RPxx Disk Address Register (RPDA)
   //

   wire [5:0] rpSA = `rpDA_SA(rpDA);
   wire [5:0] rpTA = `rpDA_TA(rpDA);

   //
   // RPxx Offset (RPOF) Register
   //

   wire rpFMT22 = `rpOF_FMT22(rpOF);
   wire rpECI   = `rpOF_ECI(rpOF);
   wire rpHCI   = `rpOF_HCI(rpOF);

   //
   // RPxx Desired Cylinder (RPDC) Register
   //

   wire [9:0] rpDCA = `rpDC_DCA(rpDC);

   //
   // RPxx Maintenance (RPMR) Register
   //

   wire rpSBD;                                  // Sync byte detected
   wire rpZD;                                   // Zero detect
   wire rpDWRD;                                 // Diagnostic write data
   wire rpDRDD = `rpMR_DRDD(rpMR);              // Diagnostic read data
   wire rpDSCK = `rpMR_DSCK(rpMR);              // Diagnostic sector clock
   wire rpDIND = `rpMR_DIND(rpMR);              // Diagnostic index pulse
   wire rpDCLK = `rpMR_DCLK(rpMR);              // Diagnostic clock
   wire rpDMD  = `rpMR_DMD(rpMR);               // Diagnostic mode

   //
   // Get number of sectors for this mode.
   //  rpFMT22 is asserted in 16-bit mode.
   //  rpFMT22 is negated in 18-bit mode.  (default)
   //

   wire [5:0] rpSECNUM = rpFMT22 ? rpSECN16 : rpSECN18;

   //
   // Misc signals
   //

   wire rpDRY;                                  // Drive ready
   wire rpPIP;                                  // Positioning in progress
   wire rpECE;                                  // ECC field envelope
   wire rpDFE;                                  // Data field envelope
   wire rpADRSTRT;                              // Start sector address calculation
   wire rpADRBUSY;                              // Busy calculation sector address
   wire rpSETATA;                               // Set attention
   wire rpSETOPI;                               // Set operation incomplete
   wire rpSETDCK;                               // Set data check error
   wire rpSETDTE;                               // Set drive timing error
   wire rpSETSKI;                               // Set seek incomplete
   wire rpSETHCRC;                              // Set header CRC error
   wire rpEBL;                                  // End of block

   //
   // Increment sector
   //
   // The sector is incremented by the SD Card normally but is incremented by the
   // EBL pulse in Diagnostic Mode.
   //

   wire rpINCSECT = rpDMD ? rpEBL : (rpINCRSECT & rpSELECT);

   //
   // Increment cylinder
   //

   wire rpINCCYL  = rpINCSECT & (rpSA == rpSECNUM) & (rpTA == rpTRKNUM);

   //
   // Write lock error
   //
   // Trace
   //  M7773/SN1/E59
   //

   wire rpSETWLE  = ((rpWRL & rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funWRITE ) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                     (rpWRL & rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funWRITEH) & `rpCS1_GO(rpDATAI) & !rpPAT));

   //
   // Invalid address error
   //
   // Asserted when an invalid disk address is selected and a disk operation is
   // executed.
   //
   // Trace
   //  M7786/SS4/E47
   //

   wire rpINVADDR  = (rpSA > rpSECNUM) | (rpTA > rpTRKNUM) | (rpDCA > rpCYLNUM);

   wire rpSETIAE  = ((rpINVADDR & rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funWRITE ) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                     (rpINVADDR & rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funWRITEH) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                     (rpINVADDR & rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funREAD  ) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                     (rpINVADDR & rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funREADH ) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                     (rpINVADDR & rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funWRCHK ) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                     (rpINVADDR & rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funWRCHKH) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                     (rpINVADDR & rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funSEEK  ) & `rpCS1_GO(rpDATAI) & !rpPAT) |
                     (rpINVADDR & rpWRCS1 & (`rpCS1_FUN(rpDATAI) == `funSEARCH) & `rpCS1_GO(rpDATAI) & !rpPAT));

   //
   // Address overflow error
   //
   // The address overflow error occurs during mid-transfer seeks.
   //
   // Trace
   //  M7786/SS4/E47
   //

   wire rpSETAOE  = (rpINCSECT & (rpSA == rpSECNUM) & (rpTA == rpTRKNUM) & (rpDCA == rpCYLNUM));

   //
   // Last sector transferred
   //
   // Trace
   //  M7786/SS4/E68
   //

   wire rpSETLST  = ((rpSA == rpSECNUM) & (rpTA == rpTRKNUM) & (rpDCA == rpCYLNUM));

   //
   // Register Modification Refused
   //
   // Only the RPMR and the RPAS registers can be written during an operation.
   //
   // Trace
   //  M7774/RG6/E29
   //

   wire rpSETRMR  = ((rpWRCS1 & !rpDRY) |
                     (rpWRER1 & !rpDRY) |
                     (rpWROF  & !rpDRY) |
                     (rpWRDA  & !rpDRY) |
                     (rpWRDC  & !rpDRY) |
                     (rpWRER2 & !rpDRY) |
                     (rpWRER3 & !rpDRY));

   //
   // Parity Error
   //
   // Asserted when a register is modified and there is incorrect parity.
   //

   wire rpSETPAR  =  ((rpWRCS1 & rpPAT) |
                      (rpWRER1 & rpPAT) |
                      (rpWRMR  & rpPAT) |
                      (rpWROF  & rpPAT) |
                      (rpWRDA  & rpPAT) |
                      (rpWRDC  & rpPAT) |
                      (rpWRER2 & rpPAT) |
                      (rpWRER3 & rpPAT));

   //
   // Class B errors
   //
   // Note: The header errors are only asserted when performing an operation
   //  that reads the sector header.
   //
   // Trace
   //  M7774/RG0/E4
   //  M7774/RG0/E29
   //  M7774/RG0/E33
   //  M7774/RG0/E46
   //  M7774/RG0/E47
   //  M7776/EC6/E52
   //  M7776/EC7/E80
   //  M7776/EC7/E85
   //  M7776/EC7/E49
   //  M7776/EC7/E59
   //  M7776/EC7/E85
   //  M7776/EC7/E93
   //

   wire rpCLBERR = ((`rpER1_DCK(rpER1)) |
                    (`rpER1_OPI(rpER1)) |
//FIXME             (`rpER1_DTE(rpER1)) |
                    (`rpER1_WLE(rpER1)) |
                    (`rpER1_IAE(rpER1)) |
                    (`rpER1_AOE(rpER1)) |
                    (`rpER1_HCRC(rpER1) & ((rpFUN == `funREADH ) | (rpFUN == `funWRCHKH))) |
                    (`rpER1_HCE(rpER1)  & ((rpFUN == `funREADH ) | (rpFUN == `funWRCHKH))) |
                    (`rpER1_ECH(rpER1)) |
                    (`rpER1_WCF(rpER1)) |
                    (`rpER1_FER(rpER1)  & ((rpFUN == `funREADH ) | (rpFUN == `funWRCHKH))) |
                    (`rpER1_ILF(rpER1)) |
                    (rpER2 != 0) |
                    (rpER3 != 0));

   //
   // Clear attention
   //
   // Trace
   //  M7774/RG3/E41
   //  M7774/RG3/E44
   //  M7774/RG3/E49
   //  M7774/RG3/E54
   //  M7774/RG3/E68
   //  M7787/DP2/E14
   //  M7787/DP2/E57
   //

   wire rpCLRATA = ((rpWRAS & `rpAS_ATA7(rpDATAI) & (rpNUM == 7)) |
                    (rpWRAS & `rpAS_ATA6(rpDATAI) & (rpNUM == 6)) |
                    (rpWRAS & `rpAS_ATA5(rpDATAI) & (rpNUM == 5)) |
                    (rpWRAS & `rpAS_ATA4(rpDATAI) & (rpNUM == 4)) |
                    (rpWRAS & `rpAS_ATA3(rpDATAI) & (rpNUM == 3)) |
                    (rpWRAS & `rpAS_ATA2(rpDATAI) & (rpNUM == 2)) |
                    (rpWRAS & `rpAS_ATA1(rpDATAI) & (rpNUM == 1)) |
                    (rpWRAS & `rpAS_ATA0(rpDATAI) & (rpNUM == 0)) |
                    (rpFUN_GO & !rpERR));

   //
   // RPxx Control/Status Register (RPCS1)
   //

   RPCS1 CS1 (
      .clk         (clk),
      .rst         (rst),
      .rpDATAI     (rpDATAI),
      .rpWRCS1     (rpWRCS1),
      .rpDRY       (rpDRY),
      .rpCS1       (rpCS1)
   );

   //
   // RPxx Disk Address Register (RPDA)
   //

   RPDA DA (
      .clk         (clk),
      .rst         (rst),
      .rpDATAI     (rpDATAI),
      .rpWRDA      (rpWRDA),
      .rpPRESET    (rpFUN_PRESET),
      .rpSECNUM    (rpSECNUM),
      .rpTRKNUM    (rpTRKNUM),
      .rpINCSECT   (rpINCSECT),
      .rpDRY       (rpDRY),
      .rpDA        (rpDA)
   );

   //
   // RPxx Disk Status Register (RPDS)
   //

   RPDS DS (
      .clk         (clk),
      .rst         (rst),
      .devRESET    (devRESET),
      .rpCLRATA    (rpCLRATA),
      .rpCLRLST    (rpWRDA),
      .rpSETLST    (rpSETLST),
      .rpSETATA    (rpSETATA),
      .rpGO        (rpFUN_GO),
      .rpMOL       (rpMOL),
      .rpWRL       (rpWRL),
      .rpDPR       (rpDPR),
      .rpPIP       (rpPIP),
      .rpDRY       (rpDRY),
      .rpDRVCLR    (rpFUN_DRVCLR),
      .rpPRESET    (rpFUN_PRESET),
      .rpPAKACK    (rpFUN_PAKACK),
      .rpER1       (rpER1),
      .rpER2       (rpER2),
      .rpER3       (rpER3),
      .rpDS        (rpDS)
   );

   //
   // RPxx Error #1 (RPER1) Register
   //

   RPER1 ER1 (
      .clk         (clk),
      .rst         (rst),
      .devRESET    (devRESET),
      .rpDRVCLR    (rpFUN_DRVCLR),
      .rpSETDCK    (rpSETDCK),
      .rpSETOPI    (rpSETOPI),
      .rpSETDTE    (rpSETDTE),
      .rpSETWLE    (rpSETWLE),
      .rpSETIAE    (rpSETIAE),
      .rpSETAOE    (rpSETAOE),
      .rpSETPAR    (rpSETPAR),
      .rpSETRMR    (rpSETRMR),
      .rpSETILF    (rpSETILF),
      .rpSETHCRC   (rpSETHCRC),
      .rpDATAI     (rpDATAI),
      .rpWRER1     (rpWRER1),
      .rpHCI       (rpHCI),
      .rpDRY       (rpDRY),
      .rpER1       (rpER1)
   );

   //
   // RPxx Look Ahead (RPLA) Register
   //

   RPLA LA (
      .clk         (clk),
      .rst         (rst),
      .rpDSCK      (rpDSCK),
      .rpDIND      (rpDIND),
      .rpDMD       (rpDMD),
      .rpSECNUM    (rpSECNUM),
      .rpSA        (rpSA),
      .rpLA        (rpLA)
   );

   //
   // RPxx Offset (RPOF) Register
   //

   RPOF OF (
      .clk         (clk),
      .rst         (rst),
      .devRESET    (devRESET),
      .rpCENTER    (rpFUN_CENTER),
      .rpPRESET    (rpFUN_PRESET),
      .rpSEEK      (rpFUN_SEEK),
      .rpWRITE     (rpFUN_WRITE),
      .rpWRITEH    (rpFUN_WRITEH),
      .rpDATAI     (rpDATAI),
      .rpWROF      (rpWROF),
      .rpDRY       (rpDRY),
      .rpOF        (rpOF)
   );

   //
   // RPxx Desired Cylinder (RPDC) Register
   //

   RPDC DC (
      .clk         (clk),
      .rst         (rst),
      .rpDATAI     (rpDATAI),
      .rpPRESET    (rpFUN_PRESET),
      .rpRECAL     (rpFUN_RECAL),
      .rpWRDC      (rpWRDC),
      .rpINCCYL    (rpINCCYL),
      .rpDRY       (rpDRY),
      .rpDC        (rpDC)
   );

   //
   // RPxx Maintenaince (RPMR) Register
   //

   RPMR MR (
      .clk         (clk),
      .rst         (rst),
      .devRESET    (devRESET),
      .rpDRVCLR    (rpFUN_DRVCLR),
      .rpDATAI     (rpDATAI),
      .rpWRMR      (rpWRMR),
      .rpDRY       (rpDRY),
      .rpSBD       (rpSBD),
      .rpZD        (rpZD),
      .rpDFE       (rpDFE),
      .rpECE       (rpECE),
      .rpDWRD      (rpDWRD),
      .rpMR        (rpMR)
   );

   //
   // RPxx Error Status #2 (RPER2) Register
   //

   RPER2 ER2 (
      .clk         (clk),
      .rst         (rst),
      .devRESET    (devRESET),
      .rpDRVCLR    (rpFUN_DRVCLR),
      .rpDATAI     (rpDATAI),
      .rpWRER2     (rpWRER2),
      .rpDRY       (rpDRY),
      .rpER2       (rpER2)
   );

   //
   // RPxx Error Status #3 (RPER3) Register
   //

   RPER3 ER3 (
      .clk         (clk),
      .rst         (rst),
      .devRESET    (devRESET),
      .rpDRVCLR    (rpFUN_DRVCLR),
      .rpSETSKI    (rpSETSKI),
      .rpDATAI     (rpDATAI),
      .rpWRER3     (rpWRER3),
      .rpDRY       (rpDRY),
      .rpER3       (rpER3)
   );

   //
   // Linear sector address calculation
   //

   RPADDR ADDR (
      .clk         (clk),
      .rst         (rst),
      .rpTRKNUM    (rpTRKNUM),
      .rpSECNUM    (rpSECNUM),
      .rpDCA       (rpDCA),
      .rpTA        (rpTA),
      .rpSA        (rpSA),
      .rpSDLSA     (rpSDLSA),
      .rpADRSTRT   (rpADRSTRT),
      .rpADRBUSY   (rpADRBUSY)
   );

   //
   // Controller state machine
   //

   RPCTRL CTRL (
      .clk         (clk),
      .rst         (rst),
      .devRESET    (devRESET),
      .rpGO        (rpFUN_GO),
      .rpFUN       (rpFUN),
      .rpCYLNUM    (rpCYLNUM),
      .rpCC        (rpCC),
      .rpDA        (rpDA),
      .rpDC        (rpDC),
      .rpLA        (rpLA),
      .rpDMD       (rpDMD),
      .rpDCLK      (rpDCLK),
      .rpDSCK      (rpDSCK),
      .rpDIND      (rpDIND),
      .rpDRDD      (rpDRDD),
      .rpDWRD      (rpDWRD),
      .rpDFE       (rpDFE),
      .rpSBD       (rpSBD),
      .rpZD        (rpZD),
      .rpDRY       (rpDRY),
      .rpEBL       (rpEBL),
      .rpECE       (rpECE),
      .rpECI       (rpECI),
      .rpFMT22     (rpFMT22),
      .rpPAT       (rpPAT),
      .rpPIP       (rpPIP),
      .rpCLBERR    (rpCLBERR),
      .rpSETAOE    (rpSETAOE),
      .rpSETATA    (rpSETATA),
      .rpSETDCK    (rpSETDCK),
      .rpSETDTE    (rpSETDTE),
      .rpSETOPI    (rpSETOPI),
      .rpSETSKI    (rpSETSKI),
      .rpSETWLE    (rpSETWLE),
      .rpSETHCRC   (rpSETHCRC),
      .rpADRSTRT   (rpADRSTRT),
      .rpADRBUSY   (rpADRBUSY),
      .rpSDOP      (rpSDOP),
      .rpSDREQ     (rpSDREQ),
      .rpSDACK     (rpSDACK),
      .rpACTIVE    (rpACTIVE)
   );

   //
   // Fixups
   //

   assign rpDT  = rpDRVTYP;
   assign rpSN  = rpDRVSN;
   assign rpEC1 = 16'b0;
   assign rpEC2 = 16'b0;

endmodule
