;license:MIT
;(c) 2017-2018 by qkumba

!cpu 6502
!to "..\..\build\ONBEYONDZ3#063000",plain
*=$3000

vars=$306
eip=$b0e

;unpacker variables, no need to change these
src	=	$0
dst	=	$2
ecx	=	$4
last	=	$6
tmp	=	$8

init
	ldy	$2006
-	lda	$2006,y
	sta	$306,y
	dey
	bpl	-

	lda	#>pakoff
	sta	src+1
	lda	#<pakoff
	sta	src
	lda	#>eip
	sta	dst+1
	lda	#<eip
	sta	dst

	jsr	unpack
	jmp	eip

unpack ;unpacker entrypoint
	lda	#0
	sta	last
	sta	ecx+1

literal
	jsr	getput
	ldy	#2

nexttag
	jsr	getbit
	bcc	literal
	jsr	getbit
	bcc	codepair
	jsr	getbit
	bcs	onebyte
	jsr	getsrc
	lsr
	beq	donedepacking
	ldx	#0
	stx	ecx
	rol	ecx
	stx	last+1
	tax
	bne	domatch_with_2inc

getbit
	asl	last
	bne	.stillbitsleft
	jsr	getsrc
	asl
	sta	last
	inc	last

.stillbitsleft

donedepacking
	rts

onebyte
	ldy	#1
	sty	ecx
	iny
	lda	#0
	sta	tmp+1
	lda	#$10

.getmorebits
	pha
	jsr	getbit
	pla
	rol
	bcc	.getmorebits
	bne	domatch
	jsr	putdst

linktag
	bne	nexttag

codepair
	jsr	getgamma
-	jsr	dececx
	dey
	bne	-
	tay
	ora	ecx+1
	beq	+

normalcodepair
	dey
	sty	last+1
	jsr	getsrc
	tax
	!byte	$a9
+	iny
	jsr	getgamma
	cpy	#$7d
	bcs	domatch_with_2inc
	cpy	#5
	bcs	domatch_with_inc
	txa
	bmi	domatch_new_lastpos
	tya
	bne	domatch_new_lastpos

domatch_with_2inc
	inc	ecx
	bne	domatch_with_inc
	inc	ecx+1

domatch_with_inc
	inc	ecx
	bne	domatch_new_lastpos
	inc	ecx+1

domatch_new_lastpos

domatch_lastpos
	ldy	#1
	lda	last+1
	sta	tmp+1
	txa

domatch
	sta	tmp
	lda	src+1
	pha
	lda	src
	pha
	lda	dst
	sec
	sbc	tmp
	sta	src
	lda	dst+1
	sbc	tmp+1
	sta	src+1
-	jsr	getput
	jsr	dececx
	ora	ecx+1
	bne	-
	pla
	sta	src
	pla
	sta	src+1
	bne	linktag

getgamma
	lda	#1
	sta	ecx
	sta	ecx+1
	dec	ecx+1

.getgammaloop
	jsr	getbit
	rol	ecx
	rol	ecx+1
	jsr	getbit
	bcs	.getgammaloop
	rts

dececx
	lda	ecx
	bne	+
	dec	ecx+1
+	dec	ecx
	lda	ecx
	rts

getput
	jsr	getsrc

putdst
	sty	tmp
	ldy	#0
	sta	(dst), y
	inc	dst
	bne	+
	inc	dst+1
	bne	+

getsrc
	sty	tmp
	ldy	#0
	lda	(src), y
	inc	src
	bne	+
	inc	src+1
+	ldy	tmp
	rts

cc_parms
c7_parms        !byte   1
                !word   $200

c5_parms        !byte   2
                !byte   0
                !word   $201
                !byte   $d1

c4_parms        !byte   $0a
                !word   $2006
                !text   "qkumba was here"
quit_parms      !byte   4

pakoff
!bin "0800-23ff.pak"
