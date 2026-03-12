// vectors.asm
// -----------------------------------------------------------------------------
// Objetivo:
//   Definir vetores de interrupção (native + emulation) em $00:FFE0-$00:FFFF.
//
// Depende de:
//   - macro seek() (mapeamento LoROM para offset de arquivo)
//   - reset.asm exporta labels: ResetHandler, NMI
//
// Notas:
//   - Boot real usa o vetor de EMULATION RESET em $00:FFFC.
//   - Mantemos também o Native RESET por consistência.
//   - A engine mantém IRQ desligado (NMITIMEN sem bits de IRQ), então IRQ/COP/BRK
//     não devem disparar. Os handlers abaixo são apenas “failsafe”.
// -----------------------------------------------------------------------------

// Handlers dummy (failsafe). Se disparar, é sinal de configuração errada.
// Nomes com prefixo para evitar colisão entre arquivos.
VEC_COP_Dummy:
  rti

VEC_BRK_Dummy:
  rti

VEC_ABORT_Dummy:
  rti

VEC_IRQ_Dummy:
  rti

// Native vectors ($00:FFE4..$00:FFEE)
seek($00FFE4) // COP
dw VEC_COP_Dummy

seek($00FFE6) // BRK
dw VEC_BRK_Dummy

seek($00FFE8) // ABORT
dw VEC_ABORT_Dummy

seek($00FFEA) // NMI
dw NMI

seek($00FFEC) // RESET (native)
dw ResetHandler

seek($00FFEE) // IRQ (native)
dw VEC_IRQ_Dummy

// Emulation vectors ($00:FFFA..$00:FFFF)
seek($00FFFA) // NMI (emulation)
dw NMI

seek($00FFFC) // RESET (emulation) - boot usa este
dw ResetHandler

seek($00FFFE) // IRQ/BRK (emulation)
dw VEC_IRQ_Dummy
