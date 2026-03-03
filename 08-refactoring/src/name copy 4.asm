.include "constants.inc"
.include "header.inc"

.segment "CODE"

.proc DrawBackground
    BIT PPUSTATUS
    LDA #$20
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    LDX #$00        ; high counter (3 full pages + remainder)
    LDY #$00
loop:
    LDA map,Y
    STA PPUDATA
    INY
    BNE loop
    INX
    CPX #$03        ; after 3 full pages (768 bytes), do remainder
    BNE loop
    ; last 192 bytes (768 + 192 = 960)
    LDY #$00
remainder:
    LDA map+768,Y
    STA PPUDATA
    INY
    CPY #192
    BNE remainder
    RTS
.endproc

.proc DrawAttributes
    BIT PPUSTATUS
    LDA #$23
    STA PPUADDR
    LDA #$C0
    STA PPUADDR

    LDX #0
attr_loop:
    LDA palette_map,X
    STA PPUDATA
    INX
    CPX #64
    BNE attr_loop
    RTS
.endproc

.proc irq_handler
RTI
.endproc

.proc nmi_handler
RTI
.endproc

.import reset_handler

.export main
.proc main

; turn rendering OFF
LDA #$00
STA PPUCTRL
STA PPUMASK

vblankwait:
BIT PPUSTATUS
BPL vblankwait

; write a palette ;We will make a subroutine that draws all sprites.
LDX PPUSTATUS
LDX #$3f
STX PPUADDR
LDX #$00
STX PPUADDR
load_palettes:
LDA palettes,X
STA PPUDATA
INX
CPX #$20
BNE load_palettes

; LDA #$20
; STA nametable_hi
; LDA #$00
; STA nametable_lo

LDA PPUSTATUS   ; reset latch
JSR DrawBackground
JSR DrawAttributes

; LDA PPUSTATUS
; LDA #$23
; STA PPUADDR
; LDA #$e0
; STA PPUADDR
; LDA #%00000000
; STA PPUDATA

; vblankwait: ; wait for another vblank before continuing
; BIT PPUSTATUS
; BPL vblankwait
; Set scroll = 0,0
LDA PPUSTATUS
LDA #$00
STA PPUSCROLL ;$2005 in case it doesn't work
STA PPUSCROLL ;Helps to remove issue a random tile in the first position

; enable Rendering
LDA #%10000000;#%10010000 ; turn on NMIs, sprites use first pattern table
STA PPUCTRL
LDA #%00011110 ; turn on screen
STA PPUMASK

forever:
JMP forever
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes: ; Siempre el mismo color para la pos 00 (es el color transparente en este caso $0F)
.byte $0f, $11, $21, $32
.byte $0f, $1A, $2A, $3B
.byte $0f, $16, $26, $37
.byte $0f, $16, $26, $37

.byte $0f, $20, $00, $00
.byte $0f, $00, $00, $00
.byte $0f, $00, $00, $00
.byte $0f, $00, $00, $00

; Import the Map data
.include "map.asm"


palette_map:
; Mirrors the level_map, one attribute byte controls a 2x2 block of metatiles
; Each attribute needs all quadrants to be the same so:
; Palette 0 = %00000000, Palette 1 = %01010101 Palette 2 = %10101010
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %10101010, %10101010, %10101010, %10101010, %10101010, %10101010, %00000000
.byte %01010101, %10101010, %10101010, %10101010, %10101010, %10101010, %10101010, %01010101
.byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101
.byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101
.byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101

.segment "CHR"
.incbin "tiles.chr"

;.res $2000 - (* - chr_start)
;  * = current location counter
; * - chr_start = cur_pos - X
; how many bytes we have written into this segment so far
; or = bytes already used in CHR

;Cartridge needs to measure 8kb, this is the left over after making the tiles.
;Whenever we add tiles we need to modify this number.
; One 8x8 tile is 16 bytes 8bytes low and 8 bytes high
; One 16x16 metatile is 64 bytes.

;General Formula = 8192 - (Tiles * 16)