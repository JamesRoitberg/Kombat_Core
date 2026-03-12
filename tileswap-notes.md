# TileSwap Notes

## Objetivo
Guia rapido para configurar e debugar o modulo `tileswap.asm` sem quebrar o comportamento validado do `JOB0`.

## Controle Manual (config.asm)
Cada job e controlado por:
- `STAGE_TSWAP_JOB0_ENABLE` / `STAGE_TSWAP_JOB0_TARGET_BG`
- `STAGE_TSWAP_JOB1_ENABLE` / `STAGE_TSWAP_JOB1_TARGET_BG`
- `STAGE_TSWAP_JOB2_ENABLE` / `STAGE_TSWAP_JOB2_TARGET_BG`
- `STAGE_TSWAP_JOB3_ENABLE` / `STAGE_TSWAP_JOB3_TARGET_BG`

Valores:
- `ENABLE`: `0` desligado, `1` ligado
- `TARGET_BG`: `1=BG1`, `2=BG2`

## Regras Seguras
- Maximo de 2 jobs no mesmo BG.
- Para animacao grande (ex.: `5x11`) no BG2, preferir 1 job por BG.
- Evitar multiplos targets no mesmo job grande no BG2.
- Para repetir animacao grande em varios pontos, preferir jobs separados com mesmo `SEQ`/`DELAY`.

## Combinacoes Recomendadas
- Producao basica: `JOB0` em BG2, demais off.
- Dois BGs: `JOB0` em BG2 + `JOB1` em BG1.
- BG1 com dois pequenos: `JOB1` + `JOB3` no BG1.
- Teste estendido: ate 4 jobs, respeitando maximo de 2 por BG.

## Checklist de Debug
Quando algo nao renderizar:
1. Conferir se `ENABLE=1` no job correto.
2. Conferir `TARGET_BG` (1 ou 2) no job correto.
3. Conferir `W/H` e tamanho real do frame CHR (`W * H * 32` bytes).
4. Conferir `SEQ` (indices dentro de `0..NUM_FRAMES-1`).
5. Conferir `Targets` (coordenadas dentro do mapa do BG).
6. Conferir regra de conflito por BG (nao exceder 2 jobs/BG).
7. Rebuild: `bass main.asm`.

## Referencias
- `config.asm`
- `tileswap.asm`
- `main.asm`
