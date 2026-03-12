# KOMBAT_CORE

Engine de jogo de luta para SNES em Bass assembler (`wdc65816`).

Estado atual do projeto:
- mapeamento `LoROM`
- ROM de `4MB`
- `FastROM` habilitado no reset via `MEMSEL`
- arquitetura separada em `core` + `stages`

## Visao Geral

O projeto esta migrando de uma engine focada em cenarios para uma base mais ampla de jogo de luta. Neste momento, o foco principal ainda e consolidar os stages e seus subsistemas compartilhados.

O ponto de entrada e `main.asm`. Ele monta o core da engine e inclui um stage selecionado em build-time por `stage_select.asm`.

## Estrutura

```text
core/
  animation.asm
  anim_colorcycle.asm
  anim_gradient.asm
  anim_scrolltrack.asm
  game.asm
  header.asm
  input.asm
  macros.asm
  parallax.asm
  regs.asm
  reset.asm
  stage_contract.asm
  tileswap.asm
  tileswap-stub.asm
  vectors.asm

stages/<stage_name>/
  stage.asm
  config.asm
  assets/

main.asm
stage_select.asm
```

## Arquitetura Atual

- `main.asm`: entrypoint, header, includes do core e montagem final da ROM
- `stage_select.asm`: selecao manual de stage em build-time via `STAGE_BUILD_ID`
- `stages/<nome>/stage.asm`: pacote do stage com assets canonicos, TileSwap frames e include do `config.asm`
- `core/stage_contract.asm`: validacao compile-time do contrato minimo exigido pelo core

## Subsystems

- `input.asm`: leitura de `JOY1` via `$4016` e controle de `BG1_WORLDX`
- `parallax.asm`: scroll por 5 bandas em `BG1` e 5 bandas em `BG2`
- `animation.asm`: init e tick de animacao do stage
- `tileswap.asm`: modulo de TileSwap em VBlank, atualmente com dependencia pratica de `JOB0` quando `STAGE_TSWAP_ENABLE = 1`

## Build

Assembler esperado:
- Bass (fork `Dgdiniz/bass`)

Build esperado:
- montar `main.asm`
- saida padrao em `rom/kombat_core.sfc`

Os arquivos de ROM gerados nao sao versionados neste repositorio.

## Status

Stages ja integrados/testados nesta base:
- The Tower
- The Pit II
- The Portal
- The Wasteland
- The Waterfront
- The Armory
- Kahn's Arena

## Proximos Passos

- expandir e refinar os cenarios
- consolidar o core da engine
- evoluir depois para o futuro `screen core` das telas do jogo
