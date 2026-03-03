.include "constants.inc"
.include "header.inc"

.segment "CODE"

; Keep track of the offset if not we reach 256 bytes and we go back to the start
; Symptom First 4 rows kept being repeated.
.proc DrawBackground
    BIT PPUSTATUS
    LDA #$20
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    LDY #$00
page0:
    LDA map,Y
    STA PPUDATA
    INY
    BNE page0

    LDY #$00
page1:
    LDA map+256,Y
    STA PPUDATA
    INY
    BNE page1

    LDY #$00
page2:
    LDA map+512,Y
    STA PPUDATA
    INY
    BNE page2

    LDY #$00
page3:
    LDA map+768,Y
    STA PPUDATA
    INY
    BNE page3

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

LDA PPUSTATUS   ; reset latch
JSR DrawBackground

; vblankwait: ; wait for another vblank before continuing
; BIT PPUSTATUS
; BPL vblankwait
; Set scroll = 0,0
LDA PPUSTATUS
LDA #$00
STA PPUSCROLL ;$2005 in case it doesn't work
STA PPUSCROLL ;Helps to remove issue a random tile in the first position

; enable Rendering
LDA #%10000000  ;#%10010000 ; turn on NMIs, sprites use first pattern table
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
.byte $0f, $00, $10, $30
.byte $0f, $11, $21, $32
.byte $0f, $16, $26, $37
.byte $0f, $1A, $2A, $3B


.byte $0f, $20, $00, $00
.byte $0f, $00, $00, $00
.byte $0f, $00, $00, $00
.byte $0f, $00, $00, $00

; Import the Map data
.include "map.asm"

.segment "CHR"
.incbin "tiles.chr"
