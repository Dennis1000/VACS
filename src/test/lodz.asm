;2650 Equates-------------------------------------------------------------
z              equ 0
eq             equ z
p              equ 1
gt             equ p
n              equ 2
lt             equ n
un             equ 3

page0 equ 0
page1 equ 2000h 
page2 equ 4000h 
page3 equ 6000h 
page4 equ 8000h 

       org     2000H
      lodz r0
      lodz r1
      lodz r2
      lodz r3

third:   nop
       loda,r0 here3

here3: db 20h

       org     0000H

first:  
       loda,r0  here1
here1:
       db 10h
       bcta,un second+page1
       bcta,un third
       lodz r0

       org     000H

second:
       loda,r0 here2
here2:
       db 20h


       
 end


>lodz,r0 means r0 = r0;
>iorz,r0 means r0 |= r0;

>Neither of them do anything very useful :-) The only conceivable use 
>for them is that they do affect the condition codes...

>To quote from the 2650 manual: "The instruction %00000000 [lodz,r0] 
>yields indeterminate results." So therefore it is not a valid opcode.

>I would guess that AS2650 is translating lodz,r0 to iorz,r0, which is 
>roughly equivalent but avoids using the %00000000 instruction. The 
>other solution would be simply to flag lodz,r0 as an error.

I'll fix it to 



>A few random suggestions for VACS:
> * unimportant: allow $1234 style of hex numbers (Amiga-style)

lodi,r0 $12   ; already works fine


> * unimportant: allow X1234 style of hex numbers (DASMX-style)

I've tried to include it, but there is a problem regarding
labels - and your fixer does a great job...


> * unimportant: currently numbers such as A0H must be entered as 
>0A0H, it would be better to not require the leading zero (although I 
>presume this might cause problems determining whether a label or a 
>literal is meant)

oh, this is something I'm already used to. You'll find this
behaviour in nearly every assembler.


> * more important: some way of telling VACS about the layout of 
>Arcadia ROMs:
>$0000..$0FFF (first 4K): loaded into $0000..$0FFF at runtime
>$1000 and onwards (beyond first 4K): loaded into $2000 and onwards at 
>runtime.
>If VACS knew this it would make things a lot easier.


well, with the second 4k loaded in $2000, thus exceeding
the page boundary and reverting to $0000 addresses on page 1,
you'll have to set it manually to org 0000h again:


0000              
0000                     org     0000H       ; first 4k, $0000/page 0
0000              first:   
0000 0C0003              loda,r0  here1
0003              here1:
0003 10                  db 10h            
0004 
[..]                                   
0FFF 
0000                     org     0000H       ; we're now on $1000, which resides at $2000, that is $0000/page1
0000              second: 
0000 0C0003              loda,r0 here2
0003              
0003              here2:
0003 20                  db 20h


as you can't do a direct page boundary load in the first page, e.g.

0004                    loda,r0  here2

which compiles fine, but is obviously wrong, you have to use indirect
addressing mode.
You can't use org 2000h in the second page, because VACS tries
to fit the 2000h in the 13bits which fails. 
Ok, now how to branch to "second" ?
 
0004 1F0000        bcta,un second

compiles to the wrong address (0000 instead of 2000h). Well. 
How to accommodate this? Don't know. You could always specify
the page if you're doing page jumps:

page0 equ 0
page1 equ 2000h 

0004 1F2000        bcta,un second+page1

Or how about adding a PAGE statement (as PAGE is already defined, but is the same as PGLEN this
shouldn't be a problem at all) like this?

   org 0000h
   page 0   ; 0 = default

first:

0000 1F2000  bcta,un second  
     

  org  0000h
  page 1    ; we're on $2000

second:

       
0000 1F0000  bcta,un first







------------------------ Yahoo! Groups Sponsor ---------------------~-->
Get 128 Bit SSL Encryption!
http://us.click.yahoo.com/xaxhjB/hdqFAA/VygGAA/hWFolB/TM
---------------------------------------------------------------------~->

To unsubscribe from this group, send an email to:
arcadia2001consoles-unsubscribe@yahoogroups.com

 

Your use of Yahoo! Groups is subject to http://docs.yahoo.com/info/terms/

