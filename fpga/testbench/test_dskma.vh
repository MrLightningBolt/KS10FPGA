
        //
        // DSKMA (DSKMA DECSYSTEM 2020 KMC11 DIAGNOSTICS)
        //

        expects("UBA # - ",                                                    "1\015",     state[ 0]);
        expects("DISK:<DIRECTORY> OR DISK:[P,PN] - ",                          "PS:\015",   state[ 1]);
        expects("SMMON CMD - ",                                                "DSKMA\015", state[ 2]);
        expects("TTY SWITCH CONTROL ? - 0,S OR Y <CR> - ",                     "Y\015",     state[ 3]);
        expects("LH SWITCHES <# OR ?> - ",                                     "100\015",   state[ 4]);
        expects("RH SWITCHES <# OR ?> - ",                                     "0\015",     state[ 5]);
        expects("*",                                                           " 66\015",   state[ 6]);
