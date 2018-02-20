;license:MIT
;(c) 2017-2018 by qkumba

!cpu 6502
*=$b0e

gamename=$306
savename=$350
scrpname=$390

xstart
-	jsr	$bf00
op_c7
	!byte	$c7
	!word	c7_parms
	ldx	$200
	bne	+
	lda	$bf30
	sta	c5_parms+1
	jsr	$bf00
	!byte	$c5
	!word	c5_parms
	ldx	$201
	inx
        txa
	and	#$0f
	sta	$200
	lda	#$2f
	sta	$201
	dec	op_c7
	bne	-
+
	lda	$305
	eor	$304
	eor	$303
	eor	$302
	eor	$301
	eor	$300
	eor	#$a5
	beq	+
	lda	#$D9
	sta	$300	;80-cols
	ldx	#1
	stx	$301	;lowercase
	dex
	stx	$303	;no script
	dex
	stx	$302	;no load
+

	ldx	$300
	cpx	#$ce
	beq	skip80
	lda	$bf98
	and	#2
	bne	okay80
	ldx	#$ce

skip80
	lda	#$df
	sta	mapmask+1
okay80
	stx	$1793

	lda	$301
	beq     +
	lda	$bf98
	bpl	+
	inc	$17ba
	bne	++
+
	inc	$17b6
++
	lda	$303
	beq	+
	lda	#<print
	sta	$18ba
	lda	#>print
	sta	$18bb
	lda	#<printer
	sta	$1364
	lda	#>printer
	sta	$1365

	lda	$304
	beq	+
	lda	#<callbackprn1
	sta	$11de
	lda	#>callbackprn1
	sta	$11df
+
	ldx	$302
	inx
	beq	+
	lda	$11de
	sta	loadcall1+1
	lda	$11df
	sta	loadcall2+1
	lda	#<callback1
	sta	$11de
	lda	#>callback1
	sta	$11df
+

no_opt
	ldy	gamename
	lda	#'V'
	sta	savename+1,y
	lda	#'A'
	sta	savename,y
	lda	#'S'
	sta	savename-1,y
	lda	#'G'
	sta	scrpname+1,y
	lda	#'O'
	sta	scrpname,y
	lda	#'L'
	sta	scrpname-1,y
	dey
	dey
-
	lda	gamename,y
	sta	savename,y
	sta	scrpname,y
	dey
	bpl	-
	inc	savename
	inc	scrpname

	jsr	closefile
	jmp	$173d

c7_parms
	!byte	1
	!word	$200

c5_parms
	!byte	2
	!byte	0
	!word	$201


xend
*=$c11
	ora	#$ca
	sta	pro_op
	lda	#0
	sta	ce_parms+2
	sta	ce_parms+4
	sec
	lda	$65
adjust
	sbc	#0
	asl
	asl
	asl
	rol	ce_parms+4
	asl
	rol	ce_parms+4
	ora	$64
	sta	ce_parms+3

-	jsr	$bf00
	!byte	$ce		;seek
	!word	ce_parms
	bcc	+
	jsr	$bf00
	!byte	$d0		;set EOF
	!word	ce_parms
	bcc	-

+
	jsr	$bf00
pro_op
	!byte	$ca		;read file
	!word	ca_parms
	bcs	jmpquit
-	rts

printer
	cmp	#$8d
	bne	-
	iny
	sty	cb_parms+4
	dey
	lda	#<scrpname
	sta	c8_parms+1
	ldx	#(<gamename xor <scrpname)
	jsr	closefile1

	jsr	$bf00
	!byte	$d1
	!word	ce_parms

	jsr	$bf00
	!byte	$ce
	!word	ce_parms

	jsr	$bf00
	!byte	$cb
	!word	cb_parms

	bcc	closefile
jmpquit	jmp	$dfe

savefile

	jsr	$bf00
	!byte	$c0
	!word	c0_parms
	lda	$e5a
	sta	c0_parms+5
	jsr	$bf00
	!byte	$c3
	!word	c0_parms
	ldx	#$e6
	!byte	$2c

loadfile
	ldx	#$b8

	lda	#$0d
	pha
	txa
	pha

closefile
	ldx	#(<gamename xor <savename)

closefile1
	jsr	xclose
	jsr	xopen
	lda	adjust+1
	eor	#3
	sta	adjust+1
	txa
	eor	c8_parms+1
	sta	c8_parms+1
	rts

callback1
	lda	xrestore,y
	cmp	#$8d
	bne	+
	ldx	#<callback2
	stx	$11de
;!if #>callback1 != #>callback2 {
;	ldx	#>callback2
;	stx	$11df
;}
+	rts

callback2
	lda	$302
	ora	#$b0
	ldx	#<callback3
	stx	$11de
;!if #>callback2 != #>callback3 {
;	ldx	#>callback3
;	stx	$11df
;}
+	rts

callback3
	lda	#$D9
loadcall1
	ldx	#$0c
	stx	$11de
loadcall2
	ldx	#$fd
	stx	$11df
	rts

xrestore
	!byte	$d2,$c5,$d3,$d4,$cf,$d2,$c5,$8d

callbackprn1
	lda	xscript,y
	cmp	#$8d
	bne	+
	ldx	#$0c
	stx	$11de
	ldx	#$fd
	stx	$11df
+	rts

xscript
	!byte	$d3,$c3,$d2,$c9,$d0,$d4,$8d

print
	jsr	$bf00
	!byte	$c1
	!word	c1_parms
	lda	#<scrpname
	sta	c0_parms+1
	jsr	$bf00
	!byte	$c0
	!word	c0_parms

	inc	$1363
	lda	#<savename
	sta	c0_parms+1
	rts

xclose
	jsr	$bf00
	!byte	$cc
	!word	cc_parms
	rts

xopen
	jsr	$bf00
	!byte	$c8
	!word	c8_parms
	lda	c8_parms+5
	sta	ce_parms+1
	sta	ca_parms+1
	sta	cb_parms+1
	rts

casemap
	ldy	$32
	bmi	+
	cmp	#$61
	bcc	+
	cmp	#$7b
	bcs	+
mapmask
	and	#$ff
+	sta	$200,x
-	rts

waitkey
	jsr	$12f8
	lda	$c010
-	lda	$c000
	bpl	-

quit
	jsr	xclose
	jsr	$bf00
	!byte	$65
	!word	quit_parms


c8_parms
	!byte	3
	!word	gamename
	!word	$800
	!byte	0

c0_parms
	!byte	7
	!word	savename
	!byte	%11000011
	!byte	04
	!word	0
	!byte	1
	!word	0
	!word	0

ce_parms
	!byte	2
	!byte	0
	!byte	0
	!byte	0
	!byte	0

ca_parms
	!byte	4
	!byte	$ff
	!word	$2900
	!word	$100
	!word	$ffff

cc_parms
	!byte	1
	!byte	0

c1_parms
	!byte	1
	!word	scrpname

cb_parms
	!byte	4
	!byte	$ff
	!word	$200
	!word	$00ff
	!word	$ffff

quit_parms
	!byte	4
	!byte	0
	!word	0
	!byte	0
	!word	0

!ifdef PASS2 {
!warn "savefile=",savefile
!warn "loadfile=",loadfile
!warn "closefile=",closefile
!warn "casemap=",casemap
!warn "quit=",quit
!warn "waitkey=",waitkey
!warn "base=",$c11-(xend-xstart)
!if >callback1 != >callback2 {
!warn "callbacks=", >callback1, >callback2
}
!if >callback2 != >callback3 {
!warn "callbacks=", >callback2, >callback3
}
} else {
!set PASS2=1
}