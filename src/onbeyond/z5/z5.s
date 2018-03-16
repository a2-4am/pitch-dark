;license:BSD-3-Clause
;extended open/read/write binary file in ProDOS filesystem, with random access
;copyright (c) Peter Ferrie 2013-18

ver_02 = 1

!if ver_02 = 1 {
  !cpu 6502
} else { ;ver_02
  !cpu 65c02
} ;ver_02
!to "build/ONBEYONDZ5",plain
*=$3000

!macro version {!text "1/180221"}

xsechi=$b7
xseclo=$b6
xside=$eb
entry=$dd52

;unpacker variables, no need to change these
src	=	$0
dst	=	$2
ecx	=	$4
last	=	$6
tmp	=	$8

;place no code before init label below.

                ;user-defined options
                verbose_info = 0        ;set to 1 to enable display of memory usage
                poll_drive   = 0        ;set to 1 to check if disk is in drive, recommended if allow_multi is enabled
                override_adr = 1        ;set to 1 to require an explicit load address
                aligned_read = 0        ;set to 1 if all reads can be a multiple of block size
                enable_write = 1        ;set to 1 to enable write support
                                        ;file must exist already and its size cannot be altered
                                        ;writes occur in multiples of block size
                enable_seek  = 1        ;set to 1 to enable seek support
                                        ;seeking with aligned_read=1 requires non-zero offset
                check_chksum = 0        ;set to 1 to enforce checksum verification for floppies
                allow_subdir = 0        ;set to 1 to allow opening subdirectories to access files
                might_exist  = 1        ;set to 1 if file is not known to always exist already
                                        ;makes use of status to indicate success or failure
                allow_aux    = 0        ;set to 1 to allow read/write directly to/from aux memory
                                        ;requires load_high to be set for arbitrary memory access
                                        ;else driver must be running from same memory target
                                        ;i.e. running from main if accessing main, running from aux if accessing aux
                allow_saplings=0        ;enable support for saplings
                allow_trees  = 1        ;enable support for tree files, as opposed to only seedlings and saplings
                fast_trees   = 0        ;keep tree block in memory, requires an additional 512 bytes of RAM
                allow_sparse = 1        ;enable support for reading sparse files
                                        ;recommended if enable_write is enabled, to prevent writing to sparse blocks
                bounds_check = 0        ;set to 1 to prevent access beyond the end of the file
                                        ;but limits file size to 64k-2 bytes.
                swap_zp      = 1        ;set to 1 to include code to preserve zpage
                                        ;must be called manually to save if not in RWTS mode (restore is done automatically)
                rwts_mode    = 1        ;set to 1 to enable emulation of DOS RWTS when running from hard disk
                                        ;use unique volume numbers to distinguish between images in the same file
                                        ;requires override_adr, enable_seek
                                        ;not compatible with enable_floppy, aligned_read, allow_subdir, might_exist, allow_aux, bounds_check
                load_high    = 0        ;set to 1 to load to top of RAM (either main or banked, enables a himem check)
                load_aux     = 0        ;load to aux memory
                load_banked  = 1        ;set to 1 to load into banked RAM instead of main RAM (can be combined with load_aux for aux banked)
                lc_bank      = 1        ;load into specified bank (1 or 2) if load_banked=1
                one_page     = 0        ;set to 1 if verbose mode says that you should (smaller code)

                ;user-defined driver load address
!if load_banked = 1 {
  !if load_high = 1 {
    !ifdef PASS2 {
    } else { ;PASS2 not defined
                reloc     = $ff00       ;page-aligned, as high as possible, the ideal value will be shown on mismatch
    } ;PASS2
  } else { ;load_high = 0
                reloc     = $d400       ;page-aligned, but otherwise wherever you want
  } ;load_high
} else { ;load_banked = 0
  !if load_high = 1 {
    !ifdef PASS2 {
    } else { ;PASS2 not defined
                reloc     = $bf00       ;page-aligned, as high as possible, the ideal value will be shown on mismatch
    } ;PASS2
  } else { ;load_high = 0
                reloc     = $BC00       ;page-aligned, but otherwise wherever you want
  } ;load_high
} ;load_banked

                ;there are also buffers that can be moved if necessary:
                ;dirbuf, encbuf, treebuf (and corresponding hdd* versions that load to the same place)
                ;they are independent of each other so they can be placed separately
                ;see near EOF for those
                ;note that hddencbuf must be even-page-aligned in RWTS-mode

                ;zpage usage, arbitrary selection except for the "ProDOS constant" ones
                ;feel free to move them around

!if (might_exist + poll_drive) > 0 {
                status    = $5a         ;returns non-zero on error
} ;might_exist or poll_drive
!if allow_aux = 1 {
                auxreq    = $5b         ;set to 1 to read/write aux memory, else main memory is used
} ;allow_aux
                sizelo    = $50         ;set if enable_write=1 and writing, or reading, or if enable_seek=1 and seeking
                sizehi    = $51         ;set if enable_write=1 and writing, or reading, or if enable_seek=1 and seeking
!if (enable_write + enable_seek) > 0 {
                reqcmd    = $52         ;set (read/write/seek) if enable_write=1 or enable_seek=1
} ;enable_write or enable_seek
                ldrlo     = $56         ;set to load address if override_adr=1
                ldrhi     = $57         ;set to load address if override_adr=1
                namlo     = $58         ;name of file to access
                namhi     = $59         ;name of file to access

                command   = $42         ;ProDOS constant
                unit      = $43         ;ProDOS constant
                adrlo     = $44         ;ProDOS constant
                adrhi     = $45         ;ProDOS constant
                bloklo    = $46         ;ProDOS constant
                blokhi    = $47         ;ProDOS constant

                entries   = $3f         ;(internal) total number of entries in directory

!if allow_trees = 1 {
                treeidx   = $54         ;(internal) index into tree block list
                istree    = $55         ;(internal) flag to indicate tree file
  !if rwts_mode = 1 {
                lasttree  = $51         ;(internal) previous index into tree block list
  } ;rwts_mode
} ;allow_trees
                blkidx    = $53         ;(internal) index into sapling block list
!if rwts_mode = 1 {
                lastblk   = $50         ;(internal) previous index into sapling block list
} ;rwts_mode
!if bounds_check = 1 {
                bleftlo   = $5c         ;(internal) bytes left in file
                blefthi   = $5d         ;(internal) bytes left in file
} ;bounds_check
!if (aligned_read + rwts_mode) = 0 {
                blkofflo  = $5e         ;(internal) offset within cache block
                blkoffhi  = $5f         ;(internal) offset within cache block
} ;!(aligned_read or rwts_mode)

                ;constants
                cmdseek   = 0           ;requires enable_seek=1
                cmdread   = 1           ;requires enable_write=1
                cmdwrite  = 2           ;requires enable_write=1
                DEVNUM    = $bf30
                PHASEOFF  = $c080
                MOTOROFF  = $c088
                MOTORON   = $c089
                DRV0EN    = $c08a
                Q6L       = $c08c
                Q6H       = $c08d
                Q7L       = $c08e
                Q7H       = $c08f
                MLI       = $bf00
                NAME_LENGTH = $4        ;ProDOS constant
                MASK_SUBDIR = $d0       ;ProDOS constant
                MASK_ALL    = $f0       ;ProDOS constant
                KEY_POINTER = $11       ;ProDOS constant
                EOF_LO    = $15         ;ProDOS constant
                EOF_HI    = $16         ;ProDOS constant
                AUX_TYPE  = $1f         ;ProDOS constant
                ENTRY_SIZE = $27        ;ProDOS constant
                NEXT_BLOCK_LO = $2      ;ProDOS constant
                NEXT_BLOCK_HI = $3      ;ProDOS constant
                SAPLING   = $20         ;ProDOS constant
                FILE_COUNT = $25        ;ProDOS constant
                DEVADR01HI = $bf11      ;ProDOS constant
                ROMIN     = $c081
                LCBANK2   = $c089
                CLRAUXRD  = $c002
                CLRAUXWR  = $c004
                SETAUXWR  = $c005
                CLRAUXZP  = $c008
                SETAUXZP  = $c009

                first_zp  = $40         ;lowest address to save if swap_zp enabled
                last_zp   = $59         ;highest address to save if swap_zp enabled (max 127 entries later)

init            lda     DEVNUM
                sta     x80_parms + 1
                sta     unrunit
                and     #$70
                pha
                ldx     #1
                stx     namlo
                inx
                stx     namhi

                ;fetch path, if any

                jsr     MLI
                !byte   $c7
                !word   c7_parms
                ldx     $200
                dex
                stx     sizelo
                bmi     +++

                ;find current directory name in directory

readblock       jsr     MLI
                !byte   $80
                !word   x80_parms

                lda     #<(readbuff + NAME_LENGTH)
                sta     bloklo
                lda     #>(readbuff + NAME_LENGTH)
                sta     blokhi
inextent        ldy     #0
                lda     (bloklo), y
                pha
                and     #$0f
                tax
--              iny
                lda     (bloklo), y
                cmp     (namlo), y
                beq     ifoundname

                ;match failed, move to next directory in this block, if possible

-               pla
                clc
                lda     bloklo
                adc     #ENTRY_SIZE
                sta     bloklo
                bcc     +

                ;there can be only one page crossed, so we can increment instead of adc

                inc     blokhi
+               cmp     #<(readbuff + $1ff) ;4 + ($27 * $0d)
                lda     blokhi
                sbc     #>(readbuff + $1ff)
                bcc     inextent

                ;read next directory block when we reach the end of this block

                lda     readbuff + NEXT_BLOCK_LO
                ldx     readbuff + NEXT_BLOCK_HI
                bcs     +

ifoundname      dex
                bne     --

                ;parse path until last directory is seen

                iny
                lda     (namlo), y
                cmp     #'/'
                bne     -
                tya
                eor     #$ff
                adc     sizelo
                sta     sizelo
                clc
                tya
                adc     namlo
                sta     namlo
                pla
                and     #$20 ;Volume Directory Header XOR subdirectory
                bne     ++

                ;cache block number of current directory
                ;as starting position for subsequent searches

                ldy     #(KEY_POINTER + 1)
                lda     (bloklo), y
                tax
                dey
                lda     (bloklo), y
                sta     unrhddblocklo
                stx     unrhddblockhi
+               sta     x80_parms + 4
                stx     x80_parms + 5
++              lda     sizelo
                bne     readblock

                ;unit to slot for SmartPort interface

+++             pla
                lsr
                lsr
                lsr
                tax
                lsr
                ora     #$c0
                ldy     DEVADR01HI, x
                cpy     #$c8
                bcs     set_slot
                tya
set_slot        sta     slot + 2
                sta     unrentry + 1
!if load_aux = 1 {
                sta     SETAUXWR + (load_banked * 4) ;SETAUXWR or SETAUXZP
} ;load_aux

                ;copy interpreter to language card

                lda     $c08b
                lda     $c08b
                lda     #>pakoff
                sta     src + 1
                lda     #<pakoff
                sta     src
                lda     #$d5
                sta     dst + 1
                lda     #0
                sta     dst
                jsr     unpack
                lda     #8
                sta     dst + 1
                jsr     unpack

                ;init interpreter before routine is overwritten

                jsr     $d505

                ;copy new RWTS and interpreter support routines

slot            lda     $cfff
                sta     unrentry
                ldy     #0
-               lda     unrelochdd, y
                sta     reloc, y
                iny
                bne     -

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
                sta     $300	;80-cols
                ldx     #1
                stx     $301	;lowercase
                stx     $305	;warn about missing .sav
                dex
                dex
                stx     $302	;no load
+

                ldy     #casemap_e-casemap
-               lda     xcasemap-1, y
                sta     casemap-1, y
                dey
                bne     -

                lda     #<call80
                sta     $965
                lda     #>call80
                sta     $966

                ldx     $300
                cpx     #$ce
                beq     skip80
                lda     $bf98
                and     #2
                bne     okay80

skip80
                lda     #$93
                sta     call80+1
                lda     #$fe
                sta     call80+2
                lda     #$df
                sta     inversemask+1
                lda     #7
                sta     $dda6
                lda     #$28
                sta     $ded0

okay80
                lda     $301
                beq     useupper
                lda     $bf98
                bmi     skipupper
useupper
                lda     #$df
                sta     normalmask+1
                sta     inversemask+1

skipupper
                ldx     $302
                inx
                beq     +
                ldy     #callback_e-callback1
-               lda     hookkbd-1, y
                sta     callback1-1, y
                dey
                bne     -
                txa
                clc
                adc     #$af
                sta     callback3+1
                lda     $914
                sta     loadcall1+1
                lda     $915
                sta     loadcall2+1
                lda     #<callback1
                sta     $914
                lda     #>callback1
                sta     $915

+
                ldy     #quit_e-waitkey
-               lda     hookquit-1, y
                sta     waitkey-1, y
                dey
                bne     -

                lda     #<waitkey
                sta     $f6a7
                lda     #>waitkey
                sta     $f6a8

                lda     #<quit
                sta     $f6b6
                lda     #>quit
                sta     $f6b7

                ldy     #save_end-saveme
-               lda     saveme-1, y
                sta     $2ff, y
                dey
                bne     -

                lda     #<brand
                sta     $ddb6
                lda     #>brand
                sta     $ddb7

                ldy     $2006
                inc     $2006
                lda     #'V'
                sta     $2006+1,y
                lda     #'A'
                sta     $2006,y
                lda     #'S'
                sta     $2006-1,y
                jsr     hddopendir
                lda     hddgametreelo
                sta     hddsavetreelo
                lda     hddgametreehi
                sta     hddsavetreehi

                ;disable save if no .sav file exists

                lda     status
                beq     +
                lda     #$38 ;sec
                sta     $300
                lda     #$60 ;rts
                sta     $301

+               dec     $2006
                ldy     $2006
                lda     #'5'
                sta     $2006,y
                lda     #'Z'
                sta     $2006-1,y
                jsr     hddopendir
                jmp     entry

call80          jsr     $c300
                lda     $36
                sta     printchar + 1
                lda     $37
                sta     printchar + 2
                lda     #<casemap
                sta     $36
                lda     #>casemap
                sta     $37
                rts

brand           jsr     $db5b
                lda     #$5b
                sta     $ddb6
                lda     #$db
                sta     $ddb7
                lda     #$17
                sta     $25
                lda     #0
                sta     $24
                sta     $57b
                jsr     $8a9
                lda     #>brandtext
                ldx     #<brandtext
                ldy     #(brandtext_e-brandtext)
                jsr     $db5b
                lda     $305
                beq     +
                lda     $300
                cmp     #$38
                bne     +
                dec     $25
                lda     #0
                sta     $24
                sta     $57b
                jsr     $8a9
                lda     #>nosave
                ldx     #<nosave
                ldy     #(nosave_e-nosave)
                jsr     $db5b
+               rts

brandtext       !text   "On Beyond Z-Machine! revision "
                +version
brandtext_e

nosave          !text   "No .sav file, saving disabled"
nosave_e

!if load_aux = 1 {
                sta     CLRAUXWR + (load_banked * 4) ;CLRAUXWR or CLRAUXZP
} ;load_aux

!if rwts_mode = 1 {
                ;read volume directory key block
                ;self-modified by init code

hddopendir
unrhddblocklo = * + 1
                ldx     #2
unrhddblockhi = * + 1
                lda     #0
hddreaddir1
  !if ver_02 = 1 {
                ldy     #0
                sty     adrlo
  } else { ;ver_02 = 0
                stz     adrlo
  } ;ver_02
                ldy     #>hdddirbuf
                sty     adrhi
                jsr     hddseekrd

                ;include volume directory header in count

hddreaddir
  !if might_exist = 1 {
                ldx     hdddirbuf + FILE_COUNT ;assuming only 256 files per subdirectory
                inx
                stx     entries
  } ;might_exist

hddfirstent     lda     #NAME_LENGTH
                sta     bloklo
                lda     #>(hdddirbuf - 1)
                sta     blokhi

                ;there can be only one page crossed, so we can increment here

hddnextent1     inc     blokhi
hddnextent      ldy     #0
  !if (might_exist + allow_trees) > 0 {
                lda     (bloklo), y
    !if might_exist = 1 {
                sty     status

                ;skip deleted entries without counting

                and     #MASK_ALL
                beq     +
    } ;might_exist
                lda     (bloklo), y

                ;remember type
                ;now bits 5-4 are represented by carry (subdirectory), sign (sapling)

                asl
                asl

                ;now bits 5-3 are represented by carry (subdirectory), sign (sapling),
                ;overflow (seedling), and sign+overflow (tree)

                sta     adrhi
                bit     adrhi
                php
  } ;might_exist or allow_trees

                ;match name lengths before attempting to match names

                lda     (bloklo), y
                and     #$0f
                tax
                inx
-               cmp     $2006, y
                beq     hddfoundname

                ;match failed, check if any directory entries remain

  !if allow_trees = 1 {
                plp
  } ;allow_trees
  !if might_exist = 1 {
                dec     entries
                bne     +
                inc     status
                rts
  } ;might_exist

                ;move to next directory in this block, if possible

+               clc
                lda     bloklo
                adc     #ENTRY_SIZE
                sta     bloklo
                bcs     hddnextent1
                cmp     #$ff ;4 + ($27 * $0d)
                bne     hddnextent

                ;read next directory block when we reach the end of this block

                ldx     hdddirbuf + NEXT_BLOCK_LO
                lda     hdddirbuf + NEXT_BLOCK_HI
                bcs     hddreaddir1

hddfoundname    iny
                lda     (bloklo), y
                dex
                bne -

                ;initialise essential variables
                ;if swap_zp then set the values in the array before swapping in

  !if swap_zp = 0 {
    !if allow_trees = 1 {
                stx     treeidx
                stx     istree
                sty     lasttree
    } ;allow_trees
                stx     blkidx
                sty     lastblk
  } else { ;swap_zp = 1
    !if allow_trees = 1 {
                stx     zp_array + treeidx - first_zp
                stx     zp_array + istree - first_zp
                sty     zp_array + lasttree - first_zp
    } ;allow_trees
                stx     zp_array + blkidx - first_zp
                sty     zp_array + lastblk - first_zp
  } ;swap_zp

                ;cache AUX_TYPE (load offset for binary files)

                ldy     #AUX_TYPE
                lda     (bloklo), y
  !if allow_trees = 1 {
                sta     ldrlo
                iny
                lda     (bloklo), y
                sta     ldrhi
  } else { ;allow_trees = 0
                pha
                iny
                lda     (bloklo), y
                pha
  } ;allow_trees

                ;cache KEY_POINTER

                ldy     #KEY_POINTER
                lda     (bloklo), y
                tax
  !if allow_trees = 1 {
                sta     hdddirbuf
    !if fast_trees = 0 {
                sta     hddtreeblklo
      !if (rwts_mode + enable_write) > 1 {
                sta     hddgametreelo
      } ;rwts_mode and enable_write
    } ;fast_trees
                iny
                lda     (bloklo), y
                sta     hdddirbuf + 256
    !if fast_trees = 0 {
                sta     hddtreeblkhi
      !if (rwts_mode + enable_write) > 1 {
                sta     hddgametreehi
      } ;rwts_mode and enable_write
    } ;fast_trees
                plp
                bpl     ++
                ldy     #>hdddirbuf
                bvc     +
    !if fast_trees = 0 {
      !if swap_zp = 0 {
                sty     istree
      } else { ;swap_zp = 1
                sty     zp_array + istree - first_zp
                jsr     swap_zpg
      } ;swap_zp
                bvs     preread
    } else { ;fast_trees = 1
                ldy     #>hddtreebuf
      !if swap_zp = 0 {
                sty     istree
      } else { ;swap_zp = 1
                sty     zp_array + istree - first_zp
      } ;swap_zp
    } ;fast_trees
+
  } else { ;allow_trees = 0
                iny
                lda     (bloklo), y
                ldy     #>hdddirbuf
  } ;allow_trees

                ;read index block in case of sapling

  !if swap_zp = 0 {
                sty     adrhi
  } else { ;swap_zp = 1
                sty     zp_array + adrhi - first_zp
    !if ver_02 = 1 {
                tay
                txa
    } else { ;ver_02 = 0
                phx
    } ;ver_02
                jsr     swap_zpg
    !if ver_02 = 1 {
                tax
                tya
    } else { ;ver_02 = 0
                plx
    } ;ver_02
  } ;swap_zp
                jsr     hddseekrd

                ;read first block of file to complete initialisation
                ;causes tree block to be read and cached if needed

preread         jsr     hddrdwrfile
  !if swap_zp = 1 {
                jsr     swap_zpg
  } ;swap_zp

++
                rts
} ;rwts_mode

c7_parms        !byte   1
                !word   $200

x80_parms       !byte   3, $d1
                !word   readbuff, 2

unrelochdd
!pseudopc reloc {
!if rwts_mode = 1 {
                jsr     swap_zpg
                bmi     swapgame
readimm
                lda     xsechi
                lsr
                sta     treeidx
                lda     xseclo
                ror
                sta     blkidx
                php
                jsr     hddrdwrfile
                plp
                bcc     +
                inc     adrhi
+
intercept
                lda     #$0a
                sta     blokhi
                ldy     #0
                sty     bloklo
                jsr     hddcopycache
clear_carry     clc

swap_zpg        pha
                tya
                pha
                ldx     #(last_zp - first_zp)
-               lda     first_zp,x
                ldy     hddcodeend,x
                sta     hddcodeend,x
                sty     first_zp,x
                dex
                bpl     -
                pla
                tay
                pla
                rts

                ;restore game file base block
                ;and trigger tree block reload

swapgame        sta     lasttree
                lda     xsechi
                lsr
                lda     xseclo
                ror
                tax
                inx
                stx     lastblk
hddgametreelo = * + 1
                ldx     #$d1
                stx     hddtreeblklo
hddgametreehi = * + 1
                lda     #$d1
                sta     hddtreeblkhi
                ldy     istree
                bne     clear_carry
                ldy     #>hdddirbuf
                sty     adrhi
                jsr     hddseekrd
                bcc     readimm

} else { ;rwts_mode = 0
  !if (override_adr + allow_subdir) > 0 {
hddrdwrpart     jmp     hddrdwrfile
  } ;override_adr or allow_subdir
                ;read volume directory key block
                ;self-modified by init code

hddopendir
unrhddblocklo = unrelochdd + (* - reloc)
                ldx     #2
unrhddblockhi = unrelochdd + (* - reloc)
                lda     #0
hddreaddir1     jsr     hddreaddirsel

                ;include volume directory header in count

hddreaddir
  !if might_exist = 1 {
                ldx     hdddirbuf + FILE_COUNT ;assuming only 256 files per subdirectory
                inx
                stx     entries
  } ;might_exist

hddfirstent     lda     #NAME_LENGTH
                sta     bloklo
                lda     #>(hdddirbuf - 1)
                sta     blokhi

                ;there can be only one page crossed, so we can increment here

hddnextent1     inc     blokhi
hddnextent      ldy     #0
  !if (might_exist + allow_subdir + allow_saplings + allow_trees) > 0 {
                lda     (bloklo), y
    !if might_exist = 1 {
                sty     status

                ;skip deleted entries without counting

                and     #MASK_ALL
                beq     +
    } ;might_exist

    !if (allow_subdir + allow_saplings + allow_trees) > 0 {
                ;remember type
                ;now bits 5-4 are represented by carry (subdirectory), sign (sapling)

                asl
                asl

      !if allow_trees = 1 {
                ;now bits 5-3 are represented by carry (subdirectory), sign (sapling),
                ;overflow (seedling), and sign+overflow (tree)

                sta     treeidx
                bit     treeidx
      } ;allow_trees
                php
    } ;allow_subdir or allow_saplings or allow_trees
  } ;might_exist or allow_subdir or allow_saplings or allow_trees

                ;match name lengths before attempting to match names

                lda     (bloklo), y
                and     #$0f
                tax
                inx
-               cmp     (namlo), y
                beq     hddfoundname

                ;match failed, check if any directory entries remain

  !if (allow_subdir + allow_saplings + allow_trees) > 0 {
                plp
  } ;allow_subdir or allow_saplings or allow_trees
  !if might_exist = 1 {
                dec     entries
                bne     +
                inc     status
                rts
  } ;might_exist

                ;move to next directory in this block, if possible

+               clc
                lda     bloklo
                adc     #ENTRY_SIZE
                sta     bloklo
                bcs     hddnextent1
                cmp     #$ff ;4 + ($27 * $0d)
                bne     hddnextent

                ;read next directory block when we reach the end of this block

                ldx     hdddirbuf + NEXT_BLOCK_LO
                lda     hdddirbuf + NEXT_BLOCK_HI
                bcs     hddreaddir1

hddfoundname    iny
                lda     (bloklo), y
                dex
                bne     -

  !if allow_trees = 1 {
                stx     treeidx
                stx     istree
  } ;allow_trees
                stx     entries
  !if aligned_read = 0 {
                stx     blkofflo
                stx     blkoffhi
  } ;aligned_read
  !if enable_write = 1 {
                ldy     reqcmd
                cpy     #cmdwrite ;control carry instead of zero
                bne     +

                ;round requested size up to nearest block if writing

                lda     sizelo
                adc     #$fe
                lda     sizehi
                adc     #1
                and     #$fe
                sta     sizehi
    !if aligned_read = 0 {
                stx     sizelo
      !if bounds_check = 1 {
                sec
      } ;bounds_check
    } ;aligned_read
+
  } ;enable_write

  !if bounds_check = 1 {
                ;cache EOF (file size, loaded backwards)

                ldy     #EOF_HI
                lda     (bloklo), y
    !if (enable_write + aligned_read) > 0 {
                tax
                dey ;EOF_LO
                lda     (bloklo), y

                ;round file size up to nearest block if writing without aligned reads
                ;or always if using aligned reads

      !if aligned_read = 0 {
                bcc     +
      } else { ;aligned_read = 1
        !if enable_write = 1 {
                sec
        } ;enable_write
      } ;aligned_read
                adc     #$fe
                txa
                adc     #1
                and     #$fe
      !if aligned_read = 0 {
                tax
                lda     #0
+               stx     blefthi
                sta     bleftlo
      } else { ;aligned_read = 1
                sta     blefthi
      } ;aligned_read
    } else { ;not (enable_write or aligned_read)
                sta     blefthi
                dey ;EOF_LO
                lda     (bloklo), y
                sta     bleftlo
    } ;enable_write or aligned_read
  } ;bounds_check
                ;cache AUX_TYPE (load offset for binary files)

  !if override_adr = 0 {
                ldy     #AUX_TYPE
                lda     (bloklo), y
    !if (allow_subdir + allow_saplings + allow_trees + (aligned_read xor 1)) > 0 {
                sta     ldrlo
                iny
                lda     (bloklo), y
                sta     ldrhi
    } else { ;not (allow_subdir or allow_saplings or allow_trees) or aligned_read
                pha
                iny
                lda     (bloklo), y
                pha
    } ;allow_subdir or allow_saplings or allow_trees or not aligned_read
  } ;override_adr

                ;cache KEY_POINTER

                ldy     #KEY_POINTER
                lda     (bloklo), y
                tax
  !if (allow_subdir + allow_saplings + allow_trees) > 0 {
                sta     hdddirbuf
                iny
                lda     (bloklo), y
                sta     hdddirbuf + 256
                plp
                bpl     ++
    !if allow_subdir = 1 {
                php
    } ;allow_subdir
    !if allow_trees = 1 {
                ldy     #>hdddirbuf
                bvc     +
      !if fast_trees = 1 {
                ldy     #>hddtreebuf
      } ;fast_trees
                sty     istree
+
    } ;allow_trees
  } else { ;not (allow_subdir or allow_saplings or allow_trees)
                iny
                lda     (bloklo), y
  } ;allow_subdir or allow_saplings or allow_trees

                ;read index block in case of sapling

                jsr     hddreaddirsect

  !if allow_subdir = 1 {
                plp
  } ;allow_subdir
++
} ;rwts_mode

hddrdwrfile
!if rwts_mode = 0 {
  !if (allow_subdir + allow_saplings + allow_trees + (aligned_read xor 1)) > 0 {
                ;restore load offset

                ldx     ldrhi
                lda     ldrlo
    !if allow_subdir = 1 {
                ;check file type and fake size and load address for subdirectories

                bcc     +
                ldy     #2
                sty     sizehi
                ldx     #>hdddirbuf
                lda     #0
      !if aligned_read = 0 {
                sta     sizelo
      } ;aligned_read
+
    } ;allow_subdir
                sta     adrlo
                stx     adrhi
  } else { ;not (allow_subdir or allow_saplings or allow_trees)
                pla
                sta     adrhi
                pla
                sta     adrlo
  } ;allow_subdir or allow_saplings or allow_trees

                ;set requested size to min(length, requested size)

  !if aligned_read = 0 {
    !if bounds_check = 1 {
                ldy     bleftlo
                cpy     sizelo
                lda     blefthi
                tax
                sbc     sizehi
                bcs     hddcopyblock
                sty     sizelo
                stx     sizehi
    } ;bounds_check

hddcopyblock
    !if allow_aux = 1 {
                ldx     auxreq
                jsr     hddsetaux
    } ;allow_aux
    !if enable_write = 1 {
                lda     reqcmd
                lsr
                bne     hddrdwrloop
    } ;enable_write

                ;if offset is non-zero then we return from cache

                lda     blkofflo
                tax
                ora     blkoffhi
                beq     hddrdwrloop
                lda     sizehi
                pha
                lda     sizelo
                pha
                lda     adrhi
                sta     blokhi
                lda     adrlo
                sta     bloklo
                stx     adrlo
                lda     #>hddencbuf
                clc
                adc     blkoffhi
                sta     adrhi

                ;determine bytes left in block

                lda     #1
                sbc     blkofflo
                tay
                lda     #2
                sbc     blkoffhi
                tax

                ;set requested size to min(bytes left, requested size)

                cpy     sizelo
                sbc     sizehi
                bcs     +
                sty     sizelo
                stx     sizehi
+
    !if enable_seek = 1 {
                lda     sizehi
    } else { ;enable_seek = 0
                ldy     sizehi
    } ;enable_seek
                jsr     hddcopycache

                ;align to next block and resume read

                lda     ldrlo
                adc     sizelo
                sta     ldrlo
                lda     ldrhi
                adc     sizehi
                sta     ldrhi
                sec
                pla
                sbc     sizelo
                sta     sizelo
                pla
                sbc     sizehi
                sta     sizehi
                ora     sizelo
                bne     hddrdwrfile
    !if (allow_aux + swap_zp) = 0 {
                rts
    } else { ;allow_aux or swap_zp
                beq     hddrdwrdone
    } ;not (allow_aux or swap_zp)
  } else { ;aligned_read = 1
    !if bounds_check = 1 {
                lda     blefthi
                cmp     sizehi
                bcs     +
                sta     sizehi
+
    } ;bounds_check
    !if allow_aux = 1 {
                ldx     auxreq
                jsr     hddsetaux
    } ;allow_aux
  } ;aligned_read
} ;rwts_mode

hddrdwrloop
!if aligned_read = 0 {
  !if rwts_mode = 0 {
    !if (enable_write + enable_seek) > 0 {
                ldx     reqcmd
    } ;enable_write or enable_seek

                ;set read/write size to min(length, $200)

                lda     sizehi
                cmp     #2
                bcs     +
                pha

                ;redirect read to private buffer for partial copy

                lda     adrhi
                pha
                lda     adrlo
                pha
                lda     #2
                sta     sizehi
  } ;rwts_mode
                lda     #>hddencbuf
                sta     adrhi
  !if ver_02 = 1 {
                ldx     #0
                stx     adrlo
    !if ((enable_write + enable_seek) and (rwts_mode - 1)) > 0 {
                inx ;ldx #cmdread
    } ;(enable_write or enable_seek) and not rwts_mode
  } else { ;ver_02 = 0
                stz     adrlo
    !if ((enable_write + enable_seek) and (rwts_mode - 1)) > 0 {
                ldx     #cmdread
    } ;(enable_write or enable_seek) and not rwts_mode
  } ;ver_02
+
} ;aligned_read

!if allow_trees = 1 {
                ;read tree data block only if tree and not read already
                ;the indication of having read already is that at least one sapling/seed block entry has been read, too

  !if rwts_mode = 0 {
                ldy     blkidx
                bne     +
                lda     istree
  } else { ;rwts_mode = 1
                ldy     istree
  } ;rwts_mode
                beq     +
                lda     adrhi
                pha
                lda     adrlo
                pha
  !if rwts_mode = 0 {
    !if ((aligned_read xor 1) + (enable_write or enable_seek)) > 1 {
      !if ver_02 = 1 {
                txa
                pha
      } else { ;ver_02 = 0
                phx
      } ;ver_02
    } ;(not aligned_read) and (enable_write or enable_seek)
    !if aligned_read = 0 {
                php
    } ;aligned_read
                lda     #>hdddirbuf
                sta     adrhi
                sty     adrlo
  } else { ;rwts_mode = 1
                ;or in this case, read whenever tree index changes

                sty     adrhi
                ldy     treeidx
                cpy     lasttree
                sty     lasttree
                beq     skiptree
                ldx     blkidx
                inx
                stx     lastblk
  } ;rwts_mode

                ;fetch tree data block and read it

  !if fast_trees = 0 {
hddtreeblklo = * + 1
                ldx     #$d1
hddtreeblkhi = * + 1
                lda     #$d1
                jsr     hddseekrd
    !if rwts_mode = 0 {
                ldy     treeidx
                inc     treeidx
    } else { ;rwts_mode = 1
                ldy     treeidx
    } ;rwts_mode
                ldx     hdddirbuf, y
                lda     hdddirbuf + 256, y
  } else { ;fast_trees = 1
    !if rwts_mode = 0 {
                inc     treeidx
    } ;rwts_mode
                ldx     hddtreebuf, y
                lda     hddtreebuf + 256, y
  } ;fast_trees
                jsr     hddseekrd

skiptree
  !if rwts_mode = 0 {
    !if aligned_read = 0 {
                plp
    } ;aligned_read
    !if ((aligned_read xor 1) + (enable_write or enable_seek)) > 1 {
      !if ver_02 = 1 {
                pla
                tax
      } else { ;ver_02 = 0
                plx
      } ;ver_02
    } ;(not aligned_read) and (enable_write or enable_seek)
  } ;rwts_mode
                pla
                sta     adrlo
                pla
                sta     adrhi
} ;allow_trees

                ;fetch data block and read/write it

!if rwts_mode = 1 {
+
} ;rwts_mode
                ldy     blkidx
!if rwts_mode = 0 {
+               inc     blkidx
  !if aligned_read = 0 {
    !if enable_seek = 1 {
                txa ;cpx #cmdseek, but that would require php at top
                beq     +
    } ;enable_seek
    !if enable_write = 1 {
                stx     command
    } ;enable_write
  } ;aligned_read
} else { ;rwts_mode = 1
                ;read whenever block index changes

                cpy     lastblk
                sty     lastblk
                beq     skipblk
} ;rwts_mode

                ldx     hdddirbuf, y
                lda     hdddirbuf + 256, y
!if allow_sparse = 1 {
                pha
                ora     hdddirbuf, y
                tay
                pla
                dey
                iny ;don't affect carry
} ;allow_sparse
!if (aligned_read + rwts_mode) = 0 {
                php
} ;aligned_read or rwts_mode
!if allow_sparse = 1 {
  !if rwts_mode = 0 {
                beq     hddissparse
  } else { ;rwts_mode = 1
                bne     hddseekrd
  } ;rwts_mode
} ;allow_sparse
!if rwts_mode = 0 {
  !if (aligned_read and (enable_write or enable_seek)) = 1 {
                ldy     reqcmd
    !if enable_seek = 1 {
                beq     +
    } ;enable_seek
  } ;aligned_read and (enable_write or enable_seek)
  !if enable_write = 1 {
                jsr     hddseekrdwr
  } else { ;enable_write = 0
                jsr     hddseekrd
  } ;enable_write
hddresparse
  !if aligned_read = 0 {
                plp
    !if bounds_check = 1 {
+               bcc     +
                dec     blefthi
                dec     blefthi
    } ;bounds_check
  } ;aligned_read
                inc     adrhi
                inc     adrhi
+               dec     sizehi
                dec     sizehi
                bne     hddrdwrloop
  !if aligned_read = 0 {
    !if bounds_check = 0 {
                bcc     +
    } ;bounds_check
                lda     sizelo
                bne     hddrdwrloop
  } ;aligned_read
hddrdwrdone
  !if allow_aux = 1 {
                ldx     #0
hddsetaux       sta     CLRAUXRD, x
                sta     CLRAUXWR, x
  } ;allow_aux
  !if swap_zp = 1 {
swap_zpg
                pha
                tya
                pha
                ldx     #(last_zp - first_zp)
-               lda     first_zp,x
                ldy     hddcodeend,x
                sta     hddcodeend,x
                sty     first_zp,x
                dex
                bpl     -
                pla
                tay
                pla
  } ;swap_zp
                rts
} ;rwts_mode

!if allow_sparse = 1 {
hddissparse
-               sta     (adrlo), y
                inc     adrhi
                sta     (adrlo), y
                dec     adrhi
                iny
                bne     -
  !if rwts_mode = 0 {
                beq     hddresparse
  } ;rwts_mode
} ;allow_sparse
!if rwts_mode = 1 {
skipblk         rts
} ;rwts_mode

!if aligned_read = 0 {
  !if rwts_mode = 0 {
                ;cache partial block offset

+               pla
                sta     bloklo
                pla
                sta     blokhi
                pla
                sta     sizehi
    !if bounds_check = 0 {
                dec     adrhi
                dec     adrhi
    } ;bounds_check

    !if enable_seek = 1 {
hddcopycache
                ldy     reqcmd
                ;cpy #cmdseek
                beq     ++
                tay
    } else { ;enable_seek = 0
                tay
hddcopycache
    } ;enable_seek
                beq     +
                dey
  } else { ;rwts_mode = 1
hddcopycache
  } ;rwts_mode
-               lda     (adrlo), y
                sta     (bloklo), y
                iny
                bne     -
  !if rwts_mode = 0 {
                inc     blokhi
                inc     adrhi
                bne     +
-               lda     (adrlo), y
                sta     (bloklo), y
                iny
+               cpy     sizelo
                bne     -
++
    !if bounds_check = 1 {
                lda     bleftlo
                sec
                sbc     sizelo
                sta     bleftlo
                lda     blefthi
                sbc     sizehi
                sta     blefthi
    } ;bounds_check
                clc
    !if enable_seek = 1 {
                lda     sizelo
    } else { ;enable_seek = 0
                tya
    } ;enable_seek
                adc     blkofflo
                sta     blkofflo
                lda     sizehi
                adc     blkoffhi
                and     #$fd
                sta     blkoffhi
                bcc     hddrdwrdone ;always
  } else { ;rwts_mode = 1
                rts
  } ;rwts_mode
} ;aligned_read

!if rwts_mode = 0 {
hddreaddirsel
  !if ver_02 = 1 {
                ldy     #0
                sty     adrlo
    !if might_exist = 1 {
                sty     status
    } ;might_exist
  } else { ;ver_02 = 0
                stz     adrlo
    !if might_exist = 1 {
                stz     status
    } ;might_exist
  } ;ver_02

  !if allow_multi = 1 {
                asl     reqcmd
                lsr     reqcmd
  } ;allow_multi

hddreaddirsec
  !if allow_trees = 0 {
hddreaddirsect  ldy     #>hdddirbuf
  } else { ;allow_trees = 1
                ldy     #>hdddirbuf
hddreaddirsect
  } ;allow_trees
                sty     adrhi
} ;rwts_mode
hddseekrd       ldy     #cmdread
!if (aligned_read + enable_write) > 1 {
hddseekrdwr     sty     command
} else { ;not (aligned_read or enable_write)
                sty     command
hddseekrdwr
} ;aligned_read and enable_write

                stx     bloklo
                sta     blokhi

hddcallsp
unrunit = unrelochdd + (* + 1 - reloc)
                lda     #$d1
                sta     unit

unrentry = unrelochdd + (* + 1 - reloc)
                jmp     $d1d1

hddcodeend
  !if swap_zp = 1 {
zp_array        !fill last_zp - first_zp
  } ;swap_zp
hdddataend
} ;reloc

;[music] you can't touch this [music]
;math magic to determine ideal loading address, and information dump
!ifdef PASS2 {
} else { ;PASS2 not defined
  !set PASS2=1
  !if reloc < $c000 {
    !if ((hdddataend + $ff) & -256) > $c000 {
      !serious "initial reloc too high, adjust to ", $c000 - (((hdddataend + $ff) & -256) - reloc)
    } ;hdddataend
    !if load_high = 1 {
      !if ((hdddataend + $ff) & -256) != $c000 {
        !warn "initial reloc too low, adjust to ", $c000 - (((hdddataend + $ff) & -256) - reloc)
      } ;hdddataend
      hdddirbuf = reloc - $200
      !if aligned_read = 0 {
        hddencbuf = hdddirbuf - $200
      } ;aligned_read
      !if allow_trees = 1 {
        !if aligned_read = 0 {
          hddtreebuf = hddencbuf - $200
        } else { ;aligned_read = 1
          hddtreebuf = hdddirbuf - $200
        } ;aligned_read
      } ;allow_trees
    } else { ;load_high = 0
      !pseudopc ((hdddataend + $ff) & -256) {
        hdddirbuf = *
      }
      !if aligned_read = 0 {
        hddencbuf = hdddirbuf + $200
        !if hddencbuf >= $c000 {
          !if hddencbuf < $d000 {
            !set hddencbuf = reloc - $200
          }
        }
      } ;aligned_read
      !if allow_trees = 1 {
        !if aligned_read = 0 {
          hddtreebuf = hddencbuf + $200
          !if hddtreebuf >= reloc {
            !if hddencbuf < hddcodeend {
              !set hddtreebuf = hddencbuf - $200
            }
          }
        } else { ;aligned_read = 1
          hddtreebuf = hdddirbuf + $200
        } ;aligned_read
      } ;allow_trees
    } ;load_high
  } else { ;reloc > $c000
    !if ((hdddataend + $ff) & -256) < reloc {
      !serious "initial reloc too high, adjust to ", (0 - (((hdddataend + $ff) & -256) - reloc)) & $ffff
    } ;hdddataend
    !if load_high = 1 {
        !if (((hdddataend + $ff) & -256) & $ffff) != 0 {
          !warn "initial reloc too low, adjust to ", (0 - (((hdddataend + $ff) & -256) - reloc)) & $ffff
        } ;hdddataend
      hdddirbuf = reloc - $200
      !if aligned_read = 0 {
        hddencbuf = hdddirbuf - $200
      } ;aligned_read
      !if allow_trees = 1 {
        !if aligned_read = 0 {
          hddtreebuf = hddencbuf - $200
        } else { ;aligned_read = 1
          hddtreebuf = hdddirbuf - $200
        } ;aligned_read
      } ;allow_trees
    } else { ;load_high = 0
      !pseudopc ((hdddataend + $ff) & -256) {
        hdddirbuf = reloc - $200
      }
      !if aligned_read = 0 {
        hddencbuf = hdddirbuf - $200
      } ;aligned_read
      !if (allow_trees + fast_trees) > 1 {
        !if aligned_read = 0 {
          hddtreebuf = hddencbuf + $200
        } else { ;aligned_read = 1
          hddtreebuf = hdddirbuf + $200
        } ;aligned_read
      } ;allow_trees
    } ;load_high
  } ;reloc
  !if verbose_info = 1 {
    !warn "hdd code: ", reloc, "-", hddcodeend - 1
    !warn "hdd data: ", hddcodeend, "-", hdddataend - 1
    !warn "hdd dirbuf: ", hdddirbuf, "-", hdddirbuf + $1ff
    !if aligned_read = 0 {
      !warn "hdd encbuf: ", hddencbuf, "-", hddencbuf + $1ff
    } ;aligned_read
    !if (allow_trees + fast_trees) > 1 {
      !warn "hdd treebuf: ", hddtreebuf, "-", hddtreebuf + $1ff
    } ;allow_trees
    !warn "hdd driver start: ", unrelochdd - init
    !if one_page = 0 {
      !if ((hddcodeend - hddopendir) < $100) {
        !warn "one_page can be enabled, code is small enough"
      } ;hddcodeend
    } ;!one_page
  } ;verbose_info
} ;PASS2

xcasemap !pseudopc $2e7 {;;-(callback_e-callback1) {
casemap
        ora     #$80
        cmp     #$e1
        bcc     printchar
        cmp     #$fb
        bcs     printchar
normalmask
        and     #$ff
        sty     $35
        ldy     $32
        bmi     +
inversemask
        and     #$ff
+       ldy     $35
printchar
        jmp     $d1d1
casemap_e
}
!if verbose_info = 1 {
         !warn "case=",$300-(casemap_e-casemap)
}

saveme
!pseudopc $300 {
                jsr     swap_zpg
                lsr
                sta     xsechi
hddsavetreelo = * + 1
                lda     #$d1
                sta     hddtreeblklo
hddsavetreehi = * + 1
                lda     #$d1
                sta     hddtreeblkhi

                ;always enable tree mode
                ;trigger tree block reload on first pass

                php
                sec
                ror     lasttree
                lda     $5
                asl
                asl
                asl
                rol     xsechi
                asl
                rol     xsechi
                ora     $4
                sta     xseclo
                jsr     readpart
                plp
                bcc     restore

                ;if sparse block

                lda     hdddirbuf, y
                ora     hdddirbuf + 256, y
                beq     sparseblk
                inc     command

copyblock       ldy     #0
-               lda     $a00, y
                sta     (adrlo), y
                iny
                bne     -
                lda     #>hddencbuf
                sta     adrhi
                ldy     lastblk
                ldx     hdddirbuf, y
                lda     hdddirbuf + 256, y
                jsr     hddseekrdwr
return          jmp     swap_zpg

restore         jmp     intercept

                ;read volume bitmap

sparseblk       ldx     #2
                jsr     hddseekrd
                sta     namlo
                sta     namhi

                ;round up to block count

                lda     hddencbuf + $29
                adc     #$ff
                lda     hddencbuf + $2A
                adc     #1
                lsr
                sta     ldrhi
                ldx     hddencbuf + $27
                lda     hddencbuf + $28
---             ldy     #>hddencbuf
                sty     adrhi
                jsr     hddseekrd
                tay

                ;scan for a free block

--              lda     #$80
                sta     ldrlo
-               lda     (adrlo), y
                and     ldrlo
                bne     foundbit
                inc     namlo
                lsr     ldrlo
                bcc     -
                lda     namlo
                bne     +
                inc     namhi
+               iny
                bne     --
                inc     adrhi
                lda     adrhi
                cmp     #(>hddencbuf) + 2
                bne     --
                inc     bloklo
                bne     +
                inc     blokhi
+               dec     ldrhi
                bne     --

                ;signal disk full via implicit carry set

                beq     return

                ;allocate block and update bitmap

foundbit        lda     (adrlo), y
                eor     ldrlo
                sta     (adrlo), y
                lda     #>hddencbuf
                jsr     writeimm
                sec
                ror     lasttree
                jsr     readpart
                lda     namlo
                sta     hdddirbuf, y
                lda     namhi
                sta     hdddirbuf + 256, y
                lda     #>hdddirbuf
                jsr     writeimm
                lda     #>hddencbuf
                sta     adrhi
                jmp     copyblock

writeimm        sta     adrhi
                inc     command
                jmp     hddcallsp

readpart        lda     istree
                pha
                lda     #>hdddirbuf
                sta     istree

                ;block copy after read

                lda     #$60
                sta     intercept
                jsr     readimm

                ;restore code for future

                lda     #$a9
                sta     intercept
                pla
                sta     istree
                ldy     lastblk
                rts
}
save_end

hookkbd
!pseudopc $2a7 {;;-(callback_e-callback1) {
callback1
                ldx     #<callback2
                lda     #$8d
                bne     setcall

callback2
                cpy     #$ff
                beq     callback3
                ldx     #<callback3
restpos
                lda     xrestore
                inc     restpos+1
                cmp     #$8d
                beq     setcall
                rts

callback3
                lda     #$d1
                ldx     #<callback4
                bne     setcall

callback4
                lda     #$D9
loadcall2
                ldx     #$fd
                stx     $915
loadcall1
                ldx     #$0c
setcall
                stx     $914
                rts

xrestore
                !byte   $d2,$c5,$d3,$d4,$cf,$d2,$c5,$8d
callback_e
}

hookquit
!pseudopc $2d9 {;;-(quit_e-waitkey) {
waitkey
                lda     $c010
-               lda     $c000
                bpl     -

quit            lda     $c081
                jmp     $faa6
quit_e
}

!if verbose_info = 1 {
        !warn "base=",casemap-((quit_e-waitkey)+(callback_e-callback1))
        !warn "quit=",casemap-(quit_e-waitkey)
}

unpack ;unpacker entrypoint
		lda	#0
		sta	last
		sta	ecx+1

literal		jsr	getput
		ldy	#2

nexttag		jsr	getbit
		bcc	literal
		jsr	getbit
		bcc	codepair
		jsr	getbit
		bcs	onebyte
		jsr	getsrc
		lsr
		beq	donedepacking
		ldx	#0
		stx	ecx
		rol	ecx
		stx	last+1
		tax
		bne	domatch_with_2inc

getbit		asl	last
		bne	.stillbitsleft
		jsr	getsrc
		sec
		rol
		sta	last

.stillbitsleft

donedepacking	rts

onebyte		ldy	#0
		sty	tmp+1
		iny
		sty	ecx
		iny
		lda	#$10

.getmorebits	pha
		jsr	getbit
		pla
		rol
		bcc	.getmorebits
		bne	domatch
		jsr	putdst

linktag		bne	nexttag

codepair	jsr	getgamma
-		jsr	dececx
		dey
		bne	-
		tay
		beq	+

normalcodepair	dey
		sty	last+1
		jsr	getsrc
		tax
		!byte	$a9
+		iny
		jsr	getgamma
		cpy	#$7d
		bcs	domatch_with_2inc
		cpy	#5
		bcs	domatch_with_inc
		txa
		bmi	domatch_new_lastpos
		tya
		bne	domatch_new_lastpos

domatch_with_2inc
		clc
		!byte	$24
set_carry	sec

domatch_with_inc
		inc	ecx
		bne	test_carry
		inc	ecx+1
test_carry	bcc	set_carry

domatch_new_lastpos

domatch_lastpos	ldy	#1
		lda	last+1
		sta	tmp+1
		txa

domatch		sta	tmp
		lda	src+1
		pha
		lda	src
		pha
		lda	dst
		sec
		sbc	tmp
		sta	src
		lda	dst+1
		sbc	tmp+1
		sta	src+1
;;access1
;;		sta 	$c003
-		jsr	getput
		jsr	dececx
		ora	ecx+1
		bne	-
;;		sta	$c002
		pla
		sta	src
		pla
		sta	src+1
		bne	linktag

getgamma	lda	#1
		sta	ecx

.getgammaloop	jsr	getbit
		rol	ecx
		rol	ecx+1
		jsr	getbit
		bcs	.getgammaloop
		rts

dececx		lda	ecx
		bne	+
		dec	ecx+1
+		dec	ecx
		lda	ecx
		rts

getput		jsr	getsrc

putdst		sty	tmp
		ldy	#0
		sta	(dst), y
		inc	dst
		bne	+
		inc	dst+1
+		ldy	tmp
		rts

getsrc		sty	tmp
		ldy	#0
		lda	(src), y
		inc	src
		bne	+
		inc	src+1
+		ldy	tmp
		rts

pakoff
!bin "src/onbeyond/z5/d500-ffff.pak"
!bin "src/onbeyond/z5/0800-09ff.pak"

readbuff
!byte $D3,$C1,$CE,$A0,$C9,$CE,$C3,$AE
