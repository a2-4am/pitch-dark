;license:MIT
;(c) 2018 by qkumba

!cpu 6502
!to "build/zinfo5u",plain
*=$3000

save_name      =    $2006
read_buffer    =    $2e00 ;512 bytes
info_buffer    =    $2000 ;record_size*8, 600 ($258) bytes
zpage_info     =    $fe   ;word
zpage_ptr      =    $fd
zpage_gamind   =    $fc
name_offset    =    0  ;1+37 bytes, a zero-length name is an empty record
time_offset    =    42 ;1+8 bytes ("12:01 pm")
score_offset   =    51 ;1+6 bytes (-12345)
moves_offset   =    58 ;1+5 bytes (12345)
date_offset    =    64 ;1+10 bytes ("10/10/2099")
record_size    =    75 ;bytes

;zpage used by Infocom code
zp_58    =    $58
zp_59    =    $59
zp_5A    =    $5a
zp_5B    =    $5b
zp_6B    =    $6b
zp_6C    =    $6c
zp_6D    =    $6d
zp_6E    =    $6e
zp_7B    =    $7b
zp_7C    =    $7c
zp_7D    =    $7d
zp_7E    =    $7e
zp_7F    =    $7f
zp_80    =    $80
zp_83    =    $83
zp_84    =    $84
zp_87    =    $87
zp_88    =    $88
zp_89    =    $89
zp_8A    =    $8a
zp_A0    =    $a0
zp_A1    =    $a1
zp_A8    =    $a8
zp_A9    =    $a9
zp_AA    =    $aa
zp_AB    =    $ab
zp_AC    =    $ac
zp_AD    =    $ad
zp_AE    =    $ae
zp_CC    =    $cc
zp_CD    =    $cd
zp_CE    =    $ce
zp_CF    =    $cf
zp_D0    =    $d0
zp_D1    =    $d1
zp_D2    =    $d2
zp_D3    =    $d3
zp_D4    =    $d4

    jsr    exchange
    jsr    $bf00
    !byte  $c8       ;open file
    !word  c8_parms
    lda    c8_handle
    sta    ce_handle
    sta    ca_handle

    lda    #>info_buffer
    sta    zpage_info+1
    lda    #<info_buffer
    sta    zpage_info

zero_info
    ldy    #name_offset
    sty    zpage_ptr
    tya
    sta    (zpage_info),y
    clc
    lda    zpage_info
    adc    #record_size
    sta    zpage_info
    bcc    +
    inc    zpage_info+1
+   inc    index+1
index
    lda    #0
    cmp    #8
    bcc    zero_info

    lda    #0
    sta    zpage_gamind
    lda    #<gamelist
    sta    zpage_info
    lda    #>gamelist
    sta    zpage_info+1
--- ldy    #0
    lda    (zpage_info),y
    beq    close
+   pha
    cmp    $2006
    beq    +
--  inc    zpage_gamind
    pla
    sec
    adc    zpage_info
    sta    zpage_info
    bcc    ---
    inc    zpage_info+1
    bne    ---
+   tay
-   lda    $2006,y
    cmp    (zpage_info),y
    bne    --
    dey
    bne    -
    pla

    lda    #>info_buffer
    sta    zpage_info+1
    lda    #<info_buffer
    sta    zpage_info

    ;position to file offset

fetch_info
    lda    #0
    sta    ce_offset+2
position
    ldx    #0
    beq    ++
-   clc
    adc    #$b8
    bcc    +
    inc    ce_offset+2
+   dex
    bne    -
++  clc
    adc    #5
    sta    ce_offset+1
    sta    ce_base1+1
    bcc    +
    inc    ce_offset+2
+   lda    ce_offset+2
    sta    ce_base2+1
    jsr    seekread
    bcs    nextpos
    ldy    #name_offset
    sty    zpage_ptr
    jsr    dump_info

nextpos
    clc
    lda    zpage_info
    adc    #record_size
    sta    zpage_info
    bcc    +
    inc    zpage_info+1
+   inc    position+1
    lda    position+1
    cmp    #3
    bcc    fetch_info

close
    jsr    $bf00
    !byte  $cc       ;close file
    !word  cc_parms

quit
    lda    $bf30
    sta    c5_parms+1
    jsr    $bf00
    !byte  $c5
    !word  c5_parms
    lda    $201
    and    #$0f
    tax
    inx
    stx    $200
    lda    #$2f
    sta    $201
    jsr    $bf00
    !byte  $c6
    !word  c6_parms

exchange
    ldx    #(zp_D4-zp_58)
-   ldy    zpage_old-1,x
    lda    zp_58-1,x
    sty    zp_58-1,x
    sta    zpage_old-1,x
    dex
    bne    -
    rts

load_page
    ldx    zp_80
    cpx    zp_A1
    bne    +
    cmp    zp_A0
    beq    seek_ret
+   stx    zp_A1
    sta    zp_A0
    clc
ce_base1
    adc    #0
    sta    ce_offset+1
    txa
ce_base2
    adc    #0   
    sta    ce_offset+2

seekread
    jsr    $bf00
    !byte  $ce       ;seek
    !word  ce_parms
    bcs    seek_ret
    jsr    $bf00
    !byte  $ca       ;read file
    !word  ca_parms
seek_ret
    rts

c8_parms
    !byte    3
    !word    save_name
    !word    $1C00
c8_handle
    !byte    0

ce_parms
    !byte    2
ce_handle
    !byte    0
ce_offset
    !byte    0,0,0

ca_parms
    !byte    4
ca_handle
    !byte    0
ca_offset
    !word    read_buffer
ca_size
    !word    $200
    !word    $ffff

cc_parms
c6_parms
    !byte    1
    !byte    0

c5_parms
    !byte    2
    !byte    0
    !word    $201
    !byte    $d1

dump_info
    tsx
    stx    stack_pointer+1

    ;set up pointers for decompression and "score" display

    lda    #0
    sta    zp_7E
    sta    zp_80
    sta    zp_A0
    sta    zp_A1
    lda    read_buffer+$0d
    sta    zp_83
    lda    read_buffer+$0c
    sta    zp_84
    lda    read_buffer+$19
    sta    zp_87
    lda    read_buffer+$18
    sta    zp_88
    lda    read_buffer+$0b
    sta    zp_89
    lda    read_buffer+$0a
    sta    zp_8A

    ;dump info, actual Infocom code in upper-case

    lda    #42
    sta    max_chars
    ldx    zpage_gamind
    lda    gameloc, x
    JSR    fetch_obj
    lda    zp_6B
    ora    zp_6C
    bne    +
    rts
+   LDA    zp_6B
    LDX    zp_6C
    JSR    decompress
    lda    zpage_ptr
    ldy    #name_offset
    sta    (zpage_info),y

    ldy    #time_offset
    sty    zpage_ptr
    lda    #0
    sta    max_chars ;can't overflow anymore
    sta    (zpage_info),y

    ldy    #score_offset
    sty    zpage_ptr
    lda    #0
    sta    (zpage_info),y

    ldy    #moves_offset
    sty    zpage_ptr
    lda    #0
    sta    (zpage_info),y

    ldx    zpage_gamind
    lda    gamemoves, x
    beq    skip_moves
    jsr    fetch_obj
    lda    zp_6B
    sta    zp_58
    lda    zp_6C
    sta    zp_59
    jsr    loc_E9E4
    sec
    lda    zpage_ptr
    sbc    #moves_offset
    ldy    #moves_offset
    sta    (zpage_info),y

skip_moves
    ldy    #date_offset
    sty    zpage_ptr
    lda    #0
    sta    (zpage_info),y

rts

!source "src/zinfo/z5u/gamedata.txt"

fetch_obj:
                JSR     sub_E1B1
    lda    zp_6E
    pha
    jsr    load_page
    lda    #>read_buffer
    sta    zp_6E
                LDA     (zp_6D),Y
                STA     zp_6C
                INY
                LDA     (zp_6D),Y
                STA     zp_6B
    pla
    sta    zp_6E
                RTS

sub_E1B1:
                SEC
                SBC     #$10
                LDY     #0
                STY     zp_6E
                ASL
                ROL     zp_6E
                CLC
                ADC     zp_83
                STA     zp_6D
                LDA     zp_6E
                ADC     zp_84
                STA     zp_6E

locret_E1C6:
                RTS

decompress
                JSR     sub_F538
                LDY     #$C
    jsr    load_page
    lda    #>read_buffer
    sta    zp_6E
                LDA     (zp_6D),Y
                TAX
                INY
                LDA     (zp_6D),Y
                STA     zp_6D
                STX     zp_6E
                INC     zp_6D
                BNE     loc_E49C
                INC     zp_6E

loc_E49C:
                JSR     sub_F081
                JMP     sub_F307

sub_E7BD:
                JSR     sub_E7C7
                LDX     zp_CE
                LDA     zp_CF
    rts

sub_E7C7:
                LDA     zp_59
                STA     zp_D3
                EOR     zp_5B
                STA     zp_D2
                LDA     zp_58
                STA     zp_CC
                LDA     zp_59
                STA     zp_CD
                BPL     loc_E7DC
                JSR     sub_E805

loc_E7DC:
                LDA     zp_5A
                STA     zp_CE
                LDA     zp_5B
                STA     zp_CF
                BPL     loc_E7E9
                JSR     sub_E7F7

loc_E7E9:
                JSR     sub_E813
                LDA     zp_D2
                BPL     loc_E7F3
                JSR     sub_E805

loc_E7F3:
                LDA     zp_D3
                BPL     locret_E804

sub_E7F7:
                LDA     #0
                SEC
                SBC     zp_CE
                STA     zp_CE
                LDA     #0
                SBC     zp_CF
                STA     zp_CF

locret_E804:
                RTS

sub_E805:
                LDA     #0
                SEC
                SBC     zp_CC
                STA     zp_CC
                LDA     #0
                SBC     zp_CD
                STA     zp_CD
                RTS

sub_E813:
                JSR     sub_E849

loc_E81C:
                ROL     zp_CC
                ROL     zp_CD
                ROL     zp_D0
                ROL     zp_D1
                LDA     zp_D0
                SEC
                SBC     zp_CE
                TAY
                LDA     zp_D1
                SBC     zp_CF
                BCC     loc_E834
                STY     zp_D0
                STA     zp_D1

loc_E834:
                DEX
                BNE     loc_E81C
                ROL     zp_CC
                ROL     zp_CD
                LDA     zp_D0
                STA     zp_CE
                LDA     zp_D1
                STA     zp_CF
                RTS

sub_E849:
                LDX     #$10
                LDA     #0
                STA     zp_D0
                STA     zp_D1
                CLC
                RTS

loc_E9E4:
                LDA     zp_58
                STA     zp_CC
                LDA     zp_59
                STA     zp_CD
                LDA     zp_CD
                BPL     loc_E9F8
                LDA     #$2D
                JSR     emit_char
                JSR     sub_E805

loc_E9F8:
                LDA     #0
                STA     zp_D4

loc_E9FC:
                LDA     zp_CC
                ORA     zp_CD
                BEQ     loc_EA14
                LDA     #$A
                STA     zp_CE
                LDA     #0
                STA     zp_CF
                JSR     sub_E813
                LDA     zp_CE
                PHA
                INC     zp_D4
                BNE     loc_E9FC

loc_EA14:
                LDA     zp_D4
                BNE     loc_EA1D
                LDA     #$30
                JMP     emit_char

loc_EA1D:
                PLA
                CLC
                ADC     #$30
                JSR     emit_char
                DEC     zp_D4
                BNE     loc_EA1D
                RTS

sub_F081:
                LDA     zp_6D
                STA     zp_7B
                LDA     zp_6E
                STA     zp_7C
                LDA     #0
                STA     zp_7D
                JMP     sub_F109

sub_F109:
    ldy    zp_7D
                LDA     zp_7C
                STY     zp_80
                STA     zp_7F
                RTS

sub_F2AC:
                PHA
                INC     zp_7C
                BNE     loc_F2B3
                INC     zp_7D

loc_F2B3:
                JSR     sub_F109
                PLA
                RTS

sub_F2C4:
                LDY     zp_7B
    lda    zp_7F
    pha
    jsr    load_page
    lda    #>read_buffer
    sta    zp_7F
                LDA     (zp_7E),Y
                INC     zp_7B
                BNE     loc_F2D7
                JSR     sub_F2AC

loc_F2D7:
                TAY
    pla
    sta    zp_7F
    tya
                RTS

sub_F2EE:
                LDA     zp_6D
                ASL
                STA     zp_7B
                LDA     zp_6E
                ROL
                STA     zp_7C
                LDA     #0
                ROL
                STA     zp_7D
                ASL     zp_7B
                ROL     zp_7C
                ROL     zp_7D
                JMP     sub_F109

locret_F306:
                RTS

sub_F307:
                LDX     #0
                STX     zp_A8
                STX     zp_AC
                DEX
                STX     zp_A9

loc_F310:
                JSR     sub_F3ED
                BCS     locret_F306
                STA     zp_AA
                TAX
                BEQ     loc_F35B
                CMP     #4
                BCC     loc_F379
                CMP     #6
                BCC     loc_F35F
                JSR     sub_F3CF
                TAX
                BNE     loc_F333
                LDA     #$5B

loc_F32A:
                CLC
                ADC     zp_AA

loc_F32D:
                JSR     emit_char
                JMP     loc_F310

loc_F333:
                CMP     #1
                BNE     loc_F33B
                LDA     #$3B
                BNE     loc_F32A

loc_F33B:
                LDA     zp_AA
                SEC
                SBC     #6
                BEQ     loc_F349
                TAX
                LDA     byte_F51E,X
                JMP     loc_F32D

loc_F349:
                JSR     sub_F3ED
                ASL
                ASL
                ASL
                ASL
                ASL
                STA     zp_AA
                JSR     sub_F3ED
                ORA     zp_AA
                JMP     loc_F32D

loc_F35B:
                LDA     #$20
                BNE     loc_F32D

loc_F35F:
                SEC
                SBC     #3
                TAY
                JSR     sub_F3CF
                BNE     loc_F36D
                STY     zp_A9
                JMP     loc_F310

loc_F36D:
                STY     zp_A8
                CMP     zp_A8
                BEQ     loc_F310
                LDA     #0
                STA     zp_A8
                BEQ     loc_F310

loc_F379:
                SEC
                SBC     #1
                ASL
                ASL
                ASL
                ASL
                ASL
                ASL
                STA     zp_AB
                JSR     sub_F3ED
                ASL
                CLC
                ADC     zp_AB
                TAY
    lda    zp_88
    pha
    jsr    load_page
    lda    #>read_buffer
    sta    zp_88
                LDA     (zp_87),Y
                STA     zp_6E
                INY
                LDA     (zp_87),Y
                STA     zp_6D
    pla
    sta    zp_88
                LDA     zp_7D
                PHA
                LDA     zp_7C
                PHA
                LDA     zp_7B
                PHA
                LDA     zp_A9
                PHA
                LDA     zp_AC
                PHA
                LDA     zp_AE
                PHA
                LDA     zp_AD
                PHA
                JSR     sub_F3DB
                JSR     sub_F307
                PLA
                STA     zp_AD
                PLA
                STA     zp_AE
                PLA
                STA     zp_AC
                PLA
                STA     zp_A8
                PLA
                STA     zp_7B
                PLA
                STA     zp_7C
                PLA
                STA     zp_7D
                LDX     #$FF
                STX     zp_A9
                JSR     sub_F109
                JMP     loc_F310

sub_F3CF:
                LDA     zp_A9
                BPL     loc_F3D6
                LDA     zp_A8
                RTS

loc_F3D6:
                LDY     #$FF
                STY     zp_A9
                RTS

sub_F3DB:
                LDA     zp_6D
                ASL
                STA     zp_7B
                LDA     zp_6E
                ROL
                STA     zp_7C
                LDA     #0
                ROL
                STA     zp_7D
                JMP     sub_F109

sub_F3ED:
                LDA     zp_AC
                BPL     loc_F3F3
                SEC
                RTS

loc_F3F3:
                BNE     loc_F408
                INC     zp_AC
                JSR     sub_F2C4
                STA     zp_AE
                JSR     sub_F2C4
                STA     zp_AD
                LDA     zp_AE
                LSR
                LSR
                JMP     loc_F431

loc_F408:
                SEC
                SBC     #1
                BNE     loc_F423
                LDA     #2
                STA     zp_AC
                LDA     zp_AD
                STA     zp_6D
                LDA     zp_AE
                ASL     zp_6D
                ROL
                ASL     zp_6D
                ROL
                ASL     zp_6D
                ROL
                JMP     loc_F431

loc_F423:
                LDA     #0
                STA     zp_AC
                LDA     zp_AE
                BPL     loc_F42F
                LDA     #$FF
                STA     zp_AC

loc_F42F:
                LDA     zp_AD

loc_F431:
                AND     #$1F
                CLC
                RTS

byte_F51E:
      !BYTE 0, $D, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', ',', '!', '?', '_'
      !BYTE '#', $27, '"', '/', $5C, '-', ':', '(', ')'

sub_F538:
                STX     zp_6E
                ASL
                STA     zp_6D
                ROL     zp_6E
                LDX     zp_6E
                ASL
                ROL     zp_6E
                ASL
                ROL     zp_6E
                ASL
                ROL     zp_6E
                SEC
                SBC     zp_6D
                STA     zp_6D
                LDA     zp_6E
                STX     zp_6E
                SBC     zp_6E
                STA     zp_6E
                LDA     zp_6D
                CLC
                ADC     #$70
                BCC     loc_F5B5
                INC     zp_6E

loc_F5B5:
                CLC
                ADC     zp_89
                STA     zp_6D
                LDA     zp_6E
                ADC     zp_8A
                STA     zp_6E
                RTS

emit_char
    sty    yreg+1
    inc    zpage_ptr
    ldy    zpage_ptr
    sta    (zpage_info),y
    dec    max_chars
    beq    fail_slot
yreg
    ldy    #0
    rts

fail_slot
stack_pointer
    ldx    #0
    txs
    rts

max_chars  !byte 0

zpage_old
