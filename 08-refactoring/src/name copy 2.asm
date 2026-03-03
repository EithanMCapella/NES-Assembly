.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
nametable_lo:  .res 1
nametable_hi:  .res 1
metatile_ptr:  .res 2
tmp:           .res 1

.segment "CODE"

.proc DrawMetatile
    ; A = metatile index

    ; PHA
    ; TYA 
    ; PHA 

    ASL A
    ASL A
    TAY                 ; Y = index * 4

    ; --- Top Row ---

    LDA nametable_hi
    STA PPUADDR
    LDA nametable_lo
    STA PPUADDR

    LDA metatiles,Y     ; TL
    STA PPUDATA

    INY
    LDA metatiles,Y     ; TR
    STA PPUDATA

    ; --- Move down 1 row ---

    CLC
    LDA nametable_lo
    ADC #32
    STA nametable_lo
    BCC :+
    INC nametable_hi
:

    LDA nametable_hi
    STA PPUADDR
    LDA nametable_lo
    STA PPUADDR

    INY
    LDA metatiles,Y     ; BL
    STA PPUDATA

    INY
    LDA metatiles,Y     ; BR
    STA PPUDATA

    ; --- Restore top row address ---
    SEC
    LDA nametable_lo
    SBC #32
    STA nametable_lo
    BCS :+
    DEC nametable_hi
:

    ; PLA 
    ; TAY 
    ; PLA 
    ; TAY 

    RTS
.endproc


.proc DrawBackground

    ; Start at $2000
    LDA #$20
    STA nametable_hi
    LDA #$00
    STA nametable_lo

    LDY #0          ; index into level_map
    LDX #16         ; 16 metatiles per row

NextMetatile:
    LDA level_map,Y
    JSR DrawMetatile

    ; Move 2 tiles right
    CLC
    LDA nametable_lo
    ADC #2
    STA nametable_lo
    BCC :+
    INC nametable_hi
:

    INY
    DEX
    BNE NextMetatile

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

; write a palette
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

LDA #$20
STA nametable_hi
LDA #$00
STA nametable_lo
LDA PPUSTATUS   ; reset latch

JSR DrawBackground


; finally, attribute table. These addresses don't match the actual characters
LDA PPUSTATUS
LDA #$23
STA PPUADDR
LDA #$DD
STA PPUADDR
LDA #%00000101 ; This assigns the palette
STA PPUDATA

; finally, attribute table. These addresses don't match the actual characters
LDA PPUSTATUS
LDA #$23
STA PPUADDR
LDA #$DC
STA PPUADDR
LDA #%00001010 ; This assigns the palette
STA PPUDATA

LDA PPUSTATUS
LDA #$23
STA PPUADDR
LDA #$e0
STA PPUADDR
LDA #%00001100
STA PPUDATA

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
.byte $0f, $00, $00, $00

.byte $0f, $20, $00, $00
.byte $0f, $00, $00, $00
.byte $0f, $00, $00, $00
.byte $0f, $00, $00, $00

; Define Metatiles
; TL TR BL BR
metatiles:
.byte $00, $00, $00, $00
.byte $01, $02, $03, $04 ; Tile 1 Brick
.byte $05, $06, $07, $08 ; Tile 2 Block
.byte $09, $0A, $0B, $0C ; Tile 3 Column
.byte $0D, $0E, $0F, $10 ; Tile 4 Stone


; 32x30 tiles, metatiles are 2x2 so 16x15 metatiles
level_map:
.byte 3,1,1,1,1,1,1,1,2,2,2,2,3,3,3,4
.byte 0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0
.byte 0,1,1,1,2,2,2,1,1,0,0,2,2,2,1,0


.segment "CHR"
chr_start:
;.incbin "starfield.chr"
.byte $00, $00, $00, $00, $00, $00, $00, $00 ; Capa Alta Don't know which this one refers to background?
.byte $00, $00, $00, $00, $00, $00, $00, $00 ; Capa Baja

;low
.byte %11111111 ; TL (00) Percentage means binary ; these are the low bits
.byte %11000000
.byte %11000000
.byte %11000000
.byte %11000000
.byte %11111111
.byte %10000001
.byte %10000001
;High Byte
.byte %00000000
.byte %00111111
.byte %01111111 
.byte %01111111 
.byte %01111111 
.byte $00
.byte %01111110 
.byte %01111110 ; these are the high bits in Hexadecimal $

.byte %11111111 ; TR (01)
.byte %00010001
.byte %00010001
.byte %00010001
.byte %00010001
.byte %11111111
.byte %10000001
.byte %10000001
;High Byte
.byte %00000000
.byte %11101110
.byte %11101110 
.byte %11101110 
.byte %11101110 
.byte $00000000
.byte %01111110 
.byte %11111110

.byte %10000001 ; BL (02)
.byte %10000001
.byte %11111111
.byte %11000000
.byte %11000000
.byte %11000000
.byte %11000000
.byte %11111111
;High Byte
.byte %01111110
.byte %01111110
.byte %00000000 
.byte %00111111 
.byte %01111111 
.byte %01111111
.byte %01111111 
.byte %00000000


.byte %10000001 ; BR (03)
.byte %10000001
.byte %11111111
.byte %10000001
.byte %10000001
.byte %10000001
.byte %10000001
.byte %11111111
;High Byte
.byte %11111110
.byte %11111110
.byte %00000000 
.byte %01111110 
.byte %01111110 
.byte %01111110
.byte %01111110 
.byte %00000000


.byte %01111111 ; TL1 (04)
.byte %10000000
.byte %10000000
.byte %10000000
.byte %10000000
.byte %10000000
.byte %10000000
.byte %10000000
;High Byte
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111

.byte %11111111 ; TR1 (05)
.byte %00000001
.byte %00000001
.byte %00000001
.byte %00000001
.byte %00000001
.byte %00000001
.byte %00000001
;High Byte
.byte %11111110
.byte %11111110
.byte %11111110
.byte %11111110
.byte %11111110
.byte %11111110
.byte %11111110
.byte %11111110

.byte %10000000 ; BL1 (06)
.byte %10000000
.byte %10000000
.byte %10000000
.byte %10000000
.byte %10000000
.byte %11111111
.byte %11111111
;High Byte
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %10000000
.byte %00000000

.byte %00000001 ; BR1 (07)
.byte %00000001
.byte %00000001
.byte %00000001
.byte %00000001
.byte %00000001
.byte %11111101
.byte %11111111
;High Byte
.byte %11111110
.byte %11111110
.byte %11111110
.byte %11111110
.byte %11111110
.byte %11111110
.byte %00000010
.byte %00000000

.byte %11111111 ; TL2 (08)
.byte %11000111
.byte %11000111
.byte %11000110
.byte %10000010
.byte %10000010
.byte %10000010
.byte %10000010
;High Byte
.byte %00000000
.byte %00111000
.byte %01111101
.byte %01111101
.byte %01111101
.byte %01111101
.byte %01111101
.byte %01111101

.byte %11111111 ; TR2 (09)
.byte %11100011
.byte %01100011
.byte %01100011
.byte %01000001
.byte %01000001
.byte %01000001
.byte %01000001
;High Byte
.byte %00000000
.byte %10011100
.byte %10111110
.byte %10111110
.byte %10111110
.byte %10111110
.byte %10111110
.byte %10111110

.byte %10000010 ; BL2 (0A)
.byte %10000010
.byte %10000010
.byte %10000010
.byte %11000110
.byte %11000110
.byte %11000111
.byte %11111111
;High Byte
.byte %01111101
.byte %01111101
.byte %01111101
.byte %01111101
.byte %01111101
.byte %01111101
.byte %00111001
.byte %00000000

.byte %01000001 ; BR2 (0A)
.byte %01000001
.byte %01000001
.byte %01000001
.byte %01100011
.byte %01100011
.byte %11100011
.byte %11111111
;High Byte
.byte %10111110
.byte %10111110
.byte %10111110
.byte %10111110
.byte %10111110
.byte %10111110
.byte %10011100
.byte %00000000

.byte %01111111 ; TL3 (0A)
.byte %10000000
.byte %10000000
.byte %10000000
.byte %10000000
.byte %10000000
.byte %10000000
.byte %10000000
;High Byte
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111
.byte %11111111

.byte %11011111 ; TR3 (0A)
.byte %01100001
.byte %01100001
.byte %11100001
.byte %11110001
.byte %11111110
.byte %11000001
.byte %11000001
;High Byte
.byte %10111110
.byte %10111110
.byte %10111110
.byte %10111110
.byte %10101110
.byte %10100001
.byte %10111110
.byte %10111110

.byte %10000000 ; BL3 (0A)
.byte %10000000
.byte %11100000
.byte %11111000
.byte %00011111
.byte %00000111
.byte %00000001
.byte %11111110
;High Byte
.byte %11111111
.byte %11111111
.byte %00011111
.byte %11100111
.byte %11111000
.byte %11111110
.byte %11111110
.byte %00000001

.byte %01100001 ; BR3 (0A)
.byte %01100001
.byte %11000001
.byte %11000001
.byte %10000001
.byte %10000001
.byte %10000011
.byte %11111110
;High Byte
.byte %10111110
.byte %10111110
.byte %01111110
.byte %01111110
.byte %11111110
.byte %11111110
.byte %11111100
.byte %10000001

.res $2000 - (* - chr_start)
;  * = current location counter
; * - chr_start = cur_pos - X
; how many bytes we have written into this segment so far
; or = bytes already used in CHR

;Cartridge needs to measure 8kb, this is the left over after making the tiles.
;Whenever we add tiles we need to modify this number.
; One 8x8 tile is 16 bytes 8bytes low and 8 bytes high
; One 16x16 metatile is 64 bytes.

;General Formula = 8192 - (Tiles * 16)