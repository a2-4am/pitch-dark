;license:MIT
;(c) 2018 by qkumba

!cpu 6502
!to "build/zinfo2",plain
*=$3000

save_name      =    $2006
read_buffer    =    $3500 ;512 bytes
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
zp_BA    =    $ba
zp_BB    =    $bb
zp_C0    =    $c0
zp_CE    =    $ce
zp_CF    =    $cf
zp_D0    =    $d0
zp_D1    =    $d1
zp_D2    =    $d2
zp_E2    =    $e2
zp_E3    =    $e3
zp_E4    =    $e4
zp_E5    =    $e5
zp_E6    =    $e6
zp_E7    =    $e7
zp_E8    =    $e8
zp_E9    =    $e9

    jsr    exchange
    jsr    $bf00
    !byte  $c8       ;open file
    !word  c8_parms
    bcs    quit
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

quit
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

exchange
    ldx    #(zp_E9-zp_91)
-   ldy    zpage_old-1,x
    lda    zp_91-1,x
    sty    zp_91-1,x
    sta    zpage_old-1,x
    dex
    bne    -
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
    !word    $100
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

    ;set up pointers for decompression and score display

    lda    #0
    sta    zp_C0
    lda    #$ca ;read_buffer+$19
    sta    zp_E2
    lda    #$00 ;read_buffer+$18
    sta    zp_E3
    lda    #$de ;read_buffer+$0d
    sta    zp_98
    lda    #$20 ;read_buffer+$0c
    sta    zp_99
    lda    #$0a ;read_buffer+$0b
    sta    zp_BA
    lda    #$01 ;read_buffer+$0a
    sta    zp_BB

    ;dump info, actual Infocom code in upper-case

    lda    #42
    sta    max_chars
    LDA    #$10          ; location
    JSR    fetch_obj
    LDA    zp_E6
    JSR    decompress

    lda    zpage_ptr
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
    JSR    sub_1506

    sec
    lda    zpage_ptr
    sbc    #score_offset
    ldy    #score_offset
    sta    (zpage_info),y

    LDA    #$12       ; moves
    JSR    fetch_obj

    ldy    #moves_offset
    sty    zpage_ptr

    JSR    sub_1506

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
                STA     zp_E4
                LDA     #0
                ROL
                STA     zp_E5
                CLC
                LDA     zp_98
                ADC     zp_E4
                STA     zp_E4
                LDA     zp_99
                ADC     zp_E5
                STA     zp_E5
                LDY     #0
    lda    zp_E5
    pha
    jsr    load_page
    lda    #>read_buffer
    sta    zp_E5
                LDA     (zp_E4),Y
                STA     zp_E7
                INY
                LDA     (zp_E4),Y
                STA     zp_E6
    pla
    sta    zp_E5
                RTS

decompress:
                JSR     sub_16BB
                LDY     #7
    jsr    load_page
    lda    #>read_buffer
    sta    zp_E7
                LDA     (zp_E6),Y
                STA     zp_E5
                INY
                LDA     (zp_E6),Y
                STA     zp_E4
                LDA     zp_E4
                STA     zp_E6
                LDA     zp_E5
                STA     zp_E7
                INC     zp_E6
                BNE     loc_DF9
                INC     zp_E7

loc_DF9:
                JSR     sub_17D1
                JMP     sub_18D2

sub_1506:
                LDA     zp_E7
                BPL     loc_150D
                JSR     sub_153F

loc_150D:
                LDA     #0
                STA     zp_E8

loc_1511:
                LDA     zp_E7
                ORA     zp_E6
                BEQ     loc_152A
                LDA     #$A
                STA     zp_E4
                LDA     #0
                STA     zp_E5
                JSR     loc_15C1
                LDA     zp_E4
                PHA
                INC     zp_E8
                JMP     loc_1511

loc_152A:
                LDA     zp_E8
                BEQ     loc_153A

loc_152E:
                PLA
                CLC
                ADC     #$30
                JSR     emit_char
                DEC     zp_E8
                BNE     loc_152E
                RTS

loc_153A:
                LDA     #$30
                JMP     emit_char

sub_153F:
                LDA     #$2D
                JSR     emit_char
                JMP     loc_1625

loc_15C1:
                LDA     zp_E8
                PHA
                LDA     zp_E9
                PHA
                LDA     zp_E6
                STA     zp_E8
                LDA     zp_E7
                STA     zp_E9
                LDA     #0
                STA     zp_E6
                LDA     #0
                STA     zp_E7
                LDX     #$11

loc_15D9:
                SEC
                LDA     zp_E6
                SBC     zp_E4
                TAY
                LDA     zp_E7
                SBC     zp_E5
                BCC     loc_15EA
                STA     zp_E7
                TYA
                STA     zp_E6

loc_15EA:
                ROL     zp_E8
                ROL     zp_E9
                ROL     zp_E6
                ROL     zp_E7
                DEX
                BNE     loc_15D9
                CLC
                LDA     zp_E7
                ROR
                STA     zp_E5
                LDA     zp_E6
                ROR
                STA     zp_E4
                LDA     zp_E8
                STA     zp_E6
                LDA     zp_E9
                STA     zp_E7
                PLA
                STA     zp_E9
                PLA
                STA     zp_E8
                RTS

loc_1625:
                SEC
                LDA     #0
                SBC     zp_E6
                STA     zp_E6
                LDA     #0
                SBC     zp_E7
                STA     zp_E7
                RTS

sub_16BB:
                STA     zp_E6
                LDA     #0
                STA     zp_E7
                LDA     zp_E6
                ASL     zp_E6
                ROL     zp_E7
                ASL     zp_E6
                ROL     zp_E7
                ASL     zp_E6
                ROL     zp_E7
                CLC
                ADC     zp_E6
                BCC     loc_16D7
                INC     zp_E7
                CLC

loc_16D7:
                ADC     #$35
                STA     zp_E6
                BCC     loc_16DF
                INC     zp_E7

loc_16DF:
    lda    zp_BA
                CLC
                ADC     zp_E6
                STA     zp_E6
    lda    zp_BB
                ADC     zp_E7
                STA     zp_E7
                RTS

sub_17D1:
                LDA     zp_E6
                STA     zp_93
                LDA     zp_E7
                STA     zp_91
                LDA     #0
                STA     zp_92

loc_17DD:
                LDA     #0
                STA     zp_96
                RTS

sub_17E2:
                LDA     zp_E6
                ASL
                STA     zp_93
                LDA     zp_E7
                ROL
                STA     zp_91
                LDA     #0
                ROL
                STA     zp_92
                JMP     loc_17DD

sub_17F4:
                JSR     sub_1801
                PHA
                JSR     sub_1801
                STA     zp_E6
                PLA
                STA     zp_E7
                RTS

sub_1801:
                LDA     zp_96
                BEQ     loc_181A
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
                BEQ     loc_180F
                RTS

loc_180F:
                LDY     #0
                STY     zp_96
                INC     zp_91
                BNE     locret_1819
                INC     zp_92

locret_1819:
                RTS

loc_181A:
                LDA     zp_91
                STA     zp_95
                LDA     #0
                STA     zp_94
                LDA     #$FF
                STA     zp_96
                JMP     sub_1801

sub_18D2:
                LDA     #0
                STA     zp_CF
                STA     zp_D0
                LDA     #$FF
                STA     zp_CE

loc_18DC:
                JSR     loc_19D9
                BCC     loc_18E2
                RTS

loc_18E2:
                STA     zp_E8
                BEQ     loc_1932
                CMP     #1
                BEQ     loc_195F
                CMP     #4
                BCC     loc_1941
                CMP     #6
                BCC     loc_1951
                JSR     sub_19CD
                ORA     #0
                BNE     loc_1904
                LDA     #$5B

loc_18FB:
                CLC
                ADC     zp_E8

loc_18FE:
                JSR     emit_char
                JMP     loc_18DC

loc_1904:
                CMP     #1
                BNE     loc_190D
                LDA     #$3B
                JMP     loc_18FB

loc_190D:
                LDA     zp_E8
                SEC
                SBC     #7
                BCC     loc_191E
                BEQ     loc_1937
                TAY
                DEY
                LDA     byte_19B5,Y
                JMP     loc_18FE

loc_191E:
                JSR     loc_19D9
                ASL
                ASL
                ASL
                ASL
                ASL
                PHA
                JSR     loc_19D9
                STA     zp_E8
                PLA
                ORA     zp_E8
                JMP     loc_18FE

loc_1932:
                LDA     #$20
                JMP     loc_18FE

loc_1937:
                LDA     #$D
                JSR     emit_char
                LDA     #$A
                JMP     loc_18FE

loc_1941:
                JSR     sub_19CD
                CLC
                ADC     #2
                ADC     $E8
                JSR     sub_19AA
                STA     $CE
                JMP     loc_18DC

loc_1951:
                JSR     sub_19CD
                CLC
                ADC     $E8
                JSR     sub_19AA
                STA     $CF
                JMP     loc_18DC

loc_195F:
                JSR     loc_19D9
                ASL
                ADC     #1
                TAY
    lda    zp_E3
    pha
    jsr    load_page
    lda    #>read_buffer
    sta    zp_E3
                LDA     (zp_E2),Y
                STA     zp_E6
                DEY
                LDA     (zp_E2),Y
                STA     zp_E7
    pla
    sta    zp_E3
                LDA     zp_CF
                PHA
                LDA     zp_D0
                PHA
                LDA     zp_D1
                PHA
                LDA     zp_D2
                PHA
                LDA     zp_93
                PHA
                LDA     zp_91
                PHA
                LDA     zp_92
                PHA
                JSR     sub_17E2
                JSR     sub_18D2
                PLA
                STA     zp_92
                PLA
                STA     zp_91
                PLA
                STA     zp_93
                LDA     #0
                STA     zp_96
                PLA
                STA     zp_D2
                PLA
                STA     zp_D1
                PLA
                STA     zp_D0
                PLA
                STA     zp_CF
                LDA     #$FF
                STA     zp_CE
                JMP     loc_18DC

sub_19AA:
                CMP     #3
                BCC     locret_19B4
                SEC
                SBC     #3
                JMP     sub_19AA

locret_19B4:
                RTS

byte_19B5:
      !BYTE '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', ',', '!', '?', '_', '#'
      !BYTE $27, '"', '/', $5C, '-', ':', '(', ')'

sub_19CD:
                LDA     zp_CE
                BPL     loc_19D4
                LDA     zp_CF
                RTS

loc_19D4:
                LDY     #$FF
                STY     zp_CE
                RTS

loc_19D9:
                LDA     zp_D0
                BPL     loc_19DF
                SEC
                RTS

loc_19DF:
                BNE     loc_19F6
                INC     zp_D0
                JSR     sub_17F4
                LDA     zp_E6
                STA     zp_D1
                LDA     zp_E7
                STA     zp_D2
                LDA     zp_D2
                LSR
                LSR
                AND     #$1F
                CLC
                RTS

loc_19F6:
                SEC
                SBC     #1
                BNE     loc_1A13
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

loc_1A13:
                LDA     #0
                STA     zp_D0
                LDA     zp_D2
                BPL     loc_1A1F
                LDA     #$FF
                STA     zp_D0

loc_1A1F:
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
!if *+(zp_E9-zp_91)>=read_buffer {
  !error "Code is too large"
}
