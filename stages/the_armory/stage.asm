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
  insert "assets/armory-bg1.pal"
BG1_Palette_End:

BG1_Tiles:
  insert "assets/armory-bg1.chr"
BG1_Tiles_End:

// Bank: BG1 map sozinho (64x64 = 0x2000)
seek($0D8000)

BG1_Map:
  insert "assets/armory-bg1.map"
BG1_Map_End:


// Bank: BG2 palette + tiles + map + animation chr
seek($0E8000)

BG2_Palette:
  insert "assets/armory-bg2.pal"
BG2_Palette_End:

BG2_Tiles:
  insert "assets/armory-bg2.chr"
BG2_Tiles_End:

BG2_Map:
  insert "assets/armory-bg2.map"
BG2_Map_End:

// -----------------------------------------------------------------------------
// Nota de TileSwap deste stage:
// - Declare apenas os jobs ativos e mantenha OFF os nao usados.
// - Mantenha jobs nao usados em OFF no config.
//
// -----------------------------------------------------------------------------
seek($0F8000)

TSWAP_JOB0_FR0:
  insert "assets/armory-anim-01.chr"
TSWAP_JOB0_FR0_End:

TSWAP_JOB0_FR1:
  insert "assets/armory-anim-02.chr"
TSWAP_JOB0_FR1_End:

TSWAP_JOB0_FR2:
  insert "assets/armory-anim-03.chr"
TSWAP_JOB0_FR2_End:

TSWAP_JOB0_FR3:
  insert "assets/armory-anim-04.chr"
TSWAP_JOB0_FR3_End:

TSWAP_JOB0_FR4:
  insert "assets/armory-anim-05.chr"
TSWAP_JOB0_FR4_End:

TSWAP_JOB0_FR5:
  insert "assets/armory-anim-06.chr"
TSWAP_JOB0_FR5_End:

TSWAP_JOB0_FR6:
  insert "assets/armory-anim-07.chr"
TSWAP_JOB0_FR6_End:

TSWAP_JOB0_FR7:
  insert "assets/armory-anim-08.chr"
TSWAP_JOB0_FR7_End:

// Chr de Animacoes JOB1 (alinhado apos JOB0)
seek((TSWAP_JOB0_FR7_End + $001F) & $FFFFE0)

TSWAP_JOB1_FR0:
  insert "assets/armory-anim-09.chr"
TSWAP_JOB1_FR0_End:

TSWAP_JOB1_FR1:
  insert "assets/armory-anim-10.chr"
TSWAP_JOB1_FR1_End:

TSWAP_JOB1_FR2:
  insert "assets/armory-anim-11.chr"
TSWAP_JOB1_FR2_End:

TSWAP_JOB1_FR3:
  insert "assets/armory-anim-12.chr"
TSWAP_JOB1_FR3_End:

TSWAP_JOB1_FR4:
  insert "assets/armory-anim-13.chr"
TSWAP_JOB1_FR4_End:

TSWAP_JOB1_FR5:
  insert "assets/armory-anim-14.chr"
TSWAP_JOB1_FR5_End:

TSWAP_JOB1_FR6:
  insert "assets/armory-anim-15.chr"
TSWAP_JOB1_FR6_End:

TSWAP_JOB1_FR7:
  insert "assets/armory-anim-16.chr"
TSWAP_JOB1_FR7_End:

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
