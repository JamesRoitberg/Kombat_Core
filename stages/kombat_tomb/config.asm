// config.asm
// -----------------------------------------------------------------------------
// Stage config template (default)
// - Feature flags do stage
// - Layout base de VRAM e registradores PPU do stage
// - Parallax/HDMA bands + ratios + offsets
// - ScrollTracks (ate 5)
// - ColorCycle (ate 4)
// - CGRAM gradient (opcional)
// - TileSwap jobs (0..3) com dummies prontos para habilitar
// -----------------------------------------------------------------------------


// ============================================================================
// Stage feature flags
// ============================================================================
constant STAGE_ENABLE_GRADIENT   = 1
constant STAGE_ENABLE_ANIM       = 1
constant STAGE_ENABLE_INPUT      = 1

// HDMAEN masks (write-only) usados pelo gradient/colorcycle.
// - Scroll/parallax usa CH5-CH7                 => %11100000 = $E0
// - Degrade CGRAM usa CH2-CH3 + scroll (CH5-7) => %11101100 = $EC
constant STAGE_HDMAEN_MASK_SCROLL_ONLY      = $E0
constant STAGE_HDMAEN_MASK_SCROLL_PLUS_GRAD = $EC

// Quando 1, ColorCycle pausa/retoma CH2/CH3 durante escrita em CGRAM.
// Quando 0, nao toca em HDMAEN dentro do ColorCycle.
constant STAGE_GRADIENT_CC_SAFE_TOGGLE = 1

// ColorCycle como feature do stage (CC0_ENABLE espelha isto)
constant STAGE_ENABLE_COLORCYCLE = 0

// Habilita ou desabilita motor do tileswap.
// Nota: com STAGE_TSWAP_ENABLE=1, o core exige STAGE_TSWAP_JOB0_ENABLE=1.
constant STAGE_TSWAP_ENABLE = 1

// Ajustes de movimentacao (stage/debug)
constant STAGE_INPUT_DRIVE_WORLDX = 1
constant STAGE_INPUT_WORLDX_SPEED = 1


// ============================================================================
// Stage WRAM block
// - Padrao: $0200..$02FF (256 bytes)
// - Nao passar de $0700 (HDMA_CGRAM_* comeca em $0700).
// ============================================================================
constant STAGE_ANIM_WRAM_BASE = $0200
constant STAGE_ANIM_WRAM_SIZE = $0100


// ============================================================================
// VRAM layout do stage (enderecos em bytes)
// ----------------------------------------------------------------------------
// Ajuste aqui o mapeamento de tiles/tilemaps de cada cenario.
// O core/game.asm usa estes valores no upload inicial via DMA para VRAM.
// ============================================================================
constant VRAM_BG1_TILES = $0000
constant VRAM_BG1_MAP   = $6800 // 64x64 => $2000 bytes

constant VRAM_BG2_TILES = $A000
constant VRAM_BG2_MAP   = $F000 // 64x32 => $1000 bytes

// Valores pre-calculados para registradores de base de tiles/map:
// - BG12NBA ($210B): base de CHR de BG1/BG2
// - BG1SC   ($2107): base/size do tilemap de BG1
// - BG2SC   ($2108): base/size do tilemap de BG2
constant REG_BG12NBA = $50
constant REG_BG1SC   = $37
constant REG_BG2SC   = $79


// ============================================================================
// HDMA bands (5 bandas)
// Altura maxima por banda = 128 linhas
// - Garanta soma final de 224 linhas em BG1.
// - Garanta soma final de 224 linhas em BG2.
// ============================================================================
constant BG1_BAND0_LINES = 12
constant BG1_BAND1_LINES = 119
constant BG1_BAND2_LINES = 53
constant BG1_BAND3_LINES = 35
constant BG1_BAND4_LINES = 4

constant BG2_BAND0_LINES = 16
constant BG2_BAND1_LINES = 56
constant BG2_BAND2_LINES = 39
constant BG2_BAND3_LINES = 40
constant BG2_BAND4_LINES = 72


// ============================================================================
// Parallax ratios (byte, Q0.8)
// - $80 ~= 0.5
// - $FF ~= ~1.0 (255/256)
// ============================================================================
constant BG1_RATIO_B0 = $FA
constant BG1_RATIO_B1 = $FC
constant BG1_RATIO_B2 = $FC
constant BG1_RATIO_B3 = $FE
constant BG1_RATIO_B4 = $FF

constant BG2_RATIO_B0 = $FF
constant BG2_RATIO_B1 = $80
constant BG2_RATIO_B2 = $62
constant BG2_RATIO_B3 = $D0
constant BG2_RATIO_B4 = $FF


// ============================================================================
// Stage offsets (word)
// ============================================================================
constant STAGE_BG1_X_OFFSET = $0000
constant STAGE_BG1_Y_OFFSET = $0007
constant STAGE_BG2_X_OFFSET = $0000
constant STAGE_BG2_Y_OFFSET = $0008


// ============================================================================
// (1) ScrollTracks (ate 5) - HOFS subpixel
// ----------------------------------------------------------------------------
// Campos:
// - ENABLE: 0/1
// - TARGET_BG: 1=BG1, 2=BG2
// - BAND: 0..4
// - DIR: 0=+ 1=-
// - SPEED_INT: pixels/frame (word)
// - SPEED_FRAC: fracao/256 (byte)
// - WRAP_MASK: word (ex.: $01FF)
// - APPLY_MODE: 0=ADD (soma com parallax), 1=SET (substitui HOFS da banda)
// ============================================================================

// Track0
constant STAGE_SCROLL_TRACK0_ENABLE = 0
constant STAGE_SCROLL_TRACK0_TARGET_BG = 2
constant STAGE_SCROLL_TRACK0_BAND = 0
constant STAGE_SCROLL_TRACK0_DIR = 0
constant STAGE_SCROLL_TRACK0_SPEED_INT = 0
constant STAGE_SCROLL_TRACK0_SPEED_FRAC = 64
constant STAGE_SCROLL_TRACK0_WRAP_MASK = $01FF
constant STAGE_SCROLL_TRACK0_APPLY_MODE = 0

// Track1
constant STAGE_SCROLL_TRACK1_ENABLE = 0
constant STAGE_SCROLL_TRACK1_TARGET_BG = 2
constant STAGE_SCROLL_TRACK1_BAND = 1
constant STAGE_SCROLL_TRACK1_DIR = 0
constant STAGE_SCROLL_TRACK1_SPEED_INT = 1
constant STAGE_SCROLL_TRACK1_SPEED_FRAC = 64
constant STAGE_SCROLL_TRACK1_WRAP_MASK = $01FF
constant STAGE_SCROLL_TRACK1_APPLY_MODE = 0

// Track2
constant STAGE_SCROLL_TRACK2_ENABLE = 0
constant STAGE_SCROLL_TRACK2_TARGET_BG = 2
constant STAGE_SCROLL_TRACK2_BAND = 2
constant STAGE_SCROLL_TRACK2_DIR = 1
constant STAGE_SCROLL_TRACK2_SPEED_INT = 0
constant STAGE_SCROLL_TRACK2_SPEED_FRAC = 128
constant STAGE_SCROLL_TRACK2_WRAP_MASK = $01FF
constant STAGE_SCROLL_TRACK2_APPLY_MODE = 0

// Track3
constant STAGE_SCROLL_TRACK3_ENABLE = 0
constant STAGE_SCROLL_TRACK3_TARGET_BG = 2
constant STAGE_SCROLL_TRACK3_BAND = 3
constant STAGE_SCROLL_TRACK3_DIR = 0
constant STAGE_SCROLL_TRACK3_SPEED_INT = 0
constant STAGE_SCROLL_TRACK3_SPEED_FRAC = 0
constant STAGE_SCROLL_TRACK3_WRAP_MASK = $01FF
constant STAGE_SCROLL_TRACK3_APPLY_MODE = 0

// Track4
constant STAGE_SCROLL_TRACK4_ENABLE = 0
constant STAGE_SCROLL_TRACK4_TARGET_BG = 2
constant STAGE_SCROLL_TRACK4_BAND = 4
constant STAGE_SCROLL_TRACK4_DIR = 0
constant STAGE_SCROLL_TRACK4_SPEED_INT = 0
constant STAGE_SCROLL_TRACK4_SPEED_FRAC = 0
constant STAGE_SCROLL_TRACK4_WRAP_MASK = $01FF
constant STAGE_SCROLL_TRACK4_APPLY_MODE = 0


// ============================================================================
// (2) ColorCycle (ate 4 instancias) - LEN 2..6
// ----------------------------------------------------------------------------
// - Roda so em VBlank e e safe com gradiente
// - Scheduler: no maximo 1 instancia aplicada por frame (round-robin)
// - MODE por instancia:
//   0=loop infinito
//   1=burst e para
//   2=burst, pausa e repete
// ============================================================================

// CC0
constant STAGE_CC0_ENABLE = STAGE_ENABLE_COLORCYCLE

constant STAGE_CC0_SUBPAL = 2
constant STAGE_CC0_LEN = 3
constant STAGE_CC0_DIR = 1
constant STAGE_CC0_DELAY = 12
constant STAGE_CC0_MODE = 0
constant STAGE_CC0_BURST_LOOPS = 3
constant STAGE_CC0_BURST_STEPS = (STAGE_CC0_LEN * STAGE_CC0_BURST_LOOPS)
constant STAGE_CC0_PAUSE_FRAMES = 120

constant STAGE_CC0_OFF0 = 1
constant STAGE_CC0_OFF1 = 2
constant STAGE_CC0_OFF2 = 3
constant STAGE_CC0_OFF3 = 4
constant STAGE_CC0_OFF4 = 5
constant STAGE_CC0_OFF5 = 6

// CC1
constant STAGE_CC1_ENABLE = 0

constant STAGE_CC1_SUBPAL = 3
constant STAGE_CC1_LEN = 3
constant STAGE_CC1_DIR = 0
constant STAGE_CC1_DELAY = 12
constant STAGE_CC1_MODE = 0
constant STAGE_CC1_BURST_LOOPS = 3
constant STAGE_CC1_BURST_STEPS = (STAGE_CC1_LEN * STAGE_CC1_BURST_LOOPS)
constant STAGE_CC1_PAUSE_FRAMES = 120

constant STAGE_CC1_OFF0 = 1
constant STAGE_CC1_OFF1 = 2
constant STAGE_CC1_OFF2 = 3
constant STAGE_CC1_OFF3 = 4
constant STAGE_CC1_OFF4 = 5
constant STAGE_CC1_OFF5 = 6

// CC2
constant STAGE_CC2_ENABLE = 0

constant STAGE_CC2_SUBPAL = 4
constant STAGE_CC2_LEN = 3
constant STAGE_CC2_DIR = 0
constant STAGE_CC2_DELAY = 12
constant STAGE_CC2_MODE = 0
constant STAGE_CC2_BURST_LOOPS = 3
constant STAGE_CC2_BURST_STEPS = (STAGE_CC2_LEN * STAGE_CC2_BURST_LOOPS)
constant STAGE_CC2_PAUSE_FRAMES = 120

constant STAGE_CC2_OFF0 = 1
constant STAGE_CC2_OFF1 = 2
constant STAGE_CC2_OFF2 = 3
constant STAGE_CC2_OFF3 = 4
constant STAGE_CC2_OFF4 = 5
constant STAGE_CC2_OFF5 = 6

// CC3
constant STAGE_CC3_ENABLE = 0

constant STAGE_CC3_SUBPAL = 5
constant STAGE_CC3_LEN = 3
constant STAGE_CC3_DIR = 0
constant STAGE_CC3_DELAY = 12
constant STAGE_CC3_MODE = 0
constant STAGE_CC3_BURST_LOOPS = 3
constant STAGE_CC3_BURST_STEPS = (STAGE_CC3_LEN * STAGE_CC3_BURST_LOOPS)
constant STAGE_CC3_PAUSE_FRAMES = 120

constant STAGE_CC3_OFF0 = 1
constant STAGE_CC3_OFF1 = 2
constant STAGE_CC3_OFF2 = 3
constant STAGE_CC3_OFF3 = 4
constant STAGE_CC3_OFF4 = 5
constant STAGE_CC3_OFF5 = 6

// Indices absolutos derivados (0..255)
constant STAGE_CC0_BASE = (STAGE_CC0_SUBPAL * 16)
constant STAGE_CC0_IDX0 = (STAGE_CC0_BASE + STAGE_CC0_OFF0)
constant STAGE_CC0_IDX1 = (STAGE_CC0_BASE + STAGE_CC0_OFF1)
constant STAGE_CC0_IDX2 = (STAGE_CC0_BASE + STAGE_CC0_OFF2)
constant STAGE_CC0_IDX3 = (STAGE_CC0_BASE + STAGE_CC0_OFF3)
constant STAGE_CC0_IDX4 = (STAGE_CC0_BASE + STAGE_CC0_OFF4)
constant STAGE_CC0_IDX5 = (STAGE_CC0_BASE + STAGE_CC0_OFF5)

constant STAGE_CC1_BASE = (STAGE_CC1_SUBPAL * 16)
constant STAGE_CC1_IDX0 = (STAGE_CC1_BASE + STAGE_CC1_OFF0)
constant STAGE_CC1_IDX1 = (STAGE_CC1_BASE + STAGE_CC1_OFF1)
constant STAGE_CC1_IDX2 = (STAGE_CC1_BASE + STAGE_CC1_OFF2)
constant STAGE_CC1_IDX3 = (STAGE_CC1_BASE + STAGE_CC1_OFF3)
constant STAGE_CC1_IDX4 = (STAGE_CC1_BASE + STAGE_CC1_OFF4)
constant STAGE_CC1_IDX5 = (STAGE_CC1_BASE + STAGE_CC1_OFF5)

constant STAGE_CC2_BASE = (STAGE_CC2_SUBPAL * 16)
constant STAGE_CC2_IDX0 = (STAGE_CC2_BASE + STAGE_CC2_OFF0)
constant STAGE_CC2_IDX1 = (STAGE_CC2_BASE + STAGE_CC2_OFF1)
constant STAGE_CC2_IDX2 = (STAGE_CC2_BASE + STAGE_CC2_OFF2)
constant STAGE_CC2_IDX3 = (STAGE_CC2_BASE + STAGE_CC2_OFF3)
constant STAGE_CC2_IDX4 = (STAGE_CC2_BASE + STAGE_CC2_OFF4)
constant STAGE_CC2_IDX5 = (STAGE_CC2_BASE + STAGE_CC2_OFF5)

constant STAGE_CC3_BASE = (STAGE_CC3_SUBPAL * 16)
constant STAGE_CC3_IDX0 = (STAGE_CC3_BASE + STAGE_CC3_OFF0)
constant STAGE_CC3_IDX1 = (STAGE_CC3_BASE + STAGE_CC3_OFF1)
constant STAGE_CC3_IDX2 = (STAGE_CC3_BASE + STAGE_CC3_OFF2)
constant STAGE_CC3_IDX3 = (STAGE_CC3_BASE + STAGE_CC3_OFF3)
constant STAGE_CC3_IDX4 = (STAGE_CC3_BASE + STAGE_CC3_OFF4)
constant STAGE_CC3_IDX5 = (STAGE_CC3_BASE + STAGE_CC3_OFF5)


// ============================================================================
// CGRAM gradient (1 cor) — parâmetros (usado pelo game.asm + macros.asm)
// ============================================================================
// Cor 0 do backdrop (CGRAM[0]) consumida pelo core/game.asm.
// Ajuste aqui a cor de fundo principal do stage.
constant STAGE_BACKDROP_COLOR0      = $0000

constant STAGE_CGRAM_GRAD_CGADD = $00                 // CGRAM color index (0..255)
// Ajuste aqui a cor final do degradê do stage (BGR555)
constant STAGE_CGRAM_GRAD_COLOR_B =  $042D   // cor final (BGR555 word)

constant STAGE_CGRAM_GRAD_LINES_PER_ENTRY = 2
constant STAGE_CGRAM_GRAD_ENTRIES = (224 / STAGE_CGRAM_GRAD_LINES_PER_ENTRY)
constant STAGE_CGRAM_GRAD_DENOM_HIRES = (STAGE_CGRAM_GRAD_ENTRIES - 1)
constant STAGE_CGRAM_GRAD_ROUND_HIRES = (STAGE_CGRAM_GRAD_DENOM_HIRES / 2)


// ============================================================================
// TileSwap v2/v3 (config template)
// ----------------------------------------------------------------------------
// Regras:
// - Cada frame CHR precisa ter: (W * H * 32) bytes.
// - Cada job usa Seq com indices 0..(NUM_FRAMES-1).
// - Targets sao pares (col,row) em tiles.
// - O stage package deve exportar labels FR0..FR7 para cada job ativo.
// ============================================================================

// JOB0
constant STAGE_TSWAP_JOB0_ENABLE = 1
constant STAGE_TSWAP_JOB0_TARGET_BG = 2
constant STAGE_TSWAP_JOB0_W = 7
constant STAGE_TSWAP_JOB0_H = 6
constant STAGE_TSWAP_JOB0_PAL = 5
constant STAGE_TSWAP_JOB0_PRIO = 0
constant STAGE_TSWAP_JOB0_PAL_BITS = ((STAGE_TSWAP_JOB0_PAL << 10) | (STAGE_TSWAP_JOB0_PRIO << 13))
constant STAGE_TSWAP_JOB0_DELAY = 8
constant STAGE_TSWAP_JOB0_NUM_FRAMES = 8
constant STAGE_TSWAP_JOB0_GAP = 0

Stage_TSwapJob0_Seq:
  db $00
  db $01
  db $02
  db $03
  db $04
  db $05
  db $06
  db $07
Stage_TSwapJob0_Seq_End:

constant STAGE_TSWAP_JOB0_SEQ_LEN = (Stage_TSwapJob0_Seq_End - Stage_TSwapJob0_Seq)

Stage_TSwapJob0_Targets:
  db 44
  db 4
Stage_TSwapJob0_Targets_End:

constant STAGE_TSWAP_JOB0_TARGET_COUNT = ((Stage_TSwapJob0_Targets_End - Stage_TSwapJob0_Targets) / 2)

// JOB1
constant STAGE_TSWAP_JOB1_ENABLE = 0
constant STAGE_TSWAP_JOB1_TARGET_BG = 2
constant STAGE_TSWAP_JOB1_W = 7
constant STAGE_TSWAP_JOB1_H = 6
constant STAGE_TSWAP_JOB1_PAL = 0
constant STAGE_TSWAP_JOB1_PRIO = 0
constant STAGE_TSWAP_JOB1_PAL_BITS = ((STAGE_TSWAP_JOB1_PAL << 10) | (STAGE_TSWAP_JOB1_PRIO << 13))
constant STAGE_TSWAP_JOB1_DELAY = 8
constant STAGE_TSWAP_JOB1_NUM_FRAMES = 8
constant STAGE_TSWAP_JOB1_GAP = 0

Stage_TSwapJob1_Seq:
  db $00
Stage_TSwapJob1_Seq_End:

constant STAGE_TSWAP_JOB1_SEQ_LEN = (Stage_TSwapJob1_Seq_End - Stage_TSwapJob1_Seq)

Stage_TSwapJob1_Targets:
  db 0
  db 0
Stage_TSwapJob1_Targets_End:

constant STAGE_TSWAP_JOB1_TARGET_COUNT = ((Stage_TSwapJob1_Targets_End - Stage_TSwapJob1_Targets) / 2)

// JOB2
constant STAGE_TSWAP_JOB2_ENABLE = 0
constant STAGE_TSWAP_JOB2_TARGET_BG = 1
constant STAGE_TSWAP_JOB2_W = 1
constant STAGE_TSWAP_JOB2_H = 1
constant STAGE_TSWAP_JOB2_PAL = 0
constant STAGE_TSWAP_JOB2_PRIO = 0
constant STAGE_TSWAP_JOB2_PAL_BITS = ((STAGE_TSWAP_JOB2_PAL << 10) | (STAGE_TSWAP_JOB2_PRIO << 13))
constant STAGE_TSWAP_JOB2_DELAY = 8
constant STAGE_TSWAP_JOB2_NUM_FRAMES = 1
constant STAGE_TSWAP_JOB2_GAP = 0

Stage_TSwapJob2_Seq:
  db $00
Stage_TSwapJob2_Seq_End:

constant STAGE_TSWAP_JOB2_SEQ_LEN = (Stage_TSwapJob2_Seq_End - Stage_TSwapJob2_Seq)

Stage_TSwapJob2_Targets:
  db 0
  db 0
Stage_TSwapJob2_Targets_End:

constant STAGE_TSWAP_JOB2_TARGET_COUNT = ((Stage_TSwapJob2_Targets_End - Stage_TSwapJob2_Targets) / 2)

// JOB3
constant STAGE_TSWAP_JOB3_ENABLE = 0
constant STAGE_TSWAP_JOB3_TARGET_BG = 1
constant STAGE_TSWAP_JOB3_W = 1
constant STAGE_TSWAP_JOB3_H = 1
constant STAGE_TSWAP_JOB3_PAL = 0
constant STAGE_TSWAP_JOB3_PRIO = 0
constant STAGE_TSWAP_JOB3_PAL_BITS = ((STAGE_TSWAP_JOB3_PAL << 10) | (STAGE_TSWAP_JOB3_PRIO << 13))
constant STAGE_TSWAP_JOB3_DELAY = 8
constant STAGE_TSWAP_JOB3_NUM_FRAMES = 1
constant STAGE_TSWAP_JOB3_GAP = 0

Stage_TSwapJob3_Seq:
  db $00
Stage_TSwapJob3_Seq_End:

constant STAGE_TSWAP_JOB3_SEQ_LEN = (Stage_TSwapJob3_Seq_End - Stage_TSwapJob3_Seq)

Stage_TSwapJob3_Targets:
  db 0
  db 0
Stage_TSwapJob3_Targets_End:

constant STAGE_TSWAP_JOB3_TARGET_COUNT = ((Stage_TSwapJob3_Targets_End - Stage_TSwapJob3_Targets) / 2)
