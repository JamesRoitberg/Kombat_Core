// game.asm
// -----------------------------------------------------------------------------
// Objetivo:
//   Inicialização padrão (Mode 1: BG1 + BG2) e engine de parallax/HDMA:
//
//   - Upload de VRAM (tiles + maps) e CGRAM (paletas).
//   - Setup de HDMA Mode 2 (direct) com 5 bandas por layer (BG1/BG2).
//   - (Opcional) Setup de degradê CGRAM via HDMA (CH2/CH3).
//   - Loop principal 60fps:
//       * (opcional) Input_FrameTick        -> pode mover BG1_WORLDX (stage)
//       * UpdateScrollParallax              -> calcula HOFS/VOFS por banda (WRAM)
//       * WAI                               -> espera NMI/VBlank
//       * (opcional) StageAnim_NmiTick      -> ajustes por cenário (ex.: nuvens)
//       * Atualiza payload das tabelas HDMA (lo/hi) a partir dos words por banda
//
// Depende de:
//   - regs.asm      (PPU/CPU regs + layout WRAM + HDMA table addrs)
//   - config.asm    (layout de VRAM do stage + flags + offsets)
//   - macros.asm    (DmaToVram, DMA_CGRAM, WRITE_CGRAM_COLOR, HDMA_* helpers)
//   - parallax.asm  (UpdateScrollParallax)
//   - input.asm     (Input_FrameTick)
//   - animation.asm (StageAnim_NmiTick)
//
// Flags por cenário (config.asm):
//   - STAGE_ENABLE_GRADIENT  (0/1)  -> habilita tabelas + canais CH2/CH3
//   - STAGE_ENABLE_INPUT     (0/1)  -> chama Input_FrameTick no loop
//   - STAGE_ENABLE_ANIM      (0/1)  -> chama StageAnim_NmiTick após WAI
//
// Notas importantes:
//   - Writes em $21xx sempre em A8.
//   - Zerar words em WRAM: usar REP #$20 + STZ VAR (não usar VAR+1 em A16).
//   - $420C (HDMAEN) é write-only: não faça read-modify-write.
//   - Input pode mover BG1_WORLDX quando STAGE_INPUT_DRIVE_WORLDX=1.
// -----------------------------------------------------------------------------

// ============================================================================
// Main
// ============================================================================
Main:
  // CPU state: A8 para PPU ($21xx), X/Y16 para DMA pointers/length
  sep #$20
  rep #$10

  // DBR = banco do código
  // Obs: WRAM $0000-$1FFF é espelhada, então acesso às vars $01xx continua ok.
  phk
  plb

  // Desliga NMI/IRQ/HDMA durante init
  stz NMITIMEN        // $4200
  stz HDMAEN          // $420C

  // Forced blank durante uploads
  lda.b #FORCE_BLANK
  sta INIDISP         // $2100

  // Mode 1 (BG1/BG2 4bpp)
  lda.b #$01
  sta BGMODE          // $2105

  // Base de tiles (CHR) BG1/BG2 em VRAM
  lda.b #REG_BG12NBA
  sta BG12NBA         // $210B

  // Base de tilemap + size
  lda.b #REG_BG1SC
  sta BG1SC           // $2107

  lda.b #REG_BG2SC
  sta BG2SC           // $2108

  // VRAM increment (garantia)
  lda.b #V_INC_1
  sta VMAIN           // $2115

  // Scroll inicial no PPU (writes duplos)
  stz BG1HOFS
  stz BG1HOFS
  stz BG1VOFS
  stz BG1VOFS

  stz BG2HOFS
  stz BG2HOFS
  lda.b #(STAGE_BG2_Y_OFFSET & $00FF)
  sta BG2VOFS
  lda.b #((STAGE_BG2_Y_OFFSET >> 8) & $00FF)
  sta BG2VOFS

  // --------------------------------------------------------------------------
  // Upload VRAM (tiles + tilemaps)
  // --------------------------------------------------------------------------
  DmaToVram(VRAM_BG1_TILES, BG1_Tiles, BG1_Tiles_End)
  DmaToVram(VRAM_BG1_MAP,   BG1_Map,   BG1_Map_End)
  DmaToVram(VRAM_BG2_TILES, BG2_Tiles, BG2_Tiles_End)
  DmaToVram(VRAM_BG2_MAP,   BG2_Map,   BG2_Map_End)

  // --------------------------------------------------------------------------
  // Upload CGRAM (paletas e cor 0 do fundo do Bg)
  // --------------------------------------------------------------------------
  // Cor 0 vem do contrato do stage (STAGE_BACKDROP_COLOR0)
  WRITE_CGRAM_COLOR(0, STAGE_BACKDROP_COLOR0)
  DMA_CGRAM(STAGE_BG1_CGADD, BG1_Palette, (BG1_Palette_End - BG1_Palette))
  DMA_CGRAM(STAGE_BG2_CGADD, BG2_Palette, (BG2_Palette_End - BG2_Palette))

  // Liga BG1+BG2 no main screen
  lda.b #BG12_ON
  sta TM              // $212C

  // --------------------------------------------------------------------------
  // Zera variáveis WRAM (tudo word)
  // --------------------------------------------------------------------------
  rep #$20

    stz BG1_HOFS
    stz BG1_VOFS
    stz BG2_HOFS
    stz BG1_WORLDX

    stz BG1_HOFS_B0
    stz BG1_HOFS_B1
    stz BG1_HOFS_B2
    stz BG1_HOFS_B3
    stz BG1_HOFS_B4

    stz BG1_VOFS_B0
    stz BG1_VOFS_B1
    stz BG1_VOFS_B2
    stz BG1_VOFS_B3
    stz BG1_VOFS_B4

    stz BG2_HOFS_B0
    stz BG2_HOFS_B1
    stz BG2_HOFS_B2
    stz BG2_HOFS_B3
    stz BG2_HOFS_B4

    stz BG2_VOFS_B0
    stz BG2_VOFS_B1
    stz BG2_VOFS_B2
    stz BG2_VOFS_B3
    stz BG2_VOFS_B4

  // --------------------------------------------------------------------------
  // Monta tabelas HDMA (Mode 2 direct)
  // Formato: [count][lo][hi] x5, [00] end
  // --------------------------------------------------------------------------
  HDMA_TABLE_INIT_5BANDS(HDMA_BG1HOFS_TABLE, BG1_BAND0_LINES, BG1_BAND1_LINES, BG1_BAND2_LINES, BG1_BAND3_LINES, BG1_BAND4_LINES)
  HDMA_TABLE_INIT_5BANDS(HDMA_BG1VOFS_TABLE, BG1_BAND0_LINES, BG1_BAND1_LINES, BG1_BAND2_LINES, BG1_BAND3_LINES, BG1_BAND4_LINES)

  HDMA_TABLE_INIT_5BANDS(HDMA_BG2HOFS_TABLE, BG2_BAND0_LINES, BG2_BAND1_LINES, BG2_BAND2_LINES, BG2_BAND3_LINES, BG2_BAND4_LINES)

  // --------------------------------------------------------------------------
  // CGRAM gradient opcional (controlado por STAGE_ENABLE_GRADIENT)
  // - Monta tabelas em WRAM (HDMA_CGRAM_*) e configura CH2/CH3 se ligado.
  // - Importante: branch curto (BNE) + JMP para evitar out-of-bounds.
  // --------------------------------------------------------------------------
  sep #$20
  lda.b #STAGE_ENABLE_GRADIENT
  bne Main_DoGradient
  jmp Main_SkipGradient

Main_DoGradient:
  CGRAM_GRAD_BUILD_TABLES()

  // CH2 -> $2121 (CGADD), Mode 0 direct
  HDMA_SETUP_MODE0_DIRECT($4320, $21, HDMA_CGRAM_CGADD_TABLE)
  // CH3 -> $2122 (CGDATA), Mode 2 direct (2 bytes/line)
  HDMA_SETUP_MODE2_DIRECT($4330, $22, HDMA_CGRAM_CGDATA_TABLE)

Main_SkipGradient:

  // --------------------------------------------------------------------------
  // Setup HDMA scroll/parallax (sempre)
  // - CH5: BG1VOFS ($210E)
  // - CH6: BG1HOFS ($210D)
  // - CH7: BG2HOFS ($210F)
  // - BG2VOFS ($2110) fica fixo (sem HDMA) para liberar CH4
  // --------------------------------------------------------------------------
  HDMA_SETUP_MODE2_DIRECT($4350, $0E, HDMA_BG1VOFS_TABLE)        // CH5
  HDMA_SETUP_MODE2_DIRECT($4360, $0D, HDMA_BG1HOFS_TABLE)        // CH6
  HDMA_SETUP_MODE2_DIRECT($4370, $0F, HDMA_BG2HOFS_TABLE)        // CH7

WaitVBlank_EnableHDMA:
  sep #$20
  lda HVBJOY
  bpl WaitVBlank_EnableHDMA

  // --------------------------------------------------------------------------
  // Habilita HDMA conforme gradient
  // --------------------------------------------------------------------------
  sep #$20
  lda.b #STAGE_ENABLE_GRADIENT
  bne Main_EnableHDMA_WithGrad
  jmp Main_EnableHDMA_ScrollOnly

Main_EnableHDMA_WithGrad:
  lda.b #STAGE_HDMAEN_MASK_SCROLL_PLUS_GRAD
  sta HDMAEN
  jmp Main_EnableHDMA_Done

Main_EnableHDMA_ScrollOnly:
  lda.b #STAGE_HDMAEN_MASK_SCROLL_ONLY
  sta HDMAEN

Main_EnableHDMA_Done:

  // Sai do forced blank
  lda.b #FULL_BRIGHT
  sta INIDISP               // $2100

  // Habilita NMI (VBlank) e limpa latch
  lda RDNMI                 // ACK/clear NMI flag
  lda.b #NMI_ON
  sta NMITIMEN
  stz LAST_NMI

  jmp Infinite_Loop

// ============================================================================
// Loop principal (60fps)
// ============================================================================
Infinite_Loop:
  // Normaliza estado (evita depender do que macros deixaram)
  sep #$20
  rep #$10

  // --------------------------------------------------------------------------
  // 1) Input (opcional)
  // --------------------------------------------------------------------------
  sep #$20
  lda.b #STAGE_ENABLE_INPUT
  bne Loop_DoInput
  jmp Loop_AfterInput

Loop_DoInput:
  jsr Input_FrameTick

Loop_AfterInput:

  // --------------------------------------------------------------------------
  // 2) Calcula parallax (WRAM -> words por banda)
  // --------------------------------------------------------------------------
  jsr UpdateScrollParallax

  // --------------------------------------------------------------------------
  // 3) Espera NMI/VBlank (NMI escreve HOFS/VOFS base e faz ACK)
  // --------------------------------------------------------------------------
  wai

  // --------------------------------------------------------------------------
  // 4) Stage animation (opcional) - roda 1x por frame após voltar do NMI
  // --------------------------------------------------------------------------
  sep #$20
  lda.b #STAGE_ENABLE_ANIM
  bne Loop_DoAnim
  jmp Loop_AfterAnim

Loop_DoAnim:
  jsr StageAnim_NmiTick

Loop_AfterAnim:

  // --------------------------------------------------------------------------
  // 5) Atualiza payload HDMA (lo/hi) a partir dos words por banda
  // --------------------------------------------------------------------------
  HDMA_TABLE_UPDATE_5BANDS_FROM_WORDS(HDMA_BG1HOFS_TABLE, BG1_HOFS_B0, BG1_HOFS_B1, BG1_HOFS_B2, BG1_HOFS_B3, BG1_HOFS_B4)
  HDMA_TABLE_UPDATE_5BANDS_FROM_WORDS(HDMA_BG1VOFS_TABLE, BG1_VOFS_B0, BG1_VOFS_B1, BG1_VOFS_B2, BG1_VOFS_B3, BG1_VOFS_B4)

  HDMA_TABLE_UPDATE_5BANDS_FROM_WORDS(HDMA_BG2HOFS_TABLE, BG2_HOFS_B0, BG2_HOFS_B1, BG2_HOFS_B2, BG2_HOFS_B3, BG2_HOFS_B4)

  jmp Infinite_Loop
