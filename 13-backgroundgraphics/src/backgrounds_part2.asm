.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
SPRITE_TILE:  .res 1
SPRITE_X:  .res 1
SPRITE_Y:  .res 1
SPRITE_ATTR: .res 1 ; $00 No flip, $40 Horizontal Flip
OAM_INDEX:  .res 1
frame_ready: .res 1
anim_state: .res 1 ; 0=idle, 1=up, 2=right, 3=down, 4=left
anim_frame: .res 1 ; 0 or 1 (two frames per direction)
anim_timer: .res 1 ; Countdown, switches frame when hits 0


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

  LDA #$01
  STA frame_ready

	STA $2005
	STA $2005
  RTI
.endproc

.import reset_handler
.import draw_starfield


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

LDA #$00
STA anim_state
STA anim_frame
LDA #$10
STA anim_timer

; Trigger OAM DMA to push $0200-$02FF to PPU
LDA #$02
STA OAMDMA

  ; write nametables
  LDX #$20
  JSR draw_starfield

  LDX #$28
  JSR draw_starfield

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
    ; wait for NMI to signal frame is ready
    LDA frame_ready
    BEQ wait_frame ; loop until its 1
    ; clear flag (consume the frame)
    LDA #$00
    STA frame_ready

  ; --- tick animation timer ---
  DEC anim_timer
  BNE :+              ; timer not done, skip frame/state update

 ; toggle anim_frame between 0 and 1
  LDA anim_frame
  EOR #$01
  STA anim_frame

  ; reset frame timer
  LDA #$10            ; how fast frames alternate (lower = faster)
  STA anim_timer

  ; check if we've shown both frames (frame just went back to 0)
  LDA anim_frame
  BNE :+              ; still on frame 1, don't advance state yet

  ; advance to next state
  INC anim_state
  LDA anim_state
  CMP #$0A            ; 5 states total (0-4)
  BNE :+
  LDA #$00            ; wrap back to idle
  STA anim_state

  : ; --- draw current sprite ---
  LDA #$00
  STA OAM_INDEX

  ; look up tile for current state + frame
; look up tile for current state + frame
LDA anim_state
ASL A               ; state * 2
CLC
ADC anim_frame      ; + frame (0 or 1)
TAX                 ; X = correct index into anim_table
LDA anim_table,X
STA SPRITE_TILE

  ; look up attr (flip or not)
  LDA anim_state
  TAX
  LDA anim_attrs,X
  STA SPRITE_ATTR

  LDA #$80
  STA SPRITE_X
  LDA #$70
  STA SPRITE_Y
  JSR DrawSprite

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

; Each entry is: tile_index, attr
anim_table:
;        frame1  frame2
.byte $04, $20   ; idle (both frames same)
.byte $04, $20   ; idle (both frames same)
.byte $08, $0C   ; up
.byte $08, $0C   ; up
.byte $18, $1C   ; right
.byte $18, $1C   ; right
.byte $10, $14   ; down
.byte $10, $14   ; down
.byte $18, $1C   ; left (same tiles as right, flip handled separately)
.byte $18, $1C   ; left (same tiles as right, flip handled separately)

anim_attrs:
.byte $00   ; idle
.byte $00   ; idle
.byte $00   ; up
.byte $00   ; up
.byte $00   ; right
.byte $00   ; right
.byte $00   ; down
.byte $00   ; down
.byte $40   ; left (flip)
.byte $40   ; left (flip)

; Duration of each direction
state_duration:
.byte $40   ; idle
.byte $20   ; up
.byte $20   ; right
.byte $20   ; down
.byte $20   ; left

.segment "CHR"
.incbin "starfield.chr"
