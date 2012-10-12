////////////////////////////////////////////////////////////////////
//
// KS-10 Processor
//
// \brief
//      Control ROM (CROM) Definitions
//
// \details
//
// \notes
//
// \file
//      crom.vh
//
// \author
//      Rob Doyle - doyle (at) cox (dot) net
//
////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2009, 2012 Rob Doyle
//
// This source file may be used and distributed without
// restriction provided that this copyright statement is not
// removed from the file and that any derivative work contains
// the original copyright notice and the associated disclaimer.
//
// This source file is free software; you can redistribute it
// and/or modify it under the terms of the GNU Lesser General
// Public License as published by the Free Software Foundation;
// version 2.1 of the License.
//
// This source is distributed in the hope that it will be
// useful, but WITHOUT ANY WARRANTY; without even the implied
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
// PURPOSE. See the GNU Lesser General Public License for more
// details.
//
// You should have received a copy of the GNU Lesser General
// Public License along with this source; if not, download it
// from http://www.gnu.org/licenses/lgpl.txt
//
////////////////////////////////////////////////////////////////////
//
// Comments are formatted for doxygen
//

`define CROM_WIDTH              108             // CROM Width
`define CROM_DATA               "crom.bin"      // CROM Data File

//
// Control ROM Fields
//

`define cromJ                   crom[0:11]      // Jump address

//
// ALU Functions
//  See LSRC and RSRC (below) for definition of R and S
//

`define cromFUN                 crom[12:14]     // ALU Function
`define cromFUN_ADD             3'b000          //  F <- R + S
`define cromFUN_SUBR            3'b001          //  F <- R - S
`define cromFUN_SUBS            3'b010          //  F <- S - R
`define cromFUN_ORRS            3'b011          //  F <- R | S
`define cromFUN_ANDRS           3'b100          //  F <- R & S
`define cromFUN_NOTRS           3'b101          //  F <- ~R & S
`define cromFUN_EXOR            3'b110          //  F <- R ^ S
`define cromFUN_EXNOR           3'b111          //  F <- ~(R ^ S)

//
// ALU Sources (Left and Right)
//

`define cromLSRC                crom[15:17]     // ALU Left Source
`define cromRSRC                crom[18:20]     // ALU Right Source
`define cromSRC_AQ              3'b000          //  R <- A, S <- Q
`define cromSRC_AB              3'b001          //  R <- A, S <- B
`define cromSRC_ZQ              3'b010          //  R <- 0, S <- Q
`define cromSRC_ZB              3'b011          //  R <- 0, S <- B
`define cromSRC_ZA              3'b100          //  R <- 0, S <- A
`define cromSRC_DA              3'b101          //  R <- D, S <- A
`define cromSRC_DQ              3'b110          //  R <- D, S <- Q
`define cromSRC_DZ              3'b111          //  R <- D, S <- 0

//
// ALU Destinations
//  The shift operation are controlled by the cromSPEC_SHSTYLE field
//

`define cromDST                 crom[21:23]     // ALU Destinations
`define cromDST_QREG            3'b000          // RAM <- RAM, Q <- F
`define cromDST_NOP             3'b001          // RAM <- RAM, Q <- Q
`define cromDST_RAMA            3'b010          // RAM <- A, Q <- Q
`define cromDST_RAMF            3'b011          // RAM <- F, Q <- Q
`define cromDST_RAMQD           3'b100          // RAM <- F shifted right, Q <- Q shifted right
`define cromDST_RAMD            3'b101          // RAM <- F shifted right, Q <- Q
`define cromDST_RAMQU           3'b110          // RAM <- F shifted left,  Q <- Q shifted left
`define cromDST_RAMU            3'b111          // RAM <- F shifted left,  Q <- Q

//
// ALU Register Selection
//


`define cromALU_A               crom[26:29]     // ALU A Address
`define cromALU_B               crom[32:35]     // ALU B Address

//
// RAMFILE Address
//

`define cromRAMADR_SEL          crom[36:38]     // RAMFILE address mux
`define cromRAMADR_SEL_AC       3'b000          //  AC
`define cromRAMADR_SEL_xxx      3'b001          //
`define cromRAMADR_SEL_XR       3'b010          //  XR
`define cromRAMADR_SEL_SPARE3   3'b011          //  Not used
`define cromRAMADR_SEL_VMA      3'b100          //  VMA
`define cromRAMADR_SEL_SPARE5   3'b101          //  Not used
`define cromRAMADR_SEL_RAM      3'b110          //
`define cromRAMADR_SEL_NUM      3'b111          //

//
// DBUS
//

`define cromDBUS                crom[40:41]     // DBUS MUX Select
`define cromDBUS_FLAGS          2'b00           //  PC Flags
`define cromDBUS_DP             2'b01           //  Datapath
`define cromDBUS_RAM            2'b10           //  RAM file
`define cromDBUS_DBM            2'b11           //  DBM Mux

//
// DBM
//

`define cromDBM_SEL             crom[42:44]     // DBM Select
`define cromDBM_SEL_SCADPFAPR   3'b000          //  SCAD,PF DISP, APR
`define cromDBM_SEL_BYTES       3'b001          //  BYTES
`define cromDBM_SEL_EXPTIME     3'b010          //  EXP, TIMER
`define cromDBM_SEL_DP          3'b011          //  DP
`define cromDBM_SEL_DPSWAP      3'b100          //  DP swapped
`define cromDBM_SEL_VMA         3'b101          //  VMA flags, VMA
`define cromDBM_SEL_MEM         3'b110          //  Memory bus
`define cromDBM_SEL_NUM         3'b111          //  CROM Number field

//
// Clock enables
//

`define cromCLKL                crom[45]        // ALU Left Clock Enable
`define cromCLKR                crom[48]        // ALU Right Clock Enable

//
// SPEC Field
//

`define cromSPEC                crom[51:56]     // SPEC Fields
`define cromSPEC_EN_40          crom[51]        //  SPEC Select 40
`define cromSPEC_EN_20          crom[52]        //  SPEC Select 20
`define cromSPEC_EN_10          crom[53]        //  SPEC Select 10
`define cromSPEC_SEL            crom[54:56]     //  SPEC Select
`define cromSPEC_SEL_PREVIOUS   3'b000          //   Force Previous Context
`define cromSPEC_SEL_LOADIR     3'b001          //   Load IR
`define cromSPEC_SEL_LOADXR     3'b001          //   Load XR
`define cromSPEC_SEL_CLR1MSEC   3'b001          //   CLR Interval Timer
`define cromSPEC_SEL_LOADPI     3'b011          //   Load PI
`define cromSPEC_SEL_LOADAPR    3'b101          //   Load APR
`define cromSPEC_SEL_LOADNICOND 3'b101          //   Load NICOND
`define cromSPEC_SEL_PXCTEN     3'b110          //   Enable PXCT
`define cromSPEC_SEL_PXCTOFF    3'b110          //   Turn off PXCT
`define cromSPEC_SEL_LOADACBLK  3'b111          //   Load AC Block
`define cromSPEC_SEL_CLRCACHE   3'b100          //   Clear/Sweep cache

`define cromSPEC_SHSTYLE        crom[54:56]     //  Shift Style
`define cromSPEC_SHSTYLE_NORM   3'b000          //   NORMAL
`define cromSPEC_SHSTYLE_ZERO   3'b001          //   ZERO
`define cromSPEC_SHSTYLE_ONES   3'b010          //   ONES
`define cromSPEC_SHSTYLE_ROT    3'b011          //   ROT
`define cromSPEC_SHSTYLE_ASHC   3'b100          //   ASHC
`define cromSPEC_SHSTYLE_LSHC   3'b101          //   LSHC
`define cromSPEC_SHSTYLE_DIV    3'b110          //   DIV
`define cromSPEC_SHSTYLE_ROTC   3'b111          //   ROTC

`define cromSPEC_BYTE           crom[54:56]     // Byte Select

//
// Displacement Select
//

`define cromDISP                crom[57:62]     // DISP Fields
`define cromDISP_EN_40          (~crom[57])     // DISP Select 40 (active low in microcode)
`define cromDISP_EN_20          (~crom[58])     // DISP Select 20 (active low in microcode)
`define cromDISP_EN_10          (~crom[59])     // DISP Select 10 (active low in microcode)
`define cromDISP_SELH           crom[61:62]     // DISP Select (high 4 bits)
`define cromDISP_SEL            crom[60:62]     // DISP Select (low 8 bits)
`define cromDISP_SELH_DIAG      2'b00
`define cromDISP_SELH_RET       2'b01
`define cromDISP_SELH_J         2'b10
`define cromDISP_SELH_AREAD     2'b11
`define cromDISP_SEL_DIAG       3'b000
`define cromDISP_SEL_RET        3'b001
`define cromDISP_SEL_MULTIPLY   3'b010
`define cromDISP_SEL_PAGEFAIL   3'b011
`define cromDISP_SEL_NICOND     3'b100
`define cromDISP_SEL_BYTE       3'b101
`define cromDISP_SEL_EAMODE     3'b110
`define cromDISP_SEL_SCAD       3'b111
`define cromDISP_SEL_ZERO       3'b000
`define cromDISP_SEL_DP18TO21   3'b001
`define cromDISP_SEL_J          3'b010
`define cromDISP_SEL_AREAD      3'b011
`define cromDISP_SEL_NORM       3'b100
`define cromDISP_SEL_DP32TO35   3'b101
`define cromDISP_SEL_DROMA      3'b110
`define cromDISP_SEL_DROMB      3'b111

// Skip Select
`define cromSKIP                crom[63:68]     // SKIP Fields
`define cromSKIP_EN_40          (~crom[63])     // SKIP Select 40 (active low in microcode)
`define cromSKIP_EN_20          (~crom[64])     // SKIP Select 20 (active low in microcode)
`define cromSKIP_EN_10          (~crom[65])     // SKIP Select 10 (active low in microcode)
`define cromSKIP_SEL            crom[66:68]     // SKIP Select

//
//
//

`define cromMEM_CYCLE           crom[76]        // Start/complete a memory or IO cycle using # field

//
// SCAD
//

`define cromSCAD_FUN            crom[90:92]     // SCAD ALU OP
`define cromSCAD_A_PLUS_A       3'b000          //  A + A
`define cromSCAD_A_OR_B         3'b001          //  A | B
`define cromSCAD_A_MINUS_B_1    3'b010          //  A - B - 1
`define cromSCAD_A_MINUS_B      3'b011          //  A - B
`define cromSCAD_A_PLUS_B       3'b100          //  A + B
`define cromSCAD_A_AND_B        3'b101          //  A & B
`define cromSCAD_A_MINUS_1      3'b110          //  A - 1
`define cromSCAD_A              3'b111          //  A

`define cromSCAD_ASEL           crom[93:95]     // SCAD A MUX Select
`define cromSCAD_ASEL_SC        3'b000          //  Step Counter
`define cromSCAD_ASEL_SNUM      3'b001          //  Small Number field
`define cromSCAD_ASEL_PTR44     3'b010          //  044
`define cromSCAD_ASEL_BYTE1     3'b011          //  DP[ 0: 6]
`define cromSCAD_ASEL_BYTE2     3'b100          //  DP[ 7:13]
`define cromSCAD_ASEL_BYTE3     3'b101          //  DP[14:20]
`define cromSCAD_ASEL_BYTE4     3'b110          //  DP[21:28]
`define cromSCAD_ASEL_BYTE5     3'b111          //  DP[28:34]

`define cromSCAD_BSEL           crom[96:97]     // SCAD B MUX Select
`define cromSCAD_BSEL_FE        2'b00           //  FE
`define cromSCAD_BSEL_EXP       2'b01           //  EXP
`define cromSCAD_BSEL_SHIFT     2'b10           //
`define cromSCAD_BSEL_SIZE      2'b11           //  DP[6:11]

//
// Memory Cycle Control
//

`define cromMEM_FORCEUSER       crom[90]        // Force user mode reference
`define cromMEM_FORCEEXEC       crom[91]        // Force exec mode reference
`define cromMEM_FETCHCYCLE      crom[92]        // This is an instruction fetch cycle
`define cromMEM_READCYCLE       crom[93]        // This is a read cycle
`define cromMEM_WRITETEST       crom[94]        // Page Fail if not written
`define cromMEM_WRITECYCLE      crom[95]        // This is a write cycle
`define cromMEM_DONTCACHE       crom[97]        // Don't lock in cache
`define cromMEM_PHYSICAL        crom[98]        // Don't invoke paging hardare
`define cromMEM_PXCTSEL         crom[99:101]    // Which PXCT bits to look at
`define cromMEM_AREAD           crom[102]       // Let DROM select sysle type and VMA load
`define cromMEM_DPFUNC          crom[103]       // Use dp[0:13] instead of cromNUM[0:13]
`define cromMEM_LOADVMA         crom[104]       // Load the VMA
`define cromMEM_EXTADDR         crom[105]       // Put VMA[14:17] Bits onto Bus
`define cromMEM_WAIT            crom[106]       // Start memory or IO cycle
`define cromMEM_BWRITE          crom[107]       // Start memory cycle if DROM asks for it

// These are only defined when cromMEM_DPFUNC (bit 103) is asserted

`define cromMEM_IOCYCLE         crom[100]       // This is an IO cycle
`define cromMEM_WRUCYCLE        crom[101]       // This is a WRU cycle
`define cromMEM_VECTORCYCLE     crom[102]       // This is a read vector interrupt cycle
`define cromMEM_IOBYTECYCLE     crom[103]       // This is a byte cycle

//
//
//

`define cromT                   crom[69:71]     //
`define cromCRY38               crom[72]        //
`define cromLOADSC              crom[73]        // Load Step Counter from SCAD
`define cromLOADFE              crom[74]        // Load FE Register from SCAD
`define cromFMWRITE             crom[75]        // Write to RAM FILE
`define cromDIVIDE              crom[72]        //
`define cromMULTIPREC           crom[78]        //
`define cromMULTISHIFT          crom[79]        //
`define cromCALL                crom[80]        //
`define cromNUM                 crom[90:107]    //
`define cromSTATE               crom[90:107]    //
`define cromSETOV               crom[90]        // Set arithmetic overflow
`define cromSETFOV              crom[91]        // Set floating point overflow
`define cromSETNDV              crom[92]        // Set no divide
`define cromCLRFPD              crom[93]        // Clear first part done
`define cromSETFPD              crom[94]        // Set first part done
`define cromHOLDUSER            crom[95]        //
`define cromSPARE1              crom[96]        // Spare
`define cromTRAP2               crom[97]        // Set trap 2
`define cromTRAP1               crom[98]        // Set trap 1
`define cromSNUM                crom[98:107]    // Small Number field (10-bit) for SCAD
`define cromLDPCU               crom[99]        // Load PCU

//
// Priority Interrupt (PI) bits
//

`define cromPI_ZER              crom[90:92]     // (Not used)
`define cromPI_IP1              crom[93]        // PI 1 in progress
`define cromPI_IP2              crom[94]        // PI 2 in progress (Not used)
`define cromPI_IP3              crom[95]        // PI 3 in progress (Not used)
`define cromPI_IP4              crom[96]        // PI 4 in progress (Not used)
`define cromPI_IP5              crom[97]        // PI 5 in progress (Not used)
`define cromPI_IP6              crom[98]        // PI 6 in progress (Not used)
`define cromPI_IP7              crom[99]        // PI 7 in progress (Not used)
`define cromPI_ON               crom[100]       // PI is on
`define cromPI_CO11             crom[101]       // Chan 1 is on (Not used)
`define cromPI_CO12             crom[102]       // Chan 2 is on (Not used)
`define cromI_CO3               crom[103]       // (Not used)
`define cromI_CO4               crom[104]       // (Not used)
`define cromI_CO5               crom[105]       // (Not used)
`define cromI_CO6               crom[106]       // (Not used)
`define cromI_CO7               crom[107]       // (Not used)

//
//
//

`define cromSPARE2              crom[100]       // Spare
`define cromSPARE3              crom[101]       // Spare
`define cromSPARE4              crom[102]       // Spare
`define cromSPARE5              crom[103]       // Spare
`define cromJFCLFLG             crom[104]       // Do a JFCL instruction
`define cromLDFLAGS             crom[105]       // Load flags from DP
`define cromSPARE6              crom[106]       //
`define cromADFLGS              crom[107]       //

//
//
//

`define cromWORK                crom[98:107]    //

//
//
//

`define cromDT                  crom[109:111]   // Not used
