; Arcadia 2001 - udc.asm
; Based on 
;  sprite.asm by Adam Trionfo - ballyalley @ hotmail.com
;  Version 1.0 - April 22, 2002
;
; Signetics 2650 source-code for the Arcadia 2001 console.
;
; This program displays a user defined char (happy face) on the screen.
;
; This file assembles well under VACS v1.24f/w32 (by W.H. Taphoorn; updated by D.D. Spreen)
;
;      asm32.exe udc.asm
;

      name UDC                 ; module name  

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

; Fill the User Defined Character
fillchar:
      loda,r0     udc1,r1+     ; get one byte of udc data
      comi,r1     08h          ; Moved eight bytes of data?
      bctr,eq     filldone     ; Exit loop when done
      stra,r0     UDC0DATA,r2+ ; Move byte to User Defined
                               ; memory area
      bctr,un     fillchar     ; Loop until done
filldone:

; Display Sprite
      lodi,r0     3Ch          ; Redefined character 1
      stra,r0     SCRUPDATA    ; Display the char
      
; Set Background Color to blue
      lodi,r0     00000110b    ; Put Blue (06h) into reg 0
      stra,r0     BGCOLOUR     ; Bits 0-2 of 19F9h control
                               ; background color

loopforever:
      bctr,un     loopforever  ; Loop forever

; UDC Data
udc1:
      dbx  ".######."   ; 7Eh
      dbx  "#......#"   ; 81h
      dbx  "#.#..#.#"   ; A5h
      dbx  "#......#"   ; 81h
      dbx  "#.#..#.#"   ; A5h
      dbx  "#..##..#"   ; 99h
      dbx  "#......#"   ; 81h
      dbx  ".######."   ; 7Eh

      end ; End of assembly
