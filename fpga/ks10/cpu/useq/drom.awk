################################################################################
##
## KS-10 Processor
##
## Brief
##   Dispatch ROM Parser
##
## Details
##
##   This awk script parses the KS10 Microcode Listing File and extracts the
##   the contents of the Dispatch ROM.
##
## File
##   drom.awk
##
## Author
##   Rob Doyle - doyle (at) cox (dot) net
##
################################################################################
##
## Copyright (C) 2012-2021 Rob Doyle
##
## This source file may be used and distributed without restriction provided
## that this copyright statement is not removed from the file and that any
## derivative work contains the original copyright notice and the associated
## disclaimer.
##
## This source file is free software; you can redistribute it and#or modify it
## under the terms of the GNU Lesser General Public License as published by the
## Free Software Foundation; version 2.1 of the License.
##
## This source is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
## for more details.
##
## You should have received a copy of the GNU Lesser General Public License
## along with this source; if not, download it from
## http://www.gnu.org/licenses/lgpl.txt
##
################################################################################

BEGIN {
    FS="[, ;	]";
    printf "//\n";
    printf "//\n";
    printf "// DROM.DAT\n";
    printf "// This code is extracted from the KS10 microcode listing by an\n";
    printf "// AWK script.   DO NOT EDIT THIS FILE!\n";
    printf "//\n";
    printf "//\n";
    printf "\n";
}

/^D [0-7][0-7][0-7][0-7], / {
     #print $2 " " $4 " " $5 " " $6 
     i        = strtonum("0" $2);
     MAP2[i]  = strtonum("0" $2);
     MAP[4,i] = strtonum("0" $4);
     MAP[5,i] = strtonum("0" $5);
     MAP[6,i] = strtonum("0" $6);
}

 END {
     for (i = 0; i < 512; i++) {
	 if (MAP2[i] == i) {
	     printf "%03x%03x%03x	// DROM[%3d] = 36'o%04o_%04o_%04o;\n", 
		 MAP[4,i], MAP[5,i], MAP[6,i], i, MAP[4,i], MAP[5,i], MAP[6,i]
	 }
     }
}
