;license:MIT
;(c) 2018 by qkumba

!cpu 6502
!to "build/zinfo3",plain
*=$3000

save_name      =    $2006
read_buffer    =    $3500 ;512 bytes
file_buffer    =    $3900 ;$400 bytes, must not overlap with read_buffer, must be page-aligned
record_size    =    $40
info_buffer    =    $2000 ;record_size*8 (currently $200) bytes, can be anywhere
zpage_info     =    $fe   ;word
zpage_ptr      =    $fd
name_offset    =    0  ;1+37 bytes
time_offset    =    42 ;1+8 bytes ("12:01 pm")
score_offset   =    51 ;1+6 bytes (-12345)
moves_offset   =    58 ;1+5 bytes (12345)


;zpage used by Infocom code

zp_8C    =    $8c
zp_8D    =    $8d
zp_8E    =    $8e
zp_8F    =    $8f
zp_9C    =    $9c
zp_9D    =    $9d
zp_9E    =    $9e
zp_9F    =    $9f
zp_A0    =    $a0
zp_A1    =    $a1
zp_AC    =    $ac
zp_AD    =    $ad
zp_B0    =    $b0
zp_B1    =    $b1
zp_B2    =    $b2
zp_B3    =    $b3
zp_C0    =    $c0
zp_C9    =    $c9
zp_CA    =    $ca
zp_CB    =    $cb
zp_CC    =    $cc
zp_CD    =    $cd
zp_CE    =    $ce
zp_CF    =    $cf
zp_D3    =    $d3
zp_D4    =    $d4
zp_D5    =    $d5
zp_D6    =    $d6
zp_D7    =    $d7
zp_D8    =    $d8
zp_DB    =    $db
zp_DC    =    $dc

    jsr    $bf00
    !byte  $c8       ;open file
    !word  c8_parms
    lda    c8_handle
    sta    ce_handle
    sta    ca_handle

    jsr    exchange
    lda    #>info_buffer
    sta    zpage_info+1
    lda    #<info_buffer
    sta    zpage_info

zero_info
    ldy    #name_offset
    sty    zpage_ptr
    !if name_offset=0 {
    tya
    } else {
    lda    #0
    }
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

    lda    #>info_buffer
    sta    zpage_info+1
    lda    #<info_buffer
    sta    zpage_info

    ;position to file offset

fetch_info
position
    lda    #0
    ldx    #0
    stx    ce_offset+2
    asl
    asl
    asl
    asl
    sec
    rol
    rol    ce_offset+2
    sec
    rol
    sta    ce_offset+1
    sta    ce_base1+1
    rol    ce_offset+2
    lda    ce_offset+2
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
    cmp    #8
    bcc    fetch_info
    jsr    $bf00
    !byte  $cc       ;close file
    !word  cc_parms

exchange
    ldx    #(zp_DC-zp_8C)
-   ldy    zpage_old-1,x
    lda    zp_8C-1,x
    sty    zp_8C-1,x
    sta    zpage_old-1,x
    dex
    bne    -
quit
    rts

load_page
    cmp    zp_C0
    beq    seek_ret
    sta    zp_C0
    clc
ce_base1
    adc    #0
    sta    ce_offset+1
    lda    #0
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

c7_parms
    !byte    1
    !word    $200

c5_parms
    !byte    2
    !byte    0
    !word    $201

c8_parms
    !byte    3
    !word    save_name
    !word    file_buffer
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
    !byte    1
    !byte    0

dump_info
    tsx
    stx    stack_pointer+1

    ;set up pointers for decompression and "score" display

    lda    #0
    sta    zp_C0
    lda    read_buffer+1
    and    #2
    sta    zp_DC
    lda    read_buffer+$0d
    sta    zp_AC
    lda    read_buffer+$0c
    sta    zp_AD
    lda    read_buffer+$19
    sta    zp_B0
    lda    read_buffer+$18
    sta    zp_B1
    lda    read_buffer+$0b
    sta    zp_B2
    lda    read_buffer+$0a
    sta    zp_B3

    ;dump info, actual Infocom code in upper-case

    lda    #42
    sta    max_chars
    LDA    #$10          ; location
    JSR    fetch_obj
    LDA    zp_8C
    JSR    decompress

    lda    zpage_ptr
    !if name_offset>0 {
    sec
    sbc    #name_offset
    }
    ldy    #name_offset
    sta    (zpage_info),y

    ldy    #time_offset
    sty    zpage_ptr
    lda    #0
    sta    max_chars ;can't overflow anymore
    sta    (zpage_info),y

    LDA    #$11          ; score
    JSR    fetch_obj

    LDA    zp_DC
    BNE    loc_1627

    ldy    #score_offset
    sty    zpage_ptr

    LDA    zp_8C
    STA    zp_D3
    LDA    zp_8D
    STA    zp_D4
    JSR    sub_215D

    sec
    lda    zpage_ptr
    sbc    #score_offset
    ldy    #score_offset
    sta    (zpage_info),y
    JMP    loc_165F

loc_1627:
    LDA    zp_8C
    BNE    loc_164B
    LDA    #$18

loc_164B:
    CMP    #$0D
    BCC    loc_1651
    SBC    #$0C

loc_1651:
    STA    zp_D3
    LDA    #$00
    STA    zp_D4
    JSR    sub_215D
    LDA    #$3A
    JSR    emit_char

loc_165F:
    LDA    #$12       ; moves or minutes
    JSR    fetch_obj
    LDA    zp_8C
    STA    zp_D3
    LDA    zp_8D
    STA    zp_D4
    LDA    zp_DC
    BNE    loc_1676

    ldy    #moves_offset
    sty    zpage_ptr

    JSR    sub_215D

    sec
    lda    zpage_ptr
    sbc    #moves_offset
    ldy    #moves_offset
    sta    (zpage_info),y
    rts

loc_1676:
    LDA    zp_8C
    CMP    #$0A
    BCS    loc_1681
    LDA    #$30
    JSR    emit_char

loc_1681:
    JSR    sub_215D
    LDA    #$20
    JSR    emit_char
    LDA    #$11          ; hours
    JSR    fetch_obj
    LDA    zp_8C
    CMP    #$0C
    BCS    loc_1698
    LDA    #$61
    BNE    loc_169A

loc_1698:
    LDA    #$70

loc_169A:
    JSR    emit_char
    LDA    #$6D
    JSR    emit_char

    sec
    lda    zpage_ptr
    sbc    #time_offset
    ldy    #time_offset
    sta    (zpage_info),y
    rts

loc_1459:
    jmp    * ;internal error

fetch_obj:
                JSR     sub_1A70
    lda    zp_8F
    pha
    jsr    load_page
    lda    #>read_buffer
    sta    zp_8F
                LDA     (zp_8E),Y
                STA     zp_8D
                INY
                LDA     (zp_8E),Y
                STA     zp_8C
    pla
    sta    zp_8F
                RTS

sub_1A70:
                SEC
                SBC     #$10
                LDY     #0
                STY     zp_8F
                ASL
                ROL     zp_8F
                CLC
                ADC     zp_AC
                STA     zp_8E
                LDA     zp_8F
                ADC     zp_AD
                STA     zp_8F

locret_1A85:
                RTS

decompress:
                JSR     sub_26A0
                LDY     #7
    jsr    load_page
    lda    #>read_buffer
    sta    zp_8F
                LDA     (zp_8E),Y
                TAX
                INY
                LDA     (zp_8E),Y
                STA     zp_8E
                STX     zp_8F
                INC     zp_8E
                BNE     loc_1D23
                INC     zp_8F

loc_1D23:
                JSR     sub_2474
                JMP     sub_2495

sub_1FE2:
                LDA     #0
                SEC
                SBC     zp_D3
                STA     zp_D3
                LDA     #0
                SBC     zp_D4
                STA     zp_D4
                RTS

sub_1FF0:
                LDA     zp_D5
                ORA     zp_D6
                BEQ     loc_2021
                JSR     sub_2026

loc_1FF9:
                ROL     zp_D3
                ROL     zp_D4
                ROL     zp_D7
                ROL     zp_D8
                LDA     zp_D7
                SEC
                SBC     zp_D5
                TAY
                LDA     zp_D8
                SBC     zp_D6
                BCC     loc_2011
                STY     zp_D7
                STA     zp_D8

loc_2011:
                DEX
                BNE     loc_1FF9
                ROL     zp_D3
                ROL     zp_D4
                LDA     zp_D7
                STA     zp_D5
                LDA     zp_D8
                STA     zp_D6
                RTS

loc_2021:
                LDA     #8
                JMP     loc_1459

sub_2026:
                LDX     #$10
                LDA     #0
                STA     zp_D7
                STA     zp_D8
                CLC
                RTS

sub_215D:
                LDA     zp_D4
                BPL     loc_2169
                LDA     #$2D
                JSR     emit_char
                JSR     sub_1FE2

loc_2169:
                LDA     #0
                STA     zp_DB

loc_216D:
                LDA     zp_D3
                ORA     zp_D4
                BEQ     loc_2185
                LDA     #$A
                STA     zp_D5
                LDA     #0
                STA     zp_D6
                JSR     sub_1FF0
                LDA     zp_D5
                PHA
                INC     zp_DB
                BNE     loc_216D

loc_2185:
                LDA     zp_DB
                BNE     loc_218E
                LDA     #$30
                JMP     emit_char

loc_218E:
                PLA
                CLC
                ADC     #$30
                JSR     emit_char
                DEC     zp_DB
                BNE     loc_218E
                RTS

sub_237E:
                LDA     zp_9D
                STA     zp_A1
                LDX     #$FF
                STX     zp_9F
                INX
                STX     zp_A0

loc_23A0:
                LDY     zp_9C
    lda    zp_A1
    pha
    jsr    load_page
    lda    #>read_buffer
    sta    zp_A1
                LDA     (zp_A0),Y
                INC     zp_9C
                BNE     loc_23B2
                LDY     #0
                STY     zp_9F
                INC     zp_9D
                BNE     loc_23B2
                INC     zp_9E

loc_23B2:
                TAY
    pla
    sta    zp_A1
    tya
                RTS

sub_2474:
                LDA     zp_8E
                STA     zp_9C
                LDA     zp_8F
                STA     zp_9D
                LDA     #0
                STA     zp_9E
                STA     zp_9F
                RTS

sub_2483:
                LDA     zp_8E
                ASL
                STA     zp_9C
                LDA     zp_8F
                ROL
                STA     zp_9D
                LDA     #0
                STA     zp_9F
                ROL
                STA     zp_9E

locret_2494:
                RTS

sub_2495:
                LDX     #0
                STX     zp_C9
                STX     zp_CD
                DEX
                STX     zp_CA

loc_249E:
                JSR     sub_2569
                BCS     locret_2494
                STA     zp_CB
                TAX
                BEQ     loc_24E9
                CMP     #4
                BCC     loc_2507
                CMP     #6
                BCC     loc_24ED
                JSR     sub_255D
                TAX
                BNE     loc_24C1
                LDA     #$5B

loc_24B8:
                CLC
                ADC     zp_CB

loc_24BB:
                JSR     emit_char
                JMP     loc_249E

loc_24C1:
                CMP     #1
                BNE     loc_24C9
                LDA     #$3B
                BNE     loc_24B8

loc_24C9:
                LDA     zp_CB
                SEC
                SBC     #6
                BEQ     loc_24D7
                TAX
                LDA     byte_2686,X
                JMP     loc_24BB

loc_24D7:
                JSR     sub_2569
                ASL
                ASL
                ASL
                ASL
                ASL
                STA     zp_CB
                JSR     sub_2569
                ORA     zp_CB
                JMP     loc_24BB

loc_24E9:
                LDA     #$20
                BNE     loc_24BB

loc_24ED:
                SEC
                SBC     #3
                TAY
                JSR     sub_255D
                BNE     loc_24FB
                STY     zp_CA
                JMP     loc_249E

loc_24FB:
                STY     zp_C9
                CMP     zp_C9
                BEQ     loc_249E
                LDA     #0
                STA     zp_C9
                BEQ     loc_249E

loc_2507:
                SEC
                SBC     #1
                ASL
                ASL
                ASL
                ASL
                ASL
                ASL
                STA     zp_CC
                JSR     sub_2569
                ASL
                CLC
                ADC     zp_CC
                TAY
    lda    zp_B1
    pha
    jsr    load_page
    lda    #>read_buffer
    sta    zp_B1
                LDA     (zp_B0),Y
                STA     zp_8F
                INY
                LDA     (zp_B0),Y
                STA     zp_8E
    pla
    sta    zp_B1
                LDA     zp_9E
                PHA
                LDA     zp_9D
                PHA
                LDA     zp_9C
                PHA
                LDA     zp_C9
                PHA
                LDA     zp_CD
                PHA
                LDA     zp_CF
                PHA
                LDA     zp_CE
                PHA
                JSR     sub_2483
                JSR     sub_2495
                PLA
                STA     zp_CE
                PLA
                STA     zp_CF
                PLA
                STA     zp_CD
                PLA
                STA     zp_C9
                PLA
                STA     zp_9C
                PLA
                STA     zp_9D
                PLA
                STA     zp_9E
                LDX     #$FF
                STX     zp_CA
                INX
                STX     zp_9F
                JMP     loc_249E

sub_255D:
                LDA     zp_CA
                BPL     loc_2564
                LDA     zp_C9
                RTS

loc_2564:
                LDY     #$FF
                STY     zp_CA
                RTS

sub_2569:
                LDA     zp_CD
                BPL     loc_256F
                SEC
                RTS

loc_256F:
                BNE     loc_2584
                INC     zp_CD
                JSR     sub_237E
                STA     zp_CF
                JSR     sub_237E
                STA     zp_CE
                LDA     zp_CF
                LSR
                LSR
                JMP     loc_25AD

loc_2584:
                SEC
                SBC     #1
                BNE     loc_259F
                LDA     #2
                STA     zp_CD
                LDA     zp_CE
                STA     zp_8E
                LDA     zp_CF
                ASL     zp_8E
                ROL
                ASL     zp_8E
                ROL
                ASL     zp_8E
                ROL
                JMP     loc_25AD

loc_259F:
                LDA     #0
                STA     zp_CD
                LDA     zp_CF
                BPL     loc_25AB
                LDA     #$FF
                STA     zp_CD

loc_25AB:
                LDA     zp_CE

loc_25AD:
                AND     #$1F
                CLC
                RTS

byte_2686:
      !BYTE 0, $D, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', ',', '!', '?', '_'
      !BYTE '#', $27, '"', '/', $5C, '-', ':', '(', ')'

sub_26A0:
                STA     zp_8E
                LDX     #0
                STX     zp_8F
                ASL
                ROL     zp_8F
                ASL
                ROL     zp_8F
                ASL
                ROL     zp_8F
                CLC
                ADC     zp_8E
                BCC     loc_26B6
                INC     zp_8F

loc_26B6:
                CLC
                ADC     #$35
                BCC     loc_26BD
                INC     zp_8F

loc_26BD:
                CLC
                ADC     zp_B2
                STA     zp_8E
                LDA     zp_8F
                ADC     zp_B3
                STA     zp_8F
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
!if *+(zp_DC-zp_8C)>=read_buffer {
  !error "Code is too large"
}
