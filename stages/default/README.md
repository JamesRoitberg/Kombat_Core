# Default Stage Template

Use esta pasta como base para criar um novo stage.

## Passos rapidos
1. Copie `stages/default` para `stages/<novo_stage>`.
2. Troque os assets em `assets/`.
3. Ajuste `config.asm` (VRAM, bandas, offsets e features).
4. Se for usar TileSwap, habilite os jobs desejados no `config.asm`.
5. Atualize `stage_select.asm` para incluir o novo stage.

## Checklist minimo (5 edicoes)
1. `stage.asm`: trocar os `insert` de `default-bg1/default-bg2` pelos assets reais.
2. `config.asm`: ajustar `VRAM_BG*` e `REG_BG*` para o layout real do stage.
3. `config.asm`: ajustar `STAGE_BG*_X_OFFSET`, bands e ratios de parallax.
4. `config.asm`: definir flags de feature (`STAGE_ENABLE_*`) e backdrop/gradient.
5. `config.asm` + `stage.asm`: se usar TileSwap, habilitar jobs e trocar FR0..FR7 dummies por CHRs reais.

## Notas
- Este template deixa todos os jobs de TileSwap em OFF por padrao.
- As labels FR0..FR7 de JOB0..JOB3 ja existem com dummies.
- Com `STAGE_TSWAP_ENABLE=1`, o core atual exige `STAGE_TSWAP_JOB0_ENABLE=1`.
