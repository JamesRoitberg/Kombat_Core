// config.asm
// -----------------------------------------------------------------------------
// Stage config (boilerplate)
// - Flags do stage
// - Layout de VRAM por stage
// - Parallax/HDMA bands + ratios + offsets
// - StageAnim motor:
//    (1) ScrollTracks (até 5)  : HOFS subpixel por banda (ADD/SET sobre o parallax)
//    (2) ColorCycle (até 4)    : CGRAM rotate LEN 2..6 (safe com gradiente)
// - CGRAM gradient (opcional)
// -----------------------------------------------------------------------------


// ============================================================================
// Stage feature flags
// ============================================================================
constant STAGE_ENABLE_GRADIENT = 1
constant STAGE_ENABLE_ANIM = 1
constant STAGE_ENABLE_INPUT = 1

// HDMAEN masks (write-only) usados pelo gradient/colorcycle.
// - Scroll/parallax usa CH5-CH7                 => %11100000 = $E0
// - Degrade CGRAM usa CH2-CH3 + scroll (CH5-7) => %11101100 = $EC
constant STAGE_HDMAEN_MASK_SCROLL_ONLY = $E0
constant STAGE_HDMAEN_MASK_SCROLL_PLUS_GRAD = $EC

// Quando 1, ColorCycle pausa/retoma CH2/CH3 durante escrita em CGRAM.
// Quando 0, nao toca em HDMAEN dentro do ColorCycle.
constant STAGE_GRADIENT_CC_SAFE_TOGGLE = 1

// ColorCycle como feature do stage (CC0_ENABLE espelha isto)
constant STAGE_ENABLE_COLORCYCLE = 1

// Habilita ou desabilita o motor de TileSwap para este stage.
constant STAGE_TSWAP_ENABLE = 0
// Nota de compatibilidade do core:
// - Se STAGE_TSWAP_ENABLE virar 1, STAGE_TSWAP_JOB0_ENABLE deve estar em 1.
// - JOB2/JOB3 fazem patch de targets em background (1 target por tick do job).

// Ajustes de movimentacao (stage/debug)
constant STAGE_INPUT_DRIVE_WORLDX = 1
constant STAGE_INPUT_WORLDX_SPEED = 1


// ============================================================================
// Stage WRAM block (boilerplate)
// - Padrao: $0200..$02FF (256 bytes)
// - Nao passar de $0700 (HDMA_CGRAM_* comeca em $0700).
// ============================================================================
constant STAGE_ANIM_WRAM_BASE = $0200
constant STAGE_ANIM_WRAM_SIZE = $0100


// ============================================================================
// VRAM layout do stage (enderecos em bytes)
// ----------------------------------------------------------------------------
// Valores deste stage (pode vir de legado ou mapeamento novo).
// ============================================================================
constant VRAM_BG1_TILES = $0000
constant VRAM_BG1_MAP = $8000

constant VRAM_BG2_TILES = $A000
constant VRAM_BG2_MAP = $F000

// Valores pre-calculados para registradores de base de tiles/map.
constant REG_BG12NBA = $50
constant REG_BG1SC = $43
constant REG_BG2SC = $79


// ============================================================================
// HDMA bands (5 bandas)
// Altura maxima por banda = 128 linhas
// Compatibilidade com layout legado de 4 bandas:
// - B4 fica com 1 linha
// - Garanta soma final de 224 linhas em BG1/BG2.
// ============================================================================
constant BG1_BAND0_LINES = 108
constant BG1_BAND1_LINES = 27
constant BG1_BAND2_LINES = 24
constant BG1_BAND3_LINES = 24
constant BG1_BAND4_LINES = 40

constant BG2_BAND0_LINES = 88
constant BG2_BAND1_LINES = 39
constant BG2_BAND2_LINES = 49
constant BG2_BAND3_LINES = 47
constant BG2_BAND4_LINES = 1


// ============================================================================
// Parallax ratios (byte, Q0.8)
// - $80 ~= 0.5
// - $FF ~= ~1.0 (255/256)
// ============================================================================
constant BG1_RATIO_B0 = $18
constant BG1_RATIO_B1 = $20
constant BG1_RATIO_B2 = $D0
constant BG1_RATIO_B3 = $D2
constant BG1_RATIO_B4 = $FF

constant BG2_RATIO_B0 = $E0
constant BG2_RATIO_B1 = $E0
constant BG2_RATIO_B2 = $E0
constant BG2_RATIO_B3 = $E0
constant BG2_RATIO_B4 = $FF


// ============================================================================
// Stage offsets (word)
// ============================================================================
constant STAGE_BG1_X_OFFSET = $0000
constant STAGE_BG1_Y_OFFSET = $0000
constant STAGE_BG2_X_OFFSET = $0004
constant STAGE_BG2_Y_OFFSET = $0000


// ============================================================================
// (1) ScrollTracks (ate 5) - HOFS subpixel
// ----------------------------------------------------------------------------
// Campos:
// - ENABLE: 0/1
// - TARGET_BG: 1=BG1, 2=BG2
// - BAND: 0..4 (B0..B4)
// - DIR: 0=+ 1=-
// - SPEED_INT: pixels/frame (word)
// - SPEED_FRAC: fracao/256 (byte)
// - WRAP_MASK: word
// - APPLY_MODE: 0=ADD, 1=SET
// ============================================================================

// Track0 (BG Band0)
constant STAGE_SCROLL_TRACK0_ENABLE = 0
constant STAGE_SCROLL_TRACK0_TARGET_BG = 1
constant STAGE_SCROLL_TRACK0_BAND = 0
constant STAGE_SCROLL_TRACK0_DIR = 1
constant STAGE_SCROLL_TRACK0_SPEED_INT = 2
constant STAGE_SCROLL_TRACK0_SPEED_FRAC = 64
constant STAGE_SCROLL_TRACK0_WRAP_MASK = $01FF
constant STAGE_SCROLL_TRACK0_APPLY_MODE = 0

// Track1 (BG Band1)
constant STAGE_SCROLL_TRACK1_ENABLE = 0
constant STAGE_SCROLL_TRACK1_TARGET_BG = 2
constant STAGE_SCROLL_TRACK1_BAND = 1
constant STAGE_SCROLL_TRACK1_DIR = 1
constant STAGE_SCROLL_TRACK1_SPEED_INT = 0
constant STAGE_SCROLL_TRACK1_SPEED_FRAC = 64
constant STAGE_SCROLL_TRACK1_WRAP_MASK = $01FF
constant STAGE_SCROLL_TRACK1_APPLY_MODE = 0

// Track2 (BG Band2)
constant STAGE_SCROLL_TRACK2_ENABLE = 0
constant STAGE_SCROLL_TRACK2_TARGET_BG = 1
constant STAGE_SCROLL_TRACK2_BAND = 2
constant STAGE_SCROLL_TRACK2_DIR = 1
constant STAGE_SCROLL_TRACK2_SPEED_INT = 0
constant STAGE_SCROLL_TRACK2_SPEED_FRAC = 128
constant STAGE_SCROLL_TRACK2_WRAP_MASK = $01FF
constant STAGE_SCROLL_TRACK2_APPLY_MODE = 0

// Track3 (BG Band3)
constant STAGE_SCROLL_TRACK3_ENABLE = 0
constant STAGE_SCROLL_TRACK3_TARGET_BG = 2
constant STAGE_SCROLL_TRACK3_BAND = 3
constant STAGE_SCROLL_TRACK3_DIR = 0
constant STAGE_SCROLL_TRACK3_SPEED_INT = 0
constant STAGE_SCROLL_TRACK3_SPEED_FRAC = 0
constant STAGE_SCROLL_TRACK3_WRAP_MASK = $01FF
constant STAGE_SCROLL_TRACK3_APPLY_MODE = 0

// Track4 (BG Band4)
constant STAGE_SCROLL_TRACK4_ENABLE = 0
constant STAGE_SCROLL_TRACK4_TARGET_BG = 2
constant STAGE_SCROLL_TRACK4_BAND = 4
constant STAGE_SCROLL_TRACK4_DIR = 0
constant STAGE_SCROLL_TRACK4_SPEED_INT = 0
constant STAGE_SCROLL_TRACK4_SPEED_FRAC = $FF
constant STAGE_SCROLL_TRACK4_WRAP_MASK = $01FF
constant STAGE_SCROLL_TRACK4_APPLY_MODE = 0


// ============================================================================
// (2) ColorCycle (ate 4 instancias) - LEN 2..6
// ----------------------------------------------------------------------------
// - Roda so em VBlank e e safe com gradiente (muta CH2/CH3 durante a troca).
// - Scheduler safe: no maximo 1 instancia aplicada por frame (round-robin).
// - MODE por instancia:
//   0=loop infinito
//   1=burst e para
//   2=burst, pausa e repete
// - BURST_STEPS = LEN * BURST_LOOPS (manter <= 255)
// ============================================================================

// CC0
constant STAGE_CC0_ENABLE = STAGE_ENABLE_COLORCYCLE

constant STAGE_CC0_SUBPAL = 7
constant STAGE_CC0_LEN = 3
constant STAGE_CC0_DIR = 0
constant STAGE_CC0_DELAY = 15
constant STAGE_CC0_MODE = 0
constant STAGE_CC0_BURST_LOOPS = 3
constant STAGE_CC0_BURST_STEPS = (STAGE_CC0_LEN * STAGE_CC0_BURST_LOOPS)
constant STAGE_CC0_PAUSE_FRAMES = 120

constant STAGE_CC0_OFF0 = 10
constant STAGE_CC0_OFF1 = 13
constant STAGE_CC0_OFF2 = 14
constant STAGE_CC0_OFF3 = 15
constant STAGE_CC0_OFF4 = 8
constant STAGE_CC0_OFF5 = 10

// CC1
constant STAGE_CC1_ENABLE = 1

constant STAGE_CC1_SUBPAL = 4
constant STAGE_CC1_LEN = 2
constant STAGE_CC1_DIR = 1
constant STAGE_CC1_DELAY = 20
constant STAGE_CC1_MODE = 0
constant STAGE_CC1_BURST_LOOPS = 3
constant STAGE_CC1_BURST_STEPS = (STAGE_CC1_LEN * STAGE_CC1_BURST_LOOPS)
constant STAGE_CC1_PAUSE_FRAMES = 120

constant STAGE_CC1_OFF0 = 14
constant STAGE_CC1_OFF1 = 15
constant STAGE_CC1_OFF2 = 13
constant STAGE_CC1_OFF3 = 3
constant STAGE_CC1_OFF4 = 4
constant STAGE_CC1_OFF5 = 5

// CC2 (OFF)
constant STAGE_CC2_ENABLE = 0

constant STAGE_CC2_SUBPAL = 1
constant STAGE_CC2_LEN = 3
constant STAGE_CC2_DIR = 0
constant STAGE_CC2_DELAY = 6
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

// CC3 (OFF)
constant STAGE_CC3_ENABLE = 0

constant STAGE_CC3_SUBPAL = 4
constant STAGE_CC3_LEN = 3
constant STAGE_CC3_DIR = 1
constant STAGE_CC3_DELAY = 7
constant STAGE_CC3_MODE = 0
constant STAGE_CC3_BURST_LOOPS = 3
constant STAGE_CC3_BURST_STEPS = (STAGE_CC3_LEN * STAGE_CC3_BURST_LOOPS)
constant STAGE_CC3_PAUSE_FRAMES = 120

constant STAGE_CC3_OFF0 = 9
constant STAGE_CC3_OFF1 = 10
constant STAGE_CC3_OFF2 = 11
constant STAGE_CC3_OFF3 = 12
constant STAGE_CC3_OFF4 = 13
constant STAGE_CC3_OFF5 = 14

// Indices absolutos derivados (0..255) - ate 6 cores por instancia
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
// CGRAM gradient (1 cor) - parametros (usado pelo game.asm + macros.asm)
// ============================================================================
// Cor 0 do backdrop (CGRAM[0]) consumida pelo core/game.asm.
constant STAGE_BACKDROP_COLOR0 = $0000

constant STAGE_CGRAM_GRAD_CGADD = $00                 // CGRAM color index (0..255)
constant STAGE_CGRAM_GRAD_COLOR_B = $2488             // cor final (BGR555 word)

constant STAGE_CGRAM_GRAD_LINES_PER_ENTRY = 2
constant STAGE_CGRAM_GRAD_ENTRIES = (224 / STAGE_CGRAM_GRAD_LINES_PER_ENTRY)
constant STAGE_CGRAM_GRAD_DENOM_HIRES = (STAGE_CGRAM_GRAD_ENTRIES - 1)
constant STAGE_CGRAM_GRAD_ROUND_HIRES = (STAGE_CGRAM_GRAD_DENOM_HIRES / 2)
