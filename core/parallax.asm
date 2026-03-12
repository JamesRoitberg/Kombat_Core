// parallax.asm
// -----------------------------------------------------------------------------
// Engine de parallax/scroll (reutilizável por cenário):
// - BG1: 5 bandas com HOFS + VOFS (tilemap 512x512 “contínuo” via quadrante)
// - BG2: 5 bandas com HOFS (0..511) e VOFS via offset (BG2 64x32 = 512x256)
// - Scale16_Q0_8: out = (in16 * ratio8) >> 8  (ratio em Q0.8)
//
// Depende de:
//   - regs.asm   (WRAM: BG1_WORLDX, BG1_HOFS_B*, BG1_VOFS_B*, BG2_HOFS_B*,
//                BG2_VOFS_B*, BG2_HOFS, SCALE16_*; regs CPU: WRMPYA/WRMPYB/RDMPYH)
//   - config.asm (ratios + offsets)
//
// Regras do projeto:
//   - sem labels locais (. / @)
//   - comentários com //
// -----------------------------------------------------------------------------

// ============================================================================
// Offsets helpers
//   Entrada: A16 = Xband (0..511 típico)
//   Saída  : A16 = Xfinal = (Xband + OFFSET) & $01FF
// ============================================================================
macro PAR_APPLY_BG1_OFFSETS() {
  clc
  adc.w #STAGE_BG1_X_OFFSET
  and.w #$01FF
}

macro PAR_APPLY_BG2_OFFSETS() {
  clc
  adc.w #STAGE_BG2_X_OFFSET
  and.w #$01FF
}

// ============================================================================
// PAR_BG1_STORE
// - Usa SCALE16_OUT (Xband) e grava HOFS/VOFS da banda (quadrante MK):
//   HOFS = Xfinal low8 (word, high=0)
//   VOFS = (Xfinal bit8 ? 256 : 0) + STAGE_BG1_Y_OFFSET   (mask 9-bit)
// ============================================================================
macro PAR_BG1_STORE(variable dstHofs, variable dstVofs) {
  // Xfinal = (SCALE16_OUT + X_OFFSET) & $01FF
  rep #$20
  lda SCALE16_OUT
  PAR_APPLY_BG1_OFFSETS()

  // Guardar Xfinal (A16) para reaproveitar em HOFS e VOFS
  pha

  // HOFS = low8 (garante high=0)
  and.w #$00FF
  sta dstHofs

  // VOFS = (bit8 de Xfinal) + Y_OFFSET
  pla
  and.w #$0100
  clc
  adc.w #STAGE_BG1_Y_OFFSET
  and.w #$01FF
  sta dstVofs
}

// ============================================================================
// PAR_BG2_STORE
// - BG2 (512x256):
//   HOFS = (Xband + STAGE_BG2_X_OFFSET) & $01FF
//   VOFS = STAGE_BG2_Y_OFFSET (0..255 útil; gravado como word na WRAM)
// ============================================================================
macro PAR_BG2_STORE(variable dstHofs, variable dstVofs) {
  rep #$20
  lda SCALE16_OUT
  PAR_APPLY_BG2_OFFSETS()
  sta dstHofs

  lda.w #STAGE_BG2_Y_OFFSET
  and.w #$00FF
  sta dstVofs
}

// ============================================================================
// Helpers para reduzir duplicidade (mesma lógica, só muda ratio/dst)
// ============================================================================
macro PAR_SCALE_FROM_BG1_WORLDX(variable ratioConst) {
  rep #$20
  lda BG1_WORLDX
  sta SCALE16_IN
  sep #$20
  lda.b #(ratioConst)
  jsr Scale16_Q0_8
}

macro PAR_COMPUTE_BG1_BAND(variable ratioConst, variable dstHofs, variable dstVofs) {
  PAR_SCALE_FROM_BG1_WORLDX(ratioConst)
  PAR_BG1_STORE(dstHofs, dstVofs)
}

macro PAR_COMPUTE_BG2_BAND(variable ratioConst, variable dstHofs, variable dstVofs) {
  // Mantém o comportamento atual: BG2 usa BG1_WORLDX como input (mesma câmera/world)
  PAR_SCALE_FROM_BG1_WORLDX(ratioConst)
  PAR_BG2_STORE(dstHofs, dstVofs)
}

macro PAR_COMPUTE_BG1_5BANDS() {
  PAR_COMPUTE_BG1_BAND(BG1_RATIO_B0, BG1_HOFS_B0, BG1_VOFS_B0)
  PAR_COMPUTE_BG1_BAND(BG1_RATIO_B1, BG1_HOFS_B1, BG1_VOFS_B1)
  PAR_COMPUTE_BG1_BAND(BG1_RATIO_B2, BG1_HOFS_B2, BG1_VOFS_B2)
  PAR_COMPUTE_BG1_BAND(BG1_RATIO_B3, BG1_HOFS_B3, BG1_VOFS_B3)
  PAR_COMPUTE_BG1_BAND(BG1_RATIO_B4, BG1_HOFS_B4, BG1_VOFS_B4)
}

macro PAR_COMPUTE_BG2_5BANDS() {
  PAR_COMPUTE_BG2_BAND(BG2_RATIO_B0, BG2_HOFS_B0, BG2_VOFS_B0)
  PAR_COMPUTE_BG2_BAND(BG2_RATIO_B1, BG2_HOFS_B1, BG2_VOFS_B1)
  PAR_COMPUTE_BG2_BAND(BG2_RATIO_B2, BG2_HOFS_B2, BG2_VOFS_B2)
  PAR_COMPUTE_BG2_BAND(BG2_RATIO_B3, BG2_HOFS_B3, BG2_VOFS_B3)
  PAR_COMPUTE_BG2_BAND(BG2_RATIO_B4, BG2_HOFS_B4, BG2_VOFS_B4)
}

macro PAR_UPDATE_BASE_SCROLL_REG_SHADOWS() {
  rep #$20

  // BG1 base (NMI escreve BG1HOFS/BG1VOFS) usa banda mais próxima (B4)
  lda BG1_HOFS_B4
  sta BG1_HOFS
  lda BG1_VOFS_B4
  sta BG1_VOFS

  // BG2_HOFS legado (NMI escreve BG2HOFS) usa banda mais próxima (B4)
  lda BG2_HOFS_B4
  sta BG2_HOFS
}

// ============================================================================
// UpdateScrollParallax (BG1 + BG2)
// ============================================================================
UpdateScrollParallax:
  // BG1 (5 bandas)
  PAR_COMPUTE_BG1_5BANDS()

  // BG2 (5 bandas)
  PAR_COMPUTE_BG2_5BANDS()

  PAR_UPDATE_BASE_SCROLL_REG_SHADOWS()

  sep #$20
  rts

// ============================================================================
// Scale16_Q0_8
// out = (in16 * ratio8) >> 8
//
// Entrada:
//   - SCALE16_IN  (word)
//   - A8 = ratio (Q0.8)
//   - Limite atual: assume input efetivo em 0..511 ($0000..$01FF),
//     adequado ao uso atual com BG1_WORLDX.
//   - Se worldx crescer alem de 9 bits, esta rotina precisa ser revista.
//
// Saída:
//   - A16 = resultado (0..511 típico)
// ============================================================================
Scale16_Q0_8:
  sep #$20
  sta SCALE16_RATIO

  // (low * ratio) >> 8 -> RDMPYH
  lda SCALE16_IN
  sta WRMPYA
  lda SCALE16_RATIO
  sta WRMPYB

  // espera multiplicação (8 ciclos)
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop

  lda RDMPYH
  sta SCALE16_OUT
  stz SCALE16_OUT+1

  // se high == 0, acabou
  lda SCALE16_IN+1
  beq SCALE16Q_Return

  // soma ratio em 8-bit com carry no high
  lda SCALE16_OUT
  clc
  adc SCALE16_RATIO
  sta SCALE16_OUT

  lda SCALE16_OUT+1
  adc #$00
  sta SCALE16_OUT+1

SCALE16Q_Return:
  rep #$20
  lda SCALE16_OUT
  rts
