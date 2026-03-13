// core/stage_contract.asm
// -----------------------------------------------------------------------------
// Contrato de stage consumido pelo core (validacao compile-time).
//
// Contrato base (sempre obrigatorio):
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
// - Para cada job ativo, o contrato tambem valida:
//   - FR0 com tamanho exato de (W * H * 32) bytes
//   - FR1..FR7 com mesmo tamanho de FR0 quando o frame estiver em uso
// -----------------------------------------------------------------------------

// ============================================================================
// Labels obrigatorias de assets do stage
// ============================================================================
constant STAGE_CONTRACT_REQ_BG1_PAL       = BG1_Palette
constant STAGE_CONTRACT_REQ_BG1_PAL_END   = BG1_Palette_End
constant STAGE_CONTRACT_REQ_BG1_TILES     = BG1_Tiles
constant STAGE_CONTRACT_REQ_BG1_TILES_END = BG1_Tiles_End
constant STAGE_CONTRACT_REQ_BG1_MAP       = BG1_Map
constant STAGE_CONTRACT_REQ_BG1_MAP_END   = BG1_Map_End

constant STAGE_CONTRACT_REQ_BG2_PAL       = BG2_Palette
constant STAGE_CONTRACT_REQ_BG2_PAL_END   = BG2_Palette_End
constant STAGE_CONTRACT_REQ_BG2_TILES     = BG2_Tiles
constant STAGE_CONTRACT_REQ_BG2_TILES_END = BG2_Tiles_End
constant STAGE_CONTRACT_REQ_BG2_MAP       = BG2_Map
constant STAGE_CONTRACT_REQ_BG2_MAP_END   = BG2_Map_End

// ============================================================================
// Constantes obrigatorias para init do core
// ============================================================================
constant STAGE_CONTRACT_REQ_BG1_CGADD      = STAGE_BG1_CGADD
constant STAGE_CONTRACT_REQ_BG2_CGADD      = STAGE_BG2_CGADD
constant STAGE_CONTRACT_REQ_BACKDROP_COLOR = STAGE_BACKDROP_COLOR0
constant STAGE_CONTRACT_REQ_TSWAP_FLAG     = STAGE_TSWAP_ENABLE

// Layout de VRAM por stage (enderecos e bytes de setup PPU)
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

    constant STAGE_CONTRACT_TSWAP_J0_FRAME_BYTES = (TSWAP_JOB0_FR0_End - TSWAP_JOB0_FR0)
    constant STAGE_CONTRACT_TSWAP_J0_EXPECTED_BYTES = (STAGE_TSWAP_JOB0_W * STAGE_TSWAP_JOB0_H * 32)

    if STAGE_CONTRACT_TSWAP_J0_FRAME_BYTES == STAGE_CONTRACT_TSWAP_J0_EXPECTED_BYTES {
      constant STAGE_CONTRACT_TSWAP_J0_FR0_OK = 1
    } else {
      error "TileSwap JOB0 FR0 size mismatch with W/H"
    }

    if STAGE_TSWAP_JOB0_NUM_FRAMES > 1 {
      constant STAGE_CONTRACT_TSWAP_J0_FR1_BYTES = (TSWAP_JOB0_FR1_End - TSWAP_JOB0_FR1)
      if STAGE_CONTRACT_TSWAP_J0_FR1_BYTES == STAGE_CONTRACT_TSWAP_J0_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J0_FR1_OK = 1
      } else {
        error "TileSwap JOB0 FR1 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB0_NUM_FRAMES > 2 {
      constant STAGE_CONTRACT_TSWAP_J0_FR2_BYTES = (TSWAP_JOB0_FR2_End - TSWAP_JOB0_FR2)
      if STAGE_CONTRACT_TSWAP_J0_FR2_BYTES == STAGE_CONTRACT_TSWAP_J0_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J0_FR2_OK = 1
      } else {
        error "TileSwap JOB0 FR2 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB0_NUM_FRAMES > 3 {
      constant STAGE_CONTRACT_TSWAP_J0_FR3_BYTES = (TSWAP_JOB0_FR3_End - TSWAP_JOB0_FR3)
      if STAGE_CONTRACT_TSWAP_J0_FR3_BYTES == STAGE_CONTRACT_TSWAP_J0_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J0_FR3_OK = 1
      } else {
        error "TileSwap JOB0 FR3 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB0_NUM_FRAMES > 4 {
      constant STAGE_CONTRACT_TSWAP_J0_FR4_BYTES = (TSWAP_JOB0_FR4_End - TSWAP_JOB0_FR4)
      if STAGE_CONTRACT_TSWAP_J0_FR4_BYTES == STAGE_CONTRACT_TSWAP_J0_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J0_FR4_OK = 1
      } else {
        error "TileSwap JOB0 FR4 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB0_NUM_FRAMES > 5 {
      constant STAGE_CONTRACT_TSWAP_J0_FR5_BYTES = (TSWAP_JOB0_FR5_End - TSWAP_JOB0_FR5)
      if STAGE_CONTRACT_TSWAP_J0_FR5_BYTES == STAGE_CONTRACT_TSWAP_J0_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J0_FR5_OK = 1
      } else {
        error "TileSwap JOB0 FR5 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB0_NUM_FRAMES > 6 {
      constant STAGE_CONTRACT_TSWAP_J0_FR6_BYTES = (TSWAP_JOB0_FR6_End - TSWAP_JOB0_FR6)
      if STAGE_CONTRACT_TSWAP_J0_FR6_BYTES == STAGE_CONTRACT_TSWAP_J0_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J0_FR6_OK = 1
      } else {
        error "TileSwap JOB0 FR6 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB0_NUM_FRAMES > 7 {
      constant STAGE_CONTRACT_TSWAP_J0_FR7_BYTES = (TSWAP_JOB0_FR7_End - TSWAP_JOB0_FR7)
      if STAGE_CONTRACT_TSWAP_J0_FR7_BYTES == STAGE_CONTRACT_TSWAP_J0_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J0_FR7_OK = 1
      } else {
        error "TileSwap JOB0 FR7 size mismatch"
      }
    }
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
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR1_END = TSWAP_JOB1_FR1_End
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR2_END = TSWAP_JOB1_FR2_End
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR3_END = TSWAP_JOB1_FR3_End
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR4_END = TSWAP_JOB1_FR4_End
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR5_END = TSWAP_JOB1_FR5_End
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR6_END = TSWAP_JOB1_FR6_End
    constant STAGE_CONTRACT_REQ_TSWAP_J1_FR7_END = TSWAP_JOB1_FR7_End

    constant STAGE_CONTRACT_TSWAP_J1_FRAME_BYTES = (TSWAP_JOB1_FR0_End - TSWAP_JOB1_FR0)
    constant STAGE_CONTRACT_TSWAP_J1_EXPECTED_BYTES = (STAGE_TSWAP_JOB1_W * STAGE_TSWAP_JOB1_H * 32)

    if STAGE_CONTRACT_TSWAP_J1_FRAME_BYTES == STAGE_CONTRACT_TSWAP_J1_EXPECTED_BYTES {
      constant STAGE_CONTRACT_TSWAP_J1_FR0_OK = 1
    } else {
      error "TileSwap JOB1 FR0 size mismatch with W/H"
    }

    if STAGE_TSWAP_JOB1_NUM_FRAMES > 1 {
      constant STAGE_CONTRACT_TSWAP_J1_FR1_BYTES = (TSWAP_JOB1_FR1_End - TSWAP_JOB1_FR1)
      if STAGE_CONTRACT_TSWAP_J1_FR1_BYTES == STAGE_CONTRACT_TSWAP_J1_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J1_FR1_OK = 1
      } else {
        error "TileSwap JOB1 FR1 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB1_NUM_FRAMES > 2 {
      constant STAGE_CONTRACT_TSWAP_J1_FR2_BYTES = (TSWAP_JOB1_FR2_End - TSWAP_JOB1_FR2)
      if STAGE_CONTRACT_TSWAP_J1_FR2_BYTES == STAGE_CONTRACT_TSWAP_J1_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J1_FR2_OK = 1
      } else {
        error "TileSwap JOB1 FR2 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB1_NUM_FRAMES > 3 {
      constant STAGE_CONTRACT_TSWAP_J1_FR3_BYTES = (TSWAP_JOB1_FR3_End - TSWAP_JOB1_FR3)
      if STAGE_CONTRACT_TSWAP_J1_FR3_BYTES == STAGE_CONTRACT_TSWAP_J1_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J1_FR3_OK = 1
      } else {
        error "TileSwap JOB1 FR3 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB1_NUM_FRAMES > 4 {
      constant STAGE_CONTRACT_TSWAP_J1_FR4_BYTES = (TSWAP_JOB1_FR4_End - TSWAP_JOB1_FR4)
      if STAGE_CONTRACT_TSWAP_J1_FR4_BYTES == STAGE_CONTRACT_TSWAP_J1_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J1_FR4_OK = 1
      } else {
        error "TileSwap JOB1 FR4 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB1_NUM_FRAMES > 5 {
      constant STAGE_CONTRACT_TSWAP_J1_FR5_BYTES = (TSWAP_JOB1_FR5_End - TSWAP_JOB1_FR5)
      if STAGE_CONTRACT_TSWAP_J1_FR5_BYTES == STAGE_CONTRACT_TSWAP_J1_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J1_FR5_OK = 1
      } else {
        error "TileSwap JOB1 FR5 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB1_NUM_FRAMES > 6 {
      constant STAGE_CONTRACT_TSWAP_J1_FR6_BYTES = (TSWAP_JOB1_FR6_End - TSWAP_JOB1_FR6)
      if STAGE_CONTRACT_TSWAP_J1_FR6_BYTES == STAGE_CONTRACT_TSWAP_J1_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J1_FR6_OK = 1
      } else {
        error "TileSwap JOB1 FR6 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB1_NUM_FRAMES > 7 {
      constant STAGE_CONTRACT_TSWAP_J1_FR7_BYTES = (TSWAP_JOB1_FR7_End - TSWAP_JOB1_FR7)
      if STAGE_CONTRACT_TSWAP_J1_FR7_BYTES == STAGE_CONTRACT_TSWAP_J1_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J1_FR7_OK = 1
      } else {
        error "TileSwap JOB1 FR7 size mismatch"
      }
    }
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
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR1_END = TSWAP_JOB2_FR1_End
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR2_END = TSWAP_JOB2_FR2_End
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR3_END = TSWAP_JOB2_FR3_End
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR4_END = TSWAP_JOB2_FR4_End
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR5_END = TSWAP_JOB2_FR5_End
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR6_END = TSWAP_JOB2_FR6_End
    constant STAGE_CONTRACT_REQ_TSWAP_J2_FR7_END = TSWAP_JOB2_FR7_End

    constant STAGE_CONTRACT_TSWAP_J2_FRAME_BYTES = (TSWAP_JOB2_FR0_End - TSWAP_JOB2_FR0)
    constant STAGE_CONTRACT_TSWAP_J2_EXPECTED_BYTES = (STAGE_TSWAP_JOB2_W * STAGE_TSWAP_JOB2_H * 32)

    if STAGE_CONTRACT_TSWAP_J2_FRAME_BYTES == STAGE_CONTRACT_TSWAP_J2_EXPECTED_BYTES {
      constant STAGE_CONTRACT_TSWAP_J2_FR0_OK = 1
    } else {
      error "TileSwap JOB2 FR0 size mismatch with W/H"
    }

    if STAGE_TSWAP_JOB2_NUM_FRAMES > 1 {
      constant STAGE_CONTRACT_TSWAP_J2_FR1_BYTES = (TSWAP_JOB2_FR1_End - TSWAP_JOB2_FR1)
      if STAGE_CONTRACT_TSWAP_J2_FR1_BYTES == STAGE_CONTRACT_TSWAP_J2_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J2_FR1_OK = 1
      } else {
        error "TileSwap JOB2 FR1 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB2_NUM_FRAMES > 2 {
      constant STAGE_CONTRACT_TSWAP_J2_FR2_BYTES = (TSWAP_JOB2_FR2_End - TSWAP_JOB2_FR2)
      if STAGE_CONTRACT_TSWAP_J2_FR2_BYTES == STAGE_CONTRACT_TSWAP_J2_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J2_FR2_OK = 1
      } else {
        error "TileSwap JOB2 FR2 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB2_NUM_FRAMES > 3 {
      constant STAGE_CONTRACT_TSWAP_J2_FR3_BYTES = (TSWAP_JOB2_FR3_End - TSWAP_JOB2_FR3)
      if STAGE_CONTRACT_TSWAP_J2_FR3_BYTES == STAGE_CONTRACT_TSWAP_J2_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J2_FR3_OK = 1
      } else {
        error "TileSwap JOB2 FR3 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB2_NUM_FRAMES > 4 {
      constant STAGE_CONTRACT_TSWAP_J2_FR4_BYTES = (TSWAP_JOB2_FR4_End - TSWAP_JOB2_FR4)
      if STAGE_CONTRACT_TSWAP_J2_FR4_BYTES == STAGE_CONTRACT_TSWAP_J2_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J2_FR4_OK = 1
      } else {
        error "TileSwap JOB2 FR4 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB2_NUM_FRAMES > 5 {
      constant STAGE_CONTRACT_TSWAP_J2_FR5_BYTES = (TSWAP_JOB2_FR5_End - TSWAP_JOB2_FR5)
      if STAGE_CONTRACT_TSWAP_J2_FR5_BYTES == STAGE_CONTRACT_TSWAP_J2_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J2_FR5_OK = 1
      } else {
        error "TileSwap JOB2 FR5 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB2_NUM_FRAMES > 6 {
      constant STAGE_CONTRACT_TSWAP_J2_FR6_BYTES = (TSWAP_JOB2_FR6_End - TSWAP_JOB2_FR6)
      if STAGE_CONTRACT_TSWAP_J2_FR6_BYTES == STAGE_CONTRACT_TSWAP_J2_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J2_FR6_OK = 1
      } else {
        error "TileSwap JOB2 FR6 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB2_NUM_FRAMES > 7 {
      constant STAGE_CONTRACT_TSWAP_J2_FR7_BYTES = (TSWAP_JOB2_FR7_End - TSWAP_JOB2_FR7)
      if STAGE_CONTRACT_TSWAP_J2_FR7_BYTES == STAGE_CONTRACT_TSWAP_J2_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J2_FR7_OK = 1
      } else {
        error "TileSwap JOB2 FR7 size mismatch"
      }
    }
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
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR1_END = TSWAP_JOB3_FR1_End
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR2_END = TSWAP_JOB3_FR2_End
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR3_END = TSWAP_JOB3_FR3_End
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR4_END = TSWAP_JOB3_FR4_End
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR5_END = TSWAP_JOB3_FR5_End
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR6_END = TSWAP_JOB3_FR6_End
    constant STAGE_CONTRACT_REQ_TSWAP_J3_FR7_END = TSWAP_JOB3_FR7_End

    constant STAGE_CONTRACT_TSWAP_J3_FRAME_BYTES = (TSWAP_JOB3_FR0_End - TSWAP_JOB3_FR0)
    constant STAGE_CONTRACT_TSWAP_J3_EXPECTED_BYTES = (STAGE_TSWAP_JOB3_W * STAGE_TSWAP_JOB3_H * 32)

    if STAGE_CONTRACT_TSWAP_J3_FRAME_BYTES == STAGE_CONTRACT_TSWAP_J3_EXPECTED_BYTES {
      constant STAGE_CONTRACT_TSWAP_J3_FR0_OK = 1
    } else {
      error "TileSwap JOB3 FR0 size mismatch with W/H"
    }

    if STAGE_TSWAP_JOB3_NUM_FRAMES > 1 {
      constant STAGE_CONTRACT_TSWAP_J3_FR1_BYTES = (TSWAP_JOB3_FR1_End - TSWAP_JOB3_FR1)
      if STAGE_CONTRACT_TSWAP_J3_FR1_BYTES == STAGE_CONTRACT_TSWAP_J3_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J3_FR1_OK = 1
      } else {
        error "TileSwap JOB3 FR1 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB3_NUM_FRAMES > 2 {
      constant STAGE_CONTRACT_TSWAP_J3_FR2_BYTES = (TSWAP_JOB3_FR2_End - TSWAP_JOB3_FR2)
      if STAGE_CONTRACT_TSWAP_J3_FR2_BYTES == STAGE_CONTRACT_TSWAP_J3_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J3_FR2_OK = 1
      } else {
        error "TileSwap JOB3 FR2 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB3_NUM_FRAMES > 3 {
      constant STAGE_CONTRACT_TSWAP_J3_FR3_BYTES = (TSWAP_JOB3_FR3_End - TSWAP_JOB3_FR3)
      if STAGE_CONTRACT_TSWAP_J3_FR3_BYTES == STAGE_CONTRACT_TSWAP_J3_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J3_FR3_OK = 1
      } else {
        error "TileSwap JOB3 FR3 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB3_NUM_FRAMES > 4 {
      constant STAGE_CONTRACT_TSWAP_J3_FR4_BYTES = (TSWAP_JOB3_FR4_End - TSWAP_JOB3_FR4)
      if STAGE_CONTRACT_TSWAP_J3_FR4_BYTES == STAGE_CONTRACT_TSWAP_J3_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J3_FR4_OK = 1
      } else {
        error "TileSwap JOB3 FR4 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB3_NUM_FRAMES > 5 {
      constant STAGE_CONTRACT_TSWAP_J3_FR5_BYTES = (TSWAP_JOB3_FR5_End - TSWAP_JOB3_FR5)
      if STAGE_CONTRACT_TSWAP_J3_FR5_BYTES == STAGE_CONTRACT_TSWAP_J3_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J3_FR5_OK = 1
      } else {
        error "TileSwap JOB3 FR5 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB3_NUM_FRAMES > 6 {
      constant STAGE_CONTRACT_TSWAP_J3_FR6_BYTES = (TSWAP_JOB3_FR6_End - TSWAP_JOB3_FR6)
      if STAGE_CONTRACT_TSWAP_J3_FR6_BYTES == STAGE_CONTRACT_TSWAP_J3_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J3_FR6_OK = 1
      } else {
        error "TileSwap JOB3 FR6 size mismatch"
      }
    }
    if STAGE_TSWAP_JOB3_NUM_FRAMES > 7 {
      constant STAGE_CONTRACT_TSWAP_J3_FR7_BYTES = (TSWAP_JOB3_FR7_End - TSWAP_JOB3_FR7)
      if STAGE_CONTRACT_TSWAP_J3_FR7_BYTES == STAGE_CONTRACT_TSWAP_J3_FRAME_BYTES {
        constant STAGE_CONTRACT_TSWAP_J3_FR7_OK = 1
      } else {
        error "TileSwap JOB3 FR7 size mismatch"
      }
    }
  }
}
