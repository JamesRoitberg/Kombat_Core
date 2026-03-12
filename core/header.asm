// header.asm
// -----------------------------------------------------------------------------
// Objetivo:
//   Definir o SNES Internal Header (LoROM) em $00:FFC0.
//
// Depende de:
//   - macro seek() (mapeamento LoROM para offset de arquivo)
//
// Exporta:
//   - Nenhum label (somente bytes no header)
//
// Notas:
//   - Este arquivo NÃO escreve vetores. Vetores ficam em vectors.asm.
//   - Checksum/complement continuam placeholders (padrão do boilerplate).
// -----------------------------------------------------------------------------

// ============================================================================
// SNES Internal Header (LoROM) @ $00:FFC0
// ============================================================================
seek($00FFC0)

// PROGRAM TITLE (21 bytes ASCII; preencher com espaços)
db "Program Name Here    "
// "123456789012345678901"

// ROM MODE/SPEED (bits 7-4 speed, bits 3-0 map mode)
db $30
// $2X = SlowROM (200ns)
// $3X = FastROM (120ns)
// Map Mode:
//   $X0 = LoROM (Mode 20)
//   $X1 = HiROM (Mode 21)
//   $X2 = LoROM + S-DD1 (Mode 22)
//   $X3 = LoROM + SA-1  (Mode 23)
//   $X5 = HiROM (Mode 25 ExHiROM)
//   $XA = HiROM + SPC7110 (Mode 2A)

// ROM TYPE
db $00
// $00 = ROM
// $01 = ROM+RAM
// $02 = ROM+RAM+Battery
// Coprocessor variants: ver tabela original se precisar no futuro.

// ROM SIZE (expoente)
// $0B = 64 banks = 2048KB (16Mbit)
// $0C = 128 banks = 4096KB (32Mbit)
db $0C

// RAM SIZE
db $00

// COUNTRY/VIDEO
db $01 // USA/Canada (NTSC)

// DEVELOPER ID
db $33 // extended header

// ROM VERSION
db $00

// COMPLEMENT CHECK / CHECKSUM (placeholders)
dw $FFFF
dw $0000
