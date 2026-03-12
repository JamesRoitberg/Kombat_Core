// animation.asm (Motor + ScrollTracks + ColorCycle) — sem lógica de TileSwap
// Integra com TileSwap apenas na inicialização (TileSwap_Init).
// -----------------------------------------------------------------------------
// StageAnim_*
// - ScrollTracks (HOFS por banda) com subpixel (SAFE, fora do VBlank ok)
// - ColorCycle (CGRAM) CC0/CC1/CC2/CC3 (SAFE, só no VBlank; protege gradiente)
//
// Regras do projeto:
// - Comentários com //
// - Sem labels locais (. / @)
// - Evitar branch out of bounds (usar JMP quando necessário)
// - 1 instrução por linha (sem ":")

// ============================================================================
// MOTOR WRAM layout (boilerplate) — STAGE_ANIM_WRAM_BASE=$0200 SIZE=$0100
// ----------------------------------------------------------------------------
// Header (8 bytes):
// +00..+01 reservado
// +02 MOTOR_RR_CC       (byte) 0..3
// +03 MOTOR_TMP         (byte) (usado pelo ColorCycle)
// +04..+07 reservado
//
// ScrollTracks (5 tracks, 4 bytes cada) @ +08:
// track i base = +08 + i*4
// +0 ACC_LO, +1 ACC_HI (word acc), +2 FRAC, +3 reserved
//
// ColorCycle (4 inst, 8 bytes cada):
// - CC0..CC2 em +38..+4F
// - CC3 em +A0..+A7 (fora da faixa usada pelo TileSwap)
// cc k base = +38 + k*8
// +0 TIMER, +1 COOLDOWN, +2..+3 SAVE(word), +4..+5 TMP(word), +6 STEPS_LEFT, +7 STATE
// ============================================================================

// Header (somente o que é usado aqui)
constant MOTOR_RR_CC     = (STAGE_ANIM_WRAM_BASE + $02)
constant MOTOR_TMP       = (STAGE_ANIM_WRAM_BASE + $03)

// Header reserved bytes (usado pelo ScrollTracks helper)
constant MOTOR_SCROLL_ACC_TMP = (STAGE_ANIM_WRAM_BASE + $00) // word
// Tracks
constant MOTOR_TRACK0_ACC  = (STAGE_ANIM_WRAM_BASE + $08) // word
constant MOTOR_TRACK0_FRAC = (STAGE_ANIM_WRAM_BASE + $0A) // byte

constant MOTOR_TRACK1_ACC  = (STAGE_ANIM_WRAM_BASE + $0C) // word
constant MOTOR_TRACK1_FRAC = (STAGE_ANIM_WRAM_BASE + $0E) // byte

constant MOTOR_TRACK2_ACC  = (STAGE_ANIM_WRAM_BASE + $10) // word
constant MOTOR_TRACK2_FRAC = (STAGE_ANIM_WRAM_BASE + $12) // byte

constant MOTOR_TRACK3_ACC  = (STAGE_ANIM_WRAM_BASE + $14) // word
constant MOTOR_TRACK3_FRAC = (STAGE_ANIM_WRAM_BASE + $16) // byte

constant MOTOR_TRACK4_ACC  = (STAGE_ANIM_WRAM_BASE + $18) // word
constant MOTOR_TRACK4_FRAC = (STAGE_ANIM_WRAM_BASE + $1A) // byte

// CC0 base
constant MOTOR_CC0_TIMER  = (STAGE_ANIM_WRAM_BASE + $38) // byte
constant MOTOR_CC0_COOLDOWN = (STAGE_ANIM_WRAM_BASE + $39) // byte
constant MOTOR_CC0_SAVELO = (STAGE_ANIM_WRAM_BASE + $3A) // byte
constant MOTOR_CC0_SAVEHI = (STAGE_ANIM_WRAM_BASE + $3B) // byte
constant MOTOR_CC0_TMPLO  = (STAGE_ANIM_WRAM_BASE + $3C) // byte
constant MOTOR_CC0_TMPHI  = (STAGE_ANIM_WRAM_BASE + $3D) // byte
constant MOTOR_CC0_STEPS  = (STAGE_ANIM_WRAM_BASE + $3E) // byte
constant MOTOR_CC0_STATE  = (STAGE_ANIM_WRAM_BASE + $3F) // byte

// CC1 base
constant MOTOR_CC1_TIMER  = (STAGE_ANIM_WRAM_BASE + $40) // byte
constant MOTOR_CC1_COOLDOWN = (STAGE_ANIM_WRAM_BASE + $41) // byte
constant MOTOR_CC1_SAVELO = (STAGE_ANIM_WRAM_BASE + $42) // byte
constant MOTOR_CC1_SAVEHI = (STAGE_ANIM_WRAM_BASE + $43) // byte
constant MOTOR_CC1_TMPLO  = (STAGE_ANIM_WRAM_BASE + $44) // byte
constant MOTOR_CC1_TMPHI  = (STAGE_ANIM_WRAM_BASE + $45) // byte
constant MOTOR_CC1_STEPS  = (STAGE_ANIM_WRAM_BASE + $46) // byte
constant MOTOR_CC1_STATE  = (STAGE_ANIM_WRAM_BASE + $47) // byte

// CC2 base
constant MOTOR_CC2_TIMER  = (STAGE_ANIM_WRAM_BASE + $48) // byte
constant MOTOR_CC2_COOLDOWN = (STAGE_ANIM_WRAM_BASE + $49) // byte
constant MOTOR_CC2_SAVELO = (STAGE_ANIM_WRAM_BASE + $4A) // byte
constant MOTOR_CC2_SAVEHI = (STAGE_ANIM_WRAM_BASE + $4B) // byte
constant MOTOR_CC2_TMPLO  = (STAGE_ANIM_WRAM_BASE + $4C) // byte
constant MOTOR_CC2_TMPHI  = (STAGE_ANIM_WRAM_BASE + $4D) // byte
constant MOTOR_CC2_STEPS  = (STAGE_ANIM_WRAM_BASE + $4E) // byte
constant MOTOR_CC2_STATE  = (STAGE_ANIM_WRAM_BASE + $4F) // byte

// CC3 base (fora da faixa do TileSwap, que usa +50..+9F)
constant MOTOR_CC3_TIMER  = (STAGE_ANIM_WRAM_BASE + $A0) // byte
constant MOTOR_CC3_COOLDOWN = (STAGE_ANIM_WRAM_BASE + $A1) // byte
constant MOTOR_CC3_SAVELO = (STAGE_ANIM_WRAM_BASE + $A2) // byte
constant MOTOR_CC3_SAVEHI = (STAGE_ANIM_WRAM_BASE + $A3) // byte
constant MOTOR_CC3_TMPLO  = (STAGE_ANIM_WRAM_BASE + $A4) // byte
constant MOTOR_CC3_TMPHI  = (STAGE_ANIM_WRAM_BASE + $A5) // byte
constant MOTOR_CC3_STEPS  = (STAGE_ANIM_WRAM_BASE + $A6) // byte
constant MOTOR_CC3_STATE  = (STAGE_ANIM_WRAM_BASE + $A7) // byte

// CC aliases
constant CC0_TIMER  = MOTOR_CC0_TIMER
constant CC0_COOLDOWN = MOTOR_CC0_COOLDOWN
constant CC0_SAVELO = MOTOR_CC0_SAVELO
constant CC0_SAVEHI = MOTOR_CC0_SAVEHI
constant CC0_TMPLO  = MOTOR_CC0_TMPLO
constant CC0_TMPHI  = MOTOR_CC0_TMPHI
constant CC0_STEPS  = MOTOR_CC0_STEPS
constant CC0_STATE  = MOTOR_CC0_STATE

constant CC1_TIMER  = MOTOR_CC1_TIMER
constant CC1_COOLDOWN = MOTOR_CC1_COOLDOWN
constant CC1_SAVELO = MOTOR_CC1_SAVELO
constant CC1_SAVEHI = MOTOR_CC1_SAVEHI
constant CC1_TMPLO  = MOTOR_CC1_TMPLO
constant CC1_TMPHI  = MOTOR_CC1_TMPHI
constant CC1_STEPS  = MOTOR_CC1_STEPS
constant CC1_STATE  = MOTOR_CC1_STATE

constant CC2_TIMER  = MOTOR_CC2_TIMER
constant CC2_COOLDOWN = MOTOR_CC2_COOLDOWN
constant CC2_SAVELO = MOTOR_CC2_SAVELO
constant CC2_SAVEHI = MOTOR_CC2_SAVEHI
constant CC2_TMPLO  = MOTOR_CC2_TMPLO
constant CC2_TMPHI  = MOTOR_CC2_TMPHI
constant CC2_STEPS  = MOTOR_CC2_STEPS
constant CC2_STATE  = MOTOR_CC2_STATE

constant CC3_TIMER  = MOTOR_CC3_TIMER
constant CC3_COOLDOWN = MOTOR_CC3_COOLDOWN
constant CC3_SAVELO = MOTOR_CC3_SAVELO
constant CC3_SAVEHI = MOTOR_CC3_SAVEHI
constant CC3_TMPLO  = MOTOR_CC3_TMPLO
constant CC3_TMPHI  = MOTOR_CC3_TMPHI
constant CC3_STEPS  = MOTOR_CC3_STEPS
constant CC3_STATE  = MOTOR_CC3_STATE

// ============================================================================
// Tables: CC0/CC1/CC2/CC3 index lists (até 6 cores)
// ============================================================================
CC0_IdxTable:
  db STAGE_CC0_IDX0
  db STAGE_CC0_IDX1
  db STAGE_CC0_IDX2
  db STAGE_CC0_IDX3
  db STAGE_CC0_IDX4
  db STAGE_CC0_IDX5

CC1_IdxTable:
  db STAGE_CC1_IDX0
  db STAGE_CC1_IDX1
  db STAGE_CC1_IDX2
  db STAGE_CC1_IDX3
  db STAGE_CC1_IDX4
  db STAGE_CC1_IDX5

CC2_IdxTable:
  db STAGE_CC2_IDX0
  db STAGE_CC2_IDX1
  db STAGE_CC2_IDX2
  db STAGE_CC2_IDX3
  db STAGE_CC2_IDX4
  db STAGE_CC2_IDX5

CC3_IdxTable:
  db STAGE_CC3_IDX0
  db STAGE_CC3_IDX1
  db STAGE_CC3_IDX2
  db STAGE_CC3_IDX3
  db STAGE_CC3_IDX4
  db STAGE_CC3_IDX5

// ============================================================================
// Stage API
// ============================================================================
StageAnim_Init:
  php
  sep #$20
  lda.b #STAGE_ENABLE_ANIM
  bne AnimInit_Do
  plp
  rts

AnimInit_Do:
  rep #$30
  ldx.w #$0000

AnimInit_ClearLoop:
  stz.w STAGE_ANIM_WRAM_BASE,x
  inx
  inx
  cpx.w #STAGE_ANIM_WRAM_SIZE
  bcc AnimInit_ClearLoop

  // init cursor do ColorCycle
  stz.w MOTOR_RR_CC
  // Jump para o tileswap
  jsr TileSwap_Init

  plp
  rts

StageAnim_NmiTick:
  php

  // Só mexe em CGRAM em VBlank
  sep #$20
  lda HVBJOY
  bmi Anim_InVBlank
  jmp Anim_DoScrollTracks

Anim_InVBlank:
  jsr Motor_ColorCycle_Tick

Anim_DoScrollTracks:
  jsr Motor_ScrollTracks_Tick

  plp
  rts

// ScrollTracks (módulo separado)
include "anim_scrolltrack.asm"

// Gradient + ColorCycle (módulos separados)
include "anim_gradient.asm"
include "anim_colorcycle.asm"
