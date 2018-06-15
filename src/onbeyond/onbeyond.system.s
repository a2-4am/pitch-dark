;license:MIT 
;(c) 2018 by qkumba 

!to "build/ONBEYOND.SYSTEM",plain
*=$2000

jmp init
!byte $ee,$ee,64
!fill 64

filetype=$f5
auxtype=$8000 ;really $80xx

        ;get prefix, if any
init
        lda     $bf30
        sta     c5_parms+1
-       jsr     $bf00
op_c7
        !byte   $c7
        !word   c7_parms
        ldx     $280
        bne     +

        ;if not, get volume name

        jsr     $bf00
        !byte   $c5
        !word   c5_parms
        lda     $281
        and     #$0f
        tax
        inx
        stx     $280
        lda     #$2f
        sta     $281

        ;set that as prefix

        dec     op_c7
        bne     -
+       lda     #$2f
        cmp     $280,x
        beq     +
        inx
        stx     $280
        sta     $280,x

        ;form absolute path

+       ldy     $2006
-       dey
        beq     +
        lda     $2006,y
        cmp     #$2f
        bne     -
        tya
        pha
        clc
        adc     $280
        sta     $280
        tax
-       lda     $2006,y
        sta     $280,x
        dex
        dey
        bne     -
        pla
        tay
        ldx     #0
-       iny
        lda     $2006,y
        sta     $2007,x
        inx
        cpy     $2006
        bne     -
        stx     $2006

        ;set that as prefix

        jsr     $bf00
        !byte   $c6
        !word   c7_parms

        ;get attributes for passed file

+       jsr     $bf00
        !byte   $c4
        !word   c4_parms
        bcc     +
quit    jsr     $bf00
        !byte   $65
        !word   quit_parms
+       lda     c4_parms+4
        cmp     #filetype
        bne     quit
        lda     c4_parms+6
        cmp     #>auxtype
        bne     quit

        ;select interpreter by auxtype
        ;1, 2, 3, 4, 5, "$55" (special case)

        lda     c4_parms+5
        beq     quit
        cmp     #$55
        beq     +
        cmp     #6
        bcs     quit
        dec     filename
        ora     #$30
        sta     version
+

        ;get volume name

        inc     c5_parms+3
        lda     #$81
        sta     c5_parms+2
        jsr     $bf00
        !byte   $c5
        !word   c5_parms
        ldx     $381
        inx
        txa
        and     #$0f
        sta     $380
        lda     #$2f
        sta     $381

        ;use that for intepreter location

        jsr     $bf00
        !byte   $c6
        !word   c6_parms

        ;open/read/close

        jsr     $bf00
        !byte   $c8
        !word   c8_parms
        lda     c8_parms+5
        sta     ca_parms+1
        jsr     $bf00
        !byte   $ca
        !word   ca_parms
        jsr     $bf00
        !byte   $cc
        !word   cc_parms

        ;set prefix to passed file

        jsr     $bf00
        !byte   $c6
        !word   c7_parms

        ;run interpreter

        jmp     $3000

c7_parms
        !byte   1
        !word   $280

c5_parms
        !byte   2
        !byte   0
        !word   $281
        !byte   $d1

c6_parms
        !byte   1
        !word   $380

c4_parms
        !byte   $0a
        !word   $2006
        !text   "qkumba was here"

c8_parms
        !byte   3
        !word   filename
        !word   $800
        !byte   0

quit_parms
ca_parms
        !byte   4
        !byte   $ff
        !word   $3000
        !word   $ffff
        !word   $ffff

cc_parms
        !byte   1
        !byte   0

filename
        !byte   (filename_e-filename)-1
        !text   "LIB/ONBEYONDZ"
version !text   "5U"
filename_e

!byte $D3,$C1,$CE,$A0,$C9,$CE,$C3,$AE
