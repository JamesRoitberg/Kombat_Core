// stage.asm
// -----------------------------------------------------------------------------
// Stage package template
// Pacote do stage:
// - Assets (pal/chr/map) com labels canonicas esperadas pelo core
// - Labels de frames FR0..FR7 para JOB0..JOB3 (TileSwap)
// - Constantes de layout de CGRAM por stage
// - Include do config.asm do stage
// -----------------------------------------------------------------------------

// ============================================================================
// Assets base do cenario
// Como 1 stage e montado por ROM, os seeks fixos abaixo nao conflitam.
// ============================================================================

// Bank: BG1 palette + tiles
seek($0C8000)

BG1_Palette:
  insert "assets/default-bg1.pal"
BG1_Palette_End:

BG1_Tiles:
  insert "assets/default-bg1.chr"
BG1_Tiles_End:

// Bank: BG1 map
seek($0D8000)

BG1_Map:
  insert "assets/default-bg1.map"
BG1_Map_End:

// Bank: BG2 palette + tiles + map
seek($0E8000)

BG2_Palette:
  insert "assets/default-bg2.pal"
BG2_Palette_End:

BG2_Tiles:
  insert "assets/default-bg2.chr"
BG2_Tiles_End:

BG2_Map:
  insert "assets/default-bg2.map"
BG2_Map_End:


// ============================================================================
// TileSwap dummy frames (JOB0..JOB3)
// - Mesmo com jobs OFF no config, as labels ficam prontas para copiar/editar.
// - Ao habilitar um job, troque os arquivos abaixo pelos CHRs reais do cenario.
// - Cada frame deve respeitar: (W * H * 32) bytes definidos no config.
// ============================================================================
seek($0F8000)

// JOB0 FR0..FR7
TSWAP_JOB0_FR0:
  insert "assets/tswap-job0-fr0.chr"
TSWAP_JOB0_FR0_End:

TSWAP_JOB0_FR1:
  insert "assets/tswap-job0-fr1.chr"
TSWAP_JOB0_FR1_End:

TSWAP_JOB0_FR2:
  insert "assets/tswap-job0-fr2.chr"
TSWAP_JOB0_FR2_End:

TSWAP_JOB0_FR3:
  insert "assets/tswap-job0-fr3.chr"
TSWAP_JOB0_FR3_End:

TSWAP_JOB0_FR4:
  insert "assets/tswap-job0-fr4.chr"
TSWAP_JOB0_FR4_End:

TSWAP_JOB0_FR5:
  insert "assets/tswap-job0-fr5.chr"
TSWAP_JOB0_FR5_End:

TSWAP_JOB0_FR6:
  insert "assets/tswap-job0-fr6.chr"
TSWAP_JOB0_FR6_End:

TSWAP_JOB0_FR7:
  insert "assets/tswap-job0-fr7.chr"
TSWAP_JOB0_FR7_End:

// JOB1 FR0..FR7
seek((TSWAP_JOB0_FR7_End + $001F) & $FFFFE0)

TSWAP_JOB1_FR0:
  insert "assets/tswap-job1-fr0.chr"
TSWAP_JOB1_FR0_End:

TSWAP_JOB1_FR1:
  insert "assets/tswap-job1-fr1.chr"
TSWAP_JOB1_FR1_End:

TSWAP_JOB1_FR2:
  insert "assets/tswap-job1-fr2.chr"
TSWAP_JOB1_FR2_End:

TSWAP_JOB1_FR3:
  insert "assets/tswap-job1-fr3.chr"
TSWAP_JOB1_FR3_End:

TSWAP_JOB1_FR4:
  insert "assets/tswap-job1-fr4.chr"
TSWAP_JOB1_FR4_End:

TSWAP_JOB1_FR5:
  insert "assets/tswap-job1-fr5.chr"
TSWAP_JOB1_FR5_End:

TSWAP_JOB1_FR6:
  insert "assets/tswap-job1-fr6.chr"
TSWAP_JOB1_FR6_End:

TSWAP_JOB1_FR7:
  insert "assets/tswap-job1-fr7.chr"
TSWAP_JOB1_FR7_End:

// JOB2 FR0..FR7
seek((TSWAP_JOB1_FR7_End + $001F) & $FFFFE0)

TSWAP_JOB2_FR0:
  insert "assets/tswap-job2-fr0.chr"
TSWAP_JOB2_FR0_End:

TSWAP_JOB2_FR1:
  insert "assets/tswap-job2-fr1.chr"
TSWAP_JOB2_FR1_End:

TSWAP_JOB2_FR2:
  insert "assets/tswap-job2-fr2.chr"
TSWAP_JOB2_FR2_End:

TSWAP_JOB2_FR3:
  insert "assets/tswap-job2-fr3.chr"
TSWAP_JOB2_FR3_End:

TSWAP_JOB2_FR4:
  insert "assets/tswap-job2-fr4.chr"
TSWAP_JOB2_FR4_End:

TSWAP_JOB2_FR5:
  insert "assets/tswap-job2-fr5.chr"
TSWAP_JOB2_FR5_End:

TSWAP_JOB2_FR6:
  insert "assets/tswap-job2-fr6.chr"
TSWAP_JOB2_FR6_End:

TSWAP_JOB2_FR7:
  insert "assets/tswap-job2-fr7.chr"
TSWAP_JOB2_FR7_End:

// JOB3 FR0..FR7
seek((TSWAP_JOB2_FR7_End + $001F) & $FFFFE0)

TSWAP_JOB3_FR0:
  insert "assets/tswap-job3-fr0.chr"
TSWAP_JOB3_FR0_End:

TSWAP_JOB3_FR1:
  insert "assets/tswap-job3-fr1.chr"
TSWAP_JOB3_FR1_End:

TSWAP_JOB3_FR2:
  insert "assets/tswap-job3-fr2.chr"
TSWAP_JOB3_FR2_End:

TSWAP_JOB3_FR3:
  insert "assets/tswap-job3-fr3.chr"
TSWAP_JOB3_FR3_End:

TSWAP_JOB3_FR4:
  insert "assets/tswap-job3-fr4.chr"
TSWAP_JOB3_FR4_End:

TSWAP_JOB3_FR5:
  insert "assets/tswap-job3-fr5.chr"
TSWAP_JOB3_FR5_End:

TSWAP_JOB3_FR6:
  insert "assets/tswap-job3-fr6.chr"
TSWAP_JOB3_FR6_End:

TSWAP_JOB3_FR7:
  insert "assets/tswap-job3-fr7.chr"
TSWAP_JOB3_FR7_End:


// ============================================================================
// Stage config (CGRAM layout) - usado pelo core/game.asm
// ============================================================================

// BG1 inicia na subpalette 2 => 2 * 16 colors = $20
constant STAGE_BG1_CGADD = (2 * 16)

// Tamanho do BG1 em cores (nao bytes)
constant STAGE_BG1_PAL_COLORS = ((BG1_Palette_End - BG1_Palette) / 2)

// BG2 comeca logo apos BG1 (em indices de cor)
constant STAGE_BG2_CGADD = (STAGE_BG1_CGADD + STAGE_BG1_PAL_COLORS)

// Volta para o bank de codigo e aplica o config do stage
seek($008000)
include "config.asm"
