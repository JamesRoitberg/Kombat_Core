// regs.asm
// -----------------------------------------------------------------------------
// Objetivo:
//   Constantes e bitmasks de registradores SNES (PPU/CPU/DMA/HDMA),
//   helpers de engine e layout base de WRAM usado pelo core.
//
// Notas:
//   - $0000-$1FFF espelha WRAM ($7E:0000-$7E:1FFF).
//   - Comentários de VRAM em bytes quando aplicável (compatível com viewers).
//   - Layout/configuração de VRAM por stage fica em stages/<stage>/config.asm.
// -----------------------------------------------------------------------------

// ============================================================================
// PPU Registers ($2100-$21FF)
// ============================================================================
constant INIDISP = $2100 // Screen Display
constant OBSEL   = $2101 // Object Size and Chr Address

constant OAMADDL = $2102 // OAM Address low byte
constant OAMADDH = $2103 // OAM Address high bit and Obj Priority
constant OAMDATA = $2104 // Data for OAM write

constant BGMODE  = $2105 // BG Mode and Character Size
constant MOSAIC  = $2106 // Screen Pixelation

constant BG1SC   = $2107 // BG1 Tilemap Address and Size
constant BG2SC   = $2108 // BG2 Tilemap Address and Size
constant BG3SC   = $2109 // BG3 Tilemap Address and Size
constant BG4SC   = $210a // BG4 Tilemap Address and Size

constant BG12NBA = $210b // BG1 and 2 Chr Address
constant BG34NBA = $210c // BG3 and 4 Chr Address

constant BG1HOFS = $210d // BG1 Horizontal Scroll
constant BG1VOFS = $210e // BG1 Vertical Scroll
constant BG2HOFS = $210f // BG2 Horizontal Scroll
constant BG2VOFS = $2110 // BG2 Vertical Scroll
constant BG3HOFS = $2111 // BG3 Horizontal Scroll
constant BG3VOFS = $2112 // BG3 Vertical Scroll
constant BG4HOFS = $2113 // BG4 Horizontal Scroll
constant BG4VOFS = $2114 // BG4 Vertical Scroll

constant VMAIN   = $2115 // Video Port Control
constant VMADDL  = $2116 // VRAM Address low byte
constant VMADDH  = $2117 // VRAM Address high byte
constant VMDATAL = $2118 // VRAM Data Write low byte
constant VMDATAH = $2119 // VRAM Data Write high byte

constant M7SEL   = $211a // Mode 7 Settings
constant M7A     = $211b // Mode 7 Matrix A
constant M7B     = $211c // Mode 7 Matrix B
constant M7C     = $211d // Mode 7 Matrix C
constant M7D     = $211e // Mode 7 Matrix D
constant M7X     = $211f // Mode 7 Center X
constant M7Y     = $2120 // Mode 7 Center Y

constant CGADD   = $2121 // CGRAM Address
constant CGDATA  = $2122 // CGRAM Data write

constant W12SEL  = $2123 // Window Mask Settings for BG1 and BG2
constant W34SEL  = $2124 // Window Mask Settings for BG3 and BG4
constant WOBJSEL = $2125 // Window Mask Settings for OBJ and Color Window
constant WH0     = $2126 // Window 1 Left Position
constant WH1     = $2127 // Window 1 Right Position
constant WH2     = $2128 // Window 2 Left Position
constant WH3     = $2129 // Window 2 Right Position
constant WBGLOG  = $212a // Window mask logic for BGs
constant WOBJLOG = $212b // Window mask logic for OBJs and Color Window

constant TM      = $212c // Main Screen Designation
constant TS      = $212d // Subscreen Designation
constant TMW     = $212e // Window Mask Designation for the Main Screen
constant TSW     = $212f // Window Mask Designation for the Subscreen

constant CGWSEL  = $2130 // Color Addition Select
constant CGADSUB = $2131 // Color math designation
constant COLDATA = $2132 // Fixed Color Data
constant SETINI  = $2133 // Screen Mode/Video Select

constant MPYL    = $2134 // Multiplication Result low byte
constant MPYM    = $2135 // Multiplication Result middle byte
constant MPYH    = $2136 // Multiplication Result high byte

constant SLHV    = $2137 // Software Latch for H/V Counter

constant OAMDATAREAD  = $2138 // Data for OAM read
constant VMDATALREAD  = $2139 // VRAM Data Read low byte
constant VMDATAHREAD  = $213a // VRAM Data Read high byte
constant CGDATAREAD   = $213b // CGRAM Data read

constant OPHCT   = $213c // Horizontal Scanline Location
constant OPVCT   = $213d // Vertical Scanline Location

constant STAT77  = $213e // PPU Status Flag and Version
constant STAT78  = $213f // PPU Status Flag and Version

constant APUIO0  = $2140 // APU I/O register 0
constant APUIO1  = $2141 // APU I/O register 1
constant APUIO2  = $2142 // APU I/O register 2
constant APUIO3  = $2143 // APU I/O register 3

constant WMDATA  = $2180 // WRAM Data read/write
constant WMADDL  = $2181 // WRAM Address low byte
constant WMADDM  = $2182 // WRAM Address middle byte
constant WMADDH  = $2183 // WRAM Address high byte

// ============================================================================
// CPU / IO Registers ($4000-$42FF)
// ============================================================================
constant JOYSER0 = $4016 // Joypad Access Port 1
constant JOYSER1 = $4017 // Joypad Access Port 2

constant NMITIMEN = $4200 // Interrupt Enable Flags
constant WRIO     = $4201 // Programmable I/O port (out-port)

constant WRMPYA   = $4202 // Multiplicand A
constant WRMPYB   = $4203 // Multiplicand B

constant WRDIVL   = $4204 // Dividend C low byte
constant WRDIVH   = $4205 // Dividend C high byte
constant WRDIVB   = $4206 // Divisor B

constant HTIMEL   = $4207 // H Timer low byte
constant HTIMEH   = $4208 // H Timer high byte
constant VTIMEL   = $4209 // V Timer low byte
constant VTIMEH   = $420a // V Timer high byte

constant MDMAEN   = $420b // DMA Enable 76543210
constant HDMAEN   = $420c // HDMA Enable 76543210 (write-only; não fazer read-modify-write)

constant MEMSEL   = $420d // ROM Access Speed

constant RDNMI    = $4210 // NMI Flag and 5A22 Version
constant TIMEUP   = $4211 // IRQ Flag
constant HVBJOY   = $4212 // PPU Status

constant RDIO     = $4213 // Programmable I/O port (in-port)

constant RDDIVL   = $4214 // Quotient low byte
constant RDDIVH   = $4215 // Quotient high byte
constant RDMPYL   = $4216 // Multiply product / remainder low byte
constant RDMPYH   = $4217 // Multiply product / remainder high byte

constant JOY1L    = $4218 // Controller 1 low
constant JOY1H    = $4219 // Controller 1 high
constant JOY2L    = $421a // Controller 2 low
constant JOY2H    = $421b // Controller 2 high
constant JOY3L    = $421c // Controller 1 (2nd) low
constant JOY3H    = $421d // Controller 1 (2nd) high
constant JOY4L    = $421e // Controller 2 (2nd) low
constant JOY4H    = $421f // Controller 2 (2nd) high

// ============================================================================
// DMA / HDMA Registers ($4300-$437F)
// ============================================================================
constant DMAPx  = $4300 // DMA Control
constant BBADx  = $4301 // DMA Destination Register
constant A1TxL  = $4302 // DMA Source Address low
constant A1TxH  = $4303 // DMA Source Address high
constant A1Bx   = $4304 // DMA Source Address bank
constant DASxL  = $4305 // DMA Size / HDMA Indirect low
constant DASxH  = $4306 // DMA Size / HDMA Indirect high
constant DASBx  = $4307 // HDMA Indirect bank
constant A2AxL  = $4308 // HDMA Table Address low
constant A2AxH  = $4309 // HDMA Table Address high
constant NLTRx  = $430a // HDMA Line Counter

constant CH0 = $00
constant CH1 = $10
constant CH2 = $20
constant CH3 = $30
constant CH4 = $40
constant CH5 = $50
constant CH6 = $60
constant CH7 = $70

// ============================================================================
// Joypad bitmasks (16-bit word)
// ============================================================================
constant KEY_B      = $8000
constant KEY_Y      = $4000
constant KEY_SELECT = $2000
constant KEY_START  = $1000
constant KEY_UP     = $0800
constant KEY_DOWN   = $0400
constant KEY_LEFT   = $0200
constant KEY_RIGHT  = $0100
constant KEY_A      = $0080
constant KEY_X      = $0040
constant KEY_L      = $0020
constant KEY_R      = $0010

// ============================================================================
// BG tilemap attributes (upper byte view, 8-bit)
// ============================================================================
constant TILE_V_FLIP    = $80
constant TILE_H_FLIP    = $40
constant TILE_PRIORITY  = $20
constant TILE_PAL_0     = $00
constant TILE_PAL_1     = $04
constant TILE_PAL_2     = $08
constant TILE_PAL_3     = $0c
constant TILE_PAL_4     = $10
constant TILE_PAL_5     = $14
constant TILE_PAL_6     = $18
constant TILE_PAL_7     = $1c

// ============================================================================
// Sprite attributes (OAM)
// ============================================================================
constant SPR_CHRSET_0 = 0
constant SPR_CHRSET_1 = 1

constant SPR_PAL_0 = $00
constant SPR_PAL_1 = $02
constant SPR_PAL_2 = $04
constant SPR_PAL_3 = $06
constant SPR_PAL_4 = $08
constant SPR_PAL_5 = $0a
constant SPR_PAL_6 = $0c
constant SPR_PAL_7 = $0e

constant SPR_PRIOR_0 = $00
constant SPR_PRIOR_1 = $10
constant SPR_PRIOR_2 = $20
constant SPR_PRIOR_3 = $30

constant SPR_V_FLIP = $80
constant SPR_H_FLIP = $40

constant SPR_POS_X = 0
constant SPR_NEG_X = 1

constant SPR_SIZE_SM = 0
constant SPR_SIZE_LG = 2

// ============================================================================
// PPU helper constants
// ============================================================================
constant BG3_BOTTOM  = 0
constant BG3_TOP     = 8
constant BGM1_3TOP   = 9

constant BG_ALL_8x8  = 0
constant BG1_16x16   = $10
constant BG2_16x16   = $20
constant BG3_16x16   = $40
constant BG4_16x16   = $80
constant BG_ALL_16x16 = $F0

constant MAP_32_32 = 0
constant MAP_64_32 = 1
constant MAP_32_64 = 2
constant MAP_64_64 = 3

constant OAM_8_16   = 0
constant OAM_8_32   = $20
constant OAM_8_64   = $40
constant OAM_16_32  = $60
constant OAM_16_64  = $80
constant OAM_32_64  = $a0

constant V_INC_1  = $80 // VRAM address +1 word
constant V_INC_32 = $81 // VRAM address +32 words

constant SCREEN_OFF    = 0
constant BG1_ON        = 1
constant BG2_ON        = 2
constant BG12_ON       = 3
constant BG3_ON        = 4
constant BG4_ON        = 8
constant BG_ALL_ON     = $0f
constant SPR_OFF       = 0
constant SPR_ON        = $10
constant ALL_ON_SCREEN = $1f

constant FULL_BRIGHT = $0f
constant HALF_BRIGHT = $08
constant NO_BRIGHT   = $00
constant FORCE_BLANK = $80

constant NO_INTERRUPTS = 0
constant NMI_ON        = $80
constant V_IRQ_ON      = $20
constant H_IRQ_ON      = $10
constant AUTO_JOY_ON   = 1

// ============================================================================
// WRAM variables (layout fixo da engine)
// ============================================================================
constant in_nmi  = $0100 // 2 bytes

constant BG1_HOFS   = $0102 // 2 bytes
constant BG2_HOFS   = $0104 // 2 bytes
constant LAST_NMI   = $0106 // 1 byte
constant BG1_VOFS   = $0108 // 2 bytes
constant BG1_WORLDX = $010A // 2 bytes
constant GRAD_TMP0  = $010C // 2 bytes (scratch: gradient builder)
constant GRAD_TMP1  = $010E // 2 bytes (scratch: gradient builder)
// $0110-$0111 reservado (livre)

// Bloco contíguo BG1 (5 bandas):
// - HOFS: $0112-$011B (B0..B4)
// - VOFS: $011C-$0125 (B0..B4)
constant BG1_HOFS_B0 = $0112
constant BG1_HOFS_B1 = $0114
constant BG1_HOFS_B2 = $0116
constant BG1_HOFS_B3 = $0118
constant BG1_HOFS_B4 = $011A

constant BG1_VOFS_B0 = $011C
constant BG1_VOFS_B1 = $011E
constant BG1_VOFS_B2 = $0120
constant BG1_VOFS_B3 = $0122
constant BG1_VOFS_B4 = $0124

// Joypad state (WRAM) — engine
// Usa espaço livre $0126-$012D (entre bandas BG1 e HDMA_BG1*).
constant JOY1_CUR   = $0126 // word (estado atual)
constant JOY1_PREV  = $0128 // word (estado anterior)
constant JOY1_TRIG  = $012A // word (apertou agora)  = CUR & ~PREV
constant JOY1_REL   = $012C // word (soltou agora)   = ~CUR & PREV
// $012E-$012F livre

// HDMA tables BG1 (mode 2 direct): 5 entries + terminator = 16 bytes
constant HDMA_BG1HOFS_TABLE = $0130 // 16 bytes
constant HDMA_BG1VOFS_TABLE = $0160 // 16 bytes

// $0140-$015F reservado para estado/vars auxiliares (por cenário).
// - O cenário define STAGE_ANIM_WRAM_BASE/SIZE em config.asm.
// - Evite colisão com as tabelas HDMA acima e abaixo.

// Bloco contíguo BG2 (5 bandas):
// - HOFS: $0170-$0179 (B0..B4)
// - VOFS: $017A-$0183 (B0..B4)
constant BG2_HOFS_B0 = $0170
constant BG2_HOFS_B1 = $0172
constant BG2_HOFS_B2 = $0174
constant BG2_HOFS_B3 = $0176
constant BG2_HOFS_B4 = $0178

constant BG2_VOFS_B0 = $017A
constant BG2_VOFS_B1 = $017C
constant BG2_VOFS_B2 = $017E
constant BG2_VOFS_B3 = $0180
constant BG2_VOFS_B4 = $0182

constant HDMA_BG2HOFS_TABLE = $01A0 // 16 bytes
constant HDMA_BG2VOFS_TABLE = $01B0 // 16 bytes (reserva; BG2VOFS fixo no runtime atual)

// Scale16 scratch
constant SCALE16_IN    = $01E0   // 2 bytes
constant SCALE16_RATIO = $01E2   // 1 byte
constant SCALE16_OUT   = $01E4   // 2 bytes

// ----------------------------------------------------------------------------
// HDMA tables: CGRAM “gradient” (reserva expandida)
// Objetivo futuro: 2 linhas por entry (224/2 = 112 entries)
//
// Tamanhos mínimos p/ 112 entries:
// - CGADD (mode 0): 112 * 2 + 1 = 225 bytes  ($00E1)
// - CGDATA (mode 2): 112 * 3 + 1 = 337 bytes ($0151)
//
// Esta reserva NÃO muda comportamento do gradiente antigo, só evita pisar WRAM
// quando a gente aumentar o número de entries.
// ----------------------------------------------------------------------------
constant HDMA_CGRAM_CGADD_TABLE  = $0700 // reserve >= $00E1 bytes
constant HDMA_CGRAM_CGDATA_TABLE = $0800 // reserve >= $0151 bytes
