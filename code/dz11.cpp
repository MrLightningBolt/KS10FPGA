//******************************************************************************
//
//  KS10 Console Microcontroller
//
//! \brief
//!    DZ11 Interface Object
//!
//! \details
//!    This object allows the console to interact with the DZ11 Terminal
//!    Multiplexer.   This is mostly for testing the DZ11 from the console.
//!
//! \file
//!    dz11.cpp
//!
//! \author
//!    Rob Doyle - doyle (at) cox (dot) net
//
//******************************************************************************
//
// Copyright (C) 2013-2022 Rob Doyle
//
// This file is part of the KS10 FPGA Project
//
// The KS10 FPGA project is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option) any
// later version.
//
// The KS10 FPGA project is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with
// this software.  If not, see <http://www.gnu.org/licenses/>.
//
//******************************************************************************
//

#include "stdio.h"
#include "uba.hpp"
#include "dz11.hpp"
#include "config.hpp"

//!
//! \brief
//!    Configuration file name
//!

static const char *cfg_file = ".ks10/dz11.cfg";

//!
//! \brief
//!    Recall the non-volatile DZ configuration from file
//!

void dz11_t::recallConfig(void) {
    if (!config_t::read(cfg_file, &cfg, sizeof(cfg))) {
        printf("KS10: Unable to read \"%s\".  Using defaults.\n", cfg_file);
        // Set CO[7:0], negate RI[7:0]
        cfg.dzccr = 0x0000ff00;
    }
    // Initialize the LP Console Control Register
    ks10_t::writeDZCCR(cfg.dzccr);
}

//!
//! \brief
//!    Save the non-volatile DZ configuration to file
//!

void dz11_t::saveConfig(void) {
    cfg.dzccr = ks10_t::readDZCCR();
    if (config_t::write(cfg_file, &cfg, sizeof(cfg))) {
        printf("      dz: sucessfully wrote configuration file \"%s\".\n", cfg_file);
    }
}

//!
//! \brief
//!    Dump DZ11 registers
//!

void dz11_t::dumpRegs(void) {

    printf("KS10: Register Dump\n"
           "      UBAS : %012llo\n"
           "      CSR  : %06o\n"
           "      TCR  : %06o\n"
           "      MSR  : %06o\n"
           "      DZCCR: 0x%08x\n",
           uba.readCSR(),
           ks10_t::readIO16(addrCSR),
           ks10_t::readIO16(addrTCR),
           ks10_t::readIO16(addrMSR),
           ks10_t::readDZCCR());
}


//!
//! \brief
//!    Setup a DZ11 line
//!
//! \param line -
//!    line number
//!

void dz11_t::setup(unsigned int line) {

    //
    // Assert Device Clear
    //

    ks10_t::writeIO(addrCSR, DZCSR_CLR);

    //
    // Wait for Device Clear to negate.  This takes about 15 uS.
    //

    while (ks10_t::readIO(addrCSR) & DZCSR_CLR) {
        ;
    }

    //
    // Configure Line Parameter Register for 9600,N,8,1
    //

    ks10_t::writeIO(addrLPR, 0x1e18 | line);

    //
    // Enable selected line
    //

    ks10_t::writeIO(addrTCR, (1 << line));

    //
    // Enable Master Scan Enable
    //

    ks10_t::writeIO(addrCSR, DZCSR_MSE);
}

//!
//! \brief
//!    Print a test message on the selected DZ11 output
//!
//! \param line
//!    ASCII line number
//!

void dz11_t::testTX(int line) {

    //
    // Initialize the DZ11 for this line
    //

    setup(line & 0x0007);

    //
    // Print test message
    //

    char testmsg[] = "This is a test on DZ11 line ?.\r\n";
    testmsg[28] = line;
    char *s = testmsg;

    while (*s != 0) {

        //
        // Wait for Transmitter Ready (TRDY) to be asserted.
        //

        while ((ks10_t::readIO(addrCSR) & DZCSR_TRDY) == 0) {
            ;
        }

        //
        // Output character to Transmitter Data Register
        //

        ks10_t::writeIO(addrTDR, *s++);
    }
}

//!
//! \brief
//!    Echo the selected TTY input to the console.
//!
//! \param line
//!    ASCII line number
//!

void dz11_t::testRX(int line) {

    printf("Characters typed on TTY%c should echo on the console. ^C to exit.\n", line);

    //
    // Initialize the DZ11 for this line
    //

    setup(line & 0x0007);

    //
    // Test receiver
    //

    for (;;) {

        //
        // Wait for Receiver Done (RDONE) to be asserted.
        //

        if (ks10_t::readIO(addrCSR) & DZCSR_RDONE) {

            //
            // Wait for Transmitter Ready (TRDY) to be asserted
            //

            while (!(ks10_t::readIO(addrCSR) & DZCSR_TRDY)) {
                ;
            }

            //
            // Read character from Receiver Buffer (RBUF)
            //

            char ch = ks10_t::readIO(addrRBUF) & 0xff;

            //
            // Abort on CTRL-C
            //

            if (ch == 3) {
                return;
            }

            printf("%c", ch);
            fflush(stdout);
        }
    }
}

//!
//! \brief
//!    Echo the selected TTY input to the back to the TTY output.
//!
//! \param line
//!    ASCII line number
//!

void dz11_t::testECHO(int line) {

    printf("Characters typed on TTY%c should echo. ^C to exit.\n", line);

    //
    // Initialize the DZ11 for this line
    //

    setup(line & 0x0007);

    //
    // Test echo
    //

    for (;;) {

        //
        // Wait for Receiver Done (RDONE) to be asserted.
        //

        if (ks10_t::readIO(addrCSR) & DZCSR_RDONE) {

            //
            // Wait for Transmitter Ready (TRDY) to be asserted
            //

            while (!(ks10_t::readIO(addrCSR) & DZCSR_TRDY)) {
                ;
            }

            //
            // Read character from Receiver Buffer (RBUF)
            //

            char ch = ks10_t::readIO(addrRBUF) & 0xff;

            //
            // Abort on CTRL-C
            //

            if (ch == 3) {
                return;
            }

            //
            // Echo character to Transmitter Data Register (TDR)
            //

            ks10_t::writeIO(addrTDR, ch);

        }
    }
}
