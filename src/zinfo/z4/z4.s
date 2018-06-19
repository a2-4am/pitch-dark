;license:MIT
;(c) 2018 by qkumba

!cpu 6502
!to "build/zinfo4",plain
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
zp_A6    =    $a6
zp_A7    =    $a7
zp_A8    =    $a8
zp_A9    =    $a9
zp_AA    =    $aa
zp_AB    =    $ab
zp_AC    =    $ac
zp_C7    =    $c7
zp_C8    =    $c8
zp_C9    =    $c9
zp_CA    =    $ca
zp_CB    =    $cb
zp_CC    =    $cc
zp_CD    =    $cd
zp_CE    =    $ce
zp_CF    =    $cf

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
    adc    #$88
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
    cmp    #4
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
    ldx    #(zp_CF-zp_58)
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
    !byte    2

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

    asl    zpage_gamind
    ldx    zpage_gamind
    lda    gametime, x
    beq    skip_time

    lda    #$9d ;in-simulation
    jsr    fetch_obj
    lda    zp_6B
    ora    zp_6C
    bne    in_sim1
    inc    zpage_gamind

in_sim1
    ldx    zpage_gamind
    lda    gametime, x
    jsr    fetch_obj
    lda    zp_6B
    sta    zp_58
    lda    zp_6C
    sta    zp_59
    lda    #$3c
    sta    zp_5A
    lda    #0
    sta    zp_5B
    jsr    sub_E7FB
    sta    zp_59
    cpx    #$0d
    bcc    +
    txa
    sbc    #$0c
    tax
+   stx    zp_58
    lda    zp_C9
    pha
    lda    zp_CA
    pha
    jsr    sub_EA09
    lda    #':'
    jsr    emit_char
    pla
    sta    zp_59
    pla
    sta    zp_58
    cmp    #$0a
    bcs    +
    lda    #$30
    jsr    emit_char
+   jsr    sub_EA09
    lda    #'a'
    ldx    zp_6C
    cpx    #2
    bcc    is_am
    bne    is_pm
    ldx    zp_6B
    cpx    #$d0
    bcc    is_am
is_pm
    lda    #'p'
is_am
    jsr    emit_char
    lda    #'m'
    jsr    emit_char
    sec
    lda    zpage_ptr
    sbc    #time_offset
    ldy    #time_offset
    sta    (zpage_info),y

skip_time
    lsr    zpage_gamind
    ldy    #score_offset
    sty    zpage_ptr
    lda    #0
    sta    (zpage_info),y

    ldx    zpage_gamind
    lda    gamescore, x
    beq    skip_score
    jsr    fetch_obj
    lda    zp_6B
    sta    zp_58
    lda    zp_6C
    sta    zp_59
    jsr    sub_EA09
    sec
    lda    zpage_ptr
    sbc    #score_offset
    ldy    #score_offset
    sta    (zpage_info),y

skip_score
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
    jsr    sub_EA09
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

    asl    zpage_gamind
    ldx    zpage_gamind
    lda    gamemonth, x
    beq    skip_date

    lda    #$9d ;in-simulation
    jsr    fetch_obj
    lda    zp_6B
    ora    zp_6C
    bne    in_sim2
    inc    zpage_gamind

in_sim2
    ldx    zpage_gamind
    lda    gamemonth, x
    jsr    fetch_obj
    lda    zp_6B
    sta    zp_58
    lda    zp_6C
    sta    zp_59
    jsr    sub_EA09
    lda    #$2f
    jsr    emit_char
    ldx    zpage_gamind
    lda    gameday, x
    jsr    fetch_obj
    lda    zp_6B
    sta    zp_58
    lda    zp_6C
    sta    zp_59
    jsr    sub_EA09
    lda    #$2f
    jsr    emit_char
    ldx    zpage_gamind
    lda    gameyear, x
    jsr    fetch_obj
    lda    zp_6B
    sta    zp_58
    lda    zp_6C
    sta    zp_59
    jsr    sub_EA09
    sec
    lda    zpage_ptr
    sbc    #date_offset
    ldy    #date_offset
    sta    (zpage_info),y

skip_date
    lsr    zpage_gamind
rts

!source "src/zinfo/z4/gamedata.txt"

fetch_obj:
                JSR     sub_E174
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

sub_E174:
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

locret_E189:
                RTS

decompress
                JSR     sub_F285
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
                BNE     loc_E4FA
                INC     zp_6E

loc_E4FA:
                JSR     loc_EDCE
                JMP     sub_F054

sub_E7FB:
                JSR     sub_E80F
                LDX     zp_C7
                LDA     zp_C8
    rts

sub_E80F:
                LDA     zp_59
                STA     zp_CE
                EOR     zp_5B
                STA     zp_CD
                LDA     zp_58
                STA     zp_C7
                LDA     zp_59
                STA     zp_C8
                BPL     loc_E824
                JSR     sub_E84D

loc_E824:
                LDA     zp_5A
                STA     zp_C9
                LDA     zp_5B
                STA     zp_CA
                BPL     loc_E831
                JSR     sub_E83F

loc_E831:
                JSR     sub_E85B
                LDA     zp_CD
                BPL     loc_E83B
                JSR     sub_E84D

loc_E83B:
                LDA     zp_CE
                BPL     locret_E84C

sub_E83F:
                LDA     #0
                SEC
                SBC     zp_C9
                STA     zp_C9
                LDA     #0
                SBC     zp_CA
                STA     zp_CA

locret_E84C:
                RTS

sub_E84D:
                LDA     #0
                SEC
                SBC     zp_C7
                STA     zp_C7
                LDA     #0
                SBC     zp_C8
                STA     zp_C8
                RTS

sub_E85B:
                JSR     sub_E891

loc_E864:
                ROL     zp_C7
                ROL     zp_C8
                ROL     zp_CB
                ROL     zp_CC
                LDA     zp_CB
                SEC
                SBC     zp_C9
                TAY
                LDA     zp_CC
                SBC     zp_CA
                BCC     loc_E87C
                STY     zp_CB
                STA     zp_CC

loc_E87C:
                DEX
                BNE     loc_E864
                ROL     zp_C7
                ROL     zp_C8
                LDA     zp_CB
                STA     zp_C9
                LDA     zp_CC
                STA     zp_CA
                RTS

sub_E891:
                LDX     #$10
                LDA     #0
                STA     zp_CB
                STA     zp_CC
                CLC
                RTS

sub_EA09:
                LDA     zp_58
                STA     zp_C7
                LDA     zp_59
                STA     zp_C8
                LDA     zp_C8
                BPL     loc_EA1D
                LDA     #$2D
                JSR     emit_char
                JSR     sub_E84D

loc_EA1D:
                LDA     #0
                STA     zp_CF

loc_EA21:
                LDA     zp_C7
                ORA     zp_C8
                BEQ     loc_EA39
                LDA     #$A
                STA     zp_C9
                LDA     #0
                STA     zp_CA
                JSR     sub_E85B
                LDA     zp_C9
                PHA
                INC     zp_CF
                BNE     loc_EA21

loc_EA39:
                LDA     zp_CF
                BNE     loc_EA42
                LDA     #$30
                JMP     emit_char

loc_EA42:
                PLA
                CLC
                ADC     #$30
                JSR     emit_char
                DEC     zp_CF
                BNE     loc_EA42
                RTS

loc_EDCE:
                LDA     zp_6D
                STA     zp_7B
                LDA     zp_6E
                STA     zp_7C
                LDA     #0
                STA     zp_7D
                JMP     sub_EE56

sub_EE56:
    ldy    zp_7D
                LDA     zp_7C
                STY     zp_80
                STA     zp_7F
                RTS

sub_EFF9:
                PHA
                INC     zp_7C
                BNE     loc_F000
                INC     zp_7D

loc_F000:
                JSR     sub_EE56
                PLA
                RTS

sub_F011:
                LDY     zp_7B
    lda    zp_7F
    pha
    jsr    load_page
    lda    #>read_buffer
    sta    zp_7F
                LDA     (zp_7E),Y
                INC     zp_7B
                BNE     loc_F024
                JSR     sub_EFF9

loc_F024:
                TAY
    pla
    sta    zp_7F
    tya
                RTS

locret_F053:
                RTS

sub_F054:
                LDX     #0
                STX     zp_A6
                STX     zp_AA
                DEX
                STX     zp_A7

loc_F05D:
                JSR     sub_F13A
                BCS     locret_F053
                STA     zp_A8
                TAX
                BEQ     loc_F0A8
                CMP     #4
                BCC     loc_F0C6
                CMP     #6
                BCC     loc_F0AC
                JSR     sub_F11C
                TAX
                BNE     loc_F080
                LDA     #$5B

loc_F077:
                CLC
                ADC     zp_A8

loc_F07A:
                JSR     emit_char
                JMP     loc_F05D

loc_F080:
                CMP     #1
                BNE     loc_F088
                LDA     #$3B
                BNE     loc_F077

loc_F088:
                LDA     zp_A8
                SEC
                SBC     #6
                BEQ     loc_F096
                TAX
                LDA     byte_F26B,X
                JMP     loc_F07A

loc_F096:
                JSR     sub_F13A
                ASL
                ASL
                ASL
                ASL
                ASL
                STA     zp_A8
                JSR     sub_F13A
                ORA     zp_A8
                JMP     loc_F07A

loc_F0A8:
                LDA     #$20
                BNE     loc_F07A

loc_F0AC:
                SEC
                SBC     #3
                TAY
                JSR     sub_F11C
                BNE     loc_F0BA
                STY     zp_A7
                JMP     loc_F05D

loc_F0BA:
                STY     zp_A6
                CMP     zp_A6
                BEQ     loc_F05D
                LDA     #0
                STA     zp_A6
                BEQ     loc_F05D

loc_F0C6:
                SEC
                SBC     #1
                ASL
                ASL
                ASL
                ASL
                ASL
                ASL
                STA     zp_A9
                JSR     sub_F13A
                ASL
                CLC
                ADC     zp_A9
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
                LDA     zp_A6
                PHA
                LDA     zp_AA
                PHA
                LDA     zp_AC
                PHA
                LDA     zp_AB
                PHA
                JSR     sub_F128
                JSR     sub_F054
                PLA
                STA     zp_AB
                PLA
                STA     zp_AC
                PLA
                STA     zp_AA
                PLA
                STA     zp_A6
                PLA
                STA     zp_7B
                PLA
                STA     zp_7C
                PLA
                STA     zp_7D
                LDX     #$FF
                STX     zp_A7
                JSR     sub_EE56
                JMP     loc_F05D

sub_F11C:
                LDA     zp_A7
                BPL     loc_F123
                LDA     zp_A6
                RTS

loc_F123:
                LDY     #$FF
                STY     zp_A7
                RTS

sub_F128:
                LDA     zp_6D
                ASL
                STA     zp_7B
                LDA     zp_6E
                ROL
                STA     zp_7C
                LDA     #0
                ROL
                STA     zp_7D
                JMP     sub_EE56

sub_F13A:
                LDA     zp_AA
                BPL     loc_F140
                SEC
                RTS

loc_F140:
                BNE     loc_F155
                INC     zp_AA
                JSR     sub_F011
                STA     zp_AC
                JSR     sub_F011
                STA     zp_AB
                LDA     zp_AC
                LSR
                LSR
                JMP     loc_F17E

loc_F155:
                SEC
                SBC     #1
                BNE     loc_F170
                LDA     #2
                STA     zp_AA
                LDA     zp_AB
                STA     zp_6D
                LDA     zp_AC
                ASL     zp_6D
                ROL
                ASL     zp_6D
                ROL
                ASL     zp_6D
                ROL
                JMP     loc_F17E

loc_F170:
                LDA     #0
                STA     zp_AA
                LDA     zp_AC
                BPL     loc_F17C
                LDA     #$FF
                STA     zp_AA

loc_F17C:
                LDA     zp_AB

loc_F17E:
                AND     #$1F
                CLC
                RTS

byte_F26B:
      !BYTE 0, $D, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', ',', '!', '?', '_'
      !BYTE '#', $27, '"', '/', $5C, '-', ':', '(', ')'

sub_F285:
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
                BCC     loc_F2AD
                INC     zp_6E

loc_F2AD:
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
