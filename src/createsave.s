;license:MIT 
;(c) 2018 by qkumba 

!cpu 6502
!to "..\build\createsave#061000",plain

*=$1000

-	jsr	$bf00
op_c7
	!byte	$c7
	!word	c7_parms
	ldx	$300
	bne	+
	lda	$bf30
	sta	c5_parms+1
	jsr	$bf00
	!byte	$c5
	!word	c5_parms
	ldx	$301
	inx
        txa
	and	#$0f
	sta	$300
	lda	#$2f
	sta	$301
	dec	op_c7
	bne	-
+	jsr	$bf00
	!byte	$c0
	!word	c0_parms
	jsr	$bf00
	!byte	$c8
	!word	c8_parms
	lda	c8_parms+5
	sta	d0_parms+1
	sta	cb_parms+1
	jsr	$bf00
	!byte	$d0
	!word	d0_parms
        dec     d0_parms+2
        dec     d0_parms+3
	jsr	$bf00
	!byte	$ce
	!word	ce_parms
	jsr	$bf00
	!byte	$cb
	!word	cb_parms
	jsr	$bf00
	!byte	$cc
	!word	cc_parms
	rts

cb_parms
	!byte	4
	!byte	$d1
	!word	cc_parms
	!word	1
	!word	$d1d1

cc_parms
	!byte	1
	!byte	0

ce_parms
d0_parms
	!byte	2
	!byte	$d1
	!byte	0,$28,2

c8_parms
	!byte	3
	!word	filename
	!word	$2000
	!byte	$d1

c0_parms
	!byte	7
	!word	filename
	!byte	%11000011
	!byte	04
	!word	0
	!byte	1
	!word	0
	!word	0

filename
	!byte	(filename_e-filename)-1
	!text	"empty.sav"
filename_e

c7_parms
	!byte	1
	!word	$300

c5_parms
	!byte	2
	!byte	0
	!word	$301
