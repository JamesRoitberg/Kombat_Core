// anim_gradient.asm
// -----------------------------------------------------------------------------
// Helpers de gradient no NMI (usados pelo ColorCycle).

macro CC_GRADIENT_HDMA_PAUSE_IF_ENABLED(variable doneLabel) {
  lda.b #STAGE_ENABLE_GRADIENT
  beq doneLabel
  lda.b #STAGE_GRADIENT_CC_SAFE_TOGGLE
  beq doneLabel
  lda.b #STAGE_HDMAEN_MASK_SCROLL_ONLY
  sta HDMAEN
}

macro CC_GRADIENT_HDMA_RESUME_IF_ENABLED(variable doneLabel) {
  lda.b #STAGE_ENABLE_GRADIENT
  beq doneLabel
  lda.b #STAGE_GRADIENT_CC_SAFE_TOGGLE
  beq doneLabel
  lda.b #STAGE_HDMAEN_MASK_SCROLL_PLUS_GRAD
  sta HDMAEN
}
