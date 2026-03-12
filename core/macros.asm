// macros.asm
// -----------------------------------------------------------------------------
// Objetivo:
//   Macros reutilizáveis para:
//   - Setup de HDMA (direct) com tabelas em WRAM.
//   - Inicialização/atualização de tabelas HDMA para 4 ou 5 bandas.
//   - DMA de ROM -> VRAM e ROM -> CGRAM.
//   - Escrita pontual de cor em CGRAM (sem DMA).
//
// Depende de:
//   - regs.asm (VMAIN, VMADDL, CGADD, CGDATA, MDMAEN, V_INC_1, etc)
//
// Notas do projeto:
//   - Sem labels locais (. / @), comentários com //.
//   - Macros HDMA_* / DMA_CGRAM / WRITE_CGRAM_COLOR forçam SEP/REP e NÃO restauram P.
//   - DmaToVram e CGRAM_GRAD_BUILD_TABLES preservam P (PHP/PLP).
//   - CGRAM_GRAD_BUILD_TABLES contém labels (macro com fluxo): chamar 1x no init.
// -----------------------------------------------------------------------------

// ============================================================================
// HDMA helpers
// ============================================================================

// ----------------------------------------------------------------------------
// HDMA_SETUP_MODE2_DIRECT
// Mode 2 (direct): escreve 2 bytes por scanline.
//
// Params:
//   channelBase : base do canal em $43x0 (ex.: $4350 para CH5, $4360 para CH6)
//   ppuRegLow   : low do registrador PPU destino (ex.: $0D=$210D, $0E=$210E)
//   tableAddr   : WRAM addr da tabela ([count][lo][hi] ... [00])
//
// Side effects:
//   - Força A8 e NÃO restaura P.
// ----------------------------------------------------------------------------
macro HDMA_SETUP_MODE2_DIRECT(variable channelBase, variable ppuRegLow, variable tableAddr) {
  sep #$20

  lda.b #$02
  sta channelBase+0         // DMAPx = mode 2, direct
  lda.b #ppuRegLow
  sta channelBase+1         // BBADx = $21xx low

  lda.b #((tableAddr) & $00FF)
  sta channelBase+2         // A1TxL
  lda.b #(((tableAddr >> 8) & $00FF))
  sta channelBase+3         // A1TxH

  lda.b #$7E
  sta channelBase+4         // A1Bx = WRAM bank
}

// ----------------------------------------------------------------------------
// HDMA_TABLE_INIT_4BANDS
// Mode 2 direct: [count][lo][hi] x4 + [00]
//
// Side effects:
//   - Força A8 e NÃO restaura P.
// ----------------------------------------------------------------------------
macro HDMA_TABLE_INIT_4BANDS(variable tableAddr, variable b0, variable b1, variable b2, variable b3) {
  sep #$20

  lda.b #b0
  sta tableAddr+0
  stz tableAddr+1
  stz tableAddr+2

  lda.b #b1
  sta tableAddr+3
  stz tableAddr+4
  stz tableAddr+5

  lda.b #b2
  sta tableAddr+6
  stz tableAddr+7
  stz tableAddr+8

  lda.b #b3
  sta tableAddr+9
  stz tableAddr+10
  stz tableAddr+11

  stz tableAddr+12          // terminator
}

// ----------------------------------------------------------------------------
// HDMA_TABLE_INIT_5BANDS
// Mode 2 direct: [count][lo][hi] x5 + [00]
//
// Side effects:
//   - Força A8 e NÃO restaura P.
// ----------------------------------------------------------------------------
macro HDMA_TABLE_INIT_5BANDS(variable tableAddr, variable b0, variable b1, variable b2, variable b3, variable b4) {
  sep #$20

  lda.b #b0
  sta tableAddr+0
  stz tableAddr+1
  stz tableAddr+2

  lda.b #b1
  sta tableAddr+3
  stz tableAddr+4
  stz tableAddr+5

  lda.b #b2
  sta tableAddr+6
  stz tableAddr+7
  stz tableAddr+8

  lda.b #b3
  sta tableAddr+9
  stz tableAddr+10
  stz tableAddr+11

  lda.b #b4
  sta tableAddr+12
  stz tableAddr+13
  stz tableAddr+14

  stz tableAddr+15          // terminator
}

// ----------------------------------------------------------------------------
// HDMA_TABLE_UPDATE_4BANDS_FROM_WORDS
// Copia 4 words (src0..src3) para payload [lo][hi] de cada banda.
//
// Side effects:
//   - Força A8 e NÃO restaura P.
// ----------------------------------------------------------------------------
macro HDMA_TABLE_UPDATE_4BANDS_FROM_WORDS(variable tableAddr, variable src0, variable src1, variable src2, variable src3) {
  sep #$20

  // Band 0
  lda src0
  sta tableAddr+1
  lda src0+1
  sta tableAddr+2

  // Band 1
  lda src1
  sta tableAddr+4
  lda src1+1
  sta tableAddr+5

  // Band 2
  lda src2
  sta tableAddr+7
  lda src2+1
  sta tableAddr+8

  // Band 3
  lda src3
  sta tableAddr+10
  lda src3+1
  sta tableAddr+11
}

// ----------------------------------------------------------------------------
// HDMA_TABLE_UPDATE_5BANDS_FROM_WORDS
// Copia 5 words (src0..src4) para payload [lo][hi] de cada banda.
//
// Side effects:
//   - Força A8 e NÃO restaura P.
// ----------------------------------------------------------------------------
macro HDMA_TABLE_UPDATE_5BANDS_FROM_WORDS(variable tableAddr, variable src0, variable src1, variable src2, variable src3, variable src4) {
  sep #$20

  // Band 0
  lda src0
  sta tableAddr+1
  lda src0+1
  sta tableAddr+2

  // Band 1
  lda src1
  sta tableAddr+4
  lda src1+1
  sta tableAddr+5

  // Band 2
  lda src2
  sta tableAddr+7
  lda src2+1
  sta tableAddr+8

  // Band 3
  lda src3
  sta tableAddr+10
  lda src3+1
  sta tableAddr+11

  // Band 4
  lda src4
  sta tableAddr+13
  lda src4+1
  sta tableAddr+14
}

// ----------------------------------------------------------------------------
// HDMA_SETUP_MODE0_DIRECT
// Mode 0 (direct): 1 byte por scanline (1 registrador PPU).
//
// Side effects:
//   - Força A8 e NÃO restaura P.
// ----------------------------------------------------------------------------
macro HDMA_SETUP_MODE0_DIRECT(variable channelBase, variable ppuRegLow, variable tableAddr) {
  sep #$20

  stz channelBase+0         // DMAPx = 0, direct
  lda.b #ppuRegLow
  sta channelBase+1         // BBADx = $21xx low

  lda.b #((tableAddr) & $00FF)
  sta channelBase+2         // A1TxL
  lda.b #(((tableAddr >> 8) & $00FF))
  sta channelBase+3         // A1TxH

  lda.b #$7E
  sta channelBase+4         // A1Bx = WRAM bank
}

// ----------------------------------------------------------------------------
// HDMA_TABLE_INIT_4BANDS_MODE0
// Mode 0 direct: [count][value] x4 + [00]
//
// Side effects:
//   - Força A8 e NÃO restaura P.
// ----------------------------------------------------------------------------
macro HDMA_TABLE_INIT_4BANDS_MODE0(variable tableAddr, variable b0, variable b1, variable b2, variable b3, variable value) {
  sep #$20

  lda.b #b0
  sta tableAddr+0
  lda.b #value
  sta tableAddr+1

  lda.b #b1
  sta tableAddr+2
  lda.b #value
  sta tableAddr+3

  lda.b #b2
  sta tableAddr+4
  lda.b #value
  sta tableAddr+5

  lda.b #b3
  sta tableAddr+6
  lda.b #value
  sta tableAddr+7

  stz tableAddr+8           // terminator
}

// ----------------------------------------------------------------------------
// HDMA_TABLE_FILL_4BANDS_FROM_IMM_WORDS
// Preenche payload [lo][hi] (Mode 2) com 4 words imediatos.
//
// Side effects:
//   - Força A8 e NÃO restaura P.
// ----------------------------------------------------------------------------
macro HDMA_TABLE_FILL_4BANDS_FROM_IMM_WORDS(variable tableAddr, variable w0, variable w1, variable w2, variable w3) {
  sep #$20

  // Band 0
  lda.b #(w0 & $00FF)
  sta tableAddr+1
  lda.b #((w0 >> 8) & $00FF)
  sta tableAddr+2

  // Band 1
  lda.b #(w1 & $00FF)
  sta tableAddr+4
  lda.b #((w1 >> 8) & $00FF)
  sta tableAddr+5

  // Band 2
  lda.b #(w2 & $00FF)
  sta tableAddr+7
  lda.b #((w2 >> 8) & $00FF)
  sta tableAddr+8

  // Band 3
  lda.b #(w3 & $00FF)
  sta tableAddr+10
  lda.b #((w3 >> 8) & $00FF)
  sta tableAddr+11
}


// ============================================================================
// DMA helpers
// ============================================================================

// ----------------------------------------------------------------------------
// DmaToVram
// DMA0: ROM -> VRAM via $2118/$2119.
//
// Preserva P (PHP/PLP).
// ----------------------------------------------------------------------------
macro DmaToVram(variable vramAddr, variable srcLabel, variable srcEnd) {
  php
  sep #$20
  rep #$10

  lda.b #V_INC_1
  sta VMAIN

  // VRAM dest (word address)
  ldx.w #((vramAddr >> 1) & $ffff)
  stx VMADDL

  // DMA0: CPU -> $2118/$2119
  lda.b #$01
  sta DMAPx               // $4300
  lda.b #$18
  sta BBADx               // $4301

  // Source addr (low 16)
  ldx.w #((srcLabel) & $ffff)
  stx A1TxL               // $4302/$4303

  // Source bank (força mirror $80-FF)
  lda.b #(((srcLabel >> 16) & $ff) | $80)
  sta A1Bx                // $4304

  // Size (16-bit)
  ldx.w #((srcEnd - srcLabel) & $ffff)
  stx DASxL               // $4305/$4306

  lda.b #$01
  sta MDMAEN              // start DMA ch0 (write-only)

  plp
}

// ----------------------------------------------------------------------------
// DMA_CGRAM
// DMA0: ROM -> CGRAM via $2122.
//
// Side effects:
//   - Força A8 e X/Y16 e NÃO restaura P.
// ----------------------------------------------------------------------------
macro DMA_CGRAM(variable cgadd, variable src, variable size) {
  sep #$20
  rep #$10

  lda.b #cgadd
  sta CGADD

  stz DMAPx              // DMAP0 = 0 (1 reg)
  lda.b #$22             // BBAD0 = $22 -> CGDATA ($2122)
  sta BBADx

  ldx.w #((src) & $ffff)
  stx A1TxL              // A1T0L/A1T0H
  lda.b #(((src >> 16) & $ff) | $80)
  sta A1Bx               // A1B0

  ldx.w #((size) & $ffff)
  stx DASxL              // DAS0L/DAS0H

  lda.b #$01
  sta MDMAEN             // start DMA ch0 (write-only)
}

// ----------------------------------------------------------------------------
// WRITE_CGRAM_COLOR
// Escreve 1 cor (word) direto em CGRAM.
//
// Side effects:
//   - Força A8 e NÃO restaura P.
// ----------------------------------------------------------------------------
macro WRITE_CGRAM_COLOR(variable colorIndex, variable colorValue) {
  sep #$20

  lda.b #colorIndex
  sta CGADD

  lda.b #(colorValue & $00FF)
  sta CGDATA
  lda.b #((colorValue >> 8) & $00FF)
  sta CGDATA
}

// ============================================================================
// CGRAM gradient builder (steps)
// ============================================================================
//
// Gera (no init) as tabelas HDMA em WRAM para um degradê vertical de 1 cor.
//
// Notas:
// - Só PREENCHE as tabelas (setup HDMA e HDMAEN ficam no game.asm).
// - Deve ser chamada ANTES de habilitar HDMAEN.
// - Preserva P e X/Y.
// - Contém labels: chamar 1x no init.
// ----------------------------------------------------------------------------
macro CGRAM_GRAD_BUILD_TABLES() {
  php
  rep #$10
  phx
  phy

CGRAMGradBuild_WaitVBlank_Read:
  sep #$20
  lda HVBJOY
  bpl CGRAMGradBuild_WaitVBlank_Read      // bit7=1 => VBlank

  // Lê a cor atual (start) do índice alvo na CGRAM -> SCALE16_IN (word)
  lda.b #STAGE_CGRAM_GRAD_CGADD
  sta CGADD
  lda CGDATAREAD
  sta.w GRAD_TMP0                         // tmp low
  lda CGDATAREAD
  and.b #$7F
  sta.w GRAD_TMP0+1                       // tmp high

  rep #$20
  lda.w GRAD_TMP0
  sta.w SCALE16_IN                        // startColor
  sep #$20

  // i = 0..(ENTRIES-1)
  stz.w SCALE16_RATIO

  rep #$10
  ldx.w #$0000                            // ofs CGADD (entry size 2)
  ldy.w #$0000                            // ofs CGDATA (entry size 3)

CGRAMGradBuild_FillLoop:
  sep #$20

  // CGADD entry: [count][cgadd]
  lda.b #STAGE_CGRAM_GRAD_LINES_PER_ENTRY
  sta.w HDMA_CGRAM_CGADD_TABLE,x
  lda.b #STAGE_CGRAM_GRAD_CGADD
  sta.w HDMA_CGRAM_CGADD_TABLE+1,x

  // CGDATA entry: [count][lo][hi]
  lda.b #STAGE_CGRAM_GRAD_LINES_PER_ENTRY
  sta.w HDMA_CGRAM_CGDATA_TABLE,y

  // ------------------------------------------------------------
  // Interpola do start (SCALE16_IN) até COLOR_B:
  // denom = STAGE_CGRAM_GRAD_DENOM_HIRES (ENTRIES-1)
  // i     = SCALE16_RATIO
  // comp  = ((start*(denom-i) + end*i) + round) / denom
  // round = STAGE_CGRAM_GRAD_ROUND_HIRES (denom/2)
  // ------------------------------------------------------------

  // ===== RED =====
  rep #$20
  lda.w SCALE16_IN
  and.w #$001F
  sep #$20
  sta WRMPYA                              // start_r
  lda.b #STAGE_CGRAM_GRAD_DENOM_HIRES
  sec
  sbc.w SCALE16_RATIO                     // (denom - i)
  sta WRMPYB
  nop
  nop
  rep #$20
  lda RDMPYL
  sta.w GRAD_TMP0                         // tmp = start_r*(denom-i)

  lda.w #STAGE_CGRAM_GRAD_COLOR_B
  and.w #$001F
  sep #$20
  sta WRMPYA                              // end_r
  lda.w SCALE16_RATIO                     // i
  sta WRMPYB
  nop
  nop
  rep #$20
  lda RDMPYL
  clc
  adc.w GRAD_TMP0
  adc.w #STAGE_CGRAM_GRAD_ROUND_HIRES
  sta WRDIVL                              // dividend

  sep #$20
  lda.b #STAGE_CGRAM_GRAD_DENOM_HIRES
  sta WRDIVB                              // start div

  // espera divisão (>=16 ciclos)
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop

  rep #$20
  lda RDDIVL
  and.w #$001F
  sta.w GRAD_TMP1                         // packed = red

  // ===== GREEN =====
  lda.w SCALE16_IN
  lsr
  lsr
  lsr
  lsr
  lsr
  and.w #$001F
  sep #$20
  sta WRMPYA                              // start_g
  lda.b #STAGE_CGRAM_GRAD_DENOM_HIRES
  sec
  sbc.w SCALE16_RATIO
  sta WRMPYB
  nop
  nop
  rep #$20
  lda RDMPYL
  sta.w GRAD_TMP0

  lda.w #STAGE_CGRAM_GRAD_COLOR_B
  lsr
  lsr
  lsr
  lsr
  lsr
  and.w #$001F
  sep #$20
  sta WRMPYA                              // end_g
  lda.w SCALE16_RATIO
  sta WRMPYB
  nop
  nop
  rep #$20
  lda RDMPYL
  clc
  adc.w GRAD_TMP0
  adc.w #STAGE_CGRAM_GRAD_ROUND_HIRES
  sta WRDIVL

  sep #$20
  lda.b #STAGE_CGRAM_GRAD_DENOM_HIRES
  sta WRDIVB

  // espera divisão
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop

  rep #$20
  lda RDDIVL
  and.w #$001F
  asl
  asl
  asl
  asl
  asl                                    // << 5
  ora.w GRAD_TMP1
  sta.w GRAD_TMP1

  // ===== BLUE =====
  lda.w SCALE16_IN
  lsr
  lsr
  lsr
  lsr
  lsr
  lsr
  lsr
  lsr
  lsr
  lsr                                    // >> 10
  and.w #$001F
  sep #$20
  sta WRMPYA                              // start_b
  lda.b #STAGE_CGRAM_GRAD_DENOM_HIRES
  sec
  sbc.w SCALE16_RATIO
  sta WRMPYB
  nop
  nop
  rep #$20
  lda RDMPYL
  sta.w GRAD_TMP0

  lda.w #STAGE_CGRAM_GRAD_COLOR_B
  lsr
  lsr
  lsr
  lsr
  lsr
  lsr
  lsr
  lsr
  lsr
  lsr
  and.w #$001F
  sep #$20
  sta WRMPYA                              // end_b
  lda.w SCALE16_RATIO
  sta WRMPYB
  nop
  nop
  rep #$20
  lda RDMPYL
  clc
  adc.w GRAD_TMP0
  adc.w #STAGE_CGRAM_GRAD_ROUND_HIRES
  sta WRDIVL

  sep #$20
  lda.b #STAGE_CGRAM_GRAD_DENOM_HIRES
  sta WRDIVB

  // espera divisão
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop

  rep #$20
  lda RDDIVL
  and.w #$001F
  asl
  asl
  asl
  asl
  asl
  asl
  asl
  asl
  asl
  asl                                    // << 10
  ora.w GRAD_TMP1
  sta.w GRAD_TMP1

  // Escreve [lo][hi] no payload da entry
  lda.w GRAD_TMP1
  sta.w HDMA_CGRAM_CGDATA_TABLE+1,y

  // i++
  sep #$20
  inc.w SCALE16_RATIO

  rep #$10
  inx
  inx                                    // CGADD entry size = 2
  iny
  iny
  iny                                    // CGDATA entry size = 3

  // Loop control
  sep #$20
  lda.w SCALE16_RATIO
  cmp.b #STAGE_CGRAM_GRAD_ENTRIES
  bcs CGRAMGradBuild_LoopEnd
  jmp CGRAMGradBuild_FillLoop

CGRAMGradBuild_LoopEnd:
  // Terminators
  lda.b #$00
  sta.w HDMA_CGRAM_CGADD_TABLE,x
  sta.w HDMA_CGRAM_CGDATA_TABLE,y

  rep #$10
  ply
  plx
  plp
}
