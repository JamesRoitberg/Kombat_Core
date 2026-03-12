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
  insert "assets/wasteland-bg1.pal"
BG1_Palette_End:

BG1_Tiles:
  insert "assets/wasteland-bg1.chr"
BG1_Tiles_End:

// Bank: BG1 map sozinho (64x64 = 0x2000)
seek($0D8000)

BG1_Map:
  insert "assets/wasteland-bg1.map"
BG1_Map_End:


// Bank: BG2 palette + tiles + map
seek($0E8000)

BG2_Palette:
  insert "assets/wasteland-bg2.pal"
BG2_Palette_End:

BG2_Tiles:
  insert "assets/wasteland-bg2.chr"
BG2_Tiles_End:

BG2_Map:
  insert "assets/wasteland-bg2.map"
BG2_Map_End:

// -----------------------------------------------------------------------------
// Nota de TileSwap deste stage:
// - Quando STAGE_TSWAP_ENABLE = 0, nao exporte labels FR/Seq/Targets.
// - Quando TileSwap estiver OFF, mantenha somente BG assets + config.
// -----------------------------------------------------------------------------

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
