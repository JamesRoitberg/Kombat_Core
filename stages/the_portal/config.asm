// config.asm
// -----------------------------------------------------------------------------
// Stage config (boilerplate)
// - Flags do stage
// - Parallax/HDMA bands + ratios + offsets
// - StageAnim motor:
//    (1) ScrollTracks (até 5)  : HOFS subpixel por banda (ADD/SET sobre o parallax)
//    (2) ColorCycle (até 4)    : CGRAM rotate LEN 2..6 (safe com gradiente)
// - CGRAM gradient (opcional)
// -----------------------------------------------------------------------------


// ============================================================================
// Stage feature flags
// ============================================================================
constant STAGE_ENABLE_GRADIENT   = 1
constant STAGE_ENABLE_ANIM       = 1
constant STAGE_ENABLE_INPUT      = 1

// HDMAEN masks (write-only) usados pelo gradient/colorcycle.
// - Scroll/parallax usa CH5–CH7                 => %11100000 = $E0
// - Degradê CGRAM usa CH2–CH3 + scroll (CH5–7) => %11101100 = $EC
constant STAGE_HDMAEN_MASK_SCROLL_ONLY      = $E0
constant STAGE_HDMAEN_MASK_SCROLL_PLUS_GRAD = $EC

// Quando 1, ColorCycle pausa/retoma CH2/CH3 durante escrita em CGRAM.
// Quando 0, não toca em HDMAEN dentro do ColorCycle (menor custo, sem proteção).
constant STAGE_GRADIENT_CC_SAFE_TOGGLE = 1

// ColorCycle como feature do stage (CC0_ENABLE espelha isto)
constant STAGE_ENABLE_COLORCYCLE = 1
// Habilita ou desabilita motor do tileswap
constant STAGE_TSWAP_ENABLE = 1

// Ajustes de movimentação (stage/debug)
constant STAGE_INPUT_DRIVE_WORLDX = 1
constant STAGE_INPUT_WORLDX_SPEED = 1


// ============================================================================
// Stage WRAM block (boilerplate)
// - Padrão: $0200..$02FF (256 bytes)
// - Não passar de $0700 (HDMA_CGRAM_* começa em $0700).
// ============================================================================
constant STAGE_ANIM_WRAM_BASE = $0200
constant STAGE_ANIM_WRAM_SIZE = $0100

// ============================================================================
// VRAM layout do stage (endereços em bytes)
// ----------------------------------------------------------------------------
// Ajuste aqui o mapeamento de tiles/tilemaps de cada cenário.
// O core/game.asm usa estes valores no upload inicial via DMA para VRAM.
// ----------------------------------------------------------------------------
constant VRAM_BG1_TILES = $0000
constant VRAM_BG1_MAP   = $4800 // 64x64 => $2000 bytes

constant VRAM_BG2_TILES = $8000
constant VRAM_BG2_MAP   = $F000 // 64x32 => $1000 bytes

// Valores pré-calculados para registradores de base de tiles/map:
// - BG12NBA ($210B): base de CHR de BG1/BG2
// - BG1SC   ($2107): base/size do tilemap de BG1
// - BG2SC   ($2108): base/size do tilemap de BG2
constant REG_BG12NBA = $40
constant REG_BG1SC   = $27
constant REG_BG2SC   = $79


// ============================================================================
// HDMA bands (5 bandas)
// Altura máxima por banda = 128 linhas
// Compatibilidade com layout legado de 4 bandas:
// - B4 fica com 1 linha
// - Garanta soma final de 224 linhas em BG1.
// - Garanta soma final de 224 linhas em BG2.
// ============================================================================
constant BG1_BAND0_LINES = 127
constant BG1_BAND1_LINES = 16
constant BG1_BAND2_LINES = 16
constant BG1_BAND3_LINES = 24
constant BG1_BAND4_LINES = 40

constant BG2_BAND0_LINES = 96
constant BG2_BAND1_LINES = 96
constant BG2_BAND2_LINES = 16
constant BG2_BAND3_LINES = 24
constant BG2_BAND4_LINES = 40


// ============================================================================
// Parallax ratios (byte, Q0.8)
// - $80 ≈ 0.5
// - $FF ≈ ~1.0 (255/256)
// ============================================================================
constant BG1_RATIO_B0 = $0A
constant BG1_RATIO_B1 = $0B
constant BG1_RATIO_B2 = $14
constant BG1_RATIO_B3 = $FA
constant BG1_RATIO_B4 = $FF

constant BG2_RATIO_B0 = $40
constant BG2_RATIO_B1 = $40
constant BG2_RATIO_B2 = $40
constant BG2_RATIO_B3 = $80
constant BG2_RATIO_B4 = $FF


// ============================================================================
// Stage offsets (word)
// ============================================================================
constant STAGE_BG1_X_OFFSET = $0000
constant STAGE_BG1_Y_OFFSET = $0000
constant STAGE_BG2_X_OFFSET = $0000
constant STAGE_BG2_Y_OFFSET = $0008


// ============================================================================
// (1) ScrollTracks (até 5) — HOFS subpixel
// ----------------------------------------------------------------------------
// Campos:
// - ENABLE: 0/1
// - TARGET_BG: 1=BG1, 2=BG2 (mantido por compatibilidade / futuro)
// - BAND: 0..4 (B0..B4)      (mantido por compatibilidade / futuro)
// - DIR: 0=+ 1=-
// - SPEED_INT: pixels/frame (word) (normalmente 0 ou 1)
// - SPEED_FRAC: fração/256 (byte) ex.: 128=0.5 px/frame
// - WRAP_MASK: word (ex.: $01FF)
// - APPLY_MODE: 0=ADD (soma com parallax), 1=SET (substitui HOFS da banda)
//
// Exemplos:
// - 0.5 px/frame  => INT=0 FRAC=128
// - 0.25 px/frame => INT=0 FRAC=64
// - 1.25 px/frame => INT=1 FRAC=64
//
// Nota:
// - O motor atual aplica até 5 tracks.
// - TARGET_BG e BAND ficam guardados aqui para evolução futura.
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
constant STAGE_SCROLL_TRACK1_SPEED_FRAC = 128
constant STAGE_SCROLL_TRACK1_WRAP_MASK = $01FF
constant STAGE_SCROLL_TRACK1_APPLY_MODE = 0

// Track2 (BG Band2)
constant STAGE_SCROLL_TRACK2_ENABLE = 0
constant STAGE_SCROLL_TRACK2_TARGET_BG = 2
constant STAGE_SCROLL_TRACK2_BAND = 2
constant STAGE_SCROLL_TRACK2_DIR = 1
constant STAGE_SCROLL_TRACK2_SPEED_INT = 1
constant STAGE_SCROLL_TRACK2_SPEED_FRAC = 64
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
constant STAGE_SCROLL_TRACK4_ENABLE    = 0
constant STAGE_SCROLL_TRACK4_TARGET_BG = 2
constant STAGE_SCROLL_TRACK4_BAND      = 4
constant STAGE_SCROLL_TRACK4_DIR       = 0
constant STAGE_SCROLL_TRACK4_SPEED_INT  = 0
constant STAGE_SCROLL_TRACK4_SPEED_FRAC = $FF
constant STAGE_SCROLL_TRACK4_WRAP_MASK  = $01FF
constant STAGE_SCROLL_TRACK4_APPLY_MODE = 0


// ============================================================================
// (2) ColorCycle (até 4 instâncias) — LEN 2..6
// ----------------------------------------------------------------------------
// - Roda só em VBlank e é safe com gradiente (muta CH2/CH3 durante a troca).
// - Scheduler safe: no máximo 1 instância aplicada por frame (round-robin).
// - MODE por instância:
//   0=loop infinito
//   1=burst e para
//   2=burst, pausa e repete
// - BURST_STEPS = LEN * BURST_LOOPS (manter <= 255)
// ============================================================================

// CC0 (ON por default se STAGE_ENABLE_COLORCYCLE=1)
constant STAGE_CC0_ENABLE = STAGE_ENABLE_COLORCYCLE

constant STAGE_CC0_SUBPAL = 3
constant STAGE_CC0_LEN = 3
constant STAGE_CC0_DIR = 1
constant STAGE_CC0_DELAY = 10
constant STAGE_CC0_MODE   = 0
constant STAGE_CC0_BURST_LOOPS = 3
constant STAGE_CC0_BURST_STEPS = (STAGE_CC0_LEN * STAGE_CC0_BURST_LOOPS)
constant STAGE_CC0_PAUSE_FRAMES = 120

// Offsets dentro da subpaleta (0..15). Usa só os LEN primeiros.
constant STAGE_CC0_OFF0 = 6
constant STAGE_CC0_OFF1 = 7
constant STAGE_CC0_OFF2 = 2
constant STAGE_CC0_OFF3 = 9
constant STAGE_CC0_OFF4 = 8
constant STAGE_CC0_OFF5 = 10

// CC1 (OFF por default)
constant STAGE_CC1_ENABLE = 0

constant STAGE_CC1_SUBPAL = 6
constant STAGE_CC1_LEN = 2
constant STAGE_CC1_DIR = 1
constant STAGE_CC1_DELAY = 1
constant STAGE_CC1_MODE   = 2
constant STAGE_CC1_BURST_LOOPS = 2
constant STAGE_CC1_BURST_STEPS = (STAGE_CC1_LEN * STAGE_CC1_BURST_LOOPS)
constant STAGE_CC1_PAUSE_FRAMES = 120

constant STAGE_CC1_OFF0 = 14
constant STAGE_CC1_OFF1 = 15
constant STAGE_CC1_OFF2 = 11
constant STAGE_CC1_OFF3 = 3
constant STAGE_CC1_OFF4 = 4
constant STAGE_CC1_OFF5 = 5

// CC2 (OFF por default)
constant STAGE_CC2_ENABLE = 0

constant STAGE_CC2_SUBPAL = 1
constant STAGE_CC2_LEN    = 3
constant STAGE_CC2_DIR    = 0
constant STAGE_CC2_DELAY  = 6
constant STAGE_CC2_MODE   = 0
constant STAGE_CC2_BURST_LOOPS = 3
constant STAGE_CC2_BURST_STEPS = (STAGE_CC2_LEN * STAGE_CC2_BURST_LOOPS)
constant STAGE_CC2_PAUSE_FRAMES = 120

constant STAGE_CC2_OFF0 = 1
constant STAGE_CC2_OFF1 = 2
constant STAGE_CC2_OFF2 = 3
constant STAGE_CC2_OFF3 = 4
constant STAGE_CC2_OFF4 = 5
constant STAGE_CC2_OFF5 = 6

// CC3 (OFF por default)
constant STAGE_CC3_ENABLE = 0

constant STAGE_CC3_SUBPAL = 4
constant STAGE_CC3_LEN    = 3
constant STAGE_CC3_DIR    = 1
constant STAGE_CC3_DELAY  = 7
constant STAGE_CC3_MODE   = 0
constant STAGE_CC3_BURST_LOOPS = 3
constant STAGE_CC3_BURST_STEPS = (STAGE_CC3_LEN * STAGE_CC3_BURST_LOOPS)
constant STAGE_CC3_PAUSE_FRAMES = 120

constant STAGE_CC3_OFF0 = 9
constant STAGE_CC3_OFF1 = 10
constant STAGE_CC3_OFF2 = 11
constant STAGE_CC3_OFF3 = 12
constant STAGE_CC3_OFF4 = 13
constant STAGE_CC3_OFF5 = 14

// Índices absolutos derivados (0..255) — até 6 cores por instância
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
constant STAGE_CGRAM_GRAD_COLOR_B = $0026     // cor final (BGR555 word)

constant STAGE_CGRAM_GRAD_LINES_PER_ENTRY = 2
constant STAGE_CGRAM_GRAD_ENTRIES = (224 / STAGE_CGRAM_GRAD_LINES_PER_ENTRY) // 112
constant STAGE_CGRAM_GRAD_DENOM_HIRES = (STAGE_CGRAM_GRAD_ENTRIES - 1)           // 111
constant STAGE_CGRAM_GRAD_ROUND_HIRES = (STAGE_CGRAM_GRAD_DENOM_HIRES / 2)       // 55


// ============================================================================
// TileSwap v2 (config) — “lib”
// ----------------------------------------------------------------------------
// Regras/limites (conservador):
// - MAX_FRAMES por job: 8  (FR0..FR7)
// - MAX_SEQ_STEPS: 16      (Seq 0..15)
// - 1 DMA por frame (scheduler)
// - Patch do tilemap roda só dentro do VBlank (NMI)
// - Repatch automático (sem config): a máquina decide a frequência e limita
//   no máx 1 patch/job por frame.
//
// Importante (para não dar merda):
// - Cada frame CHR precisa ter exatamente: (W * H * 32) bytes.
// - A sequência (Seq) só pode usar índices: 0 .. (NUM_FRAMES - 1).
// - Targets são (col,row) em tiles.
//   BG1 64x64: col 0..63, row 0..63
//   BG2 64x32: col 0..63, row 0..31
//
// IMPORTANTE p/ manter o tileswap “caixa preta” com MAX_FRAMES=8:
// - Garanta que existem labels FR0..FR7 no stage.asm do stage selecionado.
//   Se você só tem 5 frames hoje, crie FR5..FR7 duplicando o último frame.
//   (Assim o tileswap.asm pode ter tabela fixa de 8 sem você mexer nele.)
//
// GAP (pausa após terminar a sequência; em frames, ~60fps se só 1 job ativo)
//  0    = sem pausa (loop infinito como antes)
// 30    = ~0.5s
// 60    = ~1s
// 120   = ~2s
// 300   = ~5s
// 600   = ~10s
//
// Obs: com 2 jobs ativos, o job roda ~1x a cada 2 frames (pausa dobra);
//      com 3 jobs, ~1x a cada 3 frames (pausa triplica).
//
// Estado atual do core (importante):
// - STAGE_TSWAP_ENABLE=1 requer STAGE_TSWAP_JOB0_ENABLE=1.
// - JOB2/JOB3 fazem patch de targets em background (1 target por tick do job).
// - Em listas grandes de targets, os ultimos alvos podem aparecer alguns frames
//   depois do boot ate o patch inicial terminar.
//
// Regra de layout atual (cenários padrão deste projeto):
// - Máximo de 2 jobs no mesmo BG.
// - Se 3 jobs apontarem para o mesmo BG, o JOB2 entra em fail seguro.
//
// Regra prática atual para JOB0:
// - Multi-target e suportado.
// - Quando TARGET_COUNT > 1, o core patcha 1 target por NMI e desliga o double-buffer do JOB0.
// - Para cenários novos, prefira DELAY >= TARGET_COUNT para o ciclo fechar sem artefato visual.
//
// Combinações seguras rápidas:
// - Até 2 jobs por BG.
// - JOB0 grande + JOB1 pequeno em BG diferente e uma combinação estável.
// - Em cenários com carga alta, aumente DELAY antes de aumentar número de jobs.
// ============================================================================

constant STAGE_TSWAP_JOB0_ENABLE = 1
constant STAGE_TSWAP_JOB0_TARGET_BG = 1       // 1=BG1, 2=BG2

// Tamanho do retângulo em tiles (8x8):
// Ex.: 5x4 => 40x32 px
constant STAGE_TSWAP_JOB0_W = 5
constant STAGE_TSWAP_JOB0_H = 10

// Tilemap bits (pal/priority). (flip opcional no futuro)
constant STAGE_TSWAP_JOB0_PAL = 3
constant STAGE_TSWAP_JOB0_PRIO = 0
constant STAGE_TSWAP_JOB0_PAL_BITS = ((STAGE_TSWAP_JOB0_PAL << 10) | (STAGE_TSWAP_JOB0_PRIO << 13))

// Velocidade (frames por step):
// - 2  ~= 30 fps (NTSC)
// - 4  ~= 15 fps
// - 8  ~= ~7.5 fps (bem lento)
constant STAGE_TSWAP_JOB0_DELAY = 2
// Dica de tuning:
// - Com JOB0 multi-target, mantenha DELAY >= TARGET_COUNT para reduzir risco de patch parcial.
// Quantos frames existem/serão usados (0..7). Máx recomendado = 8.
// Você pode inserir 6 frames e testar com 4 aqui.
constant STAGE_TSWAP_JOB0_NUM_FRAMES = 7
//Tempo de espaço parado entre as animações  
// 0     = sem pausa (loop infinito)
// 30    = ~0.5s
// 60    = ~1s
// 120   = ~2s
// 300   = ~5s
// 600   = ~10s
constant STAGE_TSWAP_JOB0_GAP = 0

// Sequência (até 16 steps). Use índices 0..NUM_FRAMES-1.
// Ping-pong/repetições = só escrever na tabela.
Stage_TSwapJob0_Seq:
  db $00
  db $01
  db $02
  db $03
  db $04
  db $05
  db $06
  db $05
  db $04
  db $03
  db $02
  db $01
Stage_TSwapJob0_Seq_End:

constant STAGE_TSWAP_JOB0_SEQ_LEN = (Stage_TSwapJob0_Seq_End - Stage_TSwapJob0_Seq)

// Targets (col,row) — estilo Mesen (tiles).
// Repetição no cenário = mais pares aqui.
Stage_TSwapJob0_Targets:
  db 6
  db 8
  db 25
  db 8
Stage_TSwapJob0_Targets_End:

constant STAGE_TSWAP_JOB0_TARGET_COUNT = ((Stage_TSwapJob0_Targets_End - Stage_TSwapJob0_Targets) / 2)
// Ao adicionar/remover targets, revise STAGE_TSWAP_JOB0_DELAY.

//-------------------------------------------------------------------------------------------------------
// Configuração para o JOB 1 do tileswap
//-------------------------------------------------------------------------------------------------------

constant STAGE_TSWAP_JOB1_ENABLE = 1
constant STAGE_TSWAP_JOB1_TARGET_BG = 2        // 1=BG1, 2=BG2

constant STAGE_TSWAP_JOB1_W = 2
constant STAGE_TSWAP_JOB1_H = 2

constant STAGE_TSWAP_JOB1_PAL = 5
constant STAGE_TSWAP_JOB1_PRIO = 0
constant STAGE_TSWAP_JOB1_PAL_BITS = ((STAGE_TSWAP_JOB1_PAL << 10) | (STAGE_TSWAP_JOB1_PRIO << 13))

constant STAGE_TSWAP_JOB1_DELAY = 1
constant STAGE_TSWAP_JOB1_NUM_FRAMES = 8
constant STAGE_TSWAP_JOB1_GAP = 110

Stage_TSwapJob1_Seq:
  db $00
  db $01
  db $02
  db $03
  db $04
  db $05
  db $06
  db $00
  db $01
  db $02
  db $03
  db $04
  db $05
  db $06
  db $07
Stage_TSwapJob1_Seq_End:

constant STAGE_TSWAP_JOB1_SEQ_LEN = (Stage_TSwapJob1_Seq_End - Stage_TSwapJob1_Seq)

Stage_TSwapJob1_Targets:
  db 24
  db 15
Stage_TSwapJob1_Targets_End:

constant STAGE_TSWAP_JOB1_TARGET_COUNT = ((Stage_TSwapJob1_Targets_End - Stage_TSwapJob1_Targets) / 2)

//-------------------------------------------------------------------------------------------------------
// Configuração para o JOB 2 do tileswap
//-------------------------------------------------------------------------------------------------------
constant STAGE_TSWAP_JOB2_ENABLE = 0
constant STAGE_TSWAP_JOB2_TARGET_BG = 1        // 1=BG1, 2=BG2

constant STAGE_TSWAP_JOB2_W = 5
constant STAGE_TSWAP_JOB2_H = 10

constant STAGE_TSWAP_JOB2_PAL = 3
constant STAGE_TSWAP_JOB2_PRIO = 0
constant STAGE_TSWAP_JOB2_PAL_BITS = ((STAGE_TSWAP_JOB2_PAL << 10) | (STAGE_TSWAP_JOB2_PRIO << 13))

constant STAGE_TSWAP_JOB2_DELAY = 2
constant STAGE_TSWAP_JOB2_NUM_FRAMES = 7
constant STAGE_TSWAP_JOB2_GAP = 0

Stage_TSwapJob2_Seq:
  db $00
  db $01
  db $02
  db $03
  db $04
  db $05
  db $06
  db $05
  db $04
  db $03
  db $02
  db $01
Stage_TSwapJob2_Seq_End:

constant STAGE_TSWAP_JOB2_SEQ_LEN = (Stage_TSwapJob2_Seq_End - Stage_TSwapJob2_Seq)

Stage_TSwapJob2_Targets:
  db 25
  db 8
Stage_TSwapJob2_Targets_End:

constant STAGE_TSWAP_JOB2_TARGET_COUNT = ((Stage_TSwapJob2_Targets_End - Stage_TSwapJob2_Targets) / 2)

//-------------------------------------------------------------------------------------------------------
// Configuração para o JOB 3 do tileswap
// Controle manual: ENABLE 0/1
//-------------------------------------------------------------------------------------------------------
constant STAGE_TSWAP_JOB3_ENABLE    = 0
constant STAGE_TSWAP_JOB3_TARGET_BG = 1        // 1=BG1, 2=BG2

constant STAGE_TSWAP_JOB3_W = 5
constant STAGE_TSWAP_JOB3_H = 11

constant STAGE_TSWAP_JOB3_PAL  = 7
constant STAGE_TSWAP_JOB3_PRIO = 1
constant STAGE_TSWAP_JOB3_PAL_BITS = ((STAGE_TSWAP_JOB3_PAL << 10) | (STAGE_TSWAP_JOB3_PRIO << 13))

constant STAGE_TSWAP_JOB3_DELAY = 7
constant STAGE_TSWAP_JOB3_NUM_FRAMES = 7
constant STAGE_TSWAP_JOB3_GAP = 0

Stage_TSwapJob3_Seq:
  db $00
  db $01
  db $02
  db $03
  db $04
  db $05
  db $06
  db $05
  db $04
  db $03
  db $02
  db $01
Stage_TSwapJob3_Seq_End:

constant STAGE_TSWAP_JOB3_SEQ_LEN = (Stage_TSwapJob3_Seq_End - Stage_TSwapJob3_Seq)

Stage_TSwapJob3_Targets:
  db 20
  db 6
Stage_TSwapJob3_Targets_End:

constant STAGE_TSWAP_JOB3_TARGET_COUNT = ((Stage_TSwapJob3_Targets_End - Stage_TSwapJob3_Targets) / 2)
