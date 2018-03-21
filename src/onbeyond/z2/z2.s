;license:MIT
;(c) 2017-2018 by qkumba

!cpu 6502
!to "build/ONBEYONDZ2#063000",plain
*=$3000

!macro version {!scrxor $80, "1/180221"}

                ;user-defined options
                verbose_info = 0        ;set to 1 to enable display of memory usage

gamename=$2940
savename=$2980
scrpname=$29C0

;unpacker variables, no need to change these
src        =        $0
dst        =        $2
ecx        =        $4
last       =        $6
tmp        =        $8

-       jsr     $bf00
op_c7

        !byte   $c7
        !word   c7_parms
        ldx     $200
        bne     +
        lda     $bf30
        sta     c5_parms+1
        jsr     $bf00
        !byte   $c5
        !word   c5_parms
        ldx     $201
        inx
        txa
        and     #$0f
        sta     $200
        lda     #$2f
        sta     $201
        dec     op_c7
        bne     -
+

        ldy     $2006
        lda     #'2'
        sta     gamename,y
        lda     #'Z'
        sta     gamename-1,y
        lda     #'V'
        sta     savename+1,y
        lda     #'A'
        sta     savename,y
        lda     #'S'
        sta     savename-1,y
        lda     #'G'
        sta     scrpname+1,y
        lda     #'O'
        sta     scrpname,y
        lda     #'L'
        sta     scrpname-1,y
        dey
        dey
-       lda     $2006,y
        sta     gamename,y
        sta     savename,y
        sta     scrpname,y
        dey
        bpl     -
        inc     savename
        inc     scrpname

        lda     $306
        eor     $305
        eor     $304
        eor     $303
        eor     $302
        eor     $301
        eor     $300
        eor     #$a5
        beq     +
        ldx     #0
        stx     $303        ;no script
        stx     $304
        dex
        stx     $302        ;no load
+

        jsr     $fe93
        jsr     $fc58
        lda     #$17
        sta     $25
        lda     #0
        sta     $24
        sta     $57b
        jsr     $fc22
        ldy     #0
        beq     +
-       jsr     $fdf0
        iny
+       lda     brandtext,y
        bne     -

        lda     #>pakoff
        sta     src + 1
        lda     #<pakoff
        sta     src
        lda     #8
        sta     dst + 1
        lda     #0
        sta     dst
        jsr     unpack

        ;copy new RWTS and interpreter support routines

        ldy     #0
-       lda     unrelochdd, y
        sta     $2800, y
        iny
        bne     -
        ldy     #<(hddcodeend - $2800)
-       lda     unrelochdd + $ff, y
        sta     $28ff, y
        dey
        bne     -

        sty     $1e05
        sty     $1e2b
        lda     #$28
        sta     $1e06
        sta     $1e2c

        lda     $303
        beq     +
        lda     #<print
        sta     $1beb
        lda     #>print
        sta     $1bec
        lda     #<printer
        sta     $1d62
        lda     #>printer
        sta     $1d63

        lda     $304
        beq     +
        lda     #<callbackprn1
        sta     $1d4a
        lda     #>callbackprn1
        sta     $1d4b
+
        ldx     $302
        inx
        beq     +
        lda     $1d4a
        sta     loadcall1+1
        lda     $1d4b
        sta     loadcall2+1
        lda     #<callback1
        sta     $1d4a
        lda     #>callback1
        sta     $1d4b
+

        lda     #<savefile
        sta     $2065
        lda     #>savefile
        sta     $2066
        lda     #<loadfile
        sta     $20fe
        lda     #>loadfile
        sta     $20ff
        lda     #<closefile
        sta     $20e6
        sta     $20ec
        sta     $2192
        sta     $2198
        lda     #>closefile
        sta     $20e7
        sta     $20ed
        sta     $2193
        sta     $2199
        lda     #<quit
        sta     $21d1
        lda     #>quit
        sta     $21d2

        jsr     closefile
        lda     #$60
        sta     $7c ;!
        jmp     $800

brandtext
        !scrxor $80, "ON BEYOND Z-MACHINE! REVISION "
        +version
        !byte   0

c7_parms
        !byte   1
        !word   $200

c5_parms
        !byte   2
        !byte   0
        !word   $201

unrelochdd
!pseudopc $2800 {
        clc
        adc     #$c9
        sta     pro_op
        lda     #0
        sta     ce_parms+2
        lda     $e4
        sta     ce_parms+3
        lda     $e5
        sta     ce_parms+4
        lda     $e7
        sta     ca_parms+3

-       jsr     $bf00
        !byte   $ce                ;seek
        !word   ce_parms
        bcc     +
        jsr     $bf00
        !byte   $d0                ;set EOF
        !word   ce_parms
        bcc     -

+
        jsr     $bf00
pro_op
        !byte   $ca                ;read file
        !word   ca_parms
        bcs     quit
        rts

printer
        ldx     $eb
        lda     #$8d
        sta     $200,x
        inx
        stx     cb_parms+4
        lda     #<scrpname
        sta     c8_parms+1
        ldx     #(<gamename xor <scrpname)
        jsr     closefile1

        jsr     $bf00
        !byte   $d1
        !word   ce_parms

        jsr     $bf00
        !byte   $ce
        !word   ce_parms

        jsr     $bf00
        !byte   $cb
        !word   cb_parms

        bcc     closefile

quit
        jsr     xclose
        jsr     $bf00
        !byte   $65
        !word   quit_parms

savefile
        jsr     $bf00
        !byte   $c0
        !word   c0_parms
loadfile
        lda     #$ff
        sta     $e4
        sta     $e5

closefile
        ldx     #(<gamename xor <savename)

closefile1
        jsr     xclose
        jsr     xopen
        txa
        eor     c8_parms+1
        sta     c8_parms+1
        rts

callback1
        ldx     #$ff
-       inx
        lda     xrestore,x
        sta     $200,x
        jsr     $fded
        cmp     #$8d
        bne     -
loadcall1
        ldy     #$6f
        sty     $1d4a
loadcall2
        ldy     #$fd
        sty     $1d4b
        rts

xrestore
        !byte   $d2,$c5,$d3,$d4,$cf,$d2,$c5,$8d

callbackprn1
        ldx     #$ff
-       inx
        lda     xscript,x
        sta     $200,x
        jsr     $fded
        cmp     #$8d
        bne     -
        ldy     #$6f
        sty     $1d4a
        ldy     #$fd
        sty     $1d4b
        rts

xscript
        !byte   $d3,$c3,$d2,$c9,$d0,$d4,$8d

print
        jsr     $bf00
        !byte   $c1
        !word   c1_parms
        lda     #<scrpname
        sta     c0_parms+1
        jsr     $bf00
        !byte   $c0
        !word   c0_parms

        lda     #<printer
        sta     $1beb
        lda     #>printer
        sta     $1bec

        lda     #<savename
        sta     c0_parms+1
        rts

xclose
        jsr     $bf00
        !byte   $cc
        !word   cc_parms
        rts

xopen
        jsr     $bf00
        !byte   $c8
        !word   c8_parms
        lda     c8_parms+5
        sta     ce_parms+1
        sta     ca_parms+1
        sta     cb_parms+1
        rts

c8_parms
        !byte    3
        !word    gamename
        !word    $2400
        !byte    0

c0_parms
        !byte    7
        !word    savename
        !byte    %11000011
        !byte    04
        !word    0
cc_parms
        !byte    1
        !word    0
        !word    0

ce_parms
        !byte    2
        !byte    0
        !byte    0
        !byte    0
        !byte    0

ca_parms
        !byte    4
        !byte    $ff
        !word    $2900
        !word    $100
        !word    $ffff

c1_parms
        !byte    1
        !word    scrpname

cb_parms
quit_parms
        !byte    4
        !byte    $ff
        !word    $200
        !word    $00ff
        !word    $ffff
hddcodeend
}

unpack ;unpacker entrypoint
        lda    #0
        sta    last
        sta    ecx+1

literal
        jsr    getput
        ldy    #2

nexttag
        jsr    getbit
        bcc    literal
        jsr    getbit
        bcc    codepair
        jsr    getbit
        bcs    onebyte
        jsr    getsrc
        lsr
        beq    donedepacking
        ldx    #0
        stx    ecx
        rol    ecx
        stx    last+1
        tax
        bne    domatch_with_2inc

getbit
        asl    last
        bne    .stillbitsleft
        jsr    getsrc
        sec
        rol
        sta    last

.stillbitsleft

donedepacking
        rts

onebyte
        ldy    #0
        sty    tmp+1
        iny
        sty    ecx
        iny
        lda    #$10

.getmorebits
        pha
        jsr    getbit
        pla
        rol
        bcc    .getmorebits
        bne    domatch
        jsr    putdst

linktag
        bne    nexttag

codepair
        jsr    getgamma
-       jsr    dececx
        dey
        bne    -
        tay
        beq    +

normalcodepair
        dey
        sty    last+1
        jsr    getsrc
        tax
        !byte  $a9
+       iny
        jsr    getgamma
        cpy    #$7d
        bcs    domatch_with_2inc
        cpy    #5
        bcs    domatch_with_inc
        txa
        bmi    domatch_new_lastpos
        tya
        bne    domatch_new_lastpos

domatch_with_2inc
        clc
        !byte  $24
set_carry
        sec

domatch_with_inc
        inc    ecx
        bne    test_carry
        inc    ecx+1
test_carry
        bcc    set_carry

domatch_new_lastpos

domatch_lastpos
        ldy    #1
        lda    last+1
        sta    tmp+1
        txa

domatch
        sta    tmp
        lda    src+1
        pha
        lda    src
        pha
        lda    dst
        sec
        sbc    tmp
        sta    src
        lda    dst+1
        sbc    tmp+1
        sta    src+1
;;access1
;;      sta    $c003
-       jsr    getput
        jsr    dececx
        ora    ecx+1
        bne    -
;;      sta    $c002
        pla
        sta    src
        pla
        sta    src+1
        bne    linktag

getgamma
        lda    #1
        sta    ecx

.getgammaloop
        jsr    getbit
        rol    ecx
        rol    ecx+1
        jsr    getbit
        bcs    .getgammaloop
        rts

dececx
        lda    ecx
        bne    +
        dec    ecx+1
+       dec    ecx
        lda    ecx
        rts

getput
        jsr    getsrc

putdst
        sty    tmp
        ldy    #0
        sta    (dst), y
        inc    dst
        bne    +
        inc    dst+1
        bne    +

getsrc
        sty    tmp
        ldy    #0
        lda    (src), y
        inc    src
        bne    +
        inc    src+1
+       ldy    tmp
        rts

pakoff
!bin "src/onbeyond/z2/0800-21ff.pak"

!byte $D3,$C1,$CE,$A0,$C9,$CE,$C3,$AE