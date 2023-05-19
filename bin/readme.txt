Update info on the VACS V1.24 assemblers
----------------------------------------

This is the Windows port of the VACS 1.24 assembler by Wil Taphoorn and AC Verschueren with additional
binary output support for the Signetics 2650 processor and 'long file name' handling.
The Windows port is based upon the 'VACS V1.24 TP5 main modules source files" - see orig\ folder.

New parameters since v1.24b
---------------------------
  -k <num>    Padd Binary File with 00h to [num] bytes
  -c <byte>   Padd with <byte> [byte = 0..255 (decimal)] instead of 00h

New opcodes since v1.24f
------------------------
dbx   "zzzzzzzz"     defines one graphics character byte,   . or " " (space) sets the accoring bit to "0",
                       any other to logical "1".

  Equivalent examples
	db   0CAh 
	db   11001010b
	dbx  "##..#.#."
	dbx  "XX  X X "

  There is a tool called dbx in the tools\ folder which helps you converting standard DB statements to the dbx statement.                      


History
-------
v1.0 - v1.12 (1987/11)
  - Programs, up to V1.12, designed and written by ir. A.C. Verschueren, Eindhoven, November 20, 1987.
  - V1.12 was donated to the public domain in November 1987.

v1.13 - v1.20 (1988/12)
  - Programs redesigned by W.H. Taphoorn, Uithoorn, Fidonet 2:500/40.1547 
  - VACS V1.2x donated to the public domain, December 1989.

v1.21 - v1.23 (1990/06)
  - Additions like BACKWARD and FORWARD pseudo instructions, WARNING instruction.

v1.24 (1992/08)
  - First release of VACS 32-bit version, all operands and internal  calculation is changed from 16-bit to 32-bit.

v1.24a -v1.24b (1993/10)
  - String handling modified: string identifiers now work everywhere a string constant is needed.

v1.24c/w32 (2003/01):
  - Ported to Windows (Delphi) by D.D. Spreen, first win32 version.
  - Disabled the annoying beep after a successful compilation.
  - Long file name support.

v1.24d/w32 (2003/04):
  - Always generates Binary File .bin (parameter -a omitted!)
  - Added BinaryPadding -k parameter.
  - Added BinaryPadByte -c parameter.
  - Support for the DASMx automatic indexing mode
    Opcode,r [*]p [,x] [,] [+/-]     (p = 0..8191) 
    Example (both are equivalent):
       loda,r0     sprite0,r1+ 
       loda,r0     sprite0,r1,+    

v1.24e/w32 (2003/05):
  - Fixed 'missing file' handling.
  - Fixed weekday output.

v1.24f/w32 (2004/07):
  - Added dbx opcode support.

v1.24g/w32 (2004/08):
  - Support for the DASMx automatic register3 mode.
    Opcode [*]a[,3]
    Example (both are equivalent):
       bsxa    somewhere,r3 
       bsxa    somewhere

  - Support for page boundary addressing modes
    (does not work for Zbrr and Zbsr !), see examples\pageboundary.asm.

  - Fixed "lodz, r0" instruction (now assembles to 60h).


v1.24h/w32 (2004/08):
  - Fixed "lodz, r1...r3" bug (caused by the lodz, r0 - fix).

v1.24i/w32 (2022/04):
 - Added support for negative numbers, e.g. lodi,r0  -1.
 - Fixed uninitialized variables (internal).
 - Fixed shortstring and string cast warnings (internal).
 - Fixed binary output with multiple org statements (works with -c parameter).
 - Compilable with Delphi 11.1
 - Dropped "Available memory" output.

v1.24j/w32 (2023/05):
 - Fixed WIDTH expression

Support
-------
You may find the latest version here

  https://github.com/Dennis1000/VACS

Please file your bug reports here

  https://github.com/Dennis1000/VACS/issues

Or just write me an email 
  
  dennis@spreendigital.de


Examples
--------
asm32.exe mothership.asm
Generates the mothership.bin binary.

asm32.exe mothership.asm -k 4096
Generates a 4k mothership.bin binary padded with 0h (default).

asm32.exe mothership.asm -k 2048 -c 255
Generates a 2k mothership.bin binary padded with $FF (=255 decimal).