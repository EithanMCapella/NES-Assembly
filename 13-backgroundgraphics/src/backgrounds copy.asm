.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
SPRITE_TILE:  .res 1
SPRITE_X:  .res 1
SPRITE_Y:  .res 1
SPRITE_ATTR: .res 1
OAM_INDEX:  .res 1
frame_ready: .res 1


.segment "CODE"
.proc irq_handler
  RTI
.endproc


.proc DrawSprite
    LDX OAM_INDEX

    ; --- Top-left ---
    LDA SPRITE_Y
    STA $0200,X
    INX
    LDA SPRITE_ATTR         ; check if flipping
    CMP #$40
    BEQ :+
    LDA SPRITE_TILE         ; normal: TL = tile+0
    JMP :++
:   LDA SPRITE_TILE         ; flipped: TL = tile+1
    CLC
    ADC #$01
:   STA $0200,X
    INX
    LDA SPRITE_ATTR
    STA $0200,X
    INX
    LDA SPRITE_X
    STA $0200,X
    INX

    ; --- Top-right ---
    LDA SPRITE_Y
    STA $0200,X
    INX
    LDA SPRITE_ATTR
    CMP #$40
    BEQ :+
    LDA SPRITE_TILE         ; normal: TR = tile+1
    CLC
    ADC #$01
    JMP :++
:   LDA SPRITE_TILE         ; flipped: TR = tile+0
:   STA $0200,X
    INX
    LDA SPRITE_ATTR
    STA $0200,X
    INX
    LDA SPRITE_X
    CLC
    ADC #$08
    STA $0200,X
    INX

    ; --- Bottom-left ---
    LDA SPRITE_Y
    CLC
    ADC #$08
    STA $0200,X
    INX
    LDA SPRITE_ATTR
    CMP #$40
    BEQ :+
    LDA SPRITE_TILE         ; normal: BL = tile+2
    CLC
    ADC #$02
    JMP :++
:   LDA SPRITE_TILE         ; flipped: BL = tile+3
    CLC
    ADC #$03
:   STA $0200,X
    INX
    LDA SPRITE_ATTR
    STA $0200,X
    INX
    LDA SPRITE_X
    STA $0200,X
    INX

    ; --- Bottom-right ---
    LDA SPRITE_Y
    CLC
    ADC #$08
    STA $0200,X
    INX
    LDA SPRITE_ATTR
    CMP #$40
    BEQ :+
    LDA SPRITE_TILE         ; normal: BR = tile+3
    CLC
    ADC #$03
    JMP :++
:   LDA SPRITE_TILE         ; flipped: BR = tile+2
    CLC
    ADC #$02
:   STA $0200,X
    INX
    LDA SPRITE_ATTR
    STA $0200,X
    INX
    LDA SPRITE_X
    CLC
    ADC #$08
    STA $0200,X
    INX

    STX OAM_INDEX
    RTS
.endproc

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
	LDA #$00
	STA $2005
	STA $2005
  RTI
.endproc

.import reset_handler

.export main
.proc main
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

  ; write sprite data
;   LDX #$00
; load_sprites:
;   LDA sprites,X
;   STA $0200,X
;   INX
;   CPX #$70
;   BNE load_sprites

; Reset OAM index at start of your draw phase
LDA #$00
STA OAM_INDEX

; Draw a sprite at tile 4, X=$80, Y=$54
; Center
LDA #$04
STA SPRITE_TILE
LDA #$80
STA SPRITE_X
LDA #$70
STA SPRITE_Y
LDA #$00          ; no flip
STA SPRITE_ATTR
JSR DrawSprite

; Upper
LDA #$08
STA SPRITE_TILE
LDA #$80
STA SPRITE_X
LDA #$60
STA SPRITE_Y
LDA #$00          ; no flip
STA SPRITE_ATTR
JSR DrawSprite

LDA #$0C
STA SPRITE_TILE
LDA #$80
STA SPRITE_X
LDA #$50
STA SPRITE_Y
LDA #$00          ; no flip
STA SPRITE_ATTR
JSR DrawSprite

; Lower
LDA #$10
STA SPRITE_TILE
LDA #$80
STA SPRITE_X
LDA #$80
STA SPRITE_Y
LDA #$00          ; no flip
STA SPRITE_ATTR
JSR DrawSprite

LDA #$14
STA SPRITE_TILE
LDA #$80
STA SPRITE_X
LDA #$90
STA SPRITE_Y
LDA #$00          ; no flip
STA SPRITE_ATTR
JSR DrawSprite

; Right
LDA #$18
STA SPRITE_TILE
LDA #$90
STA SPRITE_X
LDA #$70
STA SPRITE_Y
LDA #$00          ; no flip
STA SPRITE_ATTR
JSR DrawSprite

LDA #$1C
STA SPRITE_TILE
LDA #$A0
STA SPRITE_X
LDA #$70
STA SPRITE_Y
LDA #$00          ; no flip
STA SPRITE_ATTR
JSR DrawSprite

; Left 
LDA #$18
STA SPRITE_TILE
LDA #$70
STA SPRITE_X
LDA #$80		;Stagger them because we have almost 8 sprite tiles beign drawn in succesion
STA SPRITE_Y
LDA #$40          ; flip horizontal
STA SPRITE_ATTR
JSR DrawSprite

LDA #$1C
STA SPRITE_TILE
LDA #$60
STA SPRITE_X
LDA #$80
STA SPRITE_Y
LDA #$40          ; flip horizontal
STA SPRITE_ATTR
JSR DrawSprite


; Trigger OAM DMA to push $0200-$02FF to PPU
LDA #$02
STA OAMDMA

	; write nametables
	; big stars first
	LDA PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$6b
	STA PPUADDR
	LDX #$2f
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$57
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$23
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$52
	STA PPUADDR
	STX PPUDATA

	; next, small star 1
	LDA PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$74
	STA PPUADDR
	LDX #$2d
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$43
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$5d
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$73
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$2f
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$f7
	STA PPUADDR
	STX PPUDATA

	; finally, small star 2
	LDA PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$f1
	STA PPUADDR
	LDX #$2e
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$a8
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$7a
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$44
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$7c
	STA PPUADDR
	STX PPUDATA

	; finally, attribute table
	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$c2
	STA PPUADDR
	LDA #%01000000
	STA PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$e0
	STA PPUADDR
	LDA #%00001100
	STA PPUDATA

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

; If a vblank is done then we turn frame_ready to 1
; ------Main Loop------
forever:
  ; update tiles *after* DMA transfer

  
  wait_frame:
    LDA frame_ready
    BEQ wait_frame ; loop until its 1
    ; clear flag (consume the frame)
    LDA #$00
    STA frame_ready

    JSR update_player
    JSR draw_player

  ;Sync add a zero_page variable called frame_ready
  ; Conditional Loop

  JMP forever
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $0f, $12, $23, $27
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $3D, $3C, $23
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

.segment "CHR"
.incbin "starfield.chr"
