;2650 Equates-------------------------------------------------------------
z              equ 0
eq             equ z
p              equ 1
gt             equ p
n              equ 2
lt             equ n
un             equ 3



	org     0000H       ; first 4k, $0000/page 0
	first:   
		loda,r0  here1
                bcta,un  second
                bcta,un  here2
 	here1:
		db 10h            


	org     2000H       ; we're now on $1000, which resides at $2000, that is $0000/page1
	second: 
		loda,r0  here2
                bcta,un  first
                ;loda,r0  here1  ;page boundary violation
	here2:
		db 20h



	org     3000H       ; we're now on $3000, $1000/page1
		nop
		loda,r0  here2  ; does work, since we're still on page1
		loda,r0  here3
                bcta,un  first
                ;loda,r0  here1  ; page boundary violation
	here3:
		db 20h



	org     4000H       ; we're now on $4000, $0000/page2
		nop
		;loda,r0  here3  ; page boundary violation
		loda,r0  here4
                bcta,un  first
                bcta,un  second
                ;loda,r0 here1 ; page boundary violation
	here4:
		db 20h


end