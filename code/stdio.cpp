
#include <stdarg.h>
#include <stdint.h>
#include <string.h>

#include "stdio.h"
#include "uart.h"

static const char *upper_digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
static const char *lower_digits = "0123456789abcdefghijklmnopqrstuvwxyz";

//!
//! \brief
//!     This function gets a character from the UART receiver.
//!
//! \returns
//!     Character read from UART receiver.
//!

char getchar(void) {
    return getUART();
}

//!
//! \brief
//!     This function outputs a character to the UART transmitter.
//!
//! \param ch
//!     Character to output to UART transmitter.
//!
//! \details
//!     This function expands newlines to CR, LF sequences.
//!
//! \returns
//!     None.
//!

void putchar(char ch) {
    if (ch == '\n') {
        putUART('\r');
    }
    putUART(ch);
}

//!
//! \brief
//!    Outputs a string to the UART transmitter.
//!
//! \param s
//!     null terminated string to print.
//!
//! \details
//!     This function outputs a string to the UART transmitter
//!     and expands newlines to CR, LF sequences.
//!
//! \returns
//!     None.
//!

void puts(const char *s) {
    while (*s) {
        putchar(*s++);
    }
}

//!
//! \brief
//!     This function gets a string from the UART receiver.
//!
//! \param [in] buf
//!     buffer to place input characters
//!
//! \param [in] len
//!     buffer length
//!
//! \details
//!     This function buffers a line of characters.
//!
//! \notes
//!     Backspace is handled.
//!
//! \returns
//!     None.
//!

char *fgets(char *buf, unsigned int len) {
    unsigned int i;
    for (i = 0; i < len - 1; ) {
        char ch = getchar();
        switch (ch) {
            case '\r':
                buf[i] = '\0';
                return buf;
            case '\n':
                break;
            case 0x7f:
                if (i > 0) {
                    i -= 1;
                    putchar(ch);
                }
                break;
            default:
                buf[i++] = ch;
                putchar(ch);
        }
    }
    buf[i] = '\0';
    return buf;
}

//
// Unsigned to ascii
//

static char *__utoa(unsigned int value, char * buffer, unsigned int radix, const char * digits)  {
    if (value / radix) {
        buffer = __utoa(value / radix, buffer, radix, digits);
    }
    *buffer++ = digits[value % radix];
    *buffer   = 0;
    return buffer;
}

//
// Unsigned long to ascii
//

static char *__ultoa(unsigned long value, char * buffer, unsigned int radix, const char * digits) {
    if (value / radix) {
        buffer = __ultoa(value / radix, buffer, radix, digits);
    }
    *buffer++ = digits[value % radix];
    *buffer   = 0;
    return buffer;
}

//
// Unsigned long long to ascii
//
// This is especially hacked to work on octal and hex numbers.  These don't
// require long long division - just shifts.  long long division requires a
// a lot of support from the run time library.   Adding decimal number requires
// lots more code and it won't be used.
//

char *__ulltoa(unsigned long long value, char * buffer, unsigned int radix, const char * digits) {
#if 1
    unsigned int shift;
    unsigned long long mask;
    if (radix == 16) {
        shift = 4;
        mask  = 15ull;
    } else if (radix == 8) {
        shift = 3;
        mask  = 7ull;
    } else {
        strcpy(buffer, "Not implemented");
        return buffer;
    }
    if (value >> shift) {
        buffer = __ulltoa(value >> shift, buffer, radix, digits);
    }
    *buffer++ = digits[value & mask];
    *buffer   = 0;
    return buffer;
#else
    unsigned int shift;
    unsigned long long mask;
    if (radix == 16) {
        shift = 4;
        mask  = 15;
    } else if (radix == 8) {
        shift = 3;
        mask = 7;
    } else {
        buffer = (char*)"Not implemented\n";
        return buffer;
    }

    int i;
    for (i = 0; (i < 63) && (mask < value); i += shift, mask <<= shift) {
        ;
    }

    if (((value & mask) >> i) == 0) {
        i -= shift;
        mask >>= shift;
    }

    for (int j = i; j > -1; j -= shift, mask >>= shift) {
        char dgt = (value & mask) >> j;
        *buffer++ = dgt + (dgt < 10 ? '0' : (1 ? 'A' : 'a') - 10);
    }
    *buffer = 0;
    return buffer;
#endif
}

//
// Integer to ascii
//

char *itoa(int value, char * buffer, int radix) {
    char *bufsav = buffer;

    if (radix < 2 || radix > 36) {
        *buffer = 0;
        return buffer;
    }

    if (radix == 10 && value < 0) {
        value =- value;
        *buffer++ = '-';
    }
    
    __utoa(value, buffer, radix, lower_digits);
    return bufsav;
}

//
// Long integer to ascii
//

char *ltoa(long value, char * buffer, int radix) {
    char *bufsav = buffer;
    
    if (radix < 2 || radix > 36) {
        *buffer = 0;
        return buffer;
    }

    if (radix == 10 && value < 0) {
        value =- value;
        *buffer++ = '-';
    }

    __ultoa((unsigned long)value, buffer, radix, lower_digits);
    return bufsav;
}

//
// Long long integer to ascii
//

char *lltoa(long long value, char * buffer, int radix) {
    char *bufsav = buffer;
    
    if (radix < 2 || radix > 36) {
        *buffer = 0;
        return buffer;
    }

    if (radix == 10 && value < 0) {
        value =- value;
        *buffer++ = '-';
    }

    __ulltoa((unsigned long long)value, buffer, radix, lower_digits);
    return bufsav;
}

//
//! Function to pad field sizes to specific widths
//!

static void padout(int width, int prec, char padchar, bool leftFlag, char* buffer) {
    (void)prec;
    (void)leftFlag;
    char* p = buffer;
    while (*p++ && width > 0){
        width--;
    }
    while (width-- > 0) { 
        putchar(padchar);
    }
    while (*buffer) {
        putchar(*buffer++);
    }
}

//
//
//

void printf(const char *fmt, ...)  {
    char buffer[128];
    char *buf = buffer;

    va_list va;
    va_start(va, fmt);

    char ch;

    while ((ch = *fmt++)) {
        if (ch != '%')  {
            putchar(ch);
        } else {
            char padchar  = ' ';
            unsigned int width = 0;
            unsigned int prec  = 0;
            unsigned int size  = 0;
            bool leftFlag = false;

            //
            // Parse modifier
            //

            ch = *fmt++;
            if (ch == '-') {
                leftFlag = true;
                ch = *fmt++;
            }

            //
            // Parse field width
            //

            if (ch == '0') {
                padchar = ch;
                ch = *fmt++;
            }
            while (ch >= '0' && ch <= '9') {
                width = (width * 10) + (ch - '0');
                ch = *fmt++;
            }
            
            //
            // Parse precision
            //
            
            if (ch == '.') {
                ch = *fmt++;
                while (ch >= '0' && ch <= '9') {
                    prec = (prec * 10) + (ch - '0');
                    ch = *fmt++;
                }
            }

            //
            // Parse size modifiers
            //

            if (ch == 'l') {
                ch = *fmt++;
                size = 1;
            }
            if (ch == 'l') {
                ch = *fmt++;
                size = 2;
            }
            
            //
            // Parse conversion type
            //

            switch (ch) {
                case 0: 
                    va_end(va);
                    return;
                case 'u' :
                    switch(size) {
                        case 0:
                            __utoa(va_arg(va, unsigned int), buf, 10, lower_digits);
                            break;
                        case 1:
                            __ultoa(va_arg(va, unsigned long), buf, 10, lower_digits);
                            break;
                        case 2:
                            __ulltoa(va_arg(va, unsigned long long), buf, 10, lower_digits);
                            break;
                    }
                    padout(width, prec, padchar, leftFlag, buf);
                    break;
                case 'o' :
                    switch(size) {
                        case 0:
                            __utoa(va_arg(va, unsigned int), buf, 8, lower_digits);
                            break;
                        case 1:
                            __ultoa(va_arg(va, unsigned long), buf, 8, lower_digits);
                            break;
                        case 2:
                            __ulltoa(va_arg(va, unsigned long long), buf, 8, lower_digits);
                            break;
                    }
                    padout(width, prec, padchar, leftFlag, buf);
                    break;
                case 'd' :
                    switch(size) {
                        case 0:
                            itoa(va_arg(va, int), buf, 10);
                            break;
                        case 1:
                            ltoa(va_arg(va, long), buf, 10);
                            break;
                        case 2:
                            lltoa(va_arg(va, long long), buf, 10);
                            break;
                    }
                    padout(width, prec, padchar, leftFlag, buf);
                    break;
                case 'x' :
                    switch(size) {
                        case 0:
                            __utoa(va_arg(va, unsigned int), buf, 16, lower_digits);
                            break;
                        case 1:
                            __ultoa(va_arg(va, unsigned long), buf, 16, lower_digits);
                            break;
                        case 2:
                            __ulltoa(va_arg(va, unsigned long long), buf, 16, lower_digits);
                            break;
                    }
                    padout(width, prec, padchar, leftFlag, buf);
                    break;
                case 'X' : 
                    switch(size) {
                        case 0:
                            __utoa(va_arg(va, unsigned int), buf, 16, upper_digits);
                            break;
                        case 1:
                            __ultoa(va_arg(va, unsigned long), buf, 16, upper_digits);
                            break;
                        case 2:
                            __ulltoa(va_arg(va, unsigned long long), buf, 16, upper_digits);
                            break;
                    }
                    padout(width, prec, padchar, leftFlag, buf);
                    break;
                case 'c' : 
                    putchar((char)(va_arg(va, int)));
                    break;
                case 's' : 
                    padout(width, prec, 0, leftFlag, va_arg(va, char*));
                    break;
                case '%' :
                    putchar(ch);
                default:
                    break;
            }
        }
    }
    va_end(va);
}
