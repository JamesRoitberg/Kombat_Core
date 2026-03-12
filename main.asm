// main.asm
// -----------------------------------------------------------------------------
// Objetivo:
//   Arquivo “raiz” do projeto (entrypoint do Bass):
//   - Define ROM (output/fill) e macro seek() (mapeamento LoROM).
//   - Inclui módulos compartilhados via core/.
//   - Inclui stage selecionado via stage_select.asm.
//   - Monta todo o código no bank $00 ($008000) para evitar JSL/JML.
//   - Escreve vetores em $00:FFE0-$00:FFFF via core/vectors.asm.
//
// Depende de:
//   - core/regs.asm, core/macros.asm, core/header.asm
//   - stage_select.asm -> stages/<stage>/stage.asm
//   - core/animation.asm, core/parallax.asm, core/reset.asm, core/game.asm
//   - core/vectors.asm
//
// Exporta:
//   - Labels de assets (BG1_Palette/BG1_Tiles/BG1_Map, BG2_*)
//   - Constantes de stage consumidas pelo core (fornecidas pelo stage selecionado)
//
// Regras práticas (Bass):
//   - Arquivos com rotinas (labels + opcodes) devem ser incluídos dentro do seek($008000).
//   - Arquivos só de macros/constants podem ser incluídos fora.
//   - IMPORTANTE: qualquer bloco que será DMA (pal/chr/map) NÃO pode cruzar $xx:FFFF.
// -----------------------------------------------------------------------------

arch wdc65816
output "rom/kombat_core.sfc", create
fill $400000

// -----------------------------------------------------------------------------
// seek(offset):
//   Converte endereço SNES LoROM (bank:addr) para offset de arquivo.
// -----------------------------------------------------------------------------
macro seek(variable offset) {
  origin ((offset & $7F0000) >> 1) | (offset & $7FFF)
  base offset
}

// ============================================================================
// Includes comuns (somente macros/constants/header; NÃO geram código executável)
//
// Observação:
// - header.asm pode ficar aqui desde que ele próprio posicione o header
//   (ex.: seek($00FFC0)) internamente.
// ============================================================================
include "core/regs.asm"
include "core/macros.asm"
include "core/header.asm"

// ============================================================================
// Stage package (assets + labels canônicas + config)
// - Mantém seleção manual via stage_select.asm
// ============================================================================

// ============================================================================
// Código (bank $00) — manter tudo junto para usar JSR/RTS (sem JSL)
// ============================================================================
seek($008000)

// Código executável (rotinas)
include "stage_select.asm"   // seleciona stage em build-time
include "core/stage_contract.asm" // valida contrato mínimo do stage
include "core/animation.asm"
// TileSwap real so quando o stage habilita a feature.
if STAGE_TSWAP_ENABLE == 1 {
  include "core/tileswap.asm"
} else {
  include "core/tileswap-stub.asm"
}
include "core/input.asm"
include "core/parallax.asm"

// Reset + NMI + main loop
include "core/reset.asm"
include "core/game.asm"

// Vetores (writes em $00:FFE0-$00:FFFF via seek interno)
include "core/vectors.asm"
