// reset.asm (bass / wdc65816)
// -----------------------------------------------------------------------------
// Objetivo:
//   ResetHandler + NMI (VBlank) estáveis para a engine.
//
// ResetHandler:
//   - Entra em modo nativo, stack/DBR, FORCE_BLANK, desliga NMI/IRQ/DMA/HDMA.
//   - Zera contador de debug (in_nmi).
//   - Chama StageAnim_Init (estado/efeitos por cenário, se usado).
//
// NMI:
//   - ACK do NMI (RDNMI em A8).
//   - Tick de TileSwap por frame (TileSwap_NmiTick).
//   - Escreve scroll base (BG1 HOFS/VOFS, BG2 HOFS).
//   - Debug: incrementa in_nmi (word).
//
// Notas:
//   - Acesso a $21xx/$42xx deve ser em A8.
//   - Leituras/escritas de WRAM aqui usam o mirror $0000-$1FFF (independente do DBR
//     estar em $00 ou $80, etc.)
// -----------------------------------------------------------------------------

// ============================================================================
// ResetHandler
// ============================================================================
ResetHandler:
  sei
  clc
  xce
  rep #$38              // AXY16 + decimal off (D=0)

  ldx.w #$1FFF          // stack
  txs

  sep #$20              // A8 (safe para registradores PPU/WRAM byte)
  lda.b #$00            // DBR = 00 (LoROM padrão)
  pha
  plb

  lda.b #FORCE_BLANK
  sta INIDISP           // $2100 forced blank

  stz NMITIMEN          // $4200 desliga NMI/IRQ/autojoy
  stz HDMAEN            // $420C desliga HDMA
  stz MDMAEN            // $420B safety: para DMA

  // Debug NMI counter (word em $0100)
  // STZ escreve byte; zeramos os 2 bytes explicitamente (em A8).
  stz.w in_nmi
  stz.w in_nmi+1
  // Zera estado do Joypad 1 (CUR/PREV/TRIG/REL, word)
  stz.w JOY1_CUR
  stz.w JOY1_CUR+1
  stz.w JOY1_PREV
  stz.w JOY1_PREV+1
  stz.w JOY1_TRIG
  stz.w JOY1_TRIG+1
  stz.w JOY1_REL
  stz.w JOY1_REL+1

  // Stage animation (por cenário, se usado)
  jsr StageAnim_Init

  // FastROM ja faz parte do core/header; reforca MEMSEL=$01 no reset
  lda.b #$01
  sta MEMSEL            // $420D

  jmp Main

// ============================================================================
// NMI (VBlank) - manutencao de frame estavel
// ============================================================================
NMI:
  // Prologue (pushes em 16-bit)
  php
  rep #$30                // A16 + X/Y16
  pha
  phx
  phy

  // A8 para $21xx/$42xx (PPU/IO)
  sep #$20

  // ACK do NMI (leitura de $4210 deve ser 8-bit)
  lda RDNMI
  jsr TileSwap_NmiTick

  // BG1 HOFS ($210D) - 2 writes (low, high)
  lda.w BG1_HOFS
  sta BG1HOFS
  lda.w BG1_HOFS+1
  sta BG1HOFS

  // BG1 VOFS ($210E) - 2 writes (low, high)
  lda.w BG1_VOFS
  sta BG1VOFS
  lda.w BG1_VOFS+1
  sta BG1VOFS

  // BG2 HOFS ($210F) - 2 writes (low, high)
  lda.w BG2_HOFS
  sta BG2HOFS
  lda.w BG2_HOFS+1
  sta BG2HOFS

  // Debug: in_nmi é word -> garantir RMW em 16-bit
  rep #$20
  inc.w in_nmi

  // Restaura regs/flags (pops em 16-bit para bater com os pushes)
  rep #$30
  ply
  plx
  pla
  plp
  rti
