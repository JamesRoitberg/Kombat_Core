// tileswap.asm
// -----------------------------------------------------------------------------
// TileSwap v2/v3 (módulo separado)
// - Scheduler round-robin de 4 slots (JOB0..JOB3)
// - VBlank only: chamado no NMI (reset.asm)
// - 1 job por VBlank (RR 0/1/2/3) entre jobs habilitados
// - Estado atual: JOB0 obrigatório; JOB1/JOB2/JOB3 opcionais via STAGE_TSWAP_JOBn_ENABLE
//
// Slots (automático):
// - SLOT0 = após Tiles_End alinhado
// - SLOT1 = SLOT0 + align32(size_job0)
//
// JOB0: sempre SLOT0 (base tile constante)
// JOB1: SLOT0 se sozinho; SLOT1 se conflita com JOB0 no mesmo BG (base tile em WRAM)
// JOB2/JOB3: regra prática atual MAX2 (até 2 jobs por BG); em conflito excedente entra em fail seguro
// JOB0: caminho de load direto/chunked/double-buffer conforme frame size
// JOB0 multi-target:
// - Se STAGE_TSWAP_JOB0_TARGET_COUNT > 1, o patch do tilemap é incremental (1 target por NMI).
// - Nesse caso, JOB0 mantém slot fixo (sem double-buffer) para evitar frame parcial/flicker.
// JOB2/JOB3 first-time patch:
// - O patch inicial de targets e distribuido em varias chamadas do job (1 target por tick),
//   para reduzir pico de custo no VBlank em cenarios com muitos targets.
//
// Regra atual de projeto:
// - Máximo de 2 jobs por BG (config/layout padrão de cenários).
// - Se houver 3 jobs no mesmo BG, JOB2/JOB3 falham de forma segura.
//
// Regras:
// - Comentários //
// - Sem labels locais (. / @)
// - 1 instrução por linha
// - Evitar branch out of bounds (usar JMP quando necessário)
// -----------------------------------------------------------------------------

constant TSWAP_ALIGN32_MASK = $FFE0

// Contrato arquitetural atual:
// - Nesta rodada, TileSwap assume JOB0 habilitado quando STAGE_TSWAP_ENABLE=1.
if STAGE_TSWAP_ENABLE == 1 {
  if STAGE_TSWAP_JOB0_ENABLE == 0 {
    error "TileSwap atual requer STAGE_TSWAP_JOB0_ENABLE = 1"
  }
}

// -----------------------------------------------------------------------------
// Frame sizes (bytes) + pads
// -----------------------------------------------------------------------------
constant TSWAP_J0_FRAME_SIZE = (TSWAP_JOB0_FR0_End - TSWAP_JOB0_FR0)
if STAGE_TSWAP_JOB1_ENABLE == 1 {
  constant TSWAP_J1_FRAME_SIZE = (TSWAP_JOB1_FR0_End - TSWAP_JOB1_FR0)
} else {
  constant TSWAP_J1_FRAME_SIZE = $0000
}
if STAGE_TSWAP_JOB2_ENABLE == 1 {
  constant TSWAP_J2_FRAME_SIZE = (TSWAP_JOB2_FR0_End - TSWAP_JOB2_FR0)
} else {
  constant TSWAP_J2_FRAME_SIZE = $0000
}
if STAGE_TSWAP_JOB3_ENABLE == 1 {
  constant TSWAP_J3_FRAME_SIZE = (TSWAP_JOB3_FR0_End - TSWAP_JOB3_FR0)
} else {
  constant TSWAP_J3_FRAME_SIZE = $0000
}

constant TSWAP_J0_FRAME_PAD  = ((TSWAP_J0_FRAME_SIZE + $001F) & TSWAP_ALIGN32_MASK)

// -----------------------------------------------------------------------------
// SLOT0 por BG (bytes)
// -----------------------------------------------------------------------------
constant TSWAP_SLOT0_BG1_VRAM = (VRAM_BG1_TILES + ((BG1_Tiles_End - BG1_Tiles + $001F) & TSWAP_ALIGN32_MASK))
constant TSWAP_SLOT0_BG2_VRAM = (VRAM_BG2_TILES + ((BG2_Tiles_End - BG2_Tiles + $001F) & TSWAP_ALIGN32_MASK))

// SLOT1 por BG (bytes) = SLOT0 + pad(job0)
constant TSWAP_SLOT1_BG1_VRAM = (TSWAP_SLOT0_BG1_VRAM + TSWAP_J0_FRAME_PAD)
constant TSWAP_SLOT1_BG2_VRAM = (TSWAP_SLOT0_BG2_VRAM + TSWAP_J0_FRAME_PAD)

// -----------------------------------------------------------------------------
// JOB0 slot/base (fixo = SLOT0)
// -----------------------------------------------------------------------------
constant TSWAP_J0_SLOT_BG1_VRAM = TSWAP_SLOT0_BG1_VRAM
constant TSWAP_J0_SLOT_BG2_VRAM = TSWAP_SLOT0_BG2_VRAM

constant TSWAP_J0_SLOT_BG1_END  = (TSWAP_J0_SLOT_BG1_VRAM + TSWAP_J0_FRAME_SIZE)
constant TSWAP_J0_SLOT_BG2_END  = (TSWAP_J0_SLOT_BG2_VRAM + TSWAP_J0_FRAME_SIZE)

constant TSWAP_J0_BASE_TILE_BG1 = ((TSWAP_J0_SLOT_BG1_VRAM - VRAM_BG1_TILES) >> 5)
constant TSWAP_J0_BASE_TILE_BG2 = ((TSWAP_J0_SLOT_BG2_VRAM - VRAM_BG2_TILES) >> 5)

constant TSWAP_J0_GAP_CNT    = (STAGE_ANIM_WRAM_BASE + $64)

// Índice do target atual no patch incremental do JOB0 (modo multi-target).
constant TSWAP_J0_PATCH_POS  = (STAGE_ANIM_WRAM_BASE + $A8)
constant TSWAP_J2_PATCH_POS  = (STAGE_ANIM_WRAM_BASE + $A9)
constant TSWAP_J3_PATCH_POS  = (STAGE_ANIM_WRAM_BASE + $AA)
constant TSWAP_J2_FIRST_LOADED = (STAGE_ANIM_WRAM_BASE + $AB)
constant TSWAP_J3_FIRST_LOADED = (STAGE_ANIM_WRAM_BASE + $AC)

constant TSWAP_J0_LOAD_FRAME      = (STAGE_ANIM_WRAM_BASE + $87)

// -----------------------------------------------------------------------------
// JOB1 slot0/slot1/base
// -----------------------------------------------------------------------------
constant TSWAP_J1_SLOT0_BG1_VRAM = TSWAP_SLOT0_BG1_VRAM
constant TSWAP_J1_SLOT1_BG1_VRAM = TSWAP_SLOT1_BG1_VRAM

constant TSWAP_J1_SLOT0_BG2_VRAM = TSWAP_SLOT0_BG2_VRAM
constant TSWAP_J1_SLOT1_BG2_VRAM = TSWAP_SLOT1_BG2_VRAM

constant TSWAP_J1_SLOT0_BG1_END  = (TSWAP_J1_SLOT0_BG1_VRAM + TSWAP_J1_FRAME_SIZE)
constant TSWAP_J1_SLOT1_BG1_END  = (TSWAP_J1_SLOT1_BG1_VRAM + TSWAP_J1_FRAME_SIZE)

constant TSWAP_J1_SLOT0_BG2_END  = (TSWAP_J1_SLOT0_BG2_VRAM + TSWAP_J1_FRAME_SIZE)
constant TSWAP_J1_SLOT1_BG2_END  = (TSWAP_J1_SLOT1_BG2_VRAM + TSWAP_J1_FRAME_SIZE)

constant TSWAP_J1_BASE_TILE0_BG1 = ((TSWAP_J1_SLOT0_BG1_VRAM - VRAM_BG1_TILES) >> 5)
constant TSWAP_J1_BASE_TILE1_BG1 = ((TSWAP_J1_SLOT1_BG1_VRAM - VRAM_BG1_TILES) >> 5)

constant TSWAP_J1_BASE_TILE0_BG2 = ((TSWAP_J1_SLOT0_BG2_VRAM - VRAM_BG2_TILES) >> 5)
constant TSWAP_J1_BASE_TILE1_BG2 = ((TSWAP_J1_SLOT1_BG2_VRAM - VRAM_BG2_TILES) >> 5)

constant TSWAP_J1_GAP_CNT    = (STAGE_ANIM_WRAM_BASE + $67)

// -----------------------------------------------------------------------------
// JOB2 slot0/slot1/base (regra atual MAX2 por BG)
// -----------------------------------------------------------------------------
constant TSWAP_J2_SLOT0_BG1_VRAM = TSWAP_SLOT0_BG1_VRAM
constant TSWAP_J2_SLOT1_BG1_VRAM = TSWAP_SLOT1_BG1_VRAM

constant TSWAP_J2_SLOT0_BG2_VRAM = TSWAP_SLOT0_BG2_VRAM
constant TSWAP_J2_SLOT1_BG2_VRAM = TSWAP_SLOT1_BG2_VRAM

constant TSWAP_J2_SLOT0_BG1_END  = (TSWAP_J2_SLOT0_BG1_VRAM + TSWAP_J2_FRAME_SIZE)
constant TSWAP_J2_SLOT1_BG1_END  = (TSWAP_J2_SLOT1_BG1_VRAM + TSWAP_J2_FRAME_SIZE)

constant TSWAP_J2_SLOT0_BG2_END  = (TSWAP_J2_SLOT0_BG2_VRAM + TSWAP_J2_FRAME_SIZE)
constant TSWAP_J2_SLOT1_BG2_END  = (TSWAP_J2_SLOT1_BG2_VRAM + TSWAP_J2_FRAME_SIZE)

constant TSWAP_J2_BASE_TILE0_BG1 = ((TSWAP_J2_SLOT0_BG1_VRAM - VRAM_BG1_TILES) >> 5)
constant TSWAP_J2_BASE_TILE1_BG1 = ((TSWAP_J2_SLOT1_BG1_VRAM - VRAM_BG1_TILES) >> 5)

constant TSWAP_J2_BASE_TILE0_BG2 = ((TSWAP_J2_SLOT0_BG2_VRAM - VRAM_BG2_TILES) >> 5)
constant TSWAP_J2_BASE_TILE1_BG2 = ((TSWAP_J2_SLOT1_BG2_VRAM - VRAM_BG2_TILES) >> 5)

constant TSWAP_J2_GAP_CNT    = (STAGE_ANIM_WRAM_BASE + $65)

// -----------------------------------------------------------------------------
// JOB3 slot0/slot1/base
// -----------------------------------------------------------------------------
constant TSWAP_J3_SLOT0_BG1_VRAM = TSWAP_SLOT0_BG1_VRAM
constant TSWAP_J3_SLOT1_BG1_VRAM = TSWAP_SLOT1_BG1_VRAM

constant TSWAP_J3_SLOT0_BG2_VRAM = TSWAP_SLOT0_BG2_VRAM
constant TSWAP_J3_SLOT1_BG2_VRAM = TSWAP_SLOT1_BG2_VRAM

constant TSWAP_J3_SLOT0_BG1_END  = (TSWAP_J3_SLOT0_BG1_VRAM + TSWAP_J3_FRAME_SIZE)
constant TSWAP_J3_SLOT1_BG1_END  = (TSWAP_J3_SLOT1_BG1_VRAM + TSWAP_J3_FRAME_SIZE)

constant TSWAP_J3_SLOT0_BG2_END  = (TSWAP_J3_SLOT0_BG2_VRAM + TSWAP_J3_FRAME_SIZE)
constant TSWAP_J3_SLOT1_BG2_END  = (TSWAP_J3_SLOT1_BG2_VRAM + TSWAP_J3_FRAME_SIZE)

constant TSWAP_J3_BASE_TILE0_BG1 = ((TSWAP_J3_SLOT0_BG1_VRAM - VRAM_BG1_TILES) >> 5)
constant TSWAP_J3_BASE_TILE1_BG1 = ((TSWAP_J3_SLOT1_BG1_VRAM - VRAM_BG1_TILES) >> 5)

constant TSWAP_J3_BASE_TILE0_BG2 = ((TSWAP_J3_SLOT0_BG2_VRAM - VRAM_BG2_TILES) >> 5)
constant TSWAP_J3_BASE_TILE1_BG2 = ((TSWAP_J3_SLOT1_BG2_VRAM - VRAM_BG2_TILES) >> 5)

constant TSWAP_J3_GAP_CNT    = (STAGE_ANIM_WRAM_BASE + $66)

// -----------------------------------------------------------------------------
// Tilemap base em WORDS
// -----------------------------------------------------------------------------
constant TSWAP_BG1_MAP_WORD = (VRAM_BG1_MAP >> 1)
constant TSWAP_BG2_MAP_WORD = (VRAM_BG2_MAP >> 1)

// ============================================================================
// WRAM layout ($0200..$02FF do stage)
// ============================================================================
constant TSWAP_J0_INIT_DONE  = (STAGE_ANIM_WRAM_BASE + $50)
constant TSWAP_J0_DELAY_CNT  = (STAGE_ANIM_WRAM_BASE + $51)
constant TSWAP_J0_SEQ_POS    = (STAGE_ANIM_WRAM_BASE + $52)
constant TSWAP_J0_FAIL       = (STAGE_ANIM_WRAM_BASE + $53)

constant TSWAP_J1_INIT_DONE  = (STAGE_ANIM_WRAM_BASE + $54)
constant TSWAP_J1_DELAY_CNT  = (STAGE_ANIM_WRAM_BASE + $55)
constant TSWAP_J1_SEQ_POS    = (STAGE_ANIM_WRAM_BASE + $56)
constant TSWAP_J1_FAIL       = (STAGE_ANIM_WRAM_BASE + $57)

constant TSWAP_TMP_COL       = (STAGE_ANIM_WRAM_BASE + $58)
constant TSWAP_TMP_ROW       = (STAGE_ANIM_WRAM_BASE + $59)
constant TSWAP_TMP_DY        = (STAGE_ANIM_WRAM_BASE + $5A)
constant TSWAP_TMP_ROWCUR    = (STAGE_ANIM_WRAM_BASE + $5B)
constant TSWAP_TMP_SEG1      = (STAGE_ANIM_WRAM_BASE + $5C)
constant TSWAP_TMP_SEG2      = (STAGE_ANIM_WRAM_BASE + $5D)
constant TSWAP_TMP_WITHIN    = (STAGE_ANIM_WRAM_BASE + $5E)
constant TSWAP_TMP_COL2      = (STAGE_ANIM_WRAM_BASE + $5F)

constant TSWAP_TMP_TILEIDX   = (STAGE_ANIM_WRAM_BASE + $60)
constant TSWAP_TMP_ADDR      = (STAGE_ANIM_WRAM_BASE + $62)

constant TSWAP_RR_NEXT       = (STAGE_ANIM_WRAM_BASE + $6C) // 0..3
constant TSWAP_J3_CONFLICTS  = (STAGE_ANIM_WRAM_BASE + $6D)

constant TSWAP_J1_SLOT_WORD  = (STAGE_ANIM_WRAM_BASE + $6E)
constant TSWAP_J1_BASE_TILE  = (STAGE_ANIM_WRAM_BASE + $70)

constant TSWAP_J2_INIT_DONE  = (STAGE_ANIM_WRAM_BASE + $72)
constant TSWAP_J2_DELAY_CNT  = (STAGE_ANIM_WRAM_BASE + $73)
constant TSWAP_J2_SEQ_POS    = (STAGE_ANIM_WRAM_BASE + $74)
constant TSWAP_J2_FAIL       = (STAGE_ANIM_WRAM_BASE + $75)

constant TSWAP_J2_SLOT_WORD  = (STAGE_ANIM_WRAM_BASE + $76)
constant TSWAP_J2_BASE_TILE  = (STAGE_ANIM_WRAM_BASE + $78)
constant TSWAP_J2_CONFLICTS  = (STAGE_ANIM_WRAM_BASE + $7A)

constant TSWAP_J3_INIT_DONE  = (STAGE_ANIM_WRAM_BASE + $7C)
constant TSWAP_J3_DELAY_CNT  = (STAGE_ANIM_WRAM_BASE + $7D)
constant TSWAP_J3_SEQ_POS    = (STAGE_ANIM_WRAM_BASE + $7E)
constant TSWAP_J3_FAIL       = (STAGE_ANIM_WRAM_BASE + $7F)

constant TSWAP_J0_DMA_SAFE_BYTES  = $0400 // <= 1024 bytes = 1 DMA
constant TSWAP_J0_DMA_CHUNK_BYTES = $0300 //  768 bytes por NMI

constant TSWAP_J0_LOAD_ACTIVE     = (STAGE_ANIM_WRAM_BASE + $80)
constant TSWAP_J0_LOAD_DOUBLEBUF  = (STAGE_ANIM_WRAM_BASE + $81)
constant TSWAP_J0_ACTIVE_SLOT     = (STAGE_ANIM_WRAM_BASE + $82)
constant TSWAP_J0_TARGET_SLOT     = (STAGE_ANIM_WRAM_BASE + $83)
constant TSWAP_J0_DBLBUF_OK       = (STAGE_ANIM_WRAM_BASE + $84)
constant TSWAP_J0_LOAD_SRC_BANK   = (STAGE_ANIM_WRAM_BASE + $85)
constant TSWAP_J0_TMP_SRC_BANK    = (STAGE_ANIM_WRAM_BASE + $86)

constant TSWAP_J0_LOAD_OFFSET     = (STAGE_ANIM_WRAM_BASE + $88)
constant TSWAP_J0_LOAD_REMAIN     = (STAGE_ANIM_WRAM_BASE + $8A)
constant TSWAP_J0_LOAD_SRC_LO     = (STAGE_ANIM_WRAM_BASE + $8C)
constant TSWAP_J0_LOAD_VRAM       = (STAGE_ANIM_WRAM_BASE + $8E)
constant TSWAP_J0_ACTIVE_VRAM     = (STAGE_ANIM_WRAM_BASE + $90)
constant TSWAP_J0_TARGET_BASE     = (STAGE_ANIM_WRAM_BASE + $92)
constant TSWAP_J0_ACTIVE_BASE     = (STAGE_ANIM_WRAM_BASE + $94)
constant TSWAP_J0_PATCH_BASE      = (STAGE_ANIM_WRAM_BASE + $96)
constant TSWAP_J0_TMP_DMA_SIZE    = (STAGE_ANIM_WRAM_BASE + $98)
constant TSWAP_J0_TMP_SRC_LO      = (STAGE_ANIM_WRAM_BASE + $9A)

constant TSWAP_J3_SLOT_WORD  = (STAGE_ANIM_WRAM_BASE + $9C)
constant TSWAP_J3_BASE_TILE  = (STAGE_ANIM_WRAM_BASE + $9E)

// ============================================================================
// Helpers de refactor (compile-time)
// ============================================================================

// Grava slot (word) + base tile (word) em WRAM do job.
macro TSWAP_STORE_SLOT_BASE(variable slotVram, variable baseTile, variable slotWordAddr, variable baseTileAddr) {
  rep #$10
  ldx.w #((slotVram >> 1) & $ffff)
  stx.w slotWordAddr
  ldx.w #baseTile
  stx.w baseTileAddr
}

// Valida fim do slot contra limite do map; em erro salta para fail.
macro TSWAP_SLOT_CHECK_OR_FAIL(variable slotEnd, variable mapLimit, variable setLabel, variable failLabel) {
  rep #$20
  lda.w #slotEnd
  cmp.w #mapLimit
  bcc setLabel
  jmp failLabel
}

// Grava slot/base e segue para caminho de VRAM ok.
macro TSWAP_SLOT_SET_AND_JMP_OK(variable slotVram, variable baseTile, variable slotWordAddr, variable baseTileAddr, variable okLabel) {
  TSWAP_STORE_SLOT_BASE(slotVram, baseTile, slotWordAddr, baseTileAddr)
  jmp okLabel
}

// Blocos comuns para desfecho do FirstTime.
macro TSWAP_FIRST_FAIL(variable failAddr) {
  sep #$20
  lda.b #$01
  sta.w failAddr
  plp
  rts
}

macro TSWAP_FIRST_VRAM_OK_BEGIN(variable failAddr, variable seqLabel, variable numFrames, variable firstFrameOkLabel) {
  sep #$20
  stz.w failAddr

  lda.l seqLabel
  cmp.b #numFrames
  bcc firstFrameOkLabel
  lda.b #$00
}

macro TSWAP_FIRST_VRAM_OK_END(variable loadFrameRoutine, variable patchTilemapRoutine, variable initDoneAddr) {
  jsr loadFrameRoutine
  jsr patchTilemapRoutine

  lda.b #$01
  sta.w initDoneAddr

  plp
  rts
}

// Blocos comuns de AdvanceSeqAndDma (JOB1/JOB2).
macro TSWAP_ADVANCE_SEQ_BEGIN(variable seqPosAddr, variable seqLen, variable seqPosOkLabel) {
  php
  sep #$20
  rep #$10

  lda.w seqPosAddr
  clc
  adc.b #$01
  cmp.b #seqLen
  bcc seqPosOkLabel
  lda.b #$00
}

macro TSWAP_ADVANCE_SEQ_LOAD_FRAME(variable seqPosAddr, variable seqLabel, variable numFrames, variable frameOkLabel) {
  sta.w seqPosAddr

  sep #$10
  tax
  lda.l seqLabel,x
  rep #$10
  cmp.b #numFrames
  bcc frameOkLabel
  lda.b #$00
}

macro TSWAP_ADVANCE_SEQ_END(variable loadFrameRoutine) {
  jsr loadFrameRoutine

  plp
  rts
}

// Helpers de conflito/seleção de slot no FirstTime do JOB2.
macro TSWAP_J2_COUNT_CONFLICT(variable jobEnable, variable jobTargetBg, variable bgValue, variable nextLabel) {
  lda.b #jobEnable
  beq nextLabel
  lda.b #jobTargetBg
  cmp.b #bgValue
  bne nextLabel
  inc.w TSWAP_J2_CONFLICTS
}

macro TSWAP_J2_PICK_SLOT_BY_CONFLICT_MAX2(variable useSlot0Label, variable useSlot1Label, variable failLabel) {
  lda.w TSWAP_J2_CONFLICTS
  beq useSlot0Label
  cmp.b #$01
  beq useSlot1Label
  jmp failLabel
}

// Escolha de slot do JOB1 baseada em conflito com JOB0 no mesmo BG.
macro TSWAP_J1_PICK_SLOT_FROM_JOB0(variable bgValue, variable useSlot0BLabel, variable useSlot1BLabel, variable useSlot0Label) {
  lda.b #STAGE_TSWAP_JOB0_ENABLE
  beq useSlot0BLabel
  lda.b #STAGE_TSWAP_JOB0_TARGET_BG
  cmp.b #bgValue
  beq useSlot1BLabel
  jmp useSlot0Label
}

macro TSWAP_J1_FIRST_PICK_FROM_JOB0(variable bgValue, variable useSlot0Label, variable useSlot1Label) {
  TSWAP_J1_PICK_SLOT_FROM_JOB0(bgValue, useSlot0Label, useSlot1Label, useSlot0Label)
}

macro TSWAP_J2_RESET_AND_COUNT_JOB0_CONFLICT(variable bgValue, variable nextLabel) {
  stz.w TSWAP_J2_CONFLICTS
  TSWAP_J2_COUNT_CONFLICT(STAGE_TSWAP_JOB0_ENABLE, STAGE_TSWAP_JOB0_TARGET_BG, bgValue, nextLabel)
}

macro TSWAP_J2_COUNT_JOB1_CONFLICT(variable bgValue, variable nextLabel) {
  TSWAP_J2_COUNT_CONFLICT(STAGE_TSWAP_JOB1_ENABLE, STAGE_TSWAP_JOB1_TARGET_BG, bgValue, nextLabel)
}

// Helpers de conflito/seleção de slot no FirstTime do JOB3.
macro TSWAP_J3_COUNT_CONFLICT(variable jobEnable, variable jobTargetBg, variable bgValue, variable nextLabel) {
  lda.b #jobEnable
  beq nextLabel
  lda.b #jobTargetBg
  cmp.b #bgValue
  bne nextLabel
  inc.w TSWAP_J3_CONFLICTS
}

macro TSWAP_J3_PICK_SLOT_BY_CONFLICT_MAX2(variable useSlot0Label, variable useSlot1Label, variable failLabel) {
  lda.w TSWAP_J3_CONFLICTS
  beq useSlot0Label
  cmp.b #$01
  beq useSlot1Label
  jmp failLabel
}

macro TSWAP_J3_RESET_AND_COUNT_JOB0_CONFLICT(variable bgValue, variable nextLabel) {
  stz.w TSWAP_J3_CONFLICTS
  TSWAP_J3_COUNT_CONFLICT(STAGE_TSWAP_JOB0_ENABLE, STAGE_TSWAP_JOB0_TARGET_BG, bgValue, nextLabel)
}

macro TSWAP_J3_COUNT_JOB1_CONFLICT(variable bgValue, variable nextLabel) {
  TSWAP_J3_COUNT_CONFLICT(STAGE_TSWAP_JOB1_ENABLE, STAGE_TSWAP_JOB1_TARGET_BG, bgValue, nextLabel)
}

macro TSWAP_J3_COUNT_JOB2_CONFLICT(variable bgValue, variable nextLabel) {
  TSWAP_J3_COUNT_CONFLICT(STAGE_TSWAP_JOB2_ENABLE, STAGE_TSWAP_JOB2_TARGET_BG, bgValue, nextLabel)
}

// Corpo comum do LoadFrameByIndex (seleção FR0..FR7).
macro TSWAP_LOAD_FRAME_BY_INDEX_BODY(variable loadJmpTableLabel) {
  php
  rep #$30
  and.w #$00FF
  and.w #$0007
  asl
  tax
  jmp (loadJmpTableLabel,x)
}

macro TSWAP_LOAD_JMPTABLE_8(variable fr0, variable fr1, variable fr2, variable fr3, variable fr4, variable fr5, variable fr6, variable fr7) {
  dw fr0
  dw fr1
  dw fr2
  dw fr3
  dw fr4
  dw fr5
  dw fr6
  dw fr7
}

// Blocos comuns do loop Run/Run_NoGap (JOB1/JOB2).
macro TSWAP_JOB_RUN_GAP_BLOCK(variable gapCntAddr, variable delayCntAddr, variable advanceRoutine, variable runNoGapLabel, variable returnLabel) {
  lda.w gapCntAddr
  beq runNoGapLabel
  dec.w gapCntAddr
  lda.w gapCntAddr
  bne returnLabel
  stz.w delayCntAddr
  jsr advanceRoutine
  jmp returnLabel
}

macro TSWAP_JOB_RUN_NOGAP_BLOCK(variable delayCntAddr, variable delayConst, variable gapConst, variable seqPosAddr, variable seqLen, variable gapCntAddr, variable doAdvanceLabel, variable returnLabel) {
  lda.w delayCntAddr
  clc
  adc.b #$01
  sta.w delayCntAddr
  cmp.b #delayConst
  bcc returnLabel

  stz.w delayCntAddr

  lda.b #gapConst
  beq doAdvanceLabel

  lda.w seqPosAddr
  cmp.b #(seqLen - 1)
  bne doAdvanceLabel

  lda.b #$FF
  sta.w seqPosAddr
  lda.b #gapConst
  sta.w gapCntAddr
  jmp returnLabel
}

// Blocos comuns de entrada do job e check de init.
macro TSWAP_JOB_DO_FAIL_CHECK(variable failAddr, variable checkInitLabel) {
  lda.w failAddr
  beq checkInitLabel
  plp
  rts
}

macro TSWAP_JOB_CHECK_INIT(variable initDoneAddr, variable runLabel, variable firstTimeLabel) {
  lda.w initDoneAddr
  bne runLabel
  jmp firstTimeLabel
}

macro TSWAP_FIRSTTIME_INIT_SEQ(variable seqPosAddr) {
  sep #$20
  stz.w seqPosAddr
}

macro TSWAP_J0_FIRSTTIME_RESET_STATE() {
  stz.w TSWAP_J0_SEQ_POS
  stz.w TSWAP_J0_PATCH_POS
  stz.w TSWAP_J0_LOAD_ACTIVE
  stz.w TSWAP_J0_LOAD_DOUBLEBUF
  stz.w TSWAP_J0_ACTIVE_SLOT
  stz.w TSWAP_J0_TARGET_SLOT
  stz.w TSWAP_J0_DBLBUF_OK
  stz.w TSWAP_J0_LOAD_FRAME
}

macro TSWAP_J0_FIRST_SET_ACTIVE_AND_CHECK_DBLBUF(variable slotVramConst, variable baseTileConst, variable slot1EndConst, variable mapLimitConst, variable dblBufOkLabel, variable vramOkLabel) {
  lda.w #slotVramConst
  sta.w TSWAP_J0_ACTIVE_VRAM
  lda.w #baseTileConst
  sta.w TSWAP_J0_ACTIVE_BASE

  lda.w #slot1EndConst
  cmp.w #mapLimitConst
  bcc dblBufOkLabel
  jmp vramOkLabel
}

macro TSWAP_J0_FIRST_MARK_DBLBUF_AND_JMP(variable vramOkLabel) {
  sep #$20
  lda.b #$01
  sta.w TSWAP_J0_DBLBUF_OK
  jmp vramOkLabel
}

macro TSWAP_J0_LOAD_CHUNKED_SET_TARGET_DBLBUF_ON(variable targetRoutine, variable setupLabel) {
  jsr targetRoutine
  lda.b #$01
  sta.w TSWAP_J0_LOAD_DOUBLEBUF
  jmp setupLabel
}

macro TSWAP_J0_LOAD_CHUNKED_SET_TARGET_DBLBUF_OFF(variable targetRoutine, variable setupLabel) {
  jsr targetRoutine
  stz.w TSWAP_J0_LOAD_DOUBLEBUF
  jmp setupLabel
}

// Blocos de reset usados em TileSwap_Init.
macro TSWAP_INIT_RESET_JOB_CORE(variable initDoneAddr, variable delayCntAddr, variable seqPosAddr, variable failAddr) {
  stz.w initDoneAddr
  stz.w delayCntAddr
  stz.w seqPosAddr
  stz.w failAddr
}

macro TSWAP_INIT_RESET_J0_LOAD_FLAGS() {
  stz.w TSWAP_J0_LOAD_ACTIVE
  stz.w TSWAP_J0_LOAD_DOUBLEBUF
  stz.w TSWAP_J0_ACTIVE_SLOT
  stz.w TSWAP_J0_TARGET_SLOT
  stz.w TSWAP_J0_DBLBUF_OK
  stz.w TSWAP_J0_LOAD_SRC_BANK
  stz.w TSWAP_J0_TMP_SRC_BANK
}

macro TSWAP_INIT_RESET_J0_LOAD_WORDS() {
  stz.w TSWAP_J0_LOAD_OFFSET
  stz.w TSWAP_J0_LOAD_REMAIN
  stz.w TSWAP_J0_LOAD_SRC_LO
  stz.w TSWAP_J0_LOAD_VRAM
  stz.w TSWAP_J0_ACTIVE_VRAM
  stz.w TSWAP_J0_TARGET_BASE
  stz.w TSWAP_J0_ACTIVE_BASE
  stz.w TSWAP_J0_PATCH_BASE
  stz.w TSWAP_J0_TMP_DMA_SIZE
  stz.w TSWAP_J0_TMP_SRC_LO
}

macro TSWAP_INIT_RESET_JOB_SLOT_BASE_WORDS() {
  stz.w TSWAP_J1_SLOT_WORD
  stz.w TSWAP_J1_BASE_TILE
  stz.w TSWAP_J2_SLOT_WORD
  stz.w TSWAP_J2_BASE_TILE
  stz.w TSWAP_J3_SLOT_WORD
  stz.w TSWAP_J3_BASE_TILE
}

macro TSWAP_FIRSTTIME_DISPATCH_BG(variable targetBg, variable firstBg1Label, variable firstBg2Label, variable failLabel) {
  lda.b #targetBg
  cmp.b #$01
  beq firstBg1Label
  cmp.b #$02
  beq firstBg2Label
  jmp failLabel
}

// Corpo comum do DMA ROM->VRAM usado por JOB1/JOB2.
macro TSWAP_DMA_TO_VRAM_BODY(variable slotWordAddr, variable frameSize) {
  php
  sep #$20
  pha

  rep #$10
  lda.b #V_INC_1
  sta VMAIN

  ldx.w slotWordAddr
  stx VMADDL

  lda.b #$01
  sta DMAPx
  lda.b #$18
  sta BBADx

  sty A1TxL

  pla
  sta A1Bx

  ldx.w #frameSize
  stx DASxL

  lda.b #$01
  sta MDMAEN

  plp
  rts
}

// Gera corpo dos handlers LoadFRx sem duplicar.
macro TSWAP_LOADFR_BODY(variable frameLabel, variable dmaRoutine) {
  sep #$20
  lda.b #(((frameLabel >> 16) & $ff) | $80)
  rep #$10
  ldy.w #((frameLabel) & $ffff)
  jsr dmaRoutine
  plp
  rts
}

// Corpo comum dos handlers SetSrcFRx do JOB0.
macro TSWAP_J0_SET_SRC_BODY(variable frameLabel) {
  rep #$20
  lda.w #((frameLabel) & $FFFF)
  sta.w TSWAP_J0_LOAD_SRC_LO
  sep #$20
  lda.b #(((frameLabel >> 16) & $FF) | $80)
  sta.w TSWAP_J0_LOAD_SRC_BANK
  plp
  rts
}

// Prepara origem/tamanho do DMA do JOB0 e salta para rotina comum de disparo.
macro TSWAP_J0_DMA_PREP_AND_JMP(variable srcExpr, variable dmaSizeExpr) {
  rep #$20
  lda.w #((srcExpr) & $FFFF)
  sta.w TSWAP_J0_TMP_SRC_LO
  lda.w #((dmaSizeExpr) & $FFFF)
  sta.w TSWAP_J0_TMP_DMA_SIZE
  sep #$20
  lda.b #((((srcExpr) >> 16) & $FF) | $80)
  sta.w TSWAP_J0_TMP_SRC_BANK
  jmp TSWAP_J0_DmaPrepared
}

// Corpo comum para fixar target VRAM/base tile do JOB0 e retornar.
macro TSWAP_J0_SET_TARGET_CONST_AND_RETURN(variable loadVramConst, variable targetBaseConst) {
  rep #$20
  lda.w #loadVramConst
  sta.w TSWAP_J0_LOAD_VRAM
  lda.w #targetBaseConst
  sta.w TSWAP_J0_TARGET_BASE
  plp
  rts
}

// Dispara DMA usando TMP_ADDR/TMP_SRC_LO/TMP_SRC_BANK/TMP_DMA_SIZE já preparados.
macro TSWAP_J0_DMA_KICK_FROM_TMPS() {
  sep #$20
  rep #$10

  lda.b #V_INC_1
  sta VMAIN

  ldx.w TSWAP_TMP_ADDR
  stx VMADDL

  lda.b #$01
  sta DMAPx
  lda.b #$18
  sta BBADx

  ldx.w TSWAP_J0_TMP_SRC_LO
  stx A1TxL

  lda.w TSWAP_J0_TMP_SRC_BANK
  sta A1Bx

  ldx.w TSWAP_J0_TMP_DMA_SIZE
  stx DASxL

  lda.b #$01
  sta MDMAEN
}

// Entrada comum do patch de tilemap (BG1/BG2).
macro TSWAP_PATCH_TILEMAP_ENTRY(variable targetBg, variable patchBg1Label, variable patchBg2Label) {
  php
  sep #$20
  rep #$10

  lda.b #V_INC_1
  sta VMAIN

  lda.b #targetBg
  cmp.b #$01
  beq patchBg1Label
  cmp.b #$02
  beq patchBg2Label
  plp
  rts
}

// Blocos comuns do loop de targets (col,row) para patch por retângulo.
macro TSWAP_PATCH_TARGET_LOOP_BEGIN(variable targetCount) {
  phx
  phy

  ldx.w #$0000
  ldy.w #targetCount
}

macro TSWAP_PATCH_TARGET_LOOP_STEP(variable targetsLabel, variable patchRectLabel) {
  sep #$20
  lda.l targetsLabel,x
  sta.w TSWAP_TMP_COL
  inx
  lda.l targetsLabel,x
  sta.w TSWAP_TMP_ROW
  inx

  jsr patchRectLabel
}

macro TSWAP_PATCH_TARGET_LOOP_END() {
  ply
  plx
  plp
  rts
}

// Corpo do loop de targets (usa label já declarada no callsite).
macro TSWAP_PATCH_TARGET_LOOP_BODY(variable targetsLabel, variable patchRectLabel, variable targetLoopLabel) {
  TSWAP_PATCH_TARGET_LOOP_STEP(targetsLabel, patchRectLabel)
  dey
  bne targetLoopLabel

  TSWAP_PATCH_TARGET_LOOP_END()
}


// Blocos comuns do PatchRect (init/step/finalização).
macro TSWAP_PATCH_RECT_BEGIN(variable baseTileAddr) {
  php
  phx
  phy

  rep #$20
  lda.w baseTileAddr
  sta.w TSWAP_TMP_TILEIDX

  sep #$20
  stz.w TSWAP_TMP_DY
}

macro TSWAP_PATCH_RECT_STEP(variable patchRowLabel) {
  lda.w TSWAP_TMP_ROW
  clc
  adc.w TSWAP_TMP_DY
  sta.w TSWAP_TMP_ROWCUR

  jsr patchRowLabel

  lda.w TSWAP_TMP_DY
  clc
  adc.b #$01
  sta.w TSWAP_TMP_DY
}

macro TSWAP_PATCH_RECT_END() {
  ply
  plx
  plp
  rts
}

// Corpo do row loop do PatchRect (usa label já declarada no callsite).
macro TSWAP_PATCH_RECT_ROW_LOOP_BODY(variable patchRowLabel, variable heightConst, variable rowLoopLabel) {
  TSWAP_PATCH_RECT_STEP(patchRowLabel)
  cmp.b #heightConst
  bcc rowLoopLabel

  TSWAP_PATCH_RECT_END()
}

// Blocos comuns do PatchRow.
macro TSWAP_PATCH_ROW_BEGIN(variable widthConst, variable segNoSplitLabel, variable doSeg1Label) {
  php
  rep #$10
  sep #$20

  lda.w TSWAP_TMP_COL
  and.b #$1F
  sta.w TSWAP_TMP_WITHIN

  lda.b #$20
  sec
  sbc.w TSWAP_TMP_WITHIN
  sta.w TSWAP_TMP_SEG1

  lda.b #widthConst
  cmp.w TSWAP_TMP_SEG1
  bcc segNoSplitLabel
  beq segNoSplitLabel

  lda.b #widthConst
  sec
  sbc.w TSWAP_TMP_SEG1
  sta.w TSWAP_TMP_SEG2
  jmp doSeg1Label
}

macro TSWAP_PATCH_ROW_SEG_NOSPLIT(variable widthConst) {
  lda.b #widthConst
  sta.w TSWAP_TMP_SEG1
  stz.w TSWAP_TMP_SEG2
}

macro TSWAP_PATCH_ROW_DO_SEG1(variable setAddrSeg1Label, variable writeSeg1Label) {
  jsr setAddrSeg1Label
  jsr writeSeg1Label
}

macro TSWAP_PATCH_ROW_DO_BOTH_SEGS(variable rowDoneLabel, variable setAddrSeg1Label, variable writeSeg1Label, variable setAddrSeg2Label, variable writeSeg2Label) {
  TSWAP_PATCH_ROW_DO_SEG1(setAddrSeg1Label, writeSeg1Label)
  TSWAP_PATCH_ROW_DO_SEG2(rowDoneLabel, setAddrSeg2Label, writeSeg2Label)
}

macro TSWAP_PATCH_ROW_DO_SEG2(variable rowDoneLabel, variable setAddrSeg2Label, variable writeSeg2Label) {
  lda.w TSWAP_TMP_SEG2
  beq rowDoneLabel

  lda.w TSWAP_TMP_COL
  clc
  adc.w TSWAP_TMP_SEG1
  sta.w TSWAP_TMP_COL2

  jsr setAddrSeg2Label
  jsr writeSeg2Label
}

macro TSWAP_PATCH_ROW_END() {
  plp
  rts
}

// Blocos comuns de escrita de segmento no tilemap.
macro TSWAP_WRITE_SEG_BEGIN(variable segAddr) {
  php
  rep #$30

  lda.w segAddr
  and.w #$00FF
  tay
}

macro TSWAP_WRITE_SEG_STEP(variable palBits) {
  lda.w TSWAP_TMP_TILEIDX
  ora.w #palBits
  sta VMDATAL
  inc.w TSWAP_TMP_TILEIDX
  dey
}

macro TSWAP_WRITE_SEG_STEP_MASKED(variable maskBits, variable palBits) {
  lda.w TSWAP_TMP_TILEIDX
  and.w #maskBits
  ora.w #palBits
  sta VMDATAL
  inc.w TSWAP_TMP_TILEIDX
  dey
}

macro TSWAP_WRITE_SEG_END() {
  plp
  rts
}

// Corpo do loop de escrita de segmento (usa label já declarada no callsite).
macro TSWAP_WRITE_SEG_LOOP_BODY(variable palBits, variable writeLoopLabel) {
  TSWAP_WRITE_SEG_STEP(palBits)
  bne writeLoopLabel

  TSWAP_WRITE_SEG_END()
}

// Corpo do loop de escrita mascarada de segmento (usa label já declarada no callsite).
macro TSWAP_WRITE_SEG_LOOP_BODY_MASKED(variable maskBits, variable palBits, variable writeLoopLabel) {
  TSWAP_WRITE_SEG_STEP_MASKED(maskBits, palBits)
  bne writeLoopLabel

  TSWAP_WRITE_SEG_END()
}

// ============================================================================
// Public API
// ============================================================================
TileSwap_Init:
  php
  sep #$20

  TSWAP_INIT_RESET_JOB_CORE(TSWAP_J0_INIT_DONE, TSWAP_J0_DELAY_CNT, TSWAP_J0_SEQ_POS, TSWAP_J0_FAIL)
  stz.w TSWAP_J0_LOAD_FRAME
  stz.w TSWAP_J0_PATCH_POS
  stz.w TSWAP_J2_PATCH_POS
  stz.w TSWAP_J3_PATCH_POS
  stz.w TSWAP_J2_FIRST_LOADED
  stz.w TSWAP_J3_FIRST_LOADED

  TSWAP_INIT_RESET_JOB_CORE(TSWAP_J1_INIT_DONE, TSWAP_J1_DELAY_CNT, TSWAP_J1_SEQ_POS, TSWAP_J1_FAIL)

  TSWAP_INIT_RESET_JOB_CORE(TSWAP_J2_INIT_DONE, TSWAP_J2_DELAY_CNT, TSWAP_J2_SEQ_POS, TSWAP_J2_FAIL)
  TSWAP_INIT_RESET_JOB_CORE(TSWAP_J3_INIT_DONE, TSWAP_J3_DELAY_CNT, TSWAP_J3_SEQ_POS, TSWAP_J3_FAIL)

  stz.w TSWAP_RR_NEXT
  stz.w TSWAP_J1_GAP_CNT
  stz.w TSWAP_J3_GAP_CNT

  TSWAP_INIT_RESET_J0_LOAD_FLAGS()

  rep #$20
  TSWAP_INIT_RESET_J0_LOAD_WORDS()
  sep #$20

  rep #$20
  TSWAP_INIT_RESET_JOB_SLOT_BASE_WORDS()
  sep #$20

  plp
  rts

TileSwap_NmiTick:
  php
  sep #$20

  lda.b #STAGE_TSWAP_ENABLE
  bne TSWAP_Sched_Entry_B
  plp
  rts

TSWAP_Sched_Entry_B:
  jmp TSWAP_Sched_Entry

TSWAP_Sched_Entry:
  lda.b #STAGE_TSWAP_JOB0_ENABLE
  bne TSWAP_Sched_Do
  lda.b #STAGE_TSWAP_JOB1_ENABLE
  bne TSWAP_Sched_Do
  lda.b #STAGE_TSWAP_JOB2_ENABLE
  bne TSWAP_Sched_Do
  lda.b #STAGE_TSWAP_JOB3_ENABLE
  bne TSWAP_Sched_Do
  plp
  rts

TSWAP_Sched_Do:
  lda.w TSWAP_J0_LOAD_ACTIVE
  beq TSWAP_Sched_Do_RR
  jmp TSWAP_J0_Do

TSWAP_Sched_Do_RR:
  lda.w TSWAP_RR_NEXT
  cmp.b #$01
  beq TSWAP_Sched_From1_B
  cmp.b #$02
  beq TSWAP_Sched_From2_B
  cmp.b #$03
  beq TSWAP_Sched_From3_B
  jmp TSWAP_Sched_From0

TSWAP_Sched_From1_B:
  jmp TSWAP_Sched_From1

TSWAP_Sched_From2_B:
  jmp TSWAP_Sched_From2

TSWAP_Sched_From3_B:
  jmp TSWAP_Sched_From3

TSWAP_Sched_From0:
  lda.b #STAGE_TSWAP_JOB0_ENABLE
  beq TSWAP_Sched_From0_Check1
  lda.b #$01
  sta.w TSWAP_RR_NEXT
  jmp TSWAP_J0_Do

TSWAP_Sched_From0_Check1:
  lda.b #STAGE_TSWAP_JOB1_ENABLE
  beq TSWAP_Sched_From0_Check2
  lda.b #$02
  sta.w TSWAP_RR_NEXT
  jmp TSWAP_J1_Do

TSWAP_Sched_From0_Check2:
  lda.b #STAGE_TSWAP_JOB2_ENABLE
  beq TSWAP_Sched_From0_Check3
  lda.b #$03
  sta.w TSWAP_RR_NEXT
  jmp TSWAP_J2_Do

TSWAP_Sched_From0_Check3:
  lda.b #STAGE_TSWAP_JOB3_ENABLE
  bne TSWAP_Sched_From0_HasJob3
  jmp TSWAP_Sched_None

TSWAP_Sched_From0_HasJob3:
  stz.w TSWAP_RR_NEXT
  jmp TSWAP_J3_Do

TSWAP_Sched_From1:
  lda.b #STAGE_TSWAP_JOB1_ENABLE
  beq TSWAP_Sched_From1_Check2
  lda.b #$02
  sta.w TSWAP_RR_NEXT
  jmp TSWAP_J1_Do

TSWAP_Sched_From1_Check2:
  lda.b #STAGE_TSWAP_JOB2_ENABLE
  beq TSWAP_Sched_From1_Check3
  lda.b #$03
  sta.w TSWAP_RR_NEXT
  jmp TSWAP_J2_Do

TSWAP_Sched_From1_Check3:
  lda.b #STAGE_TSWAP_JOB3_ENABLE
  beq TSWAP_Sched_From1_Check0
  stz.w TSWAP_RR_NEXT
  jmp TSWAP_J3_Do

TSWAP_Sched_From1_Check0:
  lda.b #STAGE_TSWAP_JOB0_ENABLE
  bne TSWAP_Sched_From1_HasJob0
  jmp TSWAP_Sched_None

TSWAP_Sched_From1_HasJob0:
  lda.b #$01
  sta.w TSWAP_RR_NEXT
  jmp TSWAP_J0_Do

TSWAP_Sched_From2:
  lda.b #STAGE_TSWAP_JOB2_ENABLE
  beq TSWAP_Sched_From2_Check3
  lda.b #$03
  sta.w TSWAP_RR_NEXT
  jmp TSWAP_J2_Do

TSWAP_Sched_From2_Check3:
  lda.b #STAGE_TSWAP_JOB3_ENABLE
  beq TSWAP_Sched_From2_Check0
  stz.w TSWAP_RR_NEXT
  jmp TSWAP_J3_Do

TSWAP_Sched_From2_Check0:
  lda.b #STAGE_TSWAP_JOB0_ENABLE
  beq TSWAP_Sched_From2_Check1
  lda.b #$01
  sta.w TSWAP_RR_NEXT
  jmp TSWAP_J0_Do

TSWAP_Sched_From2_Check1:
  lda.b #STAGE_TSWAP_JOB1_ENABLE
  bne TSWAP_Sched_From2_HasJob1
  jmp TSWAP_Sched_None

TSWAP_Sched_From2_HasJob1:
  lda.b #$02
  sta.w TSWAP_RR_NEXT
  jmp TSWAP_J1_Do

TSWAP_Sched_From3:
  lda.b #STAGE_TSWAP_JOB3_ENABLE
  beq TSWAP_Sched_From3_Check0
  stz.w TSWAP_RR_NEXT
  jmp TSWAP_J3_Do

TSWAP_Sched_From3_Check0:
  lda.b #STAGE_TSWAP_JOB0_ENABLE
  beq TSWAP_Sched_From3_Check1
  lda.b #$01
  sta.w TSWAP_RR_NEXT
  jmp TSWAP_J0_Do

TSWAP_Sched_From3_Check1:
  lda.b #STAGE_TSWAP_JOB1_ENABLE
  beq TSWAP_Sched_From3_Check2
  lda.b #$02
  sta.w TSWAP_RR_NEXT
  jmp TSWAP_J1_Do

TSWAP_Sched_From3_Check2:
  lda.b #STAGE_TSWAP_JOB2_ENABLE
  bne TSWAP_Sched_From3_HasJob2
  jmp TSWAP_Sched_None

TSWAP_Sched_From3_HasJob2:
  lda.b #$03
  sta.w TSWAP_RR_NEXT
  jmp TSWAP_J2_Do

TSWAP_Sched_None:
  plp
  rts

// ============================================================================
// JOB0
// ============================================================================
TSWAP_J0_Do:
  TSWAP_JOB_DO_FAIL_CHECK(TSWAP_J0_FAIL, TSWAP_J0_CheckLoad)

TSWAP_J0_CheckLoad:
  lda.w TSWAP_J0_LOAD_ACTIVE
  beq TSWAP_J0_CheckInit
  jsr TSWAP_J0_ContinueLoad
  plp
  rts

TSWAP_J0_CheckInit:
  TSWAP_JOB_CHECK_INIT(TSWAP_J0_INIT_DONE, TSWAP_J0_Run, TSWAP_J0_FirstTime)

TSWAP_J0_Run:
if STAGE_TSWAP_JOB0_TARGET_COUNT > 1 {
  // Multi-target: espalha patch do tilemap para reduzir custo por NMI.
  jsr TSWAP_J0_PatchTilemap_Continue
}
  TSWAP_JOB_RUN_GAP_BLOCK(TSWAP_J0_GAP_CNT, TSWAP_J0_DELAY_CNT, TSWAP_J0_AdvanceSeqAndDma, TSWAP_J0_Run_NoGap, TSWAP_J0_Return)

TSWAP_J0_Run_NoGap:
  TSWAP_JOB_RUN_NOGAP_BLOCK(TSWAP_J0_DELAY_CNT, STAGE_TSWAP_JOB0_DELAY, STAGE_TSWAP_JOB0_GAP, TSWAP_J0_SEQ_POS, STAGE_TSWAP_JOB0_SEQ_LEN, TSWAP_J0_GAP_CNT, TSWAP_J0_DoAdvance, TSWAP_J0_Return)

TSWAP_J0_DoAdvance:
  jsr TSWAP_J0_AdvanceSeqAndDma

TSWAP_J0_Return:
  plp
  rts

TSWAP_J0_FirstTime:
  sep #$20
  TSWAP_J0_FIRSTTIME_RESET_STATE()

  lda.b #STAGE_TSWAP_JOB0_TARGET_BG
  cmp.b #$01
  beq TSWAP_J0_First_BG1
  cmp.b #$02
  beq TSWAP_J0_First_BG2
  jmp TSWAP_J0_First_Fail

TSWAP_J0_First_BG1:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J0_SLOT_BG1_END, VRAM_BG1_MAP, TSWAP_J0_First_BG1_Slot0Ok, TSWAP_J0_First_Fail)

TSWAP_J0_First_BG1_Slot0Ok:
  TSWAP_J0_FIRST_SET_ACTIVE_AND_CHECK_DBLBUF(TSWAP_J0_SLOT_BG1_VRAM, TSWAP_J0_BASE_TILE_BG1, (TSWAP_SLOT1_BG1_VRAM + TSWAP_J0_FRAME_SIZE), VRAM_BG1_MAP, TSWAP_J0_First_BG1_DblBufOk, TSWAP_J0_First_VramOk)

TSWAP_J0_First_BG1_DblBufOk:
  // Com mais de 1 target no JOB0, manter slot fixo evita repatch completo por frame.
  // Com outro job ativo no mesmo BG, desliga double-buffer do JOB0 para evitar conflito de slot.
if STAGE_TSWAP_JOB0_TARGET_COUNT == 1 {
if STAGE_TSWAP_JOB1_ENABLE == 1 {
if STAGE_TSWAP_JOB1_TARGET_BG == 1 {
  jmp TSWAP_J0_First_VramOk
}
}
if STAGE_TSWAP_JOB2_ENABLE == 1 {
if STAGE_TSWAP_JOB2_TARGET_BG == 1 {
  jmp TSWAP_J0_First_VramOk
}
}
if STAGE_TSWAP_JOB3_ENABLE == 1 {
if STAGE_TSWAP_JOB3_TARGET_BG == 1 {
  jmp TSWAP_J0_First_VramOk
}
}
  TSWAP_J0_FIRST_MARK_DBLBUF_AND_JMP(TSWAP_J0_First_VramOk)
} else {
  jmp TSWAP_J0_First_VramOk
}

TSWAP_J0_First_BG2:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J0_SLOT_BG2_END, VRAM_BG2_MAP, TSWAP_J0_First_BG2_Slot0Ok, TSWAP_J0_First_Fail)

TSWAP_J0_First_BG2_Slot0Ok:
  TSWAP_J0_FIRST_SET_ACTIVE_AND_CHECK_DBLBUF(TSWAP_J0_SLOT_BG2_VRAM, TSWAP_J0_BASE_TILE_BG2, (TSWAP_SLOT1_BG2_VRAM + TSWAP_J0_FRAME_SIZE), VRAM_BG2_MAP, TSWAP_J0_First_BG2_DblBufOk, TSWAP_J0_First_VramOk)

TSWAP_J0_First_BG2_DblBufOk:
  // Mesmo critério do BG1: double-buffer só no caso 1 target.
  // Se houver outro job no BG2, JOB0 fica em slot fixo para nao sobrescrever o slot do outro job.
if STAGE_TSWAP_JOB0_TARGET_COUNT == 1 {
if STAGE_TSWAP_JOB1_ENABLE == 1 {
if STAGE_TSWAP_JOB1_TARGET_BG == 2 {
  jmp TSWAP_J0_First_VramOk
}
}
if STAGE_TSWAP_JOB2_ENABLE == 1 {
if STAGE_TSWAP_JOB2_TARGET_BG == 2 {
  jmp TSWAP_J0_First_VramOk
}
}
if STAGE_TSWAP_JOB3_ENABLE == 1 {
if STAGE_TSWAP_JOB3_TARGET_BG == 2 {
  jmp TSWAP_J0_First_VramOk
}
}
  TSWAP_J0_FIRST_MARK_DBLBUF_AND_JMP(TSWAP_J0_First_VramOk)
} else {
  jmp TSWAP_J0_First_VramOk
}

TSWAP_J0_First_Fail:
  TSWAP_FIRST_FAIL(TSWAP_J0_FAIL)

TSWAP_J0_First_VramOk:
  TSWAP_FIRST_VRAM_OK_BEGIN(TSWAP_J0_FAIL, Stage_TSwapJob0_Seq, STAGE_TSWAP_JOB0_NUM_FRAMES, TSWAP_J0_FirstFrameOk)

TSWAP_J0_FirstFrameOk:
  jsr TSWAP_J0_LoadFrameByIndex
  plp
  rts

TSWAP_J0_AdvanceSeqAndDma:
  TSWAP_ADVANCE_SEQ_BEGIN(TSWAP_J0_SEQ_POS, STAGE_TSWAP_JOB0_SEQ_LEN, TSWAP_J0_SeqPosOk)

TSWAP_J0_SeqPosOk:
  TSWAP_ADVANCE_SEQ_LOAD_FRAME(TSWAP_J0_SEQ_POS, Stage_TSwapJob0_Seq, STAGE_TSWAP_JOB0_NUM_FRAMES, TSWAP_J0_FrameOk)

TSWAP_J0_FrameOk:
  TSWAP_ADVANCE_SEQ_END(TSWAP_J0_LoadFrameByIndex)

TSWAP_J0_LoadFrameByIndex:
  php
  sep #$20

  and.b #$07
  sta.w TSWAP_J0_LOAD_FRAME

  rep #$20
  lda.w #TSWAP_J0_FRAME_SIZE
  cmp.w #TSWAP_J0_DMA_SAFE_BYTES
  bcc TSWAP_J0_Load_Direct
  beq TSWAP_J0_Load_Direct
  jmp TSWAP_J0_Load_Chunked

TSWAP_J0_Load_Direct:
  sep #$20
  lda.w TSWAP_J0_LOAD_FRAME
  jsr TSWAP_J0_SetSourceByIndex

  stz.w TSWAP_J0_LOAD_ACTIVE
  stz.w TSWAP_J0_LOAD_DOUBLEBUF

  jsr TSWAP_J0_SetTargetFromActive

  rep #$20
  stz.w TSWAP_J0_LOAD_OFFSET
  lda.w #TSWAP_J0_FRAME_SIZE
  sta.w TSWAP_J0_TMP_DMA_SIZE

  jsr TSWAP_J0_DmaDirect
  jsr TSWAP_J0_CommitLoadedFrame

  plp
  rts

TSWAP_J0_Load_Chunked:
  sep #$20

  lda.w TSWAP_J0_INIT_DONE
  beq TSWAP_J0_Load_Chunked_First

  lda.w TSWAP_J0_DBLBUF_OK
  beq TSWAP_J0_Load_Chunked_NoDbl

  lda.w TSWAP_J0_ACTIVE_SLOT
  beq TSWAP_J0_Load_Chunked_ToSlot1

  TSWAP_J0_LOAD_CHUNKED_SET_TARGET_DBLBUF_ON(TSWAP_J0_SetTargetSlot0, TSWAP_J0_Load_Chunked_Setup)

TSWAP_J0_Load_Chunked_ToSlot1:
  TSWAP_J0_LOAD_CHUNKED_SET_TARGET_DBLBUF_ON(TSWAP_J0_SetTargetSlot1, TSWAP_J0_Load_Chunked_Setup)

TSWAP_J0_Load_Chunked_NoDbl:
  TSWAP_J0_LOAD_CHUNKED_SET_TARGET_DBLBUF_OFF(TSWAP_J0_SetTargetFromActive, TSWAP_J0_Load_Chunked_Setup)

TSWAP_J0_Load_Chunked_First:
  TSWAP_J0_LOAD_CHUNKED_SET_TARGET_DBLBUF_OFF(TSWAP_J0_SetTargetFromActive, TSWAP_J0_Load_Chunked_Setup)

TSWAP_J0_Load_Chunked_Setup:
  lda.b #$01
  sta.w TSWAP_J0_LOAD_ACTIVE

  rep #$20
  stz.w TSWAP_J0_LOAD_OFFSET
  lda.w #TSWAP_J0_FRAME_SIZE
  sta.w TSWAP_J0_LOAD_REMAIN

  jsr TSWAP_J0_ContinueLoad

  plp
  rts

TSWAP_J0_SetSourceByIndex:
  php
  rep #$30
  and.w #$00FF
  and.w #$0007
  asl
  tax
  jmp (TSWAP_J0_SetSrcJmpTable,x)

TSWAP_J0_SetSrcJmpTable:
  dw TSWAP_J0_SetSrcFR0
  dw TSWAP_J0_SetSrcFR1
  dw TSWAP_J0_SetSrcFR2
  dw TSWAP_J0_SetSrcFR3
  dw TSWAP_J0_SetSrcFR4
  dw TSWAP_J0_SetSrcFR5
  dw TSWAP_J0_SetSrcFR6
  dw TSWAP_J0_SetSrcFR7

TSWAP_J0_SetSrcFR0:
  TSWAP_J0_SET_SRC_BODY(TSWAP_JOB0_FR0)

TSWAP_J0_SetSrcFR1:
  TSWAP_J0_SET_SRC_BODY(TSWAP_JOB0_FR1)

TSWAP_J0_SetSrcFR2:
  TSWAP_J0_SET_SRC_BODY(TSWAP_JOB0_FR2)

TSWAP_J0_SetSrcFR3:
  TSWAP_J0_SET_SRC_BODY(TSWAP_JOB0_FR3)

TSWAP_J0_SetSrcFR4:
  TSWAP_J0_SET_SRC_BODY(TSWAP_JOB0_FR4)

TSWAP_J0_SetSrcFR5:
  TSWAP_J0_SET_SRC_BODY(TSWAP_JOB0_FR5)

TSWAP_J0_SetSrcFR6:
  TSWAP_J0_SET_SRC_BODY(TSWAP_JOB0_FR6)

TSWAP_J0_SetSrcFR7:
  TSWAP_J0_SET_SRC_BODY(TSWAP_JOB0_FR7)

TSWAP_J0_SetTargetFromActive:
  php
  sep #$20
  lda.w TSWAP_J0_ACTIVE_SLOT
  sta.w TSWAP_J0_TARGET_SLOT

  rep #$20
  lda.w TSWAP_J0_ACTIVE_VRAM
  sta.w TSWAP_J0_LOAD_VRAM
  lda.w TSWAP_J0_ACTIVE_BASE
  sta.w TSWAP_J0_TARGET_BASE

  plp
  rts

TSWAP_J0_SetTargetSlot0:
  php
  sep #$20
  stz.w TSWAP_J0_TARGET_SLOT

  lda.b #STAGE_TSWAP_JOB0_TARGET_BG
  cmp.b #$01
  beq TSWAP_J0_SetTargetSlot0_BG1
  jmp TSWAP_J0_SetTargetSlot0_BG2

TSWAP_J0_SetTargetSlot0_BG1:
  TSWAP_J0_SET_TARGET_CONST_AND_RETURN(TSWAP_J0_SLOT_BG1_VRAM, TSWAP_J0_BASE_TILE_BG1)

TSWAP_J0_SetTargetSlot0_BG2:
  TSWAP_J0_SET_TARGET_CONST_AND_RETURN(TSWAP_J0_SLOT_BG2_VRAM, TSWAP_J0_BASE_TILE_BG2)

TSWAP_J0_SetTargetSlot1:
  php
  sep #$20
  lda.b #$01
  sta.w TSWAP_J0_TARGET_SLOT

  lda.b #STAGE_TSWAP_JOB0_TARGET_BG
  cmp.b #$01
  beq TSWAP_J0_SetTargetSlot1_BG1
  jmp TSWAP_J0_SetTargetSlot1_BG2

TSWAP_J0_SetTargetSlot1_BG1:
  TSWAP_J0_SET_TARGET_CONST_AND_RETURN(TSWAP_SLOT1_BG1_VRAM, ((TSWAP_SLOT1_BG1_VRAM - VRAM_BG1_TILES) >> 5))

TSWAP_J0_SetTargetSlot1_BG2:
  TSWAP_J0_SET_TARGET_CONST_AND_RETURN(TSWAP_SLOT1_BG2_VRAM, ((TSWAP_SLOT1_BG2_VRAM - VRAM_BG2_TILES) >> 5))

TSWAP_J0_ContinueLoad:
  php
  rep #$20

  lda.w TSWAP_J0_LOAD_REMAIN
  cmp.w #TSWAP_J0_DMA_CHUNK_BYTES
  bcc TSWAP_J0_ContinueLoad_UseRemain
  beq TSWAP_J0_ContinueLoad_UseRemain

  lda.w #TSWAP_J0_DMA_CHUNK_BYTES
  sta.w TSWAP_J0_TMP_DMA_SIZE
  jmp TSWAP_J0_ContinueLoad_DoChunk

TSWAP_J0_ContinueLoad_UseRemain:
  lda.w TSWAP_J0_LOAD_REMAIN
  sta.w TSWAP_J0_TMP_DMA_SIZE

TSWAP_J0_ContinueLoad_DoChunk:
  jsr TSWAP_J0_DmaCurrentChunk

  lda.w TSWAP_J0_LOAD_OFFSET
  clc
  adc.w TSWAP_J0_TMP_DMA_SIZE
  sta.w TSWAP_J0_LOAD_OFFSET

  lda.w TSWAP_J0_LOAD_REMAIN
  sec
  sbc.w TSWAP_J0_TMP_DMA_SIZE
  sta.w TSWAP_J0_LOAD_REMAIN
  bne TSWAP_J0_ContinueLoad_Return

  sep #$20
  stz.w TSWAP_J0_LOAD_ACTIVE
  jsr TSWAP_J0_CommitLoadedFrame

TSWAP_J0_ContinueLoad_Return:
  plp
  rts

TSWAP_J0_DmaDirect:
  php

  rep #$20
  lda.w TSWAP_J0_LOAD_VRAM
  lsr
  sta.w TSWAP_TMP_ADDR

  lda.w TSWAP_J0_LOAD_SRC_LO
  sta.w TSWAP_J0_TMP_SRC_LO

  sep #$20
  lda.w TSWAP_J0_LOAD_SRC_BANK
  sta.w TSWAP_J0_TMP_SRC_BANK

  TSWAP_J0_DMA_KICK_FROM_TMPS()

  plp
  rts

TSWAP_J0_DmaCurrentChunk:
  php
  rep #$30

  lda.w TSWAP_J0_LOAD_VRAM
  clc
  adc.w TSWAP_J0_LOAD_OFFSET
  lsr
  sta.w TSWAP_TMP_ADDR

  lda.w TSWAP_J0_LOAD_FRAME
  and.w #$00FF
  asl
  tax

  lda.w TSWAP_J0_LOAD_OFFSET
  beq TSWAP_J0_DmaChunk_Offset0
  cmp.w #$0300
  beq TSWAP_J0_DmaChunk_Offset300
  jmp (TSWAP_J0_DmaChunk2Last_Table,x)

TSWAP_J0_DmaChunk_Offset0:
  jmp (TSWAP_J0_DmaChunk0_Table,x)

TSWAP_J0_DmaChunk_Offset300:
  lda.w TSWAP_J0_LOAD_REMAIN
  cmp.w #TSWAP_J0_DMA_CHUNK_BYTES
  bcc TSWAP_J0_DmaChunk_Offset300_Last
  jmp (TSWAP_J0_DmaChunk1Full_Table,x)

TSWAP_J0_DmaChunk_Offset300_Last:
  jmp (TSWAP_J0_DmaChunk1Last_Table,x)

TSWAP_J0_DmaPrepared:
  TSWAP_J0_DMA_KICK_FROM_TMPS()

  plp
  rts

TSWAP_J0_DmaChunk0_Table:
  dw TSWAP_J0_FR0_Chunk0
  dw TSWAP_J0_FR1_Chunk0
  dw TSWAP_J0_FR2_Chunk0
  dw TSWAP_J0_FR3_Chunk0
  dw TSWAP_J0_FR4_Chunk0
  dw TSWAP_J0_FR5_Chunk0
  dw TSWAP_J0_FR6_Chunk0
  dw TSWAP_J0_FR7_Chunk0

TSWAP_J0_DmaChunk1Full_Table:
  dw TSWAP_J0_FR0_Chunk1Full
  dw TSWAP_J0_FR1_Chunk1Full
  dw TSWAP_J0_FR2_Chunk1Full
  dw TSWAP_J0_FR3_Chunk1Full
  dw TSWAP_J0_FR4_Chunk1Full
  dw TSWAP_J0_FR5_Chunk1Full
  dw TSWAP_J0_FR6_Chunk1Full
  dw TSWAP_J0_FR7_Chunk1Full

TSWAP_J0_DmaChunk1Last_Table:
  dw TSWAP_J0_FR0_Chunk1Last
  dw TSWAP_J0_FR1_Chunk1Last
  dw TSWAP_J0_FR2_Chunk1Last
  dw TSWAP_J0_FR3_Chunk1Last
  dw TSWAP_J0_FR4_Chunk1Last
  dw TSWAP_J0_FR5_Chunk1Last
  dw TSWAP_J0_FR6_Chunk1Last
  dw TSWAP_J0_FR7_Chunk1Last

TSWAP_J0_DmaChunk2Last_Table:
  dw TSWAP_J0_FR0_Chunk2Last
  dw TSWAP_J0_FR1_Chunk2Last
  dw TSWAP_J0_FR2_Chunk2Last
  dw TSWAP_J0_FR3_Chunk2Last
  dw TSWAP_J0_FR4_Chunk2Last
  dw TSWAP_J0_FR5_Chunk2Last
  dw TSWAP_J0_FR6_Chunk2Last
  dw TSWAP_J0_FR7_Chunk2Last

TSWAP_J0_FR0_Chunk0:
  TSWAP_J0_DMA_PREP_AND_JMP(TSWAP_JOB0_FR0, $0300)

TSWAP_J0_FR1_Chunk0:
  TSWAP_J0_DMA_PREP_AND_JMP(TSWAP_JOB0_FR1, $0300)

TSWAP_J0_FR2_Chunk0:
  TSWAP_J0_DMA_PREP_AND_JMP(TSWAP_JOB0_FR2, $0300)

TSWAP_J0_FR3_Chunk0:
  TSWAP_J0_DMA_PREP_AND_JMP(TSWAP_JOB0_FR3, $0300)

TSWAP_J0_FR4_Chunk0:
  TSWAP_J0_DMA_PREP_AND_JMP(TSWAP_JOB0_FR4, $0300)

TSWAP_J0_FR5_Chunk0:
  TSWAP_J0_DMA_PREP_AND_JMP(TSWAP_JOB0_FR5, $0300)

TSWAP_J0_FR6_Chunk0:
  TSWAP_J0_DMA_PREP_AND_JMP(TSWAP_JOB0_FR6, $0300)

TSWAP_J0_FR7_Chunk0:
  TSWAP_J0_DMA_PREP_AND_JMP(TSWAP_JOB0_FR7, $0300)

TSWAP_J0_FR0_Chunk1Full:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR0 + $0300), $0300)

TSWAP_J0_FR1_Chunk1Full:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR1 + $0300), $0300)

TSWAP_J0_FR2_Chunk1Full:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR2 + $0300), $0300)

TSWAP_J0_FR3_Chunk1Full:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR3 + $0300), $0300)

TSWAP_J0_FR4_Chunk1Full:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR4 + $0300), $0300)

TSWAP_J0_FR5_Chunk1Full:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR5 + $0300), $0300)

TSWAP_J0_FR6_Chunk1Full:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR6 + $0300), $0300)

TSWAP_J0_FR7_Chunk1Full:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR7 + $0300), $0300)

TSWAP_J0_FR0_Chunk1Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR0 + $0300), (TSWAP_JOB0_FR0_End - (TSWAP_JOB0_FR0 + $0300)))

TSWAP_J0_FR1_Chunk1Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR1 + $0300), (TSWAP_JOB0_FR1_End - (TSWAP_JOB0_FR1 + $0300)))

TSWAP_J0_FR2_Chunk1Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR2 + $0300), (TSWAP_JOB0_FR2_End - (TSWAP_JOB0_FR2 + $0300)))

TSWAP_J0_FR3_Chunk1Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR3 + $0300), (TSWAP_JOB0_FR3_End - (TSWAP_JOB0_FR3 + $0300)))

TSWAP_J0_FR4_Chunk1Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR4 + $0300), (TSWAP_JOB0_FR4_End - (TSWAP_JOB0_FR4 + $0300)))

TSWAP_J0_FR5_Chunk1Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR5 + $0300), (TSWAP_JOB0_FR5_End - (TSWAP_JOB0_FR5 + $0300)))

TSWAP_J0_FR6_Chunk1Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR6 + $0300), (TSWAP_JOB0_FR6_End - (TSWAP_JOB0_FR6 + $0300)))

TSWAP_J0_FR7_Chunk1Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR7 + $0300), (TSWAP_JOB0_FR7_End - (TSWAP_JOB0_FR7 + $0300)))

TSWAP_J0_FR0_Chunk2Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR0 + $0600), (TSWAP_JOB0_FR0_End - (TSWAP_JOB0_FR0 + $0600)))

TSWAP_J0_FR1_Chunk2Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR1 + $0600), (TSWAP_JOB0_FR1_End - (TSWAP_JOB0_FR1 + $0600)))

TSWAP_J0_FR2_Chunk2Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR2 + $0600), (TSWAP_JOB0_FR2_End - (TSWAP_JOB0_FR2 + $0600)))

TSWAP_J0_FR3_Chunk2Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR3 + $0600), (TSWAP_JOB0_FR3_End - (TSWAP_JOB0_FR3 + $0600)))

TSWAP_J0_FR4_Chunk2Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR4 + $0600), (TSWAP_JOB0_FR4_End - (TSWAP_JOB0_FR4 + $0600)))

TSWAP_J0_FR5_Chunk2Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR5 + $0600), (TSWAP_JOB0_FR5_End - (TSWAP_JOB0_FR5 + $0600)))

TSWAP_J0_FR6_Chunk2Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR6 + $0600), (TSWAP_JOB0_FR6_End - (TSWAP_JOB0_FR6 + $0600)))

TSWAP_J0_FR7_Chunk2Last:
  TSWAP_J0_DMA_PREP_AND_JMP((TSWAP_JOB0_FR7 + $0600), (TSWAP_JOB0_FR7_End - (TSWAP_JOB0_FR7 + $0600)))

TSWAP_J0_CommitLoadedFrame:
  php

  sep #$20
  lda.w TSWAP_J0_INIT_DONE
  beq TSWAP_J0_Commit_DoPatch

  rep #$20
  lda.w TSWAP_J0_TARGET_BASE
  cmp.w TSWAP_J0_ACTIVE_BASE
  bne TSWAP_J0_Commit_DoPatchNow
  jmp TSWAP_J0_Commit_NoPatch

TSWAP_J0_Commit_DoPatch:
  jmp TSWAP_J0_Commit_DoPatchNow

TSWAP_J0_Commit_DoPatchNow:
  rep #$20
  lda.w TSWAP_J0_TARGET_BASE
  sta.w TSWAP_J0_PATCH_BASE

if STAGE_TSWAP_JOB0_TARGET_COUNT > 1 {
  sep #$20
  stz.w TSWAP_J0_PATCH_POS
  jsr TSWAP_J0_PatchTilemap_Continue
  jmp TSWAP_J0_Commit_NoPatch
}

  jsr TSWAP_J0_PatchTilemap

TSWAP_J0_Commit_NoPatch:
  sep #$20
  lda.w TSWAP_J0_TARGET_SLOT
  sta.w TSWAP_J0_ACTIVE_SLOT

  rep #$20
  lda.w TSWAP_J0_LOAD_VRAM
  sta.w TSWAP_J0_ACTIVE_VRAM
  lda.w TSWAP_J0_TARGET_BASE
  sta.w TSWAP_J0_ACTIVE_BASE

  sep #$20
  lda.b #$01
  sta.w TSWAP_J0_INIT_DONE
  stz.w TSWAP_J0_LOAD_DOUBLEBUF

  plp
  rts

if STAGE_TSWAP_JOB0_TARGET_COUNT > 1 {
TSWAP_J0_PatchTilemap_Continue:
  php
  sep #$20
  rep #$10

  lda.w TSWAP_J0_PATCH_POS
  cmp.b #STAGE_TSWAP_JOB0_TARGET_COUNT
  bcc TSWAP_J0_PatchCont_Do
  plp
  rts

TSWAP_J0_PatchCont_Do:
  lda.b #V_INC_1
  sta VMAIN

  rep #$20
  lda.w TSWAP_J0_PATCH_POS
  and.w #$00FF
  asl
  tax

  sep #$20
  lda.l Stage_TSwapJob0_Targets,x
  sta.w TSWAP_TMP_COL
  inx
  lda.l Stage_TSwapJob0_Targets,x
  sta.w TSWAP_TMP_ROW

  lda.b #STAGE_TSWAP_JOB0_TARGET_BG
  cmp.b #$01
  beq TSWAP_J0_PatchCont_BG1
  cmp.b #$02
  beq TSWAP_J0_PatchCont_BG2
  jmp TSWAP_J0_PatchCont_Inc

TSWAP_J0_PatchCont_BG1:
  jsr TSWAP_J0_BG1_PatchRect
  jmp TSWAP_J0_PatchCont_Inc

TSWAP_J0_PatchCont_BG2:
  jsr TSWAP_J0_BG2_PatchRect

TSWAP_J0_PatchCont_Inc:
  lda.w TSWAP_J0_PATCH_POS
  clc
  adc.b #$01
  sta.w TSWAP_J0_PATCH_POS

  plp
  rts
}

// -----------------------------------------------------------------------------
// Patch tilemap JOB0 (base dinâmica)
// -----------------------------------------------------------------------------
TSWAP_J0_PatchTilemap:
  TSWAP_PATCH_TILEMAP_ENTRY(STAGE_TSWAP_JOB0_TARGET_BG, TSWAP_J0_PatchBG1, TSWAP_J0_PatchBG2)

TSWAP_J0_PatchBG2:
  TSWAP_PATCH_TARGET_LOOP_BEGIN(STAGE_TSWAP_JOB0_TARGET_COUNT)

TSWAP_J0_BG2_TargetLoop:
  TSWAP_PATCH_TARGET_LOOP_BODY(Stage_TSwapJob0_Targets, TSWAP_J0_BG2_PatchRect, TSWAP_J0_BG2_TargetLoop)

TSWAP_J0_PatchBG1:
  TSWAP_PATCH_TARGET_LOOP_BEGIN(STAGE_TSWAP_JOB0_TARGET_COUNT)

TSWAP_J0_BG1_TargetLoop:
  TSWAP_PATCH_TARGET_LOOP_BODY(Stage_TSwapJob0_Targets, TSWAP_J0_BG1_PatchRect, TSWAP_J0_BG1_TargetLoop)

TSWAP_J0_BG2_PatchRect:
  TSWAP_PATCH_RECT_BEGIN(TSWAP_J0_PATCH_BASE)

TSWAP_J0_BG2_RowLoop:
  TSWAP_PATCH_RECT_ROW_LOOP_BODY(TSWAP_J0_BG2_PatchRow, STAGE_TSWAP_JOB0_H, TSWAP_J0_BG2_RowLoop)

TSWAP_J0_BG2_PatchRow:
  TSWAP_PATCH_ROW_BEGIN(STAGE_TSWAP_JOB0_W, TSWAP_J0_BG2_Seg1IsW, TSWAP_J0_BG2_DoSeg1)

TSWAP_J0_BG2_Seg1IsW:
  TSWAP_PATCH_ROW_SEG_NOSPLIT(STAGE_TSWAP_JOB0_W)

TSWAP_J0_BG2_DoSeg1:
  TSWAP_PATCH_ROW_DO_BOTH_SEGS(TSWAP_J0_BG2_RowDone, TSWAP_BG2_SetAddr_Seg1, TSWAP_J0_BG2_WriteSeg1, TSWAP_BG2_SetAddr_Seg2, TSWAP_J0_BG2_WriteSeg2)

TSWAP_J0_BG2_RowDone:
  TSWAP_PATCH_ROW_END()

TSWAP_J0_BG2_WriteSeg1:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG1)

TSWAP_J0_BG2_WriteSeg1Loop:
  TSWAP_WRITE_SEG_LOOP_BODY_MASKED($03FF, STAGE_TSWAP_JOB0_PAL_BITS, TSWAP_J0_BG2_WriteSeg1Loop)

TSWAP_J0_BG2_WriteSeg2:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG2)

TSWAP_J0_BG2_WriteSeg2Loop:
  TSWAP_WRITE_SEG_LOOP_BODY_MASKED($03FF, STAGE_TSWAP_JOB0_PAL_BITS, TSWAP_J0_BG2_WriteSeg2Loop)

TSWAP_J0_BG1_PatchRect:
  TSWAP_PATCH_RECT_BEGIN(TSWAP_J0_PATCH_BASE)

TSWAP_J0_BG1_RowLoop:
  TSWAP_PATCH_RECT_ROW_LOOP_BODY(TSWAP_J0_BG1_PatchRow, STAGE_TSWAP_JOB0_H, TSWAP_J0_BG1_RowLoop)

TSWAP_J0_BG1_PatchRow:
  TSWAP_PATCH_ROW_BEGIN(STAGE_TSWAP_JOB0_W, TSWAP_J0_BG1_Seg1IsW, TSWAP_J0_BG1_DoSeg1)

TSWAP_J0_BG1_Seg1IsW:
  TSWAP_PATCH_ROW_SEG_NOSPLIT(STAGE_TSWAP_JOB0_W)

TSWAP_J0_BG1_DoSeg1:
  TSWAP_PATCH_ROW_DO_BOTH_SEGS(TSWAP_J0_BG1_RowDone, TSWAP_BG1_SetAddr_Seg1, TSWAP_J0_BG1_WriteSeg1, TSWAP_BG1_SetAddr_Seg2, TSWAP_J0_BG1_WriteSeg2)

TSWAP_J0_BG1_RowDone:
  TSWAP_PATCH_ROW_END()

TSWAP_J0_BG1_WriteSeg1:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG1)

TSWAP_J0_BG1_WriteSeg1Loop:
  TSWAP_WRITE_SEG_LOOP_BODY_MASKED($03FF, STAGE_TSWAP_JOB0_PAL_BITS, TSWAP_J0_BG1_WriteSeg1Loop)

TSWAP_J0_BG1_WriteSeg2:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG2)

TSWAP_J0_BG1_WriteSeg2Loop:
  TSWAP_WRITE_SEG_LOOP_BODY_MASKED($03FF, STAGE_TSWAP_JOB0_PAL_BITS, TSWAP_J0_BG1_WriteSeg2Loop)

if STAGE_TSWAP_JOB1_ENABLE == 1 {
// ============================================================================
// JOB1 (igual ao que já funcionou: slot automático 0/1 + DMA dinâmico)
// ============================================================================
TSWAP_J1_Do:
  TSWAP_JOB_DO_FAIL_CHECK(TSWAP_J1_FAIL, TSWAP_J1_CheckInit)

TSWAP_J1_CheckInit:
  TSWAP_JOB_CHECK_INIT(TSWAP_J1_INIT_DONE, TSWAP_J1_Run, TSWAP_J1_FirstTime)

TSWAP_J1_Run:
  TSWAP_JOB_RUN_GAP_BLOCK(TSWAP_J1_GAP_CNT, TSWAP_J1_DELAY_CNT, TSWAP_J1_AdvanceSeqAndDma, TSWAP_J1_Run_NoGap, TSWAP_J1_Return)

TSWAP_J1_Run_NoGap:
  TSWAP_JOB_RUN_NOGAP_BLOCK(TSWAP_J1_DELAY_CNT, STAGE_TSWAP_JOB1_DELAY, STAGE_TSWAP_JOB1_GAP, TSWAP_J1_SEQ_POS, STAGE_TSWAP_JOB1_SEQ_LEN, TSWAP_J1_GAP_CNT, TSWAP_J1_DoAdvance, TSWAP_J1_Return)

TSWAP_J1_DoAdvance:
  jsr TSWAP_J1_AdvanceSeqAndDma

TSWAP_J1_Return:
  plp
  rts

TSWAP_J1_FirstTime:
  TSWAP_FIRSTTIME_INIT_SEQ(TSWAP_J1_SEQ_POS)
  TSWAP_FIRSTTIME_DISPATCH_BG(STAGE_TSWAP_JOB1_TARGET_BG, TSWAP_J1_First_BG1, TSWAP_J1_First_BG2, TSWAP_J1_First_Fail)

TSWAP_J1_First_BG1:
  TSWAP_J1_FIRST_PICK_FROM_JOB0($01, TSWAP_J1_BG1_UseSlot0, TSWAP_J1_BG1_UseSlot1)

TSWAP_J1_BG1_UseSlot0:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J1_SLOT0_BG1_END, VRAM_BG1_MAP, TSWAP_J1_BG1_SetSlot0, TSWAP_J1_First_Fail)

TSWAP_J1_BG1_SetSlot0:
  TSWAP_SLOT_SET_AND_JMP_OK(TSWAP_J1_SLOT0_BG1_VRAM, TSWAP_J1_BASE_TILE0_BG1, TSWAP_J1_SLOT_WORD, TSWAP_J1_BASE_TILE, TSWAP_J1_First_VramOk)

TSWAP_J1_BG1_UseSlot1:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J1_SLOT1_BG1_END, VRAM_BG1_MAP, TSWAP_J1_BG1_SetSlot1, TSWAP_J1_First_Fail)

TSWAP_J1_BG1_SetSlot1:
  TSWAP_SLOT_SET_AND_JMP_OK(TSWAP_J1_SLOT1_BG1_VRAM, TSWAP_J1_BASE_TILE1_BG1, TSWAP_J1_SLOT_WORD, TSWAP_J1_BASE_TILE, TSWAP_J1_First_VramOk)

TSWAP_J1_First_BG2:
  TSWAP_J1_FIRST_PICK_FROM_JOB0($02, TSWAP_J1_BG2_UseSlot0, TSWAP_J1_BG2_UseSlot1)

TSWAP_J1_BG2_UseSlot0:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J1_SLOT0_BG2_END, VRAM_BG2_MAP, TSWAP_J1_BG2_SetSlot0, TSWAP_J1_First_Fail)

TSWAP_J1_BG2_SetSlot0:
  TSWAP_SLOT_SET_AND_JMP_OK(TSWAP_J1_SLOT0_BG2_VRAM, TSWAP_J1_BASE_TILE0_BG2, TSWAP_J1_SLOT_WORD, TSWAP_J1_BASE_TILE, TSWAP_J1_First_VramOk)

TSWAP_J1_BG2_UseSlot1:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J1_SLOT1_BG2_END, VRAM_BG2_MAP, TSWAP_J1_BG2_SetSlot1, TSWAP_J1_First_Fail)

TSWAP_J1_BG2_SetSlot1:
  TSWAP_SLOT_SET_AND_JMP_OK(TSWAP_J1_SLOT1_BG2_VRAM, TSWAP_J1_BASE_TILE1_BG2, TSWAP_J1_SLOT_WORD, TSWAP_J1_BASE_TILE, TSWAP_J1_First_VramOk)

TSWAP_J1_First_Fail:
  TSWAP_FIRST_FAIL(TSWAP_J1_FAIL)

TSWAP_J1_First_VramOk:
  TSWAP_FIRST_VRAM_OK_BEGIN(TSWAP_J1_FAIL, Stage_TSwapJob1_Seq, STAGE_TSWAP_JOB1_NUM_FRAMES, TSWAP_J1_FirstFrameOk)
TSWAP_J1_FirstFrameOk:
  TSWAP_FIRST_VRAM_OK_END(TSWAP_J1_LoadFrameByIndex, TSWAP_J1_PatchTilemap, TSWAP_J1_INIT_DONE)

TSWAP_J1_AdvanceSeqAndDma:
  TSWAP_ADVANCE_SEQ_BEGIN(TSWAP_J1_SEQ_POS, STAGE_TSWAP_JOB1_SEQ_LEN, TSWAP_J1_SeqPosOk)
TSWAP_J1_SeqPosOk:
  TSWAP_ADVANCE_SEQ_LOAD_FRAME(TSWAP_J1_SEQ_POS, Stage_TSwapJob1_Seq, STAGE_TSWAP_JOB1_NUM_FRAMES, TSWAP_J1_FrameOk)
TSWAP_J1_FrameOk:
  TSWAP_ADVANCE_SEQ_END(TSWAP_J1_LoadFrameByIndex)

TSWAP_J1_LoadFrameByIndex:
  TSWAP_LOAD_FRAME_BY_INDEX_BODY(TSWAP_J1_LoadJmpTable)

TSWAP_J1_LoadJmpTable:
  TSWAP_LOAD_JMPTABLE_8(TSWAP_J1_LoadFR0, TSWAP_J1_LoadFR1, TSWAP_J1_LoadFR2, TSWAP_J1_LoadFR3, TSWAP_J1_LoadFR4, TSWAP_J1_LoadFR5, TSWAP_J1_LoadFR6, TSWAP_J1_LoadFR7)

TSWAP_J1_DmaToVram:
  TSWAP_DMA_TO_VRAM_BODY(TSWAP_J1_SLOT_WORD, TSWAP_J1_FRAME_SIZE)

TSWAP_J1_LoadFR0:
  TSWAP_LOADFR_BODY(TSWAP_JOB1_FR0, TSWAP_J1_DmaToVram)
TSWAP_J1_LoadFR1:
  TSWAP_LOADFR_BODY(TSWAP_JOB1_FR1, TSWAP_J1_DmaToVram)
TSWAP_J1_LoadFR2:
  TSWAP_LOADFR_BODY(TSWAP_JOB1_FR2, TSWAP_J1_DmaToVram)
TSWAP_J1_LoadFR3:
  TSWAP_LOADFR_BODY(TSWAP_JOB1_FR3, TSWAP_J1_DmaToVram)
TSWAP_J1_LoadFR4:
  TSWAP_LOADFR_BODY(TSWAP_JOB1_FR4, TSWAP_J1_DmaToVram)
TSWAP_J1_LoadFR5:
  TSWAP_LOADFR_BODY(TSWAP_JOB1_FR5, TSWAP_J1_DmaToVram)
TSWAP_J1_LoadFR6:
  TSWAP_LOADFR_BODY(TSWAP_JOB1_FR6, TSWAP_J1_DmaToVram)
TSWAP_J1_LoadFR7:
  TSWAP_LOADFR_BODY(TSWAP_JOB1_FR7, TSWAP_J1_DmaToVram)

TSWAP_J1_PatchTilemap:
  TSWAP_PATCH_TILEMAP_ENTRY(STAGE_TSWAP_JOB1_TARGET_BG, TSWAP_J1_PatchBG1, TSWAP_J1_PatchBG2)

TSWAP_J1_PatchBG2:
  TSWAP_PATCH_TARGET_LOOP_BEGIN(STAGE_TSWAP_JOB1_TARGET_COUNT)

TSWAP_J1_BG2_TargetLoop:
  TSWAP_PATCH_TARGET_LOOP_BODY(Stage_TSwapJob1_Targets, TSWAP_J1_BG2_PatchRect, TSWAP_J1_BG2_TargetLoop)

TSWAP_J1_PatchBG1:
  TSWAP_PATCH_TARGET_LOOP_BEGIN(STAGE_TSWAP_JOB1_TARGET_COUNT)

TSWAP_J1_BG1_TargetLoop:
  TSWAP_PATCH_TARGET_LOOP_BODY(Stage_TSwapJob1_Targets, TSWAP_J1_BG1_PatchRect, TSWAP_J1_BG1_TargetLoop)

TSWAP_J1_BG2_PatchRect:
  TSWAP_PATCH_RECT_BEGIN(TSWAP_J1_BASE_TILE)

TSWAP_J1_BG2_RowLoop:
  TSWAP_PATCH_RECT_ROW_LOOP_BODY(TSWAP_J1_BG2_PatchRow, STAGE_TSWAP_JOB1_H, TSWAP_J1_BG2_RowLoop)

TSWAP_J1_BG2_PatchRow:
  TSWAP_PATCH_ROW_BEGIN(STAGE_TSWAP_JOB1_W, TSWAP_J1_BG2_SegNoSplit, TSWAP_J1_BG2_DoSeg1)

TSWAP_J1_BG2_SegNoSplit:
  TSWAP_PATCH_ROW_SEG_NOSPLIT(STAGE_TSWAP_JOB1_W)

TSWAP_J1_BG2_DoSeg1:
  TSWAP_PATCH_ROW_DO_BOTH_SEGS(TSWAP_J1_BG2_RowDone, TSWAP_BG2_SetAddr_Seg1, TSWAP_J1_BG2_WriteSeg1, TSWAP_BG2_SetAddr_Seg2, TSWAP_J1_BG2_WriteSeg2)

TSWAP_J1_BG2_RowDone:
  TSWAP_PATCH_ROW_END()

TSWAP_J1_BG2_WriteSeg1:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG1)

TSWAP_J1_BG2_WriteSeg1Loop:
  TSWAP_WRITE_SEG_LOOP_BODY(STAGE_TSWAP_JOB1_PAL_BITS, TSWAP_J1_BG2_WriteSeg1Loop)

TSWAP_J1_BG2_WriteSeg2:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG2)

TSWAP_J1_BG2_WriteSeg2Loop:
  TSWAP_WRITE_SEG_LOOP_BODY(STAGE_TSWAP_JOB1_PAL_BITS, TSWAP_J1_BG2_WriteSeg2Loop)

TSWAP_J1_BG1_PatchRect:
  TSWAP_PATCH_RECT_BEGIN(TSWAP_J1_BASE_TILE)

TSWAP_J1_BG1_RowLoop:
  TSWAP_PATCH_RECT_ROW_LOOP_BODY(TSWAP_J1_BG1_PatchRow, STAGE_TSWAP_JOB1_H, TSWAP_J1_BG1_RowLoop)

TSWAP_J1_BG1_PatchRow:
  TSWAP_PATCH_ROW_BEGIN(STAGE_TSWAP_JOB1_W, TSWAP_J1_BG1_SegNoSplit, TSWAP_J1_BG1_DoSeg1)

TSWAP_J1_BG1_SegNoSplit:
  TSWAP_PATCH_ROW_SEG_NOSPLIT(STAGE_TSWAP_JOB1_W)

TSWAP_J1_BG1_DoSeg1:
  TSWAP_PATCH_ROW_DO_BOTH_SEGS(TSWAP_J1_BG1_RowDone, TSWAP_BG1_SetAddr_Seg1, TSWAP_J1_BG1_WriteSeg1, TSWAP_BG1_SetAddr_Seg2, TSWAP_J1_BG1_WriteSeg2)

TSWAP_J1_BG1_RowDone:
  TSWAP_PATCH_ROW_END()

TSWAP_J1_BG1_WriteSeg1:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG1)

TSWAP_J1_BG1_WriteSeg1Loop:
  TSWAP_WRITE_SEG_LOOP_BODY(STAGE_TSWAP_JOB1_PAL_BITS, TSWAP_J1_BG1_WriteSeg1Loop)

TSWAP_J1_BG1_WriteSeg2:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG2)

TSWAP_J1_BG1_WriteSeg2Loop:
  TSWAP_WRITE_SEG_LOOP_BODY(STAGE_TSWAP_JOB1_PAL_BITS, TSWAP_J1_BG1_WriteSeg2Loop)

} else {
TSWAP_J1_Do:
  plp
  rts
}

if STAGE_TSWAP_JOB2_ENABLE == 1 {
// ============================================================================
// JOB2 — slot automático 0/1 (fail com 2 conflitos) + DMA dinâmico
// ============================================================================
TSWAP_J2_Do:
  TSWAP_JOB_DO_FAIL_CHECK(TSWAP_J2_FAIL, TSWAP_J2_CheckInit)

TSWAP_J2_CheckInit:
  TSWAP_JOB_CHECK_INIT(TSWAP_J2_INIT_DONE, TSWAP_J2_Run, TSWAP_J2_FirstTime)

TSWAP_J2_Run:
  jsr TSWAP_J2_PatchTilemap_OneTarget
  TSWAP_JOB_RUN_GAP_BLOCK(TSWAP_J2_GAP_CNT, TSWAP_J2_DELAY_CNT, TSWAP_J2_AdvanceSeqAndDma, TSWAP_J2_Run_NoGap, TSWAP_J2_Return)

TSWAP_J2_Run_NoGap:
  TSWAP_JOB_RUN_NOGAP_BLOCK(TSWAP_J2_DELAY_CNT, STAGE_TSWAP_JOB2_DELAY, STAGE_TSWAP_JOB2_GAP, TSWAP_J2_SEQ_POS, STAGE_TSWAP_JOB2_SEQ_LEN, TSWAP_J2_GAP_CNT, TSWAP_J2_DoAdvance, TSWAP_J2_Return)

TSWAP_J2_DoAdvance:
  jsr TSWAP_J2_AdvanceSeqAndDma

TSWAP_J2_Return:
  plp
  rts

TSWAP_J2_FirstTime:
  TSWAP_FIRSTTIME_INIT_SEQ(TSWAP_J2_SEQ_POS)
  stz.w TSWAP_J2_PATCH_POS
  TSWAP_FIRSTTIME_DISPATCH_BG(STAGE_TSWAP_JOB2_TARGET_BG, TSWAP_J2_First_BG1_B, TSWAP_J2_First_BG2_B, TSWAP_J2_First_Fail)

TSWAP_J2_First_BG1_B:
  jmp TSWAP_J2_First_BG1

TSWAP_J2_First_BG2_B:
  jmp TSWAP_J2_First_BG2

TSWAP_J2_First_BG1:
  TSWAP_J2_RESET_AND_COUNT_JOB0_CONFLICT($01, TSWAP_J2_BG1_CheckJ1)

TSWAP_J2_BG1_CheckJ1:
  TSWAP_J2_COUNT_JOB1_CONFLICT($01, TSWAP_J2_BG1_Pick)

TSWAP_J2_BG1_Pick:
  TSWAP_J2_PICK_SLOT_BY_CONFLICT_MAX2(TSWAP_J2_BG1_UseSlot0, TSWAP_J2_BG1_UseSlot1, TSWAP_J2_First_Fail)

TSWAP_J2_BG1_UseSlot0:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J2_SLOT0_BG1_END, VRAM_BG1_MAP, TSWAP_J2_BG1_SetSlot0, TSWAP_J2_First_Fail)

TSWAP_J2_BG1_SetSlot0:
  TSWAP_SLOT_SET_AND_JMP_OK(TSWAP_J2_SLOT0_BG1_VRAM, TSWAP_J2_BASE_TILE0_BG1, TSWAP_J2_SLOT_WORD, TSWAP_J2_BASE_TILE, TSWAP_J2_First_VramOk)

TSWAP_J2_BG1_UseSlot1:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J2_SLOT1_BG1_END, VRAM_BG1_MAP, TSWAP_J2_BG1_SetSlot1, TSWAP_J2_First_Fail)

TSWAP_J2_BG1_SetSlot1:
  TSWAP_SLOT_SET_AND_JMP_OK(TSWAP_J2_SLOT1_BG1_VRAM, TSWAP_J2_BASE_TILE1_BG1, TSWAP_J2_SLOT_WORD, TSWAP_J2_BASE_TILE, TSWAP_J2_First_VramOk)

TSWAP_J2_First_BG2:
  TSWAP_J2_RESET_AND_COUNT_JOB0_CONFLICT($02, TSWAP_J2_BG2_CheckJ1)

TSWAP_J2_BG2_CheckJ1:
  TSWAP_J2_COUNT_JOB1_CONFLICT($02, TSWAP_J2_BG2_Pick)

TSWAP_J2_BG2_Pick:
  TSWAP_J2_PICK_SLOT_BY_CONFLICT_MAX2(TSWAP_J2_BG2_UseSlot0, TSWAP_J2_BG2_UseSlot1, TSWAP_J2_First_Fail)

TSWAP_J2_BG2_UseSlot0:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J2_SLOT0_BG2_END, VRAM_BG2_MAP, TSWAP_J2_BG2_SetSlot0, TSWAP_J2_First_Fail)

TSWAP_J2_BG2_SetSlot0:
  TSWAP_SLOT_SET_AND_JMP_OK(TSWAP_J2_SLOT0_BG2_VRAM, TSWAP_J2_BASE_TILE0_BG2, TSWAP_J2_SLOT_WORD, TSWAP_J2_BASE_TILE, TSWAP_J2_First_VramOk)

TSWAP_J2_BG2_UseSlot1:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J2_SLOT1_BG2_END, VRAM_BG2_MAP, TSWAP_J2_BG2_SetSlot1, TSWAP_J2_First_Fail)

TSWAP_J2_BG2_SetSlot1:
  TSWAP_SLOT_SET_AND_JMP_OK(TSWAP_J2_SLOT1_BG2_VRAM, TSWAP_J2_BASE_TILE1_BG2, TSWAP_J2_SLOT_WORD, TSWAP_J2_BASE_TILE, TSWAP_J2_First_VramOk)

TSWAP_J2_First_Fail:
  TSWAP_FIRST_FAIL(TSWAP_J2_FAIL)

TSWAP_J2_First_VramOk:
  TSWAP_FIRST_VRAM_OK_BEGIN(TSWAP_J2_FAIL, Stage_TSwapJob2_Seq, STAGE_TSWAP_JOB2_NUM_FRAMES, TSWAP_J2_FirstFrameOk)
TSWAP_J2_FirstFrameOk:
  jsr TSWAP_J2_LoadFrameByIndex
  lda.b #$01
  sta.w TSWAP_J2_INIT_DONE
  plp
  rts

TSWAP_J2_AdvanceSeqAndDma:
  TSWAP_ADVANCE_SEQ_BEGIN(TSWAP_J2_SEQ_POS, STAGE_TSWAP_JOB2_SEQ_LEN, TSWAP_J2_SeqPosOk)
TSWAP_J2_SeqPosOk:
  TSWAP_ADVANCE_SEQ_LOAD_FRAME(TSWAP_J2_SEQ_POS, Stage_TSwapJob2_Seq, STAGE_TSWAP_JOB2_NUM_FRAMES, TSWAP_J2_FrameOk)
TSWAP_J2_FrameOk:
  TSWAP_ADVANCE_SEQ_END(TSWAP_J2_LoadFrameByIndex)

TSWAP_J2_LoadFrameByIndex:
  TSWAP_LOAD_FRAME_BY_INDEX_BODY(TSWAP_J2_LoadJmpTable)

TSWAP_J2_LoadJmpTable:
  TSWAP_LOAD_JMPTABLE_8(TSWAP_J2_LoadFR0, TSWAP_J2_LoadFR1, TSWAP_J2_LoadFR2, TSWAP_J2_LoadFR3, TSWAP_J2_LoadFR4, TSWAP_J2_LoadFR5, TSWAP_J2_LoadFR6, TSWAP_J2_LoadFR7)

TSWAP_J2_DmaToVram:
  TSWAP_DMA_TO_VRAM_BODY(TSWAP_J2_SLOT_WORD, TSWAP_J2_FRAME_SIZE)

TSWAP_J2_LoadFR0:
  TSWAP_LOADFR_BODY(TSWAP_JOB2_FR0, TSWAP_J2_DmaToVram)
TSWAP_J2_LoadFR1:
  TSWAP_LOADFR_BODY(TSWAP_JOB2_FR1, TSWAP_J2_DmaToVram)
TSWAP_J2_LoadFR2:
  TSWAP_LOADFR_BODY(TSWAP_JOB2_FR2, TSWAP_J2_DmaToVram)
TSWAP_J2_LoadFR3:
  TSWAP_LOADFR_BODY(TSWAP_JOB2_FR3, TSWAP_J2_DmaToVram)
TSWAP_J2_LoadFR4:
  TSWAP_LOADFR_BODY(TSWAP_JOB2_FR4, TSWAP_J2_DmaToVram)
TSWAP_J2_LoadFR5:
  TSWAP_LOADFR_BODY(TSWAP_JOB2_FR5, TSWAP_J2_DmaToVram)
TSWAP_J2_LoadFR6:
  TSWAP_LOADFR_BODY(TSWAP_JOB2_FR6, TSWAP_J2_DmaToVram)
TSWAP_J2_LoadFR7:
  TSWAP_LOADFR_BODY(TSWAP_JOB2_FR7, TSWAP_J2_DmaToVram)

TSWAP_J2_PatchTilemap:
  TSWAP_PATCH_TILEMAP_ENTRY(STAGE_TSWAP_JOB2_TARGET_BG, TSWAP_J2_PatchBG1, TSWAP_J2_PatchBG2)

TSWAP_J2_PatchBG2:
  TSWAP_PATCH_TARGET_LOOP_BEGIN(STAGE_TSWAP_JOB2_TARGET_COUNT)

TSWAP_J2_BG2_TargetLoop:
  TSWAP_PATCH_TARGET_LOOP_BODY(Stage_TSwapJob2_Targets, TSWAP_J2_BG2_PatchRect, TSWAP_J2_BG2_TargetLoop)

TSWAP_J2_PatchBG1:
  TSWAP_PATCH_TARGET_LOOP_BEGIN(STAGE_TSWAP_JOB2_TARGET_COUNT)

TSWAP_J2_BG1_TargetLoop:
  TSWAP_PATCH_TARGET_LOOP_BODY(Stage_TSwapJob2_Targets, TSWAP_J2_BG1_PatchRect, TSWAP_J2_BG1_TargetLoop)

TSWAP_J2_PatchTilemap_OneTarget:
  php
  sep #$20
  rep #$10

  lda.b #V_INC_1
  sta VMAIN

  lda.w TSWAP_J2_PATCH_POS
  cmp.b #STAGE_TSWAP_JOB2_TARGET_COUNT
  bcc TSWAP_J2_PatchOne_IndexOk
  plp
  rts

TSWAP_J2_PatchOne_IndexOk:
  ldx.w #$0000
  asl
  tax

  lda.l Stage_TSwapJob2_Targets,x
  sta.w TSWAP_TMP_COL
  inx
  lda.l Stage_TSwapJob2_Targets,x
  sta.w TSWAP_TMP_ROW

  lda.b #STAGE_TSWAP_JOB2_TARGET_BG
  cmp.b #$01
  beq TSWAP_J2_PatchOne_BG1
  cmp.b #$02
  beq TSWAP_J2_PatchOne_BG2
  plp
  rts

TSWAP_J2_PatchOne_BG2:
  jsr TSWAP_J2_BG2_PatchRect
  jmp TSWAP_J2_PatchOne_Inc

TSWAP_J2_PatchOne_BG1:
  jsr TSWAP_J2_BG1_PatchRect

TSWAP_J2_PatchOne_Inc:
  inc.w TSWAP_J2_PATCH_POS
  plp
  rts

TSWAP_J2_BG2_PatchRect:
  TSWAP_PATCH_RECT_BEGIN(TSWAP_J2_BASE_TILE)

TSWAP_J2_BG2_RowLoop:
  TSWAP_PATCH_RECT_ROW_LOOP_BODY(TSWAP_J2_BG2_PatchRow, STAGE_TSWAP_JOB2_H, TSWAP_J2_BG2_RowLoop)

TSWAP_J2_BG2_PatchRow:
  TSWAP_PATCH_ROW_BEGIN(STAGE_TSWAP_JOB2_W, TSWAP_J2_BG2_SegNoSplit, TSWAP_J2_BG2_DoSeg1)

TSWAP_J2_BG2_SegNoSplit:
  TSWAP_PATCH_ROW_SEG_NOSPLIT(STAGE_TSWAP_JOB2_W)

TSWAP_J2_BG2_DoSeg1:
  TSWAP_PATCH_ROW_DO_BOTH_SEGS(TSWAP_J2_BG2_RowDone, TSWAP_BG2_SetAddr_Seg1, TSWAP_J2_BG2_WriteSeg1, TSWAP_BG2_SetAddr_Seg2, TSWAP_J2_BG2_WriteSeg2)

TSWAP_J2_BG2_RowDone:
  TSWAP_PATCH_ROW_END()

TSWAP_J2_BG2_WriteSeg1:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG1)

TSWAP_J2_BG2_WriteSeg1Loop:
  TSWAP_WRITE_SEG_LOOP_BODY(STAGE_TSWAP_JOB2_PAL_BITS, TSWAP_J2_BG2_WriteSeg1Loop)

TSWAP_J2_BG2_WriteSeg2:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG2)

TSWAP_J2_BG2_WriteSeg2Loop:
  TSWAP_WRITE_SEG_LOOP_BODY(STAGE_TSWAP_JOB2_PAL_BITS, TSWAP_J2_BG2_WriteSeg2Loop)

TSWAP_J2_BG1_PatchRect:
  TSWAP_PATCH_RECT_BEGIN(TSWAP_J2_BASE_TILE)

TSWAP_J2_BG1_RowLoop:
  TSWAP_PATCH_RECT_ROW_LOOP_BODY(TSWAP_J2_BG1_PatchRow, STAGE_TSWAP_JOB2_H, TSWAP_J2_BG1_RowLoop)

TSWAP_J2_BG1_PatchRow:
  TSWAP_PATCH_ROW_BEGIN(STAGE_TSWAP_JOB2_W, TSWAP_J2_BG1_SegNoSplit, TSWAP_J2_BG1_DoSeg1)

TSWAP_J2_BG1_SegNoSplit:
  TSWAP_PATCH_ROW_SEG_NOSPLIT(STAGE_TSWAP_JOB2_W)

TSWAP_J2_BG1_DoSeg1:
  TSWAP_PATCH_ROW_DO_BOTH_SEGS(TSWAP_J2_BG1_RowDone, TSWAP_BG1_SetAddr_Seg1, TSWAP_J2_BG1_WriteSeg1, TSWAP_BG1_SetAddr_Seg2, TSWAP_J2_BG1_WriteSeg2)

TSWAP_J2_BG1_RowDone:
  TSWAP_PATCH_ROW_END()

TSWAP_J2_BG1_WriteSeg1:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG1)

TSWAP_J2_BG1_WriteSeg1Loop:
  TSWAP_WRITE_SEG_LOOP_BODY(STAGE_TSWAP_JOB2_PAL_BITS, TSWAP_J2_BG1_WriteSeg1Loop)

TSWAP_J2_BG1_WriteSeg2:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG2)

TSWAP_J2_BG1_WriteSeg2Loop:
  TSWAP_WRITE_SEG_LOOP_BODY(STAGE_TSWAP_JOB2_PAL_BITS, TSWAP_J2_BG1_WriteSeg2Loop)

} else {
TSWAP_J2_Do:
  plp
  rts
}

if STAGE_TSWAP_JOB3_ENABLE == 1 {
// ============================================================================
// JOB3 — slot automático 0/1 + DMA dinâmico (limite: 2 jobs por BG)
// ============================================================================
TSWAP_J3_Do:
  TSWAP_JOB_DO_FAIL_CHECK(TSWAP_J3_FAIL, TSWAP_J3_CheckInit)

TSWAP_J3_CheckInit:
  TSWAP_JOB_CHECK_INIT(TSWAP_J3_INIT_DONE, TSWAP_J3_Run, TSWAP_J3_FirstTime)

TSWAP_J3_Run:
  jsr TSWAP_J3_PatchTilemap_OneTarget
  TSWAP_JOB_RUN_GAP_BLOCK(TSWAP_J3_GAP_CNT, TSWAP_J3_DELAY_CNT, TSWAP_J3_AdvanceSeqAndDma, TSWAP_J3_Run_NoGap, TSWAP_J3_Return)

TSWAP_J3_Run_NoGap:
  TSWAP_JOB_RUN_NOGAP_BLOCK(TSWAP_J3_DELAY_CNT, STAGE_TSWAP_JOB3_DELAY, STAGE_TSWAP_JOB3_GAP, TSWAP_J3_SEQ_POS, STAGE_TSWAP_JOB3_SEQ_LEN, TSWAP_J3_GAP_CNT, TSWAP_J3_DoAdvance, TSWAP_J3_Return)

TSWAP_J3_DoAdvance:
  jsr TSWAP_J3_AdvanceSeqAndDma

TSWAP_J3_Return:
  plp
  rts

TSWAP_J3_FirstTime:
  TSWAP_FIRSTTIME_INIT_SEQ(TSWAP_J3_SEQ_POS)
  stz.w TSWAP_J3_PATCH_POS
  TSWAP_FIRSTTIME_DISPATCH_BG(STAGE_TSWAP_JOB3_TARGET_BG, TSWAP_J3_First_BG1_B, TSWAP_J3_First_BG2_B, TSWAP_J3_First_Fail)

TSWAP_J3_First_BG1_B:
  jmp TSWAP_J3_First_BG1

TSWAP_J3_First_BG2_B:
  jmp TSWAP_J3_First_BG2

TSWAP_J3_First_BG1:
  TSWAP_J3_RESET_AND_COUNT_JOB0_CONFLICT($01, TSWAP_J3_BG1_CheckJ1)

TSWAP_J3_BG1_CheckJ1:
  TSWAP_J3_COUNT_JOB1_CONFLICT($01, TSWAP_J3_BG1_CheckJ2)

TSWAP_J3_BG1_CheckJ2:
  TSWAP_J3_COUNT_JOB2_CONFLICT($01, TSWAP_J3_BG1_Pick)

TSWAP_J3_BG1_Pick:
  TSWAP_J3_PICK_SLOT_BY_CONFLICT_MAX2(TSWAP_J3_BG1_UseSlot0, TSWAP_J3_BG1_UseSlot1, TSWAP_J3_First_Fail)

TSWAP_J3_BG1_UseSlot0:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J3_SLOT0_BG1_END, VRAM_BG1_MAP, TSWAP_J3_BG1_SetSlot0, TSWAP_J3_First_Fail)

TSWAP_J3_BG1_SetSlot0:
  TSWAP_SLOT_SET_AND_JMP_OK(TSWAP_J3_SLOT0_BG1_VRAM, TSWAP_J3_BASE_TILE0_BG1, TSWAP_J3_SLOT_WORD, TSWAP_J3_BASE_TILE, TSWAP_J3_First_VramOk)

TSWAP_J3_BG1_UseSlot1:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J3_SLOT1_BG1_END, VRAM_BG1_MAP, TSWAP_J3_BG1_SetSlot1, TSWAP_J3_First_Fail)

TSWAP_J3_BG1_SetSlot1:
  TSWAP_SLOT_SET_AND_JMP_OK(TSWAP_J3_SLOT1_BG1_VRAM, TSWAP_J3_BASE_TILE1_BG1, TSWAP_J3_SLOT_WORD, TSWAP_J3_BASE_TILE, TSWAP_J3_First_VramOk)

TSWAP_J3_First_BG2:
  TSWAP_J3_RESET_AND_COUNT_JOB0_CONFLICT($02, TSWAP_J3_BG2_CheckJ1)

TSWAP_J3_BG2_CheckJ1:
  TSWAP_J3_COUNT_JOB1_CONFLICT($02, TSWAP_J3_BG2_CheckJ2)

TSWAP_J3_BG2_CheckJ2:
  TSWAP_J3_COUNT_JOB2_CONFLICT($02, TSWAP_J3_BG2_Pick)

TSWAP_J3_BG2_Pick:
  TSWAP_J3_PICK_SLOT_BY_CONFLICT_MAX2(TSWAP_J3_BG2_UseSlot0, TSWAP_J3_BG2_UseSlot1, TSWAP_J3_First_Fail)

TSWAP_J3_BG2_UseSlot0:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J3_SLOT0_BG2_END, VRAM_BG2_MAP, TSWAP_J3_BG2_SetSlot0, TSWAP_J3_First_Fail)

TSWAP_J3_BG2_SetSlot0:
  TSWAP_SLOT_SET_AND_JMP_OK(TSWAP_J3_SLOT0_BG2_VRAM, TSWAP_J3_BASE_TILE0_BG2, TSWAP_J3_SLOT_WORD, TSWAP_J3_BASE_TILE, TSWAP_J3_First_VramOk)

TSWAP_J3_BG2_UseSlot1:
  TSWAP_SLOT_CHECK_OR_FAIL(TSWAP_J3_SLOT1_BG2_END, VRAM_BG2_MAP, TSWAP_J3_BG2_SetSlot1, TSWAP_J3_First_Fail)

TSWAP_J3_BG2_SetSlot1:
  TSWAP_SLOT_SET_AND_JMP_OK(TSWAP_J3_SLOT1_BG2_VRAM, TSWAP_J3_BASE_TILE1_BG2, TSWAP_J3_SLOT_WORD, TSWAP_J3_BASE_TILE, TSWAP_J3_First_VramOk)

TSWAP_J3_First_Fail:
  TSWAP_FIRST_FAIL(TSWAP_J3_FAIL)

TSWAP_J3_First_VramOk:
  TSWAP_FIRST_VRAM_OK_BEGIN(TSWAP_J3_FAIL, Stage_TSwapJob3_Seq, STAGE_TSWAP_JOB3_NUM_FRAMES, TSWAP_J3_FirstFrameOk)
TSWAP_J3_FirstFrameOk:
  jsr TSWAP_J3_LoadFrameByIndex
  lda.b #$01
  sta.w TSWAP_J3_INIT_DONE
  plp
  rts

TSWAP_J3_AdvanceSeqAndDma:
  TSWAP_ADVANCE_SEQ_BEGIN(TSWAP_J3_SEQ_POS, STAGE_TSWAP_JOB3_SEQ_LEN, TSWAP_J3_SeqPosOk)
TSWAP_J3_SeqPosOk:
  TSWAP_ADVANCE_SEQ_LOAD_FRAME(TSWAP_J3_SEQ_POS, Stage_TSwapJob3_Seq, STAGE_TSWAP_JOB3_NUM_FRAMES, TSWAP_J3_FrameOk)
TSWAP_J3_FrameOk:
  TSWAP_ADVANCE_SEQ_END(TSWAP_J3_LoadFrameByIndex)

TSWAP_J3_LoadFrameByIndex:
  TSWAP_LOAD_FRAME_BY_INDEX_BODY(TSWAP_J3_LoadJmpTable)

TSWAP_J3_LoadJmpTable:
  TSWAP_LOAD_JMPTABLE_8(TSWAP_J3_LoadFR0, TSWAP_J3_LoadFR1, TSWAP_J3_LoadFR2, TSWAP_J3_LoadFR3, TSWAP_J3_LoadFR4, TSWAP_J3_LoadFR5, TSWAP_J3_LoadFR6, TSWAP_J3_LoadFR7)

TSWAP_J3_DmaToVram:
  TSWAP_DMA_TO_VRAM_BODY(TSWAP_J3_SLOT_WORD, TSWAP_J3_FRAME_SIZE)

TSWAP_J3_LoadFR0:
  TSWAP_LOADFR_BODY(TSWAP_JOB3_FR0, TSWAP_J3_DmaToVram)
TSWAP_J3_LoadFR1:
  TSWAP_LOADFR_BODY(TSWAP_JOB3_FR1, TSWAP_J3_DmaToVram)
TSWAP_J3_LoadFR2:
  TSWAP_LOADFR_BODY(TSWAP_JOB3_FR2, TSWAP_J3_DmaToVram)
TSWAP_J3_LoadFR3:
  TSWAP_LOADFR_BODY(TSWAP_JOB3_FR3, TSWAP_J3_DmaToVram)
TSWAP_J3_LoadFR4:
  TSWAP_LOADFR_BODY(TSWAP_JOB3_FR4, TSWAP_J3_DmaToVram)
TSWAP_J3_LoadFR5:
  TSWAP_LOADFR_BODY(TSWAP_JOB3_FR5, TSWAP_J3_DmaToVram)
TSWAP_J3_LoadFR6:
  TSWAP_LOADFR_BODY(TSWAP_JOB3_FR6, TSWAP_J3_DmaToVram)
TSWAP_J3_LoadFR7:
  TSWAP_LOADFR_BODY(TSWAP_JOB3_FR7, TSWAP_J3_DmaToVram)

TSWAP_J3_PatchTilemap:
  TSWAP_PATCH_TILEMAP_ENTRY(STAGE_TSWAP_JOB3_TARGET_BG, TSWAP_J3_PatchBG1, TSWAP_J3_PatchBG2)

TSWAP_J3_PatchBG2:
  TSWAP_PATCH_TARGET_LOOP_BEGIN(STAGE_TSWAP_JOB3_TARGET_COUNT)

TSWAP_J3_BG2_TargetLoop:
  TSWAP_PATCH_TARGET_LOOP_BODY(Stage_TSwapJob3_Targets, TSWAP_J3_BG2_PatchRect, TSWAP_J3_BG2_TargetLoop)

TSWAP_J3_PatchBG1:
  TSWAP_PATCH_TARGET_LOOP_BEGIN(STAGE_TSWAP_JOB3_TARGET_COUNT)

TSWAP_J3_BG1_TargetLoop:
  TSWAP_PATCH_TARGET_LOOP_BODY(Stage_TSwapJob3_Targets, TSWAP_J3_BG1_PatchRect, TSWAP_J3_BG1_TargetLoop)

TSWAP_J3_PatchTilemap_OneTarget:
  php
  sep #$20
  rep #$10

  lda.b #V_INC_1
  sta VMAIN

  lda.w TSWAP_J3_PATCH_POS
  cmp.b #STAGE_TSWAP_JOB3_TARGET_COUNT
  bcc TSWAP_J3_PatchOne_IndexOk
  plp
  rts

TSWAP_J3_PatchOne_IndexOk:
  ldx.w #$0000
  asl
  tax

  lda.l Stage_TSwapJob3_Targets,x
  sta.w TSWAP_TMP_COL
  inx
  lda.l Stage_TSwapJob3_Targets,x
  sta.w TSWAP_TMP_ROW

  lda.b #STAGE_TSWAP_JOB3_TARGET_BG
  cmp.b #$01
  beq TSWAP_J3_PatchOne_BG1
  cmp.b #$02
  beq TSWAP_J3_PatchOne_BG2
  plp
  rts

TSWAP_J3_PatchOne_BG2:
  jsr TSWAP_J3_BG2_PatchRect
  jmp TSWAP_J3_PatchOne_Inc

TSWAP_J3_PatchOne_BG1:
  jsr TSWAP_J3_BG1_PatchRect

TSWAP_J3_PatchOne_Inc:
  inc.w TSWAP_J3_PATCH_POS
  plp
  rts

TSWAP_J3_BG2_PatchRect:
  TSWAP_PATCH_RECT_BEGIN(TSWAP_J3_BASE_TILE)

TSWAP_J3_BG2_RowLoop:
  TSWAP_PATCH_RECT_ROW_LOOP_BODY(TSWAP_J3_BG2_PatchRow, STAGE_TSWAP_JOB3_H, TSWAP_J3_BG2_RowLoop)

TSWAP_J3_BG2_PatchRow:
  TSWAP_PATCH_ROW_BEGIN(STAGE_TSWAP_JOB3_W, TSWAP_J3_BG2_SegNoSplit, TSWAP_J3_BG2_DoSeg1)

TSWAP_J3_BG2_SegNoSplit:
  TSWAP_PATCH_ROW_SEG_NOSPLIT(STAGE_TSWAP_JOB3_W)

TSWAP_J3_BG2_DoSeg1:
  TSWAP_PATCH_ROW_DO_BOTH_SEGS(TSWAP_J3_BG2_RowDone, TSWAP_BG2_SetAddr_Seg1, TSWAP_J3_BG2_WriteSeg1, TSWAP_BG2_SetAddr_Seg2, TSWAP_J3_BG2_WriteSeg2)

TSWAP_J3_BG2_RowDone:
  TSWAP_PATCH_ROW_END()

TSWAP_J3_BG2_WriteSeg1:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG1)

TSWAP_J3_BG2_WriteSeg1Loop:
  TSWAP_WRITE_SEG_LOOP_BODY(STAGE_TSWAP_JOB3_PAL_BITS, TSWAP_J3_BG2_WriteSeg1Loop)

TSWAP_J3_BG2_WriteSeg2:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG2)

TSWAP_J3_BG2_WriteSeg2Loop:
  TSWAP_WRITE_SEG_LOOP_BODY(STAGE_TSWAP_JOB3_PAL_BITS, TSWAP_J3_BG2_WriteSeg2Loop)

TSWAP_J3_BG1_PatchRect:
  TSWAP_PATCH_RECT_BEGIN(TSWAP_J3_BASE_TILE)

TSWAP_J3_BG1_RowLoop:
  TSWAP_PATCH_RECT_ROW_LOOP_BODY(TSWAP_J3_BG1_PatchRow, STAGE_TSWAP_JOB3_H, TSWAP_J3_BG1_RowLoop)

TSWAP_J3_BG1_PatchRow:
  TSWAP_PATCH_ROW_BEGIN(STAGE_TSWAP_JOB3_W, TSWAP_J3_BG1_SegNoSplit, TSWAP_J3_BG1_DoSeg1)

TSWAP_J3_BG1_SegNoSplit:
  TSWAP_PATCH_ROW_SEG_NOSPLIT(STAGE_TSWAP_JOB3_W)

TSWAP_J3_BG1_DoSeg1:
  TSWAP_PATCH_ROW_DO_BOTH_SEGS(TSWAP_J3_BG1_RowDone, TSWAP_BG1_SetAddr_Seg1, TSWAP_J3_BG1_WriteSeg1, TSWAP_BG1_SetAddr_Seg2, TSWAP_J3_BG1_WriteSeg2)

TSWAP_J3_BG1_RowDone:
  TSWAP_PATCH_ROW_END()

TSWAP_J3_BG1_WriteSeg1:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG1)

TSWAP_J3_BG1_WriteSeg1Loop:
  TSWAP_WRITE_SEG_LOOP_BODY(STAGE_TSWAP_JOB3_PAL_BITS, TSWAP_J3_BG1_WriteSeg1Loop)

TSWAP_J3_BG1_WriteSeg2:
  TSWAP_WRITE_SEG_BEGIN(TSWAP_TMP_SEG2)

TSWAP_J3_BG1_WriteSeg2Loop:
  TSWAP_WRITE_SEG_LOOP_BODY(STAGE_TSWAP_JOB3_PAL_BITS, TSWAP_J3_BG1_WriteSeg2Loop)

} else {
TSWAP_J3_Do:
  plp
  rts
}

// ============================================================================
// Shared SetAddr helpers
// ============================================================================
TSWAP_BG2_SetAddr_Seg1:
  php
  rep #$30

  lda.w #TSWAP_BG2_MAP_WORD
  sta.w TSWAP_TMP_ADDR

  lda.w TSWAP_TMP_ROWCUR
  and.w #$00FF
  asl
  asl
  asl
  asl
  asl
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR

  lda.w TSWAP_TMP_WITHIN
  and.w #$00FF
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR

  sep #$20
  lda.w TSWAP_TMP_COL
  and.b #$20
  beq TSWAP_BG2_Seg1_NoScreen

  rep #$20
  lda.w #$0400
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR
  sep #$20

TSWAP_BG2_Seg1_NoScreen:
  rep #$10
  ldx.w TSWAP_TMP_ADDR
  stx VMADDL

  plp
  rts

TSWAP_BG2_SetAddr_Seg2:
  php
  rep #$30

  sep #$20
  lda.w TSWAP_TMP_COL2
  and.b #$1F
  sta.w TSWAP_TMP_WITHIN

  rep #$20
  lda.w #TSWAP_BG2_MAP_WORD
  sta.w TSWAP_TMP_ADDR

  lda.w TSWAP_TMP_ROWCUR
  and.w #$00FF
  asl
  asl
  asl
  asl
  asl
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR

  lda.w TSWAP_TMP_WITHIN
  and.w #$00FF
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR

  sep #$20
  lda.w TSWAP_TMP_COL2
  and.b #$20
  beq TSWAP_BG2_Seg2_NoScreen

  rep #$20
  lda.w #$0400
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR
  sep #$20

TSWAP_BG2_Seg2_NoScreen:
  rep #$10
  ldx.w TSWAP_TMP_ADDR
  stx VMADDL

  plp
  rts

TSWAP_BG1_SetAddr_Seg1:
  php
  rep #$30

  lda.w #TSWAP_BG1_MAP_WORD
  sta.w TSWAP_TMP_ADDR

  sep #$20
  lda.w TSWAP_TMP_ROWCUR
  and.b #$20
  beq TSWAP_BG1_Seg1_NoScreenY

  rep #$20
  lda.w #$0800
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR
  sep #$20

TSWAP_BG1_Seg1_NoScreenY:
  lda.w TSWAP_TMP_ROWCUR
  and.b #$1F
  sta.w TSWAP_TMP_WITHIN

  rep #$20
  lda.w TSWAP_TMP_WITHIN
  and.w #$00FF
  asl
  asl
  asl
  asl
  asl
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR

  lda.w TSWAP_TMP_COL
  and.w #$001F
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR

  sep #$20
  lda.w TSWAP_TMP_COL
  and.b #$20
  beq TSWAP_BG1_Seg1_NoScreenX

  rep #$20
  lda.w #$0400
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR
  sep #$20

TSWAP_BG1_Seg1_NoScreenX:
  rep #$10
  ldx.w TSWAP_TMP_ADDR
  stx VMADDL

  plp
  rts

TSWAP_BG1_SetAddr_Seg2:
  php
  rep #$30

  lda.w #TSWAP_BG1_MAP_WORD
  sta.w TSWAP_TMP_ADDR

  sep #$20
  lda.w TSWAP_TMP_ROWCUR
  and.b #$20
  beq TSWAP_BG1_Seg2_NoScreenY

  rep #$20
  lda.w #$0800
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR
  sep #$20

TSWAP_BG1_Seg2_NoScreenY:
  lda.w TSWAP_TMP_ROWCUR
  and.b #$1F
  sta.w TSWAP_TMP_WITHIN

  rep #$20
  lda.w TSWAP_TMP_WITHIN
  and.w #$00FF
  asl
  asl
  asl
  asl
  asl
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR

  sep #$20
  lda.w TSWAP_TMP_COL2
  and.b #$1F
  sta.w TSWAP_TMP_WITHIN

  rep #$20
  lda.w TSWAP_TMP_WITHIN
  and.w #$00FF
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR

  sep #$20
  lda.w TSWAP_TMP_COL2
  and.b #$20
  beq TSWAP_BG1_Seg2_NoScreenX

  rep #$20
  lda.w #$0400
  clc
  adc.w TSWAP_TMP_ADDR
  sta.w TSWAP_TMP_ADDR
  sep #$20

TSWAP_BG1_Seg2_NoScreenX:
  rep #$10
  ldx.w TSWAP_TMP_ADDR
  stx VMADDL

  plp
  rts
