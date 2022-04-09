; v1.24i Test file
;
;      org         0000H        ; Start
;width 1H        ; Start
;END 100
;WIDTH 150
;PAGE 100
;OFFS 100
;TABS 5

      name v1_24i

;2650 Equates
z     equ  0
eq    equ  z
p     equ  1
gt    equ  p
n     equ  2
lt    equ  n
un    equ  3


      org         0000H        ; Start

      lodi,r1     0         ;  $00
      lodi,r2     1         ;  $01
      lodi,r0     -1        ;  $FF
      lodi,r1     -2        ;  $FE
      lodi,r2     -128      ;  $80 
      ;lodi,r2     -129      ; "Value out of range" error
      lodi,r2     128       ;  $80
      lodi,r2     255       ;  $FF




      end ; End of assembly
