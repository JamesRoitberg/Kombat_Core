// stage_select.asm
// -----------------------------------------------------------------------------
// Seleção de stage em build-time.
// IDs conhecidos nesta fase:
// - 1: The Tower
// - 2: The Pit2
// - 3: The Portal
// - 4: The Wasteland
// - 5: The Waterfront
// - 6: The Armory
// - 7: Kahn's Arena
// -----------------------------------------------------------------------------

// constant STAGE_BUILD_ID = 1 // The Tower
// constant STAGE_BUILD_ID = 2 // The Pit2
// constant STAGE_BUILD_ID = 3 // The Portal
// constant STAGE_BUILD_ID = 4 // The Wasteland
// constant STAGE_BUILD_ID = 5 // The Waterfront
// constant STAGE_BUILD_ID = 6 // The Armory
// constant STAGE_BUILD_ID = 7 // Kahn's Arena
constant STAGE_BUILD_ID = 7 // Stage Selecionado

if STAGE_BUILD_ID == 1 {
  include "stages/the_tower/stage.asm"
} else {
  if STAGE_BUILD_ID == 2 {
    include "stages/the_pit2/stage.asm"
  } else {
    if STAGE_BUILD_ID == 3 {
      include "stages/the_portal/stage.asm"
    } else {
      if STAGE_BUILD_ID == 4 {
        include "stages/the_wasteland/stage.asm"
      } else {
        if STAGE_BUILD_ID == 5 {
          include "stages/the_waterfront/stage.asm"
        } else {
          if STAGE_BUILD_ID == 6 {
            include "stages/the_armory/stage.asm"
          } else {
            if STAGE_BUILD_ID == 7 {
              include "stages/kahns_arena/stage.asm"
            } else {
              error "STAGE_BUILD_ID invalido: nenhum stage conhecido para este ID"
            }
          }
        }
      }
    }
  }
}
