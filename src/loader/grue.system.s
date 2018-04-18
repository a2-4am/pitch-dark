;license:MIT
;(c) 2018 by qkumba

!cpu 6502
*=$2000
!to "build/GRUE.SYSTEM",plain

        !source "src/constants.a"

        lda     $BF98        ; machine identification byte
        and     #$30
        cmp     #$30         ; 128K?
        bne     QuitToProDOS ; no, quit to ProDOS
        !byte   $1a          ; 65C02 INC, clear Z flag if supported
        beq     QuitToProDOS ; not a 65C02

-       jsr     $bf00
op_c7
        !byte   $c7
        !word   runme+c7_parms-reloc
        ldx     runme+prefix-reloc
        bne     +
        lda     $bf30
        sta     c5_parms+1
        jsr     $bf00
        !byte   $c5
        !word   c5_parms
        ldx     runme+prefix+1-reloc
        inx
        txa
        and     #$0f
        sta     runme+prefix-reloc
        lda     #$2f
        sta     runme+prefix+1-reloc
        dec     op_c7
        bne     -
+       lda     #<prefix
        sta     runme+c6_parms+1-reloc
        lda     #>prefix
        sta     runme+c6_parms+2-reloc
        lda     $c083
        lda     $c083
        ldy     #0
-       lda     runme,y
        sta     $d100,y ;$d1 heh.
        sta     $1000,y
        iny
        bne     -
        jmp     $1000

QuitToProDOS
        jsr     $bf00
        !byte   $65
        !word   quit_parms
quit_parms
        !byte   4

c5_parms
        !byte   2
        !byte   0
        !word   runme+prefix+1-reloc

runme !pseudopc $1000 {
reloc   cld
        lda     $c082
        sta     $c00c
        sta     $c000
        jsr     $fe93
        jsr     $fe89
        sta     $4fb
        jsr     $fb2f
        jsr     $fc58
        ldx     #$df
        lda     #$cf
-       sta     $be79,x
        lda     #0
        txs
        inx
        bne     -
        inc     $bf6f
        jsr     $bf00
        !byte   $c6
        !word   c6_parms
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
        jmp     kPitchDarkBinaryAddress

c7_parms
c6_parms
        !byte   1
        !word   runme+prefix-reloc

c8_parms
        !byte   3
        !word   filename
        !word   $800
        !byte   0

ca_parms
        !byte   4
        !byte   $d1
        !word   kPitchDarkBinaryAddress
        !word   $ffff
        !word   $34d1

cc_parms
        !byte   1
        !byte   0

filename
        !byte   (filename_e-filename)-1
        !text   "PITCH.DARK"
filename_e

prefix
}
