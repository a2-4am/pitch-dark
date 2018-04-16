;license:MIT
;(c) 2018 by qkumba

!cpu 6502
!to "build/zinfo1",plain
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

zp_91    =    $91
zp_92    =    $92
zp_93    =    $93
zp_94    =    $94
zp_95    =    $95
zp_96    =    $96
zp_98    =    $98
zp_99    =    $99
zp_BA    =    $BA
zp_BB    =    $BB
zp_C0    =    $C0
zp_CE    =    $CE
zp_CF    =    $CF
zp_D0    =    $D0
zp_D1    =    $D1
zp_D2    =    $D2
zp_E2    =    $E2
zp_E3    =    $E3
zp_E4    =    $E4
zp_E5    =    $E5
zp_E6    =    $E6
zp_E7    =    $E7

    jsr    $bf00
    !byte  $c8       ;open file
    !word  c8_parms
    bcs    quit
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

fetch_info
    jsr    $bf00
    !byte  $ca       ;read file
    !word  ca_parms
    jsr    dump_info

    jsr    $bf00
    !byte  $cc       ;close file
    !word  cc_parms

exchange
    ldx    #(zp_E7-zp_91)
-   ldy    zpage_old-1,x
    lda    zp_91-1,x
    sty    zp_91-1,x
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
    adc    #3
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
    !word    $100
    !word    $ffff

cc_parms
    !byte    1
    !byte    0

dump_info
    tsx
    stx    stack_pointer+1

    ;set up pointers for decompression and score display

    lda    #0
    sta    zp_C0
    lda    #$3c ;read_buffer+$0d
    sta    zp_98
    lda    #$20 ;read_buffer+$0c
    sta    zp_99
    lda    #$40 ;read_buffer+$0b
    sta    zp_BA
    lda    #$00 ;read_buffer+$0a
    sta    zp_BB

    ;dump info, actual Infocom code in upper-case

    lda    #42
    sta    max_chars
    LDA    #$10          ; location
    JSR    fetch_obj
    LDA    zp_E4
    JSR    decompress

    lda    zpage_ptr
    !if name_offset>0 {
    sec
    sbc    #name_offset
    }
    ldy    #name_offset
    sta    (zpage_info),y

    lda    #0
    sta    max_chars ;can't overflow anymore
    ldy    #time_offset
    sta    (zpage_info),y

    LDA    #$11          ; score
    JSR    fetch_obj

    ldy    #score_offset
    sty    zpage_ptr
    JSR    sub_1521

    sec
    lda    zpage_ptr
    sbc    #score_offset
    ldy    #score_offset
    sta    (zpage_info),y

    LDA    #$12       ; moves
    JSR    fetch_obj

    ldy    #moves_offset
    sty    zpage_ptr

    JSR    sub_1521

    sec
    lda    zpage_ptr
    sbc    #moves_offset
    ldy    #moves_offset
    sta    (zpage_info),y
    rts

fetch_obj:
                SEC
                SBC     #$10
                ASL
                STA     zp_E2
                LDA     #0
                ROL
                STA     zp_E3
                CLC
                LDA     zp_98
                ADC     zp_E2
                STA     zp_E2
                LDA     zp_99
                ADC     zp_E3
                STA     zp_E3
                LDY     #0
    lda    zp_E3
    pha
    jsr    load_page
    lda    #>read_buffer
    sta    zp_E3
                LDA     (zp_E2),Y
                STA     zp_E5
                INY
                LDA     (zp_E2),Y
                STA     zp_E4
    pla
    sta    zp_E3
                RTS

decompress:
                JSR     sub_170D
                LDY     #7
    jsr    load_page
    lda    #>read_buffer
    sta    zp_E5
                LDA     (zp_E4),Y
                STA     zp_E3
                INY
                LDA     (zp_E4),Y
                STA     zp_E2
                LDA     zp_E2
                STA     zp_E4
                LDA     zp_E3
                STA     zp_E5
                INC     zp_E4
                BNE     loc_E01
                INC     zp_E5

loc_E01:
                JSR     sub_1823
                JMP     loc_1948

sub_1521:
                LDA     zp_E5
                BPL     loc_1528
                JSR     sub_155A

loc_1528:
                LDA     #0
                STA     zp_E6

loc_152C:
                LDA     zp_E5
                ORA     zp_E4
                BEQ     loc_1545
                LDA     #$A
                STA     zp_E2
                LDA     #0
                STA     zp_E3
                JSR     sub_1613
                LDA     zp_E2
                PHA
                INC     zp_E6
                JMP     loc_152C

loc_1545:
                LDA     zp_E6
                BEQ     loc_1555

loc_1549:
                PLA
                CLC
                ADC     #$30
                JSR     emit_char
                DEC     zp_E6
                BNE     loc_1549
                RTS

loc_1555:
                LDA     #$30
                JMP     emit_char

sub_155A:
                LDA     #$2D
                JSR     emit_char
                JMP     loc_1677

sub_1613:
                LDA     zp_E6
                PHA
                LDA     zp_E7
                PHA
                LDA     zp_E4
                STA     zp_E6
                LDA     zp_E5
                STA     zp_E7
                LDA     #0
                STA     zp_E4
                LDA     #0
                STA     zp_E5
                LDX     #$11

loc_162B:
                SEC
                LDA     zp_E4
                SBC     zp_E2
                TAY
                LDA     zp_E5
                SBC     zp_E3
                BCC     loc_163C
                STA     zp_E5
                TYA
                STA     zp_E4

loc_163C:
                ROL     zp_E6
                ROL     zp_E7
                ROL     zp_E4
                ROL     zp_E5
                DEX
                BNE     loc_162B
                CLC
                LDA     zp_E5
                ROR
                STA     zp_E3
                LDA     zp_E4
                ROR
                STA     zp_E2
                LDA     zp_E6
                STA     zp_E4
                LDA     zp_E7
                STA     zp_E5
                PLA
                STA     zp_E7
                PLA
                STA     zp_E6
                RTS

loc_1677:
                SEC
                LDA     #0
                SBC     zp_E4
                STA     zp_E4
                LDA     #0
                SBC     zp_E5
                STA     zp_E5
                RTS

sub_170D:
                STA     zp_E4
                LDA     #0
                STA     zp_E5
                LDA     zp_E4
                ASL     zp_E4
                ROL     zp_E5
                ASL     zp_E4
                ROL     zp_E5
                ASL     zp_E4
                ROL     zp_E5
                CLC
                ADC     zp_E4
                BCC     loc_1729
                INC     zp_E5
                CLC

loc_1729:
                ADC     #$35
                STA     zp_E4
                BCC     loc_1731
                INC     zp_E5

loc_1731:
    lda    zp_BA
                CLC
                ADC     zp_E4
                STA     zp_E4
    lda    zp_BB
                ADC     zp_E5
                STA     zp_E5
                RTS

sub_1823:
                LDA     zp_E4
                STA     zp_93
                LDA     zp_E5
                STA     zp_91
                LDA     #0
                STA     zp_92

loc_182F:
                LDA     #0
                STA     zp_96
                RTS

sub_1863:
                JSR     sub_1870
                PHA
                JSR     sub_1870
                STA     zp_E4
                PLA
                STA     zp_E5
                RTS

sub_1870:
                LDA     zp_96
                BEQ     loc_1889
                LDY     zp_93
    lda    zp_95
    pha
    jsr    load_page
    lda    #>read_buffer
    sta    zp_95
                LDA     (zp_94),Y
                STY     zp_93
    tay
    pla
    sta    zp_95
    tya
    inc    zp_93
                BEQ     loc_187E
                RTS

loc_187E:
                LDY     #0
                STY     zp_96
                INC     zp_91
                BNE     locret_1888
                INC     zp_92

locret_1888:
                RTS

loc_1889:
                LDA     zp_91
                STA     zp_95
                LDA     #0
                STA     zp_94
                LDA     #$FF
                STA     zp_96
                JMP     sub_1870

loc_1948:
                LDA     #0
                STA     zp_CF
                STA     zp_D0
                LDA     #$FF
                STA     zp_CE

loc_1952:
                JSR     sub_1A08
                BCC     loc_1958
                RTS

loc_1958:
                STA     zp_E6
                BEQ     loc_19AB
                CMP     #1
                BEQ     loc_19B0
                CMP     #4
                BCC     loc_19BA
                CMP     #6
                BCC     loc_19CA
                JSR     sub_19FC
                ORA     #0
                BNE     loc_197A
                LDA     #$5B

loc_1971:
                CLC
                ADC     zp_E6

loc_1974:
                JSR     emit_char
                JMP     loc_1952

loc_197A:
                CMP     #1
                BNE     loc_1983
                LDA     #$3B
                JMP     loc_1971

loc_1983:
                LDA     zp_E6
                SEC
                SBC     #7
                BCC     loc_1991
                TAY
                LDA     byte_19E3,Y
                JMP     loc_1974

loc_1991:
                JSR     sub_1A08
                ASL
                ASL
                ASL
                ASL
                ASL
                PHA
                JSR     sub_1A08
                STA     zp_E6
                PLA
                ORA     zp_E6
                CMP     #9
                BNE     loc_1974
                LDA     #$20
                JMP     loc_1974

loc_19AB:
                LDA     #$20
                JMP     loc_1974

loc_19B0:
                LDA     #$D
                JSR     emit_char
                LDA     #$A
                JMP     loc_1974

loc_19BA:
                JSR     sub_19FC
                CLC
                ADC     #2
                ADC     zp_E6
                JSR     sub_19D8
                STA     zp_CE
                JMP     loc_1952

loc_19CA:
                JSR     sub_19FC
                CLC
                ADC     zp_E6
                JSR     sub_19D8
                STA     zp_CF
                JMP     loc_1952

sub_19D8:
                CMP     #3
                BCC     locret_19E2
                SEC
                SBC     #3
                JMP     sub_19D8

locret_19E2:
                RTS

byte_19E3:
      !BYTE '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', ',', '!', '?', '_', '#'
      !BYTE $27, '"', '/', $5C, '|', '-', ':', '(', ')'

sub_19FC:
                LDA     zp_CE
                BPL     loc_1A03
                LDA     zp_CF
                RTS

loc_1A03:
                LDY     #$FF
                STY     zp_CE
                RTS

sub_1A08:
                LDA     zp_D0
                BPL     loc_1A0E
                SEC
                RTS

loc_1A0E:
                BNE     loc_1A25
                INC     zp_D0
                JSR     sub_1863
                LDA     zp_E4
                STA     zp_D1
                LDA     zp_E5
                STA     zp_D2
                LDA     zp_D2
                LSR
                LSR
                AND     #$1F
                CLC
                RTS

loc_1A25:
                SEC
                SBC     #1
                BNE     loc_1A42
                LDA     #2
                STA     zp_D0
                LDA     zp_D2
                LSR
                LDA     zp_D1
                ROR
                TAY
                LDA     zp_D2
                LSR
                LSR
                TYA
                ROR
                LSR
                LSR
                LSR
                AND     #$1F
                CLC
                RTS

loc_1A42:
                LDA     #0
                STA     zp_D0
                LDA     zp_D2
                BPL     loc_1A4E
                LDA     #$FF
                STA     zp_D0

loc_1A4E:
                LDA     zp_D1
                AND     #$1F
                CLC
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
!if *+(zp_E7-zp_91)>=read_buffer {
  !error "Code is too large"
}
