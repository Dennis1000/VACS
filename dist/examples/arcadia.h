;-------------------------------------------------------------------------
;
; arcadia.h 
; for the Emerson Arcadia 2001 family
; based on the hardware equates/memory map by James Jacobs and the
; Technical Information written by Paul Robson
;
; v1.00  2003/04  Dennis D. Spreen (initial release)
; v1.01  2003/04  Dennis D. Spreen (fixed sprite ptrs, added more infos)
;
;-------------------------------------------------------------------------

; Memory Map
; 
;  $0000..$0FFF are ROM (first 4K of cartridge)
;  $1000..$17FF are unmapped
;  $1800..$18CF are upper screen display
;  $18D0..$18EF are user RAM
;  $18F0..$19FF are control registers
;  $1A00..$1ACF are lower screen display
;  $1AD0..$1AFF are user RAM
;  $1B00..$1FFF are unmapped
;  $2000..$7FFF are ROM (last 24K of cartridge)

;-------------------------------------------------------------------------

SCRUPDATA       equ 1800h   ;$1800..$18CF are upper screen display
SCRLODATA       equ 1A00h   ;$1A00..$1ACF are lower screen display

;-------------------------------------------------------------------------

RAM1            equ 18D0h   ;$18D0..$18EF are user RAM1 - 32 Byte 
RAM2            equ 18F8h   ;$18F8..$18FB are user RAM2 -  4 Byte
RAM3            equ 1AD0h   ;$1AD0..$1AFF are user RAM3 - 48 Byte

;-------------------------------------------------------------------------

SPRITE0Y        equ 18F0h   ;sprite 0 y-position
SPRITE0X        equ 18F1h   ;sprite 0 x-position
SPRITE1Y        equ 18F2h   ;sprite 1 y-position
SPRITE1X        equ 18F3h   ;sprite 1 x-position
SPRITE2Y        equ 18F4h   ;sprite 2 y-position 
SPRITE2X        equ 18F5h   ;sprite 2 x-position
SPRITE3Y        equ 18F6h   ;sprite 3 y-position
SPRITE3X        equ 18F7h   ;sprite 3 x-position

;-------------------------------------------------------------------------

CRTCVPR         equ 18FCh   ;crtc vertical position register

PITCH           equ 18FDh   ;pitch and alternate character mode selector
                            ;bit  7:    0 = normal mode
                            ;           1 = alternate character mode color2x2 
                            ;               (2 backgrounds, 2 foreground colours)
                            ;bits 6..0: pitch

VOLUMESCROLL    equ 18FEh   ;volume and scanline scrolling
                            ;bits 7..5: horizontal scanline scrolling
                            ;bits 4:    0 = sound on
                            ;           1 = sound off
                            ;bits 3..0: volume

CHARLINE        equ 18FFh   ;1111xxxx current character line (lower 4 bits only, the 4 most 
                            ;         significant bits are always '1'). The 4 least significant 
                            ;         bits of this count 0123456789ABC0123456789ABC, going to D 
                            ;         when in vertical blank
;-------------------------------------------------------------------------

P1LEFTKEYS      equ 1900h   ;player 1 left keys
                            ;bits 7..4: unknown
                            ;bit  3:    p1 (left) '1' button
                            ;bit  2:    p1 (left) '4' button
                            ;bit  1:    p1 (left) '7' button
                            ;bit  0:    p1 (left) 'E' button (Enter)

P1MIDDLEKEYS    equ 1901h   ;player 1 middle keys
                            ;bit  3:    p1 (left) '2' button
                            ;bit  2:    p1 (left) '5' button
                            ;bit  1:    p1 (left) '8' button
                            ;bit  0:    p1 (left) '0' button

P1RIGHTKEYS     equ 1902h   ;player 1 right keys
                            ;bits 7..4: unknown
                            ;bit  3:    p1 (left) '3' button
                            ;bit  2:    p1 (left) '6' button
                            ;bit  1:    p1 (left) '9' button
                            ;bit  0:    p1 (left) 'C' button (Clear)

P1PALLADIUM     equ 1903h   ;player 1 palladium keys
                            ;bits 7..4: unknown
                            ;bit  3:    p1 (right) Palladium button #1
                            ;bit  2:    p1 (right) Palladium button #2
                            ;bit  1:    p1 (right) Palladium button #3
                            ;bit  0:    p1 (right) Palladium button #4

P2LEFTKEYS      equ 1904h   ;player 2 left keys
                            ;bits 7..4: unknown
                            ;bit  3:    p2 (right) '1' button
                            ;bit  2:    p2 (right) '4' button
                            ;bit  1:    p2 (right) '7' button
                            ;bit  0:    p2 (right) 'E' button (Enter)

P2MIDDLEKEYS    equ 1905h   ;player 2 middle keys
                            ;bits 7..4: unknown
                            ;bit  3:    p2 (right) '2' button
                            ;bit  2:    p2 (right) '5' button
                            ;bit  1:    p2 (right) '8' button
                            ;bit  0:    p2 (right) '0' button

P2RIGHTKEYS     equ 1906h   ;player 2 right keys
                            ;bits 7..4: unknown
                            ;bit  3:    p2 (right) '3' button
                            ;bit  2:    p2 (right) '6' button
                            ;bit  1:    p2 (right) '9' button
                            ;bit  0:    p2 (right) 'C' button (Clear)

P2PALLADIUM     equ 1907h   ;player 2 palladium keys
                            ;bits 7..4: unknown
                            ;bit  3:    p2 (right) Palladium button #1
                            ;bit  2:    p2 (right) Palladium button #2
                            ;bit  1:    p2 (right) Palladium button #3
                            ;bit  0:    p2 (right) Palladium button #4

CONSOLE         equ 1908h   ;console buttons
                            ;bits 7..3: unknown
                            ;bit  2:    DIFFICULTY button
                            ;bit  1:    OPTION button
                            ;bit  0:    START button

;-------------------------------------------------------------------------

; $1909..$197F: unmapped

SPRITE0DATA     equ 1980h   ;$1980..$1987: sprite #0
SPRITE1DATA     equ 1988h   ;$1988..$198F: sprite #1
SPRITE2DATA     equ 1990h   ;$1990..$1997: sprite #2
SPRITE3DATA     equ 1998h   ;$1998..$199F: sprite #3

UDC0DATA        equ 19A0h   ;$19A0..$19A7: user-defined character #0
UDC1DATA        equ 19A8h   ;$19A8..$19AF: user-defined character #1
UDC2DATA        equ 19B0h   ;$19B0..$19B7: user-defined character #2
UDC3DATA        equ 19B8h   ;$19B8..$19BF: user-defined character #3


; $19C0..$19F7: unmapped

RESOLUTION      equ 19F8h   ;screen resolution
                            ;bit  7: 0 = normal mode
                            ;        1 = block graphics mode
                            ;bit  6: 0 = low-res mode
                            ;        1 = high-res mode
                            ;bits 5..0: rectangle descriptions in block graphics mode

BGCOLOUR        equ 19F9h   ;background colour and sprite settings
                            ;bit  7:    0 = doublescanned sprites
                            ;           1 = singlescanned sprites
                            ;bit  6:    paddle interpolation (switches between the axes of the analog sticks)
                            ;bits 5..3: colours of tile set 0
                            ;bits 2..0: background colour

                            ; Colour Code    Name    Colour Elements
                            ; ------ ----    ----    ---------------
                            ;  7     111     Black   (GRB = 000)
                            ;  6     110     Blue    (GRB = 001)
                            ;  5     101     Red     (GRB = 010)
                            ;  4     100     Magenta (GRB = 011)
                            ;  3     011     Green   (GRB = 100)
                            ;  2     010     Cyan    (GRB = 101)
                            ;  1     001     Yellow  (GRB = 110)
                            ;  0     000     White   (GRB = 111)


SPRITES23CTRL   equ 19FAh   ;sprites 2 & 3 control settings
                            ;bit  7:    0 = sprite #2 normal
                            ;           1 = sprite #2 double-height
                            ;bit  6:    0 = sprite #3 normal
                            ;           1 = sprite #3 double-height
                            ;bits 5..3: colours of sprite #2
                            ;bits 2..0: colours of sprite #3

SPRITES01CTRL   equ 19FBh   ;sprites 0 & 1 control settings
                            ;bit  7:    0 = sprite #0 normal
                            ;           1 = sprite #0 double-height
                            ;bit  6:    0 = sprite #2 normal
                            ;           1 = sprite #2 double-height
                            ;bits 5..3: colours of sprite #0
                            ;bits 2..0: colours of sprite #2

BGCOLLIDE       equ 19FCh   ;background collision detection
                            ;bits 7..4: unknown
                            ;bits 3..0: collision between sprites #3..#0 (respectively) and the background

SPRITECOLLIDE   equ 19FDh   ;sprite collision detection
                            ;bits 7..6: unknown
                            ;bit 5:     sprite #2/#3 collision
                            ;bit 4:     sprite #1/#3 collision
                            ;bit 3:     sprite #1/#2 collision
                            ;bit 2:     sprite #0/#3 collision
                            ;bit 1:     sprite #0/#3 collision
                            ;bit 0:     sprite #0/#3 collision

;-------------------------------------------------------------------------

P2PADDLE        equ 19FEh   ;player 2 paddle
P1PADDLE        equ 19FFh   ;player 1 paddle

;-------------------------------------------------------------------------

;2650 Equates
z     equ  0
eq    equ  z
p     equ  1
gt    equ  p
n     equ  2
lt    equ  n
un    equ  3

;-------------------------------------------------------------------------

end