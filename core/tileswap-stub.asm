// tileswap_stub.asm
// -----------------------------------------------------------------------------
// TileSwap v2 (STUB)
// - Mesmos labels do módulo real.
// - Não faz nada (sempre retorna).
// - Deve estar no mesmo bank do caller (porque o caller usa JSR).
// -----------------------------------------------------------------------------
TileSwap_Init:
  rts

TileSwap_NmiTick:
  rts