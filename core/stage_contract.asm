// core/stage_contract.asm
// -----------------------------------------------------------------------------
// Contrato de stage consumido pelo core (validação compile-time).
//
// Contrato base (sempre obrigatório):
// - Assets BG1/BG2 (palette/tiles/map)
// - STAGE_BG1_CGADD / STAGE_BG2_CGADD
// - STAGE_BACKDROP_COLOR0
// - STAGE_TSWAP_ENABLE
// - Layout de VRAM do stage (VRAM_BG*)
// - Registradores de setup PPU do stage (REG_BG*)
//
// Contrato de TileSwap:
// - So e validado quando STAGE_TSWAP_ENABLE == 1
// - A validacao e granular por job habilitado (STAGE_TSWAP_JOBN_ENABLE == 1)
// - Cada job ativo precisa expor Seq, Targets, FR0..FR7 e os labels End
//   consumidos pelo tileswap.asm
// -----------------------------------------------------------------------------

// ============================================================================
// Labels obrigatórias de assets do stage
// ============================================================================
constant STAGE_CONTRACT_REQ_BG1_PAL      = BG1_Palette
constant STAGE_CONTRACT_REQ_BG1_PAL_END  = BG1_Palette_End
constant STAGE_CONTRACT_REQ_BG1_TILES    = BG1_Tiles
constant STAGE_CONTRACT_REQ_BG1_TILES_END = BG1_Tiles_End
constant STAGE_CONTRACT_REQ_BG1_MAP      = BG1_Map
constant STAGE_CONTRACT_REQ_BG1_MAP_END  = BG1_Map_End

constant STAGE_CONTRACT_REQ_BG2_PAL      = BG2_Palette
constant STAGE_CONTRACT_REQ_BG2_PAL_END  = BG2_Palette_End
constant STAGE_CONTRACT_REQ_BG2_TILES    = BG2_Tiles
constant STAGE_CONTRACT_REQ_BG2_TILES_END = BG2_Tiles_End
constant STAGE_CONTRACT_REQ_BG2_MAP      = BG2_Map
constant STAGE_CONTRACT_REQ_BG2_MAP_END  = BG2_Map_End

// ============================================================================
// Constantes obrigatórias para init do core
// ============================================================================
constant STAGE_CONTRACT_REQ_BG1_CGADD     = STAGE_BG1_CGADD
constant STAGE_CONTRACT_REQ_BG2_CGADD     = STAGE_BG2_CGADD
constant STAGE_CONTRACT_REQ_BACKDROP_COLOR = STAGE_BACKDROP_COLOR0
constant STAGE_CONTRACT_REQ_TSWAP_FLAG    = STAGE_TSWAP_ENABLE

// Layout de VRAM por stage (endereços e bytes de setup PPU)
constant STAGE_CONTRACT_REQ_VRAM_BG1_TILES = VRAM_BG1_TILES
constant STAGE_CONTRACT_REQ_VRAM_BG1_MAP   = VRAM_BG1_MAP
constant STAGE_CONTRACT_REQ_VRAM_BG2_TILES = VRAM_BG2_TILES
constant STAGE_CONTRACT_REQ_VRAM_BG2_MAP   = VRAM_BG2_MAP
constant STAGE_CONTRACT_REQ_REG_BG12NBA    = REG_BG12NBA
constant STAGE_CONTRACT_REQ_REG_BG1SC      = REG_BG1SC
constant STAGE_CONTRACT_REQ_REG_BG2SC      = REG_BG2SC

// ============================================================================
// Contrato de TileSwap
// - So e validado quando STAGE_TSWAP_ENABLE=1
// ============================================================================
if STAGE_TSWAP_ENABLE == 1 {
  if STAGE_TSWAP_JOB0_ENABLE == 1 {
    constant STAGE_CONTRACT_REQ_TSWAP_J0_SEQ     = Stage_TSwapJob0_Seq
    constant STAGE_CONTRACT_REQ_TSWAP_J0_TARGETS = Stage_TSwapJob0_Targets

    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR0 = TSWAP_JOB0_FR0
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR1 = TSWAP_JOB0_FR1
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR2 = TSWAP_JOB0_FR2
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR3 = TSWAP_JOB0_FR3
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR4 = TSWAP_JOB0_FR4
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR5 = TSWAP_JOB0_FR5
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR6 = TSWAP_JOB0_FR6
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR7 = TSWAP_JOB0_FR7

    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR0_END = TSWAP_JOB0_FR0_End
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR1_END = TSWAP_JOB0_FR1_End
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR2_END = TSWAP_JOB0_FR2_End
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR3_END = TSWAP_JOB0_FR3_End
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR4_END = TSWAP_JOB0_FR4_End
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR5_END = TSWAP_JOB0_FR5_End
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR6_END = TSWAP_JOB0_FR6_End
    constant STAGE_CONTRACT_REQ_TSWAP_J0_FR7_END = TSWAP_JOB0_FR7_End
  }

  if STAGE_TSWAP_JOB1_ENABLE == 1 {
    constant STAGE_CONTRACT_REQ_TSWAP_J1_SEQ     = Stage_TSwapJob1_Seq
    constant STAGE_CONTRACT_REQ_TSWAP_J1_TARGETS = Stage_TSwapJob1_Targets

    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR0 = TSWAP_JOB1_FR0
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR1 = TSWAP_JOB1_FR1
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR2 = TSWAP_JOB1_FR2
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR3 = TSWAP_JOB1_FR3
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR4 = TSWAP_JOB1_FR4
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR5 = TSWAP_JOB1_FR5
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR6 = TSWAP_JOB1_FR6
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR7 = TSWAP_JOB1_FR7

    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR0_END = TSWAP_JOB1_FR0_End
  }

  if STAGE_TSWAP_JOB2_ENABLE == 1 {
    constant STAGE_CONTRACT_REQ_TSWAP_J2_SEQ     = Stage_TSwapJob2_Seq
    constant STAGE_CONTRACT_REQ_TSWAP_J2_TARGETS = Stage_TSwapJob2_Targets

    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR0 = TSWAP_JOB2_FR0
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR1 = TSWAP_JOB2_FR1
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR2 = TSWAP_JOB2_FR2
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR3 = TSWAP_JOB2_FR3
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR4 = TSWAP_JOB2_FR4
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR5 = TSWAP_JOB2_FR5
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR6 = TSWAP_JOB2_FR6
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR7 = TSWAP_JOB2_FR7

    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR0_END = TSWAP_JOB2_FR0_End
  }

  if STAGE_TSWAP_JOB3_ENABLE == 1 {
    constant STAGE_CONTRACT_REQ_TSWAP_J3_SEQ     = Stage_TSwapJob3_Seq
    constant STAGE_CONTRACT_REQ_TSWAP_J3_TARGETS = Stage_TSwapJob3_Targets

    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR0 = TSWAP_JOB3_FR0
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR1 = TSWAP_JOB3_FR1
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR2 = TSWAP_JOB3_FR2
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR3 = TSWAP_JOB3_FR3
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR4 = TSWAP_JOB3_FR4
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR5 = TSWAP_JOB3_FR5
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR6 = TSWAP_JOB3_FR6
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR7 = TSWAP_JOB3_FR7

    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR0_END = TSWAP_JOB3_FR0_End
  }
}
