;license:MIT
;(c) 2018 by qkumba

!cpu 6502
!to "build/zinfo5",plain
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

byte_FE52=    $52
byte_FE53=    $53
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
zp_84    =    $84
zp_85    =    $85
zp_87    =    $87
zp_88    =    $88
zp_8A    =    $8a
zp_8B    =    $8b
zp_A0    =    $a0
zp_A1    =    $a1
zp_A9    =    $a9
zp_AA    =    $aa
zp_AB    =    $ab
zp_AC    =    $ac
zp_AD    =    $ad
zp_AE    =    $ae
zp_AF    =    $af
zp_C9    =    $c9
zp_CA    =    $ca
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
    ldx    #(zp_D4-byte_FE52)
-   ldy    zpage_old-1,x
    lda    byte_FE52-1,x
    sty    byte_FE52-1,x
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
    sta    zp_84
    lda    read_buffer+$0c
    sta    zp_85
    lda    read_buffer+$19
    sta    zp_87
    lda    read_buffer+$18
    sta    zp_88
    lda    read_buffer+$0b
    sta    zp_8A
    lda    read_buffer+$0a
    sta    zp_8B

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

    ldx    zpage_gamind
    lda    gametime, x
    beq    branch_skip
    jsr    fetch_obj
    lda    zp_6B
    sta    zp_58
    lda    zp_6C
    sta    zp_59
    ldx    zpage_gamind
    beq    branch_bzone
    cpx    #3
    beq    branch_print
    cpx    #$0f
    beq    branch_print
    cpx    #4
    beq    sherlock1
    cpx    #5
    beq    sherlock1
    cpx    #6
    beq    wishbr
    cpx    #$12
    beq    eleven
    cpx    #$16
    beq    i0
    cpx    #$19
    beq    jigsaw
    cpx    #$1d
    beq    ramses

branch_skip
    jmp    skip_time

branch_print
    jmp    print_time

branch_bzone
    jmp    bzone

ramses
jigsaw
i0
    lda    #$12
    jsr    fetch_obj
    lda    zp_6B
    pha
    lda    zp_6C
    pha
    lda    zp_58
    sta    zp_6B
    cmp    #$0c
    bcc    +
    sbc    #$0c
+   sta    zp_58
    jmp    print_hhmm

sherlock1
    ldy    zp_6B
    iny
    sty    zp_6D
    lda    zp_6C
    sta    zp_6E
    ldy    #0
    jsr    fetch_obj+3
    lda    zp_6C
    pha
    lda    #0
    pha
    lda    zp_6B
    sta    zp_58
    lda    #0
    sta    zp_59
    jmp    print_hhmm

wishbr
    lda    zp_6B
    pha
    lda    zp_6C
    pha
    lda    #$5c
    jsr    fetch_obj
    lda    zp_6B
    cmp    #$0c
    bcc    +
    sbc    #$0c
+   sta    zp_58
    lda    zp_6C
    sta    zp_59
    jmp    print_hhmm

eleven
    lda    #$3c
    sta    zp_5A
    lda    #0
    sta    zp_5B
    jsr    sub_E7E1
    sta    zp_59
    stx    zp_6B
    txa
    cmp    #$0c
    bcc    +
    sbc    #$0c
+   sta    zp_58
    lda    zp_CF
    pha
    lda    zp_D0
    pha
    jmp    print_hhmm

bzone
    lda    #$3c
    sta    zp_5A
    lda    #0
    sta    zp_5B
    jsr    sub_E7E1
    stx    zp_58
    sta    zp_59
    lda    #$74
    jsr    fetch_obj
    clc
    lda    zp_6B
    adc    zp_58
    sta    zp_58
    lda    zp_6C
    adc    zp_59
    sta    zp_59
    jsr    sub_E7E1
    stx    zp_58
    sta    zp_59
    lda    zp_CF
    pha
    lda    zp_D0
    pha
    lda    #$67
    jsr    fetch_obj
    clc
    lda    zp_6B
    adc    zp_58
    sta    zp_58
    lda    zp_6C
    adc    zp_59
    sta    zp_59
    lda    zp_58
    cmp    #$18
    bcc    print_hhmm
    sbc    #$18
    sta    zp_58
    lda    #'0'
    jsr    emit_char

print_hhmm
    jsr    loc_EA1C
    lda    #':'
    jsr    emit_char
    pla
    sta    zp_59
    pla
    sta    zp_58
    cmp    #$0a
    bcs    print_time
    lda    #'0'
    jsr    emit_char

print_time
    jsr    loc_EA1C

    ldx    zpage_gamind
    cpx    #$1d
    beq    ++
    cpx    #$19
    beq    ++
    cpx    #$16
    beq    ++
    cpx    #$12
    beq    ++
    cpx    #4
    bcc    +
    cpx    #7
    bcs    +
++  lda    zp_6B
    cmp    #$0c
    lda    #'a'
    bcc    print_ampm
    lda    #'p'

print_ampm
    jsr    emit_char
    lda    #'m'
    jsr    emit_char

+   sec
    lda    zpage_ptr
    sbc    #time_offset
    ldy    #time_offset
    sta    (zpage_info),y

skip_time
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
    jsr    loc_EA1C
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
    jsr    loc_EA1C
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

    ldx    zpage_gamind
    lda    gameday, x
    beq    skip_date
    jsr    fetch_obj
    lda    zp_6B
    sta    zp_58
    lda    zp_6C
    sta    zp_59
    ldx    zpage_gamind
    cpx    #6
    beq    +
    cpx    #$0e
    beq    curses
    ldy    zp_6B
    iny
    iny
    iny
    sty    zp_6D
    lda    zp_6C
    sta    zp_6E
    ldy    #0
    jsr    fetch_obj+3
    sec
    lda    zp_6C
    sbc    #$0c
    sta    zp_58
    lda    zp_6B
    sta    zp_59
    lda    #7
    sta    zp_5A
    lda    #0
    sta    zp_5B
    jsr    sub_E7E1
    ldx    zp_CF
-   lda    day_index, x
    sta    day_load+1
day_load
    lda    day_table
    beq    ++
    jsr    emit_char
    inc    day_load+1
    bne    day_load
+   jsr    loc_EA1C
    jmp    ++
curses
    lda    zp_58
    adc    #(date_index - day_index) - 2
    tax
    bne    -
++  sec
    lda    zpage_ptr
    sbc    #date_offset
    ldy    #date_offset
    sta    (zpage_info),y

skip_date
rts

!source "src/zinfo/z5/gamedata.txt"

day_index
    !byte  <sun, <mon, <tue, <wed, <thu, <fri, <sat
date_index
    !byte  <jun3, <oct5, <oct31, <none, <jun3, <mar14, <sixc, <jun3, <wint, <jun3

* = (* + 255) & -256
day_table
sun !text  "Sunday", 0
mon !text  "Monday", 0
tue !text  "Tuesday", 0
wed !text  "Wednesday", 0
thu !text  "Thursday", 0
fri !text  "Friday", 0
sat !text  "Saturday", 0

date_table
jun3  !text "06/03/1993", 0
oct5  !text "10/5/1922", 0
oct31 !text "10/31/1988", 0
none  !byte 0
mar14 !text "3/14/1808", 0
sixc  !text "500AD", 0
wint  !text "275BC", 0

fetch_obj:
                JSR     sub_E1D9
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

sub_E1D9:
                SEC
                SBC     #$10
                LDY     #0
                STY     zp_6E
                ASL
                ROL     zp_6E
                CLC
                ADC     zp_84
                STA     zp_6D
                LDA     zp_6E
                ADC     zp_85
                STA     zp_6E

locret_E1EE:
                RTS

decompress
                JSR     sub_F58D
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
                BNE     loc_E4C4
                INC     zp_6E

loc_E4C4:
                JSR     sub_F0B9
                JMP     sub_F35C

sub_E7E1:
                JSR     sub_E7F5
                LDX     zp_CD
                LDA     zp_CE
    rts

sub_E7F5:
                LDA     zp_59
                STA     zp_D2
                EOR     zp_5B
                STA     zp_D1
                LDA     zp_58
                STA     zp_CD
                LDA     zp_59
                STA     zp_CE
                BPL     loc_E80A
                JSR     sub_E833

loc_E80A:
                LDA     zp_5A
                STA     zp_CF
                LDA     zp_5B
                STA     zp_D0
                BPL     loc_E817
                JSR     sub_E825

loc_E817:
                JSR     sub_E841
                LDA     zp_D1
                BPL     loc_E821
                JSR     sub_E833

loc_E821:
                LDA     zp_D2
                BPL     locret_E832

sub_E825:
                LDA     #0
                SEC
                SBC     zp_CF
                STA     zp_CF
                LDA     #0
                SBC     zp_D0
                STA     zp_D0

locret_E832:
                RTS

sub_E833:
                LDA     #0
                SEC
                SBC     zp_CD
                STA     zp_CD
                LDA     #0
                SBC     zp_CE
                STA     zp_CE
                RTS

sub_E841:
                JSR     sub_E87F

loc_E84A:
                ROL     zp_CD
                ROL     zp_CE
                ROL     byte_FE52
                ROL     byte_FE53
                LDA     byte_FE52
                SEC
                SBC     zp_CF
                TAY
                LDA     byte_FE53
                SBC     zp_D0
                BCC     loc_E868
                STY     byte_FE52
                STA     byte_FE53

loc_E868:
                DEX
                BNE     loc_E84A
                ROL     zp_CD
                ROL     zp_CE
                LDA     byte_FE52
                STA     zp_CF
                LDA     byte_FE53
                STA     zp_D0
                RTS

sub_E87F:
                LDX     #$10
                LDA     #0
                STA     byte_FE52
                STA     byte_FE53
                CLC
                RTS

loc_EA1C:
                LDA     zp_58
                STA     zp_CD
                LDA     zp_59
                STA     zp_CE
                LDA     zp_CE
                BPL     loc_EA30
                LDA     #$2D
                JSR     emit_char
                JSR     sub_E833

loc_EA30:
                LDA     #0
                STA     zp_D3

loc_EA34:
                LDA     zp_CD
                ORA     zp_CE
                BEQ     loc_EA4C
                LDA     #$A
                STA     zp_CF
                LDA     #0
                STA     zp_D0
                JSR     sub_E841
                LDA     zp_CF
                PHA
                INC     zp_D3
                BNE     loc_EA34

loc_EA4C:
                LDA     zp_D3
                BNE     loc_EA55
                LDA     #$30
                JMP     emit_char

loc_EA55:
                PLA
                CLC
                ADC     #$30
                JSR     emit_char
                DEC     zp_D3
                BNE     loc_EA55
                RTS

sub_F0B9:
                LDA     zp_6D
                STA     zp_7B
                LDA     zp_6E
                STA     zp_7C
                LDA     #0
                STA     zp_7D
                JMP     sub_F15E

sub_F15E:
    ldy    zp_7D
                LDA     zp_7C
                STY     zp_80
                STA     zp_7F
                RTS

sub_F301:
                PHA
                INC     zp_7C
                BNE     loc_F308
                INC     zp_7D

loc_F308:
                JSR     sub_F15E
                PLA
                RTS

sub_F319:
                LDY     zp_7B
    lda    zp_7F
    pha
    jsr    load_page
    lda    #>read_buffer
    sta    zp_7F
                LDA     (zp_7E),Y
                INC     zp_7B
                BNE     loc_F32C
                JSR     sub_F301

loc_F32C:
                TAY
    pla
    sta    zp_7F
    tya
                RTS

sub_F343:
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
                JMP     sub_F15E

locret_F35B:
                RTS

sub_F35C:
                LDX     #0
                STX     zp_A9
                STX     zp_AD
                DEX
                STX     zp_AA

loc_F365:
                JSR     sub_F442
                BCS     locret_F35B
                STA     zp_AB
                TAX
                BEQ     loc_F3B0
                CMP     #4
                BCC     loc_F3CE
                CMP     #6
                BCC     loc_F3B4
                JSR     sub_F424
                TAX
                BNE     loc_F388
                LDA     #$5B

loc_F37F:
                CLC
                ADC     zp_AB

loc_F382:
                JSR     emit_char
                JMP     loc_F365

loc_F388:
                CMP     #1
                BNE     loc_F390
                LDA     #$3B
                BNE     loc_F37F

loc_F390:
                LDA     zp_AB
                SEC
                SBC     #6
                BEQ     loc_F39E
                TAX
                LDA     byte_F573,X
                JMP     loc_F382

loc_F39E:
                JSR     sub_F442
                ASL
                ASL
                ASL
                ASL
                ASL
                STA     zp_AB
                JSR     sub_F442
                ORA     zp_AB
                JMP     loc_F382

loc_F3B0:
                LDA     #$20
                BNE     loc_F382

loc_F3B4:
                SEC
                SBC     #3
                TAY
                JSR     sub_F424
                BNE     loc_F3C2
                STY     zp_AA
                JMP     loc_F365

loc_F3C2:
                STY     zp_A9
                CMP     zp_A9
                BEQ     loc_F365
                LDA     #0
                STA     zp_A9
                BEQ     loc_F365

loc_F3CE:
                SEC
                SBC     #1
                ASL
                ASL
                ASL
                ASL
                ASL
                ASL
                STA     zp_AC
                JSR     sub_F442
                ASL
                CLC
                ADC     zp_AC
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
                LDA     zp_AD
                PHA
                LDA     zp_AF
                PHA
                LDA     zp_AE
                PHA
                JSR     sub_F430
                JSR     sub_F35C
                PLA
                STA     zp_AE
                PLA
                STA     zp_AF
                PLA
                STA     zp_AD
                PLA
                STA     zp_A9
                PLA
                STA     zp_7B
                PLA
                STA     zp_7C
                PLA
                STA     zp_7D
                LDX     #$FF
                STX     zp_AA
                JSR     sub_F15E
                JMP     loc_F365

sub_F424:
                LDA     zp_AA
                BPL     loc_F42B
                LDA     zp_A9
                RTS

loc_F42B:
                LDY     #$FF
                STY     zp_AA
                RTS

sub_F430:
                LDA     zp_6D
                ASL
                STA     zp_7B
                LDA     zp_6E
                ROL
                STA     zp_7C
                LDA     #0
                ROL
                STA     zp_7D
                JMP     sub_F15E

sub_F442:
                LDA     zp_AD
                BPL     loc_F448
                SEC
                RTS

loc_F448:
                BNE     loc_F45D
                INC     zp_AD
                JSR     sub_F319
                STA     zp_AF
                JSR     sub_F319
                STA     zp_AE
                LDA     zp_AF
                LSR
                LSR
                JMP     loc_F486

loc_F45D:
                SEC
                SBC     #1
                BNE     loc_F478
                LDA     #2
                STA     zp_AD
                LDA     zp_AE
                STA     zp_6D
                LDA     zp_AF
                ASL     zp_6D
                ROL
                ASL     zp_6D
                ROL
                ASL     zp_6D
                ROL
                JMP     loc_F486

loc_F478:
                LDA     #0
                STA     zp_AD
                LDA     zp_AF
                BPL     loc_F484
                LDA     #$FF
                STA     zp_AD

loc_F484:
                LDA     zp_AE

loc_F486:
                AND     #$1F
                CLC
                RTS

byte_F573:
      !BYTE 0, $D, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', ',', '!', '?', '_'
      !BYTE '#', $27, '"', '/', $5C, '-', ':', '(', ')'

sub_F58D:
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
                ADC     zp_8A
                STA     zp_6D
                LDA     zp_6E
                ADC     zp_8B
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
