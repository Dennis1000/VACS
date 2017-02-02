; Arcadia 2001 - helloworld.asm
; By Adam Trionfo - ballyalley @ hotmail.com
;
; Version 1.0 - April 21, 2002
;
; Signetics 2650 source-code for the Arcadia 2001 console.
;
; This program prints 'HELLO WORLD' to the screen.
;
; This file assembles well under VACS v1.24/w32 (by W.H. Taphoorn; updated by D.D. Spreen)
;
;      asm32.exe helloworld.asm
;
      name HelloWorld          ; module name

      include "arcadia.h"      ; v1.01

      org         0000H        ; Start of Arcadia ROM

programentry:
      eorz  r0                 ; Zero-out register 0
      bctr,un     programstart ; Branch to start of program
      retc,un                  ; Called on VSYNC or VBLANK?
                               ; As suggested by Paul Robson

programstart:
      ppsu        00100000b    ; Set Interrupt Inhibit bit
                               ; The Tech doc that Paul
                               ; wrote infers that Inter-
                               ; rupts aren't used

; Print message onto screen 
      lodi,r0     00h          ; Zero-out registers 0
      lodi,r1     0FFh         ;
      lodi,r2     0FFh         ; 

; Print loop
displaymessage:
      loda,r0     message,r1+  ; Get one char from message
      comi,r0     0FFh         ; Use FFh as End of Message
                               ; Delimiter
      bctr,eq     displaydone  ; If it's the delimiter, then
                               ; break out of displaymessage
      stra,r0     SCRUPDATA,r2+; Print char to screen (upper screen data)
      bctr,un     displaymessage
displaydone:

; Set Background Color to blue
      lodi,r0     00000110b    ; Put Blue (06h) into reg 0
      stra,r0     BGCOLOUR     ; Bits 0-2 of 19F9h control
                               ; background color

loopforever:
      bctr,un     loopforever  ; Loop forever

; "Hello World"  This is NOT ASCII
message:
      db          21h,1Eh,25h,25h,28h,00h  ; 'HELLO '
      db          30h,28h,2Bh,25h,1Dh      ; 'WORLD'
      db          0FFh         ; End of message delimiter

      end ; End of assembly
