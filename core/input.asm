// input.asm
// -----------------------------------------------------------------------------
// Objetivo:
//   Leitura do controle (JOY1) via $4016 e, opcionalmente, dirigir BG1_WORLDX
//   para “mover a câmera” do stage.
//
// Controle por stage:
//   - STAGE_ENABLE_INPUT habilita/desabilita a leitura nesta rotina.
//   - STAGE_INPUT_DRIVE_WORLDX habilita/desabilita mover BG1_WORLDX por input.
//
// Depende de:
//   - regs.asm (JOYSER0=$4016, KEY_* masks, BG1_WORLDX)
//   - regs.asm (JOY1_CUR/JOY1_PREV/JOY1_TRIG/JOY1_REL)
// -----------------------------------------------------------------------------

constant INPUT_ENABLE        = STAGE_ENABLE_INPUT
constant INPUT_DRIVE_WORLDX  = STAGE_INPUT_DRIVE_WORLDX
constant INPUT_WORLDX_SPEED  = STAGE_INPUT_WORLDX_SPEED

// limite WORLDX 0..511
constant INPUT_WORLDX_MAX = $01FF

// ============================================================================
// Input_FrameTick
// ============================================================================
Input_FrameTick:
  php
  sep #$20
  rep #$10

  // Early return (evita branch longo/out-of-bounds)
  lda.b #INPUT_ENABLE
  bne INPUT_Enabled
  plp
  rts

INPUT_Enabled:
  // ----------------------------
  // Strobe joypad
  // ----------------------------
  lda.b #$01
  sta JOYSER0
  stz JOYSER0

  // JOY1_CUR = 0
  rep #$20
  stz.w JOY1_CUR
  sep #$20

  // Lê 16 bits serial e monta no formato compatível com KEY_*:
  // a cada bit: LSR A -> carry, depois ROL JOY1_CUR (16-bit)
  ldx.w #$0010

INPUT_ReadLoop:
  lda JOYSER0
  lsr                      // bit0 -> carry

  rep #$20
  rol.w JOY1_CUR           // 16-bit shift-in
  sep #$20

  dex
  bne INPUT_ReadLoop

  // ----------------------------
  // TRIG = (CUR xor PREV) & CUR
  // ----------------------------
  rep #$20
  lda.w JOY1_CUR
  eor.w JOY1_PREV
  and.w JOY1_CUR
  sta.w JOY1_TRIG

  // REL = (CUR xor PREV) & PREV
  lda.w JOY1_CUR
  eor.w JOY1_PREV
  and.w JOY1_PREV
  sta.w JOY1_REL

  lda.w JOY1_CUR
  sta.w JOY1_PREV
  sep #$20

  // ----------------------------
  // Dirigir BG1_WORLDX (opcional)
  // ----------------------------
  lda.b #INPUT_DRIVE_WORLDX
  bne INPUT_DoMove
  jmp INPUT_End

INPUT_DoMove:
  // Se LEFT e RIGHT juntos, não move
  rep #$20
  lda.w JOY1_CUR
  and.w #KEY_LEFT
  beq INPUT_CheckRight

  lda.w JOY1_CUR
  and.w #KEY_RIGHT
  bne INPUT_EndMove

  // LEFT
  lda.w BG1_WORLDX
  sec
  sbc.w #INPUT_WORLDX_SPEED
  bcs INPUT_StoreLeft
  lda.w #$0000

INPUT_StoreLeft:
  and.w #INPUT_WORLDX_MAX
  sta.w BG1_WORLDX
  bra INPUT_EndMove

INPUT_CheckRight:
  lda.w JOY1_CUR
  and.w #KEY_RIGHT
  beq INPUT_EndMove

  // RIGHT
  lda.w BG1_WORLDX
  clc
  adc.w #INPUT_WORLDX_SPEED
  cmp.w #$0200
  bcc INPUT_StoreRight
  lda.w #INPUT_WORLDX_MAX

INPUT_StoreRight:
  and.w #INPUT_WORLDX_MAX
  sta.w BG1_WORLDX

INPUT_EndMove:
  sep #$20

INPUT_End:
  plp
  rts
