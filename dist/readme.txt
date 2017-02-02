Update info on the VACS V1.24 assemblers
----------------------------------------

This is the Win32 port of the VACS 1.24 assembler
by Wil Taphoorn and AC Verschueren with additional
binary output support for the Signetics 2650 processor
and 'long file name' handling.

New parameters since v1.24b:

  -k <num>    Padd Binary File with 00h to [num] bytes
  -c <byte>   Padd with <byte> [byte = 0..255 (decimal)] instead of 00h

New opcodes since v1.24f:

  dbx   "zzzzzzzz"     defines one graphics character byte,  
                       . or " " (space) sets the accoring bit to "0",
                       any other to logical "1".
                       equivalent examples:
                       
                        db   0CAh 
                        db   11001010b
                        dbx  "##..#.#."
                        dbx  "XX  X X "

                       There is a tool called "dbx" in the tools\ folder
                       which helps you converting standard DB statements
                       to the dbx statement.                      


History
-------

v1.24c/w32:
  - first win32 version
  - disabled the annoying beep after a successful compilation
  - long file name support

v1.24d/w32:
  - always generate Binary File .bin (parameter -a omitted!)
  - changed -k parameter (see above)
  - added -c parameter (see above)
  - support for the DASMx automatic indexing mode

      Opcode,r [*]p [,x] [,] [+/-]     (p = 0..8191)

     example (both are equivalent):
       loda,r0     sprite0,r1+ 
       loda,r0     sprite0,r1,+    

v1.24e/w32:
  - fixed 'missing file' handling
  - fixed weekday output

v1.24f/w32:
  - added dbx opcode support (see above)

v1.24g/w32:
  - support for the DASMx automatic register3 mode

      Opcode [*]a[,3] 

    example (both are equivalent):
       bsxa    somewhere,r3 
       bsxa    somewhere

  - support for page boundary addressing modes
    (does not work for Zbrr and Zbsr !)
    see examples\pageboundary.asm

  - fixed "lodz, r0" instruction (now assembles to 60h)


v1.24h/w32:
  - fixed "lodz, r1...r3" bug (caused by the lodz, r0 - fix)



Example 1:

  asm32 mothership.asm

  generates the mothership.bin binary.

Example 2:

  asm32 mothership.asm -k 4096

  generates a 4k mothership.bin binary padded with 0h (default).

Example 3:

  asm32 mothership.asm -k 2048 -c 255

  generates a 2k mothership.bin binary padded with FFh (=255 decimal).


Regards,
 Dennis D. Spreen (dennis@spreendigital.de)
