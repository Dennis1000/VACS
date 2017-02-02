; pageboundary.asm
; Example on how to use the page boundary addressing mode 
; by Dennis D. Spreen
; v1.0 2003/04
;
; 2650 uses a 8k addressing mode:
;
;  0000h = page 0
;  2000h = page 1
;  4000h = page 2
;  [...]
;
; Arcadia ROM Layout:
;  $0000..$0FFF (first 4K): loaded into $0000..$0FFF at runtime
;  $1000 and onwards (beyond first 4K): loaded into $2000 and onwards at runtime.
;
; That means, instead of using $1000 you have to switch to the next page ($2000)
;
; This file assembles well under VACS v1.24g/w32 (by W.H. Taphoorn; updated by D.D. Spreen)
;

        name pageboundary        ; module name
 
        include "arcadia.h"      ; v1.01


       ; ----------- page 0 -----------------------------------------------------------------------

	org     0000H            ; first 4k, $0000/page 0
	first:   
		loda,r0  here1            ; load some values within current page
                bcta,un  second           ; do an absolute branch (=> doesn't care about page boundaries)
 	here1:
 
                ds  $1000-here1,10h    ; use code until 0FFFh then instead of using 1000h, switch 
                                          ; the code origin to 2000h (see below):

       ; ----------- page 1 -----------------------------------------------------------------------

	org     2000H                     ; we're now on $1000, which resides at $2000, that is $0000/page1
	second: 
		loda,r0  here2
                bcta,un  third  
                ;loda,r0  here1           ; would be a page boundary violation
        here2:

                ds $3000-here2,20h    ; code filler



	org     3000H                     ; we're now on $3000 that's $1000/page1
                                          ; as we filled the code with dbfill, this ORG isn't necessary
	third:	
                loda,r0  here2            ; does work, since we're still on page1
		loda,r0  here3
                bcta,un  fourth
                ;loda,r0  here1           ; would be a page boundary violation
	here3:
                ds $4000-here3, 30h   ; code filler


       ; ----------- page 2 -----------------------------------------------------------------------

	org     4000H                     ; we're now on $4000 that's $0000/page2
	fourth:
		;loda,r0  here3           ; page boundary violation
		loda,r0  here4
                bcta,un  first
                bcta,un  second
                bcta,un  third
                ;loda,r0 here1            ; page boundary violation
	here4:
		db 40h


end