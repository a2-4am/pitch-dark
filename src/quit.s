;license:MIT
;(c) 2018 by qkumba

!cpu 6502
*=$2000
!to "../build/QUIT.SYSTEM#FF2000",plain

	lda	$c083
	lda	$c083
	ldy	#0
-	lda	runme,y
	sta	$d100,y ;$d1 heh.
	sta	$1000,y
	iny
	bne	-
	jmp	$1000

runme !pseudopc $1000 {
	cld
	lda	$c082
	sta	$c00c
	sta	$c000
	jsr	$fe93
	jsr	$fe89
	sta	$4fb
	jsr	$fb2f
	jsr	$fc58
	ldx	#$df
	lda	#$cf
-	sta	$be79,x
	lda	#0
	txs
	inx
	bne	-
	inc	$bf6f
	jsr	$bf00
	!byte	$c6
	!word	c6_parms
	jsr	$bf00
	!byte	$c8
	!word	c8_parms
	lda	c8_parms+5
	sta	ca_parms+1
	jsr	$bf00
	!byte	$ca
	!word	ca_parms
	jsr	$bf00
	!byte	$cc
	!word	cc_parms
	jmp	$2000

c6_parms
	!byte	1
	!word	prefix

c8_parms
	!byte	3
	!word	filename
	!word	$800
	!byte	0

ca_parms
	!byte	4
	!byte	$d1
	!word	$2000
	!word	$ffff
	!word	$34d1

cc_parms
	!byte	1
	!byte	0

prefix
	!byte	(prefix_e-prefix)-1
	!text	"/PDBOOT"
prefix_e

filename
	!byte	(filename_e-filename)-1
	!text	"PITCHDRK.SYSTEM"
filename_e
}
