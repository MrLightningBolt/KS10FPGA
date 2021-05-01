################################################################################
##
## KS-10 Processor
##
## Brief
##   This AWK script reads a DEC listing file and extracts the object code.
##
## Details
##   This script is used to initialize 36-bit SSRAM for simulation.
##
## File
##   ssram36.awk
##
## Author
##   Rob Doyle - doyle (at) cox (dot) net
##
################################################################################
##
## Copyright (C) 2012-2020 Rob Doyle
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

#
# Max function
#

function max(a, b) {
    return (a < b) ? b : a;
}

#
# Start
#

BEGIN {
    FS="[	]";
    printf "/*\n";
    printf " * " filename "\n";
    printf " * Do not edit this file.  It was created by an awk script as part of the build\n"
    printf " * process.\n"
    printf " *\n";
    printf " */\n";
    printf "\n";
    lastaddr = 0;
}

#
# Pointers
#
#  These looks like:
#
#" xxx  xxxxxx  xx xx x xx xxxxxx

/^.*\t[0-7][0-7][0-7][0-7][0-7][0-7]\t[0-7][0-7] [0-7][0-7] [0-7] [0-7][0-7] [0-7][0-7][0-7][0-7][0-7][0-7].*/ {
    data1 = lshift(strtonum("0" substr($3,  1, 2)), 30);
    data2 = lshift(strtonum("0" substr($3,  4, 2)), 24);
    data3 = lshift(strtonum("0" substr($3,  7, 1)), 22);
    data4 = lshift(strtonum("0" substr($3,  9, 2)), 18);
    data5 = lshift(strtonum("0" substr($3, 12, 6)), 0);
    data  = sprintf("%012o", data1 + data2 + data3 + data4 + data5);
    i = strtonum("0" $2)
    lastaddr = max(lastaddr, i);
    if ((map[i] != "") && (map[i] != data)) {
        printf("// Address %6o modified.  Was %012o, is %012o.\n", i, map[i], data);
    }
    map[i] = data;
}

#
# IO Instructions
#
#  These looks like:
#
#" xxx  xxxxxx  7 xxx xx x xx xxxxxx

/^.*\t[0-7][0-7][0-7][0-7][0-7][0-7]\t[0-7] [0-7][0-7][0-7] [0-7][0-7] [0-7] [0-7][0-7] [0-7][0-7][0-7][0-7][0-7][0-7].*/ {
    data1 = lshift(strtonum("0" substr($3,  1, 1)), 33);
    data2 = lshift(strtonum("0" substr($3,  3, 3)), 24);
    data3 = lshift(strtonum("0" substr($3,  7, 2)), 21);
    data4 = lshift(strtonum("0" substr($3, 10, 1)), 22);
    data5 = lshift(strtonum("0" substr($3, 12, 2)), 18);
    data6 = lshift(strtonum("0" substr($3, 15, 6)),  0);
    data  = sprintf("%012o", data1 + data2 + data3 + data4 + data5 + data6);
    i = strtonum("0" $2)
    lastaddr = max(lastaddr, i);
    if ((map[i] != "") && (map[i] != data)) {
        printf("// Address %6o modified.  Was %012o, is %012o.\n", i, map[i], data);
    }
    map[i] = data;
}

#
# IO Instructions
#
#  These looks like:
#
#" xxx  xxxxxx  7 xxx x x xx xxxxxx
/^.*\t[0-7][0-7][0-7][0-7][0-7][0-7]\t[0-7] [0-7][0-7][0-7] [0-7] [0-7] [0-7][0-7] [0-7][0-7][0-7][0-7][0-7][0-7].*/ {
    data1 = lshift(strtonum("0" substr($3,  1, 1)), 33);
    data2 = lshift(strtonum("0" substr($3,  3, 3)), 24);
    data3 = lshift(strtonum("0" substr($3,  7, 1)), 23);
    data4 = lshift(strtonum("0" substr($3,  9, 1)), 22);
    data5 = lshift(strtonum("0" substr($3, 11, 2)), 18);
    data6 = lshift(strtonum("0" substr($3, 14, 6)),  0);
    data  = sprintf("%012o", data1 + data2 + data3 + data4 + data5 + data6);
    i = strtonum("0" $2)
    lastaddr = max(lastaddr, i);
    if ((map[i] != "") && (map[i] != data)) {
        printf("// Address %6o modified.  Was %012o, is %012o.\n", i, map[i], data);
    }
    map[i] = data;
}

#
# CONO Instructions
#
#  These looks like:
#
#" xxx  xxxxxx  xxx xx xx xx xxxxxx

/^.*\t[0-7][0-7][0-7][0-7][0-7][0-7]\t[0-7][0-7][0-7] [0-7][0-7] [0-7][0-7] [0-7][0-7] [0-7][0-7][0-7][0-7][0-7][0-7].*/ {
    data1 = lshift(strtonum("0" substr($3,  1, 3)), 27);
    data2 = lshift(strtonum("0" substr($3,  5, 2)), 21)
    data3 = lshift(strtonum("0" substr($3,  8, 2)), 20);
    data4 = lshift(strtonum("0" substr($3, 11, 2)), 18);
    data5 = lshift(strtonum("0" substr($3, 14, 6)),  0);
    data  = sprintf("%012o", data1 + data2 + data3 + data4 + data5);
    i = strtonum("0" $2)
    lastaddr = max(lastaddr, i);
    if ((map[i] != "") && (map[i] != data)) {
        printf("// Address %6o modified.  Was %012o, is %012o.\n", i, map[i], data);
    }
    map[i] = data;
}

#
# Sixbit
#  6x 6-bit characters span the 36-bit word
#
#  These looks like:
#
#" xxx  aaaaaa  dd dd dd dd dd dd "
#

/^.*\t[0-7][0-7][0-7][0-7][0-7][0-7]\t[0-7][0-7] [0-7][0-7] [0-7][0-7] [0-7][0-7] [0-7][0-7] [0-7][0-7].*/ {
    data1 = substr($3,  1, 2);
    data2 = substr($3,  4, 2);
    data3 = substr($3,  7, 2);
    data4 = substr($3, 10, 2);
    data5 = substr($3, 13, 2);
    data6 = substr($3, 16, 2);
    data  = sprintf("%012o", strtonum("0" data1 data2 data3 data4 data5 data6));
    i = strtonum("0" $2)
    lastaddr = max(lastaddr, i);
    if ((map[i] != "") && (map[i] != data)) {
        printf("// Address %6o modified.  Was %s, is %s.\n", i, map[i], data);
    }
    map[i] = data;
}

#
# ASCII
#  5x 7-bit characters are left justified in the 36-bit word.
#
#  These looks like:
#
#" xxx  aaaaaa  ddd ddd ddd ddd ddd "
#

/^.*\t[0-7][0-7][0-7][0-7][0-7][0-7]\t[0-7][0-7][0-7] [0-7][0-7][0-7] [0-7][0-7][0-7] [0-7][0-7][0-7] [0-7][0-7][0-7].*/ {
    data1 = lshift(and(strtonum("0" substr($3,  1, 3)), 0177), 29)
    data2 = lshift(and(strtonum("0" substr($3,  5, 3)), 0177), 22)
    data3 = lshift(and(strtonum("0" substr($3,  9, 3)), 0177), 15)
    data4 = lshift(and(strtonum("0" substr($3, 13, 3)), 0177),  8)
    data5 = lshift(and(strtonum("0" substr($3, 17, 3)), 0177),  1)
    data  = sprintf("%012o", data1 + data2 + data3 + data4 + data5);
    i = strtonum("0" $2)
    lastaddr = max(lastaddr, i);
    if ((map[i] != "") && (map[i] != data)) {
        printf("// Address %6o modified.  Was %s, is %s.\n", i, map[i], data)
    }
    map[i] = data
}

#
# BYTE
#  1x 8-bit byte is left justified in the 36-bit word.
#
#  These looks like:
#
#" xxx  aaaaaa  ddd 0000000000 "
#

/^.*\t[0-7][0-7][0-7][0-7][0-7][0-7]\t[0-7][0-7][0-7] 0000000000.*/ {
    data1 = lshift(and(strtonum("0" substr($3,  1, 3)), 0377), 29);
    data = sprintf("%012o", data1)
    i = strtonum("0" $2)
    lastaddr = max(lastaddr, i);
    if ((map[i] != "") && (map[i] != data)) {
        printf("// Address %6o modified.  Was %s, is %s.\n", i, map[i], data);
    }
    map[i] = data;
}

#
# Byte 2
#" 4800 006727  005 033 00000000        INIMSG: BYTE (7)        5,33            ;^E, ALTMODE
#
# See DSQDA
#

/^.*\t[0-7][0-7][0-7][0-7][0-7][0-7]\t[0-7][0-7][0-7] [0-7][0-7][0-7] [0-7][0-7][0-7][0-7][0-7][0-7][0-7][0-7].*/ {
    data1 = lshift(strtonum("0" substr($3,  1, 3)), 29);
    data2 = lshift(strtonum("0" substr($3,  5, 3)), 22);
    data  = sprintf("%012o", data1 + data2);
    i = strtonum("0" $2)
    lastaddr = max(lastaddr, i);
    if ((map[i] != "") && (map[i] != data)) {
        printf("// Address %6o modified.  Was %012o, is %012o.\n", i, map[i], data);
    }
    map[i] = data
}

# Bytes
#" 2791 023352  0 117 124 0 123 120     "
#
# See DSQDC
#

/^.*\t[0-7][0-7][0-7][0-7][0-7][0-7]\t[0-7] [0-7][0-7][0-7] [0-7][0-7][0-7] [0-7] [0-7][0-7][0-7] [0-7][0-7][0-7].*/ {
    data1 = lshift(strtonum("0" substr($3,  1, 1)), 34);
    data2 = lshift(strtonum("0" substr($3,  3, 3)), 26);
    data3 = lshift(strtonum("0" substr($3,  7, 3)), 18);
    data4 = lshift(strtonum("0" substr($3, 11, 1)), 16);
    data5 = lshift(strtonum("0" substr($3, 13, 3)),  8);
    data6 = lshift(strtonum("0" substr($3, 17, 3)),  0);
    data  = sprintf("%012o", data1 + data2 + data3 + data4 + data5 + data6);
    i = strtonum("0" $2)
    lastaddr = max(lastaddr, i);
    if ((map[i] != "") && (map[i] != data)) {
        printf("// Address %6o modified.  Was %012o, is %012o.\n", i, map[i], data);
    }
    map[i] = data

}

#
# OPCODES
#
#  These looks like:
#
#" xxx  aaaaaa  ddd dd d dd dddddd "
#

/^.*\t[0-7][0-7][0-7][0-7][0-7][0-7]\t[0-7][0-7][0-7] [0-7][0-7] [0-7] [0-7][0-7] [0-7][0-7][0-7][0-7][0-7][0-7].*/ {
    data1 = lshift(strtonum("0" substr($3,  1, 3)), 27);
    data2 = lshift(strtonum("0" substr($3,  5, 2)), 23);
    data3 = lshift(strtonum("0" substr($3,  8, 1)), 22);
    data4 = lshift(strtonum("0" substr($3, 10, 2)), 18);
    data5 = lshift(strtonum("0" substr($3, 13, 6)),  0);
    data  = sprintf("%012o", data1 + data2 + data3 + data4 + data5);
    i = strtonum("0" $2)
    lastaddr = max(lastaddr, i);
    if ((map[i] != "") && (map[i] != data)) {
        printf("// Address %6o modified.  Was %s, is %s.\n", i, map[i], data);
    }
    map[i] = data
}

#
# Definitions
#
#  These looks like:
#
#" xxx  aaaaaa  dddddd  dddddd "
#

/^.*\t[0-7][0-7][0-7][0-7][0-7][0-7]\t[0-7][0-7][0-7][0-7][0-7][0-7]\t[0-7][0-7][0-7][0-7][0-7][0-7].*/ {
    i = strtonum("0" $2);
    data  = sprintf("%012o", strtonum("0" ($3 $4)));
    lastaddr = max(lastaddr, i);
    if ((map[i] != "") && (map[i] != data)) {
        printf("// Address %6o modified.  Was %s, is %s.\n", i, map[i], data);
    }
    map[i] = data
}

#
# Write 36-bit sorted output to file
#

END {
   prevaddr = 0;
   for (addr = 0; addr <= lastaddr; addr++) {
       if (map[addr] != "") {
           data = strtonum("0" map[addr]);
           if (addr != prevaddr + 1) {
               printf "@%x\n", addr;
           }
           printf "%09x\t\t// mem[%06o] = %012o\n", data, addr, data;
           prevaddr = addr;
       } else {
           printf "%09x\t\t// mem[%06o] = %012o (init)\n", 0, addr, 0;
           prevaddr = addr;
       }
   }
}
