// stage.asm
// -----------------------------------------------------------------------------
// Stage package (plug-in do core)
// Pacote do stage:
// - Assets (pal/chr/map) com labels canônicas esperadas pelo core
// - Constantes de layout de CGRAM por stage
// - Configuração do stage
// - Implementa o contrato definido em core/stage_contract.asm
// -----------------------------------------------------------------------------

// ============================================================================
// Assets do cenário (fora do bank $00 para não conflitar com header/vetores/código)
// Nota: nesta fase (build-time stage select com 1 stage por ROM), os seeks fixos
// abaixo são seguros porque não há empacotamento simultâneo de múltiplos stages.
// ============================================================================

// Bank: BG1 palette + tiles
seek($0C8000)

BG1_Palette:
  insert "assets/kahns-arena-bg1.pal"
BG1_Palette_End:

BG1_Tiles:
  insert "assets/kahns-arena-bg1.chr"
BG1_Tiles_End:

// Bank: BG1 map sozinho (64x64 = 0x2000)
seek($0D8000)

BG1_Map:
  insert "assets/kahns-arena-bg1.map"
BG1_Map_End:


// Bank: BG2 palette + tiles + map + animation chr
seek($0E8000)

BG2_Palette:
  insert "assets/kahns-arena-bg2.pal"
BG2_Palette_End:

BG2_Tiles:
  insert "assets/kahns-arena-bg2.chr"
BG2_Tiles_End:

BG2_Map:
  insert "assets/kahns-arena-bg2.map"
BG2_Map_End:

// -----------------------------------------------------------------------------
// Nota de TileSwap deste stage:
// - Este stage usa JOB0/JOB1 para animacoes grandes no BG2.
// - Este stage usa JOB2/JOB3 para animacoes menores da plateia no BG1.
// - Mantenha em OFF no config os jobs que nao forem usados.
//
// -----------------------------------------------------------------------------
seek($0F8000)

// JOB0: animacao grande A.
TSWAP_JOB0_FR0:
  insert "assets/kano-anim-01.chr"
TSWAP_JOB0_FR0_End:

TSWAP_JOB0_FR1:
  insert "assets/kano-anim-02.chr"
TSWAP_JOB0_FR1_End:

TSWAP_JOB0_FR2:
  insert "assets/kano-anim-03.chr"
TSWAP_JOB0_FR2_End:

TSWAP_JOB0_FR3:
  insert "assets/kano-anim-04.chr"
TSWAP_JOB0_FR3_End:

TSWAP_JOB0_FR4:
  insert "assets/kano-anim-05.chr"
TSWAP_JOB0_FR4_End:

TSWAP_JOB0_FR5:
  insert "assets/kano-anim-06.chr"
TSWAP_JOB0_FR5_End:

TSWAP_JOB0_FR6:
  insert "assets/kano-anim-01.chr"
TSWAP_JOB0_FR6_End:

TSWAP_JOB0_FR7:
  insert "assets/kano-anim-01.chr"
TSWAP_JOB0_FR7_End:

// JOB1: animacao grande B.
seek((TSWAP_JOB0_FR7_End + $001F) & $FFFFE0)

TSWAP_JOB1_FR0:
  insert "assets/sonya-anim-01.chr"
TSWAP_JOB1_FR0_End:

TSWAP_JOB1_FR1:
  insert "assets/sonya-anim-02.chr"
TSWAP_JOB1_FR1_End:

TSWAP_JOB1_FR2:
  insert "assets/sonya-anim-03.chr"
TSWAP_JOB1_FR2_End:

TSWAP_JOB1_FR3:
  insert "assets/sonya-anim-04.chr"
TSWAP_JOB1_FR3_End:

TSWAP_JOB1_FR4:
  insert "assets/sonya-anim-05.chr"
TSWAP_JOB1_FR4_End:

TSWAP_JOB1_FR5:
  insert "assets/sonya-anim-06.chr"
TSWAP_JOB1_FR5_End:

TSWAP_JOB1_FR6:
  insert "assets/sonya-anim-07.chr"
TSWAP_JOB1_FR6_End:

TSWAP_JOB1_FR7:
  insert "assets/sonya-anim-08.chr"
TSWAP_JOB1_FR7_End:

// JOB2: animacao menor A.
seek((TSWAP_JOB1_FR7_End + $001F) & $FFFFE0)

TSWAP_JOB2_FR0:
  insert "assets/kahns-crowd-01.chr"
TSWAP_JOB2_FR0_End:

TSWAP_JOB2_FR1:
  insert "assets/kahns-crowd-03.chr"
TSWAP_JOB2_FR1_End:

TSWAP_JOB2_FR2:
  insert "assets/kahns-crowd-05.chr"
TSWAP_JOB2_FR2_End:

TSWAP_JOB2_FR3:
  insert "assets/kahns-crowd-05.chr"
TSWAP_JOB2_FR3_End:

TSWAP_JOB2_FR4:
  insert "assets/kahns-crowd-05.chr"
TSWAP_JOB2_FR4_End:

TSWAP_JOB2_FR5:
  insert "assets/kahns-crowd-05.chr"
TSWAP_JOB2_FR5_End:

TSWAP_JOB2_FR6:
  insert "assets/kahns-crowd-05.chr"
TSWAP_JOB2_FR6_End:

TSWAP_JOB2_FR7:
  insert "assets/kahns-crowd-05.chr"
TSWAP_JOB2_FR7_End:

// JOB3: animacao menor B.
seek((TSWAP_JOB2_FR7_End + $001F) & $FFFFE0)

TSWAP_JOB3_FR0:
  insert "assets/kahns-crowd-02.chr"
TSWAP_JOB3_FR0_End:

TSWAP_JOB3_FR1:
  insert "assets/kahns-crowd-04.chr"
TSWAP_JOB3_FR1_End:

TSWAP_JOB3_FR2:
  insert "assets/kahns-crowd-06.chr"
TSWAP_JOB3_FR2_End:

TSWAP_JOB3_FR3:
  insert "assets/kahns-crowd-06.chr"
TSWAP_JOB3_FR3_End:

TSWAP_JOB3_FR4:
  insert "assets/kahns-crowd-06.chr"
TSWAP_JOB3_FR4_End:

TSWAP_JOB3_FR5:
  insert "assets/kahns-crowd-06.chr"
TSWAP_JOB3_FR5_End:

TSWAP_JOB3_FR6:
  insert "assets/kahns-crowd-06.chr"
TSWAP_JOB3_FR6_End:

TSWAP_JOB3_FR7:
  insert "assets/kahns-crowd-06.chr"
TSWAP_JOB3_FR7_End:

// ============================================================================
// Stage config (CGRAM layout) — usado pelo core/game.asm
// ============================================================================

// BG1 starts at subpalette 2 => 2 * 16 colors = $20
constant STAGE_BG1_CGADD = (2 * 16)

// Tamanho do BG1 em CORES (não bytes)
constant STAGE_BG1_PAL_COLORS = ((BG1_Palette_End - BG1_Palette) / 2)

// BG2 começa logo após BG1 (em índices de cor)
constant STAGE_BG2_CGADD = (STAGE_BG1_CGADD + STAGE_BG1_PAL_COLORS)

// Volta para o bank de código e aplica o config do stage
seek($008000)
include "config.asm"
