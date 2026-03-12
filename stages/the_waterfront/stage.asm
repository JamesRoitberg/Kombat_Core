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
  insert "assets/waterfront1.pal"
BG1_Palette_End:

BG1_Tiles:
  insert "assets/waterfront1.chr"
BG1_Tiles_End:

// Bank: BG1 map sozinho (64x64 = 0x2000)
seek($0D8000)

BG1_Map:
  insert "assets/waterfront1.map"
BG1_Map_End:


// Bank: BG2 palette + tiles + map
seek($0E8000)

BG2_Palette:
  insert "assets/waterfront2.pal"
BG2_Palette_End:

BG2_Tiles:
  insert "assets/waterfront2.chr"
BG2_Tiles_End:

BG2_Map:
  insert "assets/waterfront2.map"
BG2_Map_End:

// -----------------------------------------------------------------------------
// Blocos de assets de TileSwap deste stage:
// - JOB0/JOB1 abaixo sao exemplos de jobs ativos.
// - Ajuste/remocao de jobs conforme necessidade do stage.
// - Evite manter assets dummy quando o job estiver OFF.
// -----------------------------------------------------------------------------

// Bank: animacoes JOB0
seek($0F8000)

TSWAP_JOB0_FR0:
  insert "assets/river-anim-01.chr"
TSWAP_JOB0_FR0_End:

TSWAP_JOB0_FR1:
  insert "assets/river-anim-02.chr"
TSWAP_JOB0_FR1_End:

TSWAP_JOB0_FR2:
  insert "assets/river-anim-03.chr"
TSWAP_JOB0_FR2_End:

TSWAP_JOB0_FR3:
  insert "assets/river-anim-04.chr"
TSWAP_JOB0_FR3_End:

TSWAP_JOB0_FR4:
  insert "assets/river-anim-05.chr"
TSWAP_JOB0_FR4_End:

TSWAP_JOB0_FR5:
  insert "assets/river-anim-06.chr"
TSWAP_JOB0_FR5_End:

TSWAP_JOB0_FR6:
  insert "assets/river-anim-07.chr"
TSWAP_JOB0_FR6_End:

TSWAP_JOB0_FR7:
  insert "assets/river-anim-07.chr"
TSWAP_JOB0_FR7_End:

// Bank: animacoes JOB1
seek($108000)

TSWAP_JOB1_FR0:
  insert "assets/lamp-anim-01.chr"
TSWAP_JOB1_FR0_End:

TSWAP_JOB1_FR1:
  insert "assets/lamp-anim-02.chr"
TSWAP_JOB1_FR1_End:

TSWAP_JOB1_FR2:
  insert "assets/lamp-anim-03.chr"
TSWAP_JOB1_FR2_End:

TSWAP_JOB1_FR3:
  insert "assets/lamp-anim-04.chr"
TSWAP_JOB1_FR3_End:

TSWAP_JOB1_FR4:
  insert "assets/lamp-anim-05.chr"
TSWAP_JOB1_FR4_End:

TSWAP_JOB1_FR5:
  insert "assets/lamp-anim-06.chr"
TSWAP_JOB1_FR5_End:

TSWAP_JOB1_FR6:
  insert "assets/lamp-anim-07.chr"
TSWAP_JOB1_FR6_End:

TSWAP_JOB1_FR7:
  insert "assets/lamp-anim-07.chr"
TSWAP_JOB1_FR7_End:

// ============================================================================
// Stage config (CGRAM layout) — usado pelo core/game.asm
// ============================================================================

// Ajuste BG1_CGADD conforme a organizacao de subpaletas deste stage.
constant STAGE_BG1_CGADD = (1 * 16)

// Tamanho do BG1 em CORES (não bytes)
constant STAGE_BG1_PAL_COLORS = ((BG1_Palette_End - BG1_Palette) / 2)

// BG2 começa logo após BG1 (em índices de cor)
constant STAGE_BG2_CGADD = (STAGE_BG1_CGADD + STAGE_BG1_PAL_COLORS)

// Volta para o bank de código e aplica o config do stage
seek($008000)
include "config.asm"
