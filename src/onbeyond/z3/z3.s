;license:MIT
;(c) 2017-2018 by qkumba

!cpu 6502
!to "build/ONBEYONDZ3",plain
*=$3000

!macro version {!text "1/180221"}

                ;user-defined options
                verbose_info = 0        ;set to 1 to enable display of memory usage

gamename=$307
savename=$350
scrpname=$390

;unpacker variables, no need to change these
src        =        $0
dst        =        $2
ecx        =        $4
last       =        $6
tmp        =        $8

        ldy     $2006
        lda     #'3'
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

        lda     #>pakoff
        sta     src + 1
        lda     #<pakoff
        sta     src
        lda     #$0d
        sta     dst + 1
        lda     #$7d
        sta     dst
        jsr     unpack

        ;init interpreter

        jsr     $d7d

        ;copy new RWTS and interpreter support routines

        ldy     #0
-       lda     unrelochdd, y
        sta     $c11, y
        iny
        bne     -
        ldy     #<(hddcodeend - $c11)
-       lda     unrelochdd + $ff, y
        sta     $d10, y
        dey
        bne     -
        lda     $bf30
        sta     c5_parms+1

        lda     $306
        eor     $305
        eor     $304
        eor     $303
        eor     $302
        eor     $301
        eor     $300
        eor     #$a5
        beq     +
        lda     #$D9
        sta     $300        ;80-cols
        ldx     #1
        stx     $301        ;lowercase
        dex
        stx     $303        ;no script
        dex
        stx     $302        ;no load
+

        jsr     $fe93
        ldx     $300
        cpx     #$ce
        beq     skip80
        lda     $bf98
        and     #2
        bne     okay80
        ldx     #$ce

skip80
        lda     #$df
        sta     mapmask+1
okay80
        stx     $1793

        lda     $301
        beq     +
        lda     $bf98
        bpl     +
        inc     $17ba
        bne     ++
+
        lda     #0
        sta     $1267
++
        lda     $303
        beq     +
        lda     #<print
        sta     $18ba
        lda     #>print
        sta     $18bb
        lda     #<printer
        sta     $1364
        lda     #>printer
        sta     $1365

        lda     $304
        beq     +
        lda     #<callbackprn1
        sta     $11de
        lda     #>callbackprn1
        sta     $11df
+
        ldx     $302
        inx
        beq     +
        lda     $11de
        sta     loadcall1+1
        lda     $11df
        sta     loadcall2+1
        lda     #<callback1
        sta     $11de
        lda     #>callback1
        sta     $11df
+
        lda     #<brand
        sta     $17eb
        lda     #>brand
        sta     $17ec

        lda     #<savefile
        sta     $d7d+$340
        lda     #>savefile
        sta     $d7d+$341
        lda     #<loadfile
        sta     $d7d+$3d2
        lda     #>loadfile
        sta     $d7d+$3d3
        lda     #<closefile
        sta     $d7d+$36c
        sta     $d7d+$449
        lda     #>closefile
        sta     $d7d+$36d
        sta     $d7d+$44a
        lda     #$20
        sta     $d7d+$76b
        lda     #<casemap
        sta     $d7d+$76c
        lda     #>casemap
        sta     $d7d+$76d
        lda     #<quit
        sta     $d7d+$709
        lda     #>quit
        sta     $d7d+$70a
        lda     #<waitkey
        sta     $d7d+$6fa
        lda     #>waitkey
        sta     $d7d+$6fb

        jsr     closefile
        jmp     $173d

brand
        jsr     $12f8
        lda     #$f8
        sta     $17eb
        lda     #$12
        sta     $17ec
        lda     #$17
        sta     $25
        lda     #0
        sta     $24
        sta     $57b
        jsr     $fc22
        lda     #>brandtext
        ldx     #<brandtext
        ldy     #(brandtext_e-brandtext)
        jmp     $12f8

brandtext
        !text   "On Beyond Z-Machine! revision "
        +version
brandtext_e

unrelochdd
!pseudopc $c11 {
        ora    #$ca
        sta    pro_op
        lda    #0
        sta    ce_parms+2
        sta    ce_parms+4
        sec
        lda    $65
adjust
        sbc    #0
        asl
        asl
        asl
        rol    ce_parms+4
        asl
        rol    ce_parms+4
        ora    $64
        sta    ce_parms+3

-       jsr    $bf00
        !byte  $ce                ;seek
        !word  ce_parms
        bcc    +
        jsr    $bf00
        !byte  $d0                ;set EOF
        !word  ce_parms
        bcc    -

+
        jsr    $bf00
pro_op
        !byte  $ca                ;read file
        !word  ca_parms
        bcs    jmpquit
-       rts

printer
        cmp    #$8d
        bne    -
        iny
        sty    cb_parms+4
        dey
        lda    #<scrpname
        sta    c8_parms+1
        ldx    #(<gamename xor <scrpname)
        jsr    closefile1

        jsr    $bf00
        !byte  $d1
        !word  ce_parms

        jsr    $bf00
        !byte  $ce
        !word  ce_parms

        jsr    $bf00
        !byte  $cb
        !word  cb_parms

        bcc    closefile

jmpquit
        jmp    $dfe

savefile
        jsr    $bf00
        !byte  $c0
        !word  c0_parms
        lda    $e5a
        sta    c0_parms+5
        jsr    $bf00
        !byte  $c3
        !word  c0_parms
        ldx    #$e6
        !byte  $2c
loadfile
        ldx    #$b8

        lda    #$0d
        pha
        txa
        pha

closefile
        ldx    #(<gamename xor <savename)

closefile1
        jsr    xclose
        jsr    xopen
        lda    adjust+1
        eor    #3
        sta    adjust+1
        txa
        eor    c8_parms+1
        sta    c8_parms+1
        rts

callback1
        lda    xrestore,y
        cmp    #$8d
        bne    +
        ldx    #<callback2
        stx    $11de
;!if #>callback1 != #>callback2 {
;        ldx   #>callback2
;        stx   $11df
;}
+        rts

callback2
        lda    $302
        ora    #$b0
        ldx    #<callback3
        stx    $11de
;!if #>callback2 != #>callback3 {
;        ldx   #>callback3
;        stx   $11df
;}
+        rts

callback3
        lda    #$D9
loadcall1
        ldx    #$0c
        stx    $11de
loadcall2
        ldx    #$fd
        stx    $11df
        rts

xrestore
        !byte  $d2,$c5,$d3,$d4,$cf,$d2,$c5,$8d

callbackprn1
        lda    xscript,y
        cmp    #$8d
        bne    +
        ldx    #$0c
        stx    $11de
        ldx    #$fd
        stx    $11df
+       rts

xscript
        !byte  $d3,$c3,$d2,$c9,$d0,$d4,$8d

print
        jsr    $bf00
        !byte  $c1
        !word  c1_parms
        lda    #<scrpname
        sta    c0_parms+1
        jsr    $bf00
        !byte  $c0
        !word  c0_parms

        inc    $1363
        lda    #<savename
        sta    c0_parms+1
        rts

xclose
        jsr    $bf00
        !byte  $cc
        !word  cc_parms
        rts

xopen
        jsr    $bf00
        !byte  $c8
        !word  c8_parms
        lda    c8_parms+5
        sta    ce_parms+1
        sta    ca_parms+1
        sta    cb_parms+1
        rts

casemap
        ldy    $32
        bmi    +
        cmp    #$61
        bcc    +
        cmp    #$7b
        bcs    +
mapmask
        and    #$ff
+       sta    $200,x
-       rts

waitkey
        jsr    $12f8
        lda    $c010
-       lda    $c000
        bpl    -

quit
        jsr    xclose

        jsr    $bf00
        !byte  $c5
        !word  c5_parms
        ldx    $201
        inx
        txa
        and    #$0f
        sta    $200
        lda    #$2f
        sta    $201
        jsr    $bf00
        !byte  $c6
        !word  c6_parms

        jsr    $bf00
        !byte  $65
        !word  quit_parms

c8_parms
        !byte  3
        !word  gamename
        !word  $800
        !byte  0

c0_parms
        !byte  7
        !word  savename
        !byte  %11000011
        !byte  04
        !word  0
cc_parms
        !byte  1
        !word  0
        !word  0

ce_parms
        !byte  2
        !byte  0
        !byte  0
        !byte  0
        !byte  0

ca_parms
        !byte  4
        !byte  $ff
        !word  $2900
        !word  $100
        !word  $ffff

c1_parms
c6_parms
        !byte  1
        !word  scrpname

c5_parms
        !byte  2
        !byte  0
        !word  scrpname+1
        !byte  $d1

cb_parms
quit_parms
        !byte  4
        !byte  $ff
        !word  $200
        !word  $00ff
        !word  $ffff
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

!ifdef PASS2 {
  !if >callback1 != >callback2 {
    !if verbose_info = 1 {
      !warn "callbacks=", >callback1, >callback2
    } ;verbose_info
  }
  !if >callback2 != >callback3 {
    !if verbose_info = 1 {
      !warn "callbacks=", >callback2, >callback3
    } ;verbose_info
  }
} else {
  !set PASS2=1
}

pakoff
!bin "src/onbeyond/z3/0d7d-2739.pak"

!byte $D3,$C1,$CE,$A0,$C9,$CE,$C3,$AE
