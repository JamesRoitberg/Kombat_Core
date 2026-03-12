// ============================================================================
// ColorCycle (CC0 + CC1 + CC2 + CC3) — SAFE (no máx 1 por frame, round-robin)
// - Só roda em VBlank
// - Protege gradiente: se STAGE_ENABLE_GRADIENT=1, muta CH2/CH3 durante troca
// - MODE por CC:
//   0=loop infinito | 1=burst e para | 2=burst, pausa e repete
// ============================================================================

// Helpers de refactor (compile-time) para reduzir duplicação do scheduler.
macro CC_TIMER_SAT_STEP(variable timerAddr, variable delayConst, variable doneLabel) {
  lda.w timerAddr
  cmp.b #delayConst
  bcs doneLabel
  clc
  adc.b #$01
  sta.w timerAddr
}

macro CC_READY_MASK_SET(variable readyBit) {
  lda.w MOTOR_TMP
  ora.b #readyBit
  sta.w MOTOR_TMP
}


Motor_ColorCycle_Tick:
  php
  sep #$20

  lda.b #STAGE_CC0_ENABLE
  bne CC_Enabled
  lda.b #STAGE_CC1_ENABLE
  bne CC_Enabled
  lda.b #STAGE_CC2_ENABLE
  bne CC_Enabled
  lda.b #STAGE_CC3_ENABLE
  bne CC_Enabled
  jmp CC_Done

CC_Enabled:
  lda HVBJOY
  bmi CC_InVBlank
  jmp CC_Done

CC_InVBlank:
  // ready mask em MOTOR_TMP (bit0=CC0, bit1=CC1, bit2=CC2, bit3=CC3)
  stz.w MOTOR_TMP

  jsr CC0_UpdateReady
  jsr CC1_UpdateReady
  jsr CC2_UpdateReady
  jsr CC3_UpdateReady

CC_Pick:
  lda.w MOTOR_TMP
  bne CC_Pick_HasReady
  jmp CC_Done

CC_Pick_HasReady:

  cmp.b #$01
  beq CC_Pick_Do0_B

  cmp.b #$02
  beq CC_Pick_Do1_B

  cmp.b #$04
  beq CC_Pick_Do2_B

  cmp.b #$08
  beq CC_Pick_Do3_B

  // multi-ready: round-robin (cursor 0..3)
  lda.w MOTOR_RR_CC
  cmp.b #$01
  beq CC_Pick_From1_B
  cmp.b #$02
  beq CC_Pick_From2_B
  cmp.b #$03
  beq CC_Pick_From3_B
  jmp CC_Pick_From0

CC_Pick_From1_B:
  jmp CC_Pick_From1

CC_Pick_From2_B:
  jmp CC_Pick_From2

CC_Pick_From3_B:
  jmp CC_Pick_From3

CC_Pick_Do0_B:
  jmp CC_Do0

CC_Pick_Do1_B:
  jmp CC_Do1

CC_Pick_Do2_B:
  jmp CC_Do2

CC_Pick_Do3_B:
  jmp CC_Do3

CC_Pick_From0:
  lda.w MOTOR_TMP
  and.b #$01
  bne CC_Pick_From0_Do0

  lda.w MOTOR_TMP
  and.b #$02
  bne CC_Pick_From0_Do1
  lda.w MOTOR_TMP
  and.b #$04
  bne CC_Pick_From0_Do2
  jmp CC_Pick_From0_Do3

CC_Pick_From0_Do0:
  lda.b #$01
  sta.w MOTOR_RR_CC
  jmp CC_Do0

CC_Pick_From0_Do1:
  lda.b #$02
  sta.w MOTOR_RR_CC
  jmp CC_Do1

CC_Pick_From0_Do2:
  lda.b #$03
  sta.w MOTOR_RR_CC
  jmp CC_Do2

CC_Pick_From0_Do3:
  stz.w MOTOR_RR_CC
  jmp CC_Do3

CC_Pick_From1:
  lda.w MOTOR_TMP
  and.b #$02
  bne CC_Pick_From1_Do1

  lda.w MOTOR_TMP
  and.b #$04
  bne CC_Pick_From1_Do2
  lda.w MOTOR_TMP
  and.b #$08
  bne CC_Pick_From1_Do3
  jmp CC_Pick_From1_Do0

CC_Pick_From1_Do1:
  lda.b #$02
  sta.w MOTOR_RR_CC
  jmp CC_Do1

CC_Pick_From1_Do2:
  lda.b #$03
  sta.w MOTOR_RR_CC
  jmp CC_Do2

CC_Pick_From1_Do3:
  stz.w MOTOR_RR_CC
  jmp CC_Do3

CC_Pick_From1_Do0:
  lda.b #$01
  sta.w MOTOR_RR_CC
  jmp CC_Do0

CC_Pick_From2:
  lda.w MOTOR_TMP
  and.b #$04
  bne CC_Pick_From2_Do2

  lda.w MOTOR_TMP
  and.b #$08
  bne CC_Pick_From2_Do3

  lda.w MOTOR_TMP
  and.b #$01
  bne CC_Pick_From2_Do0
  jmp CC_Pick_From2_Do1

CC_Pick_From2_Do2:
  lda.b #$03
  sta.w MOTOR_RR_CC
  jmp CC_Do2

CC_Pick_From2_Do3:
  stz.w MOTOR_RR_CC
  jmp CC_Do3

CC_Pick_From2_Do0:
  lda.b #$01
  sta.w MOTOR_RR_CC
  jmp CC_Do0

CC_Pick_From2_Do1:
  lda.b #$02
  sta.w MOTOR_RR_CC
  jmp CC_Do1

CC_Pick_From3:
  lda.w MOTOR_TMP
  and.b #$08
  bne CC_Pick_From3_Do3

  lda.w MOTOR_TMP
  and.b #$01
  bne CC_Pick_From3_Do0

  lda.w MOTOR_TMP
  and.b #$02
  bne CC_Pick_From3_Do1
  jmp CC_Pick_From3_Do2

CC_Pick_From3_Do3:
  stz.w MOTOR_RR_CC
  jmp CC_Do3

CC_Pick_From3_Do0:
  lda.b #$01
  sta.w MOTOR_RR_CC
  jmp CC_Do0

CC_Pick_From3_Do1:
  lda.b #$02
  sta.w MOTOR_RR_CC
  jmp CC_Do1

CC_Pick_From3_Do2:
  lda.b #$03
  sta.w MOTOR_RR_CC
  jmp CC_Do2

CC_Do0:
  CC_GRADIENT_HDMA_PAUSE_IF_ENABLED(CC0_Rotate)

CC0_Rotate:
  lda.b #STAGE_CC0_DIR
  beq CC0_Fwd
  jmp CC0_Bwd

CC0_Fwd:
  jsr CC0_RotateForward
  jmp CC0_After
CC0_Bwd:
  jsr CC0_RotateBackward

CC0_After:
  stz.w CC0_TIMER
  jsr CC0_AfterStep
  CC_GRADIENT_HDMA_RESUME_IF_ENABLED(CC0_After_Done)
CC0_After_Done:
  jmp CC_Done

CC_Do1:
  CC_GRADIENT_HDMA_PAUSE_IF_ENABLED(CC1_Rotate)

CC1_Rotate:
  lda.b #STAGE_CC1_DIR
  beq CC1_Fwd
  jmp CC1_Bwd

CC1_Fwd:
  jsr CC1_RotateForward
  jmp CC1_After
CC1_Bwd:
  jsr CC1_RotateBackward

CC1_After:
  stz.w CC1_TIMER
  jsr CC1_AfterStep
  CC_GRADIENT_HDMA_RESUME_IF_ENABLED(CC1_After_Done)
CC1_After_Done:
  jmp CC_Done

CC_Do2:
  CC_GRADIENT_HDMA_PAUSE_IF_ENABLED(CC2_Rotate)

CC2_Rotate:
  lda.b #STAGE_CC2_DIR
  beq CC2_Fwd
  jmp CC2_Bwd

CC2_Fwd:
  jsr CC2_RotateForward
  jmp CC2_After
CC2_Bwd:
  jsr CC2_RotateBackward

CC2_After:
  stz.w CC2_TIMER
  jsr CC2_AfterStep
  CC_GRADIENT_HDMA_RESUME_IF_ENABLED(CC2_After_Done)
CC2_After_Done:
  jmp CC_Done

CC_Do3:
  CC_GRADIENT_HDMA_PAUSE_IF_ENABLED(CC3_Rotate)

CC3_Rotate:
  lda.b #STAGE_CC3_DIR
  beq CC3_Fwd
  jmp CC3_Bwd

CC3_Fwd:
  jsr CC3_RotateForward
  jmp CC3_After
CC3_Bwd:
  jsr CC3_RotateBackward

CC3_After:
  stz.w CC3_TIMER
  jsr CC3_AfterStep
  CC_GRADIENT_HDMA_RESUME_IF_ENABLED(CC3_After_Done)
CC3_After_Done:

CC_Done:
  plp
  rts

// ============================================================================
// UpdateReady por CC (mode-aware)
// ============================================================================

CC0_UpdateReady:
  sep #$20
  lda.b #STAGE_CC0_ENABLE
  bne CC0_Update_Enabled
  rts

CC0_Update_Enabled:
  lda.b #STAGE_CC0_MODE
  beq CC0_Update_ModeLoop
  cmp.b #$01
  beq CC0_Update_ModeBurst
  jmp CC0_Update_ModeBurstPause

CC0_Update_ModeLoop:
  CC_TIMER_SAT_STEP(CC0_TIMER, STAGE_CC0_DELAY, CC0_Update_ModeLoop_TimerDone)
CC0_Update_ModeLoop_TimerDone:
  jmp CC0_Update_ReadyCheck

CC0_Update_ModeBurst:
  lda.w CC0_STATE
  bmi CC0_Update_Done

  lda.w CC0_STEPS
  bne CC0_Update_ModeBurst_Active
  lda.b #STAGE_CC0_BURST_STEPS
  sta.w CC0_STEPS
  bne CC0_Update_ModeBurst_Active

  lda.b #$80
  sta.w CC0_STATE
  jmp CC0_Update_Done

CC0_Update_ModeBurst_Active:
  CC_TIMER_SAT_STEP(CC0_TIMER, STAGE_CC0_DELAY, CC0_Update_ModeBurst_TimerDone)
CC0_Update_ModeBurst_TimerDone:
  jmp CC0_Update_ReadyCheck

CC0_Update_ModeBurstPause:
  lda.w CC0_COOLDOWN
  beq CC0_Update_ModeBurstPause_CheckSteps
  dec.w CC0_COOLDOWN
  jmp CC0_Update_Done

CC0_Update_ModeBurstPause_CheckSteps:
  lda.w CC0_STEPS
  bne CC0_Update_ModeBurstPause_Active
  lda.b #STAGE_CC0_BURST_STEPS
  sta.w CC0_STEPS
  beq CC0_Update_Done

CC0_Update_ModeBurstPause_Active:
  CC_TIMER_SAT_STEP(CC0_TIMER, STAGE_CC0_DELAY, CC0_Update_ModeBurstPause_TimerDone)
CC0_Update_ModeBurstPause_TimerDone:

CC0_Update_ReadyCheck:
  lda.w CC0_TIMER
  cmp.b #STAGE_CC0_DELAY
  bcc CC0_Update_Done
  CC_READY_MASK_SET($01)

CC0_Update_Done:
  rts


CC1_UpdateReady:
  sep #$20
  lda.b #STAGE_CC1_ENABLE
  bne CC1_Update_Enabled
  rts

CC1_Update_Enabled:
  lda.b #STAGE_CC1_MODE
  beq CC1_Update_ModeLoop
  cmp.b #$01
  beq CC1_Update_ModeBurst
  jmp CC1_Update_ModeBurstPause

CC1_Update_ModeLoop:
  CC_TIMER_SAT_STEP(CC1_TIMER, STAGE_CC1_DELAY, CC1_Update_ModeLoop_TimerDone)
CC1_Update_ModeLoop_TimerDone:
  jmp CC1_Update_ReadyCheck

CC1_Update_ModeBurst:
  lda.w CC1_STATE
  bmi CC1_Update_Done

  lda.w CC1_STEPS
  bne CC1_Update_ModeBurst_Active
  lda.b #STAGE_CC1_BURST_STEPS
  sta.w CC1_STEPS
  bne CC1_Update_ModeBurst_Active

  lda.b #$80
  sta.w CC1_STATE
  jmp CC1_Update_Done

CC1_Update_ModeBurst_Active:
  CC_TIMER_SAT_STEP(CC1_TIMER, STAGE_CC1_DELAY, CC1_Update_ModeBurst_TimerDone)
CC1_Update_ModeBurst_TimerDone:
  jmp CC1_Update_ReadyCheck

CC1_Update_ModeBurstPause:
  lda.w CC1_COOLDOWN
  beq CC1_Update_ModeBurstPause_CheckSteps
  dec.w CC1_COOLDOWN
  jmp CC1_Update_Done

CC1_Update_ModeBurstPause_CheckSteps:
  lda.w CC1_STEPS
  bne CC1_Update_ModeBurstPause_Active
  lda.b #STAGE_CC1_BURST_STEPS
  sta.w CC1_STEPS
  beq CC1_Update_Done

CC1_Update_ModeBurstPause_Active:
  CC_TIMER_SAT_STEP(CC1_TIMER, STAGE_CC1_DELAY, CC1_Update_ModeBurstPause_TimerDone)
CC1_Update_ModeBurstPause_TimerDone:

CC1_Update_ReadyCheck:
  lda.w CC1_TIMER
  cmp.b #STAGE_CC1_DELAY
  bcc CC1_Update_Done
  CC_READY_MASK_SET($02)

CC1_Update_Done:
  rts


CC2_UpdateReady:
  sep #$20
  lda.b #STAGE_CC2_ENABLE
  bne CC2_Update_Enabled
  rts

CC2_Update_Enabled:
  lda.b #STAGE_CC2_MODE
  beq CC2_Update_ModeLoop
  cmp.b #$01
  beq CC2_Update_ModeBurst
  jmp CC2_Update_ModeBurstPause

CC2_Update_ModeLoop:
  CC_TIMER_SAT_STEP(CC2_TIMER, STAGE_CC2_DELAY, CC2_Update_ModeLoop_TimerDone)
CC2_Update_ModeLoop_TimerDone:
  jmp CC2_Update_ReadyCheck

CC2_Update_ModeBurst:
  lda.w CC2_STATE
  bmi CC2_Update_Done

  lda.w CC2_STEPS
  bne CC2_Update_ModeBurst_Active
  lda.b #STAGE_CC2_BURST_STEPS
  sta.w CC2_STEPS
  bne CC2_Update_ModeBurst_Active

  lda.b #$80
  sta.w CC2_STATE
  jmp CC2_Update_Done

CC2_Update_ModeBurst_Active:
  CC_TIMER_SAT_STEP(CC2_TIMER, STAGE_CC2_DELAY, CC2_Update_ModeBurst_TimerDone)
CC2_Update_ModeBurst_TimerDone:
  jmp CC2_Update_ReadyCheck

CC2_Update_ModeBurstPause:
  lda.w CC2_COOLDOWN
  beq CC2_Update_ModeBurstPause_CheckSteps
  dec.w CC2_COOLDOWN
  jmp CC2_Update_Done

CC2_Update_ModeBurstPause_CheckSteps:
  lda.w CC2_STEPS
  bne CC2_Update_ModeBurstPause_Active
  lda.b #STAGE_CC2_BURST_STEPS
  sta.w CC2_STEPS
  beq CC2_Update_Done

CC2_Update_ModeBurstPause_Active:
  CC_TIMER_SAT_STEP(CC2_TIMER, STAGE_CC2_DELAY, CC2_Update_ModeBurstPause_TimerDone)
CC2_Update_ModeBurstPause_TimerDone:

CC2_Update_ReadyCheck:
  lda.w CC2_TIMER
  cmp.b #STAGE_CC2_DELAY
  bcc CC2_Update_Done
  CC_READY_MASK_SET($04)

CC2_Update_Done:
  rts


CC3_UpdateReady:
  sep #$20
  lda.b #STAGE_CC3_ENABLE
  bne CC3_Update_Enabled
  rts

CC3_Update_Enabled:
  lda.b #STAGE_CC3_MODE
  beq CC3_Update_ModeLoop
  cmp.b #$01
  beq CC3_Update_ModeBurst
  jmp CC3_Update_ModeBurstPause

CC3_Update_ModeLoop:
  CC_TIMER_SAT_STEP(CC3_TIMER, STAGE_CC3_DELAY, CC3_Update_ModeLoop_TimerDone)
CC3_Update_ModeLoop_TimerDone:
  jmp CC3_Update_ReadyCheck

CC3_Update_ModeBurst:
  lda.w CC3_STATE
  bmi CC3_Update_Done

  lda.w CC3_STEPS
  bne CC3_Update_ModeBurst_Active
  lda.b #STAGE_CC3_BURST_STEPS
  sta.w CC3_STEPS
  bne CC3_Update_ModeBurst_Active

  lda.b #$80
  sta.w CC3_STATE
  jmp CC3_Update_Done

CC3_Update_ModeBurst_Active:
  CC_TIMER_SAT_STEP(CC3_TIMER, STAGE_CC3_DELAY, CC3_Update_ModeBurst_TimerDone)
CC3_Update_ModeBurst_TimerDone:
  jmp CC3_Update_ReadyCheck

CC3_Update_ModeBurstPause:
  lda.w CC3_COOLDOWN
  beq CC3_Update_ModeBurstPause_CheckSteps
  dec.w CC3_COOLDOWN
  jmp CC3_Update_Done

CC3_Update_ModeBurstPause_CheckSteps:
  lda.w CC3_STEPS
  bne CC3_Update_ModeBurstPause_Active
  lda.b #STAGE_CC3_BURST_STEPS
  sta.w CC3_STEPS
  beq CC3_Update_Done

CC3_Update_ModeBurstPause_Active:
  CC_TIMER_SAT_STEP(CC3_TIMER, STAGE_CC3_DELAY, CC3_Update_ModeBurstPause_TimerDone)
CC3_Update_ModeBurstPause_TimerDone:

CC3_Update_ReadyCheck:
  lda.w CC3_TIMER
  cmp.b #STAGE_CC3_DELAY
  bcc CC3_Update_Done
  CC_READY_MASK_SET($08)

CC3_Update_Done:
  rts


// ============================================================================
// AfterStep por CC (mode-aware)
// ============================================================================

CC0_AfterStep:
  sep #$20
  lda.b #STAGE_CC0_MODE
  beq CC0_AfterStep_Done
  cmp.b #$01
  beq CC0_AfterStep_ModeBurst
  jmp CC0_AfterStep_ModeBurstPause

CC0_AfterStep_ModeBurst:
  lda.w CC0_STEPS
  beq CC0_AfterStep_Done
  dec.w CC0_STEPS
  bne CC0_AfterStep_Done
  lda.b #$80
  sta.w CC0_STATE
  jmp CC0_AfterStep_Done

CC0_AfterStep_ModeBurstPause:
  lda.w CC0_STEPS
  beq CC0_AfterStep_Done
  dec.w CC0_STEPS
  bne CC0_AfterStep_Done
  lda.b #STAGE_CC0_PAUSE_FRAMES
  sta.w CC0_COOLDOWN

CC0_AfterStep_Done:
  rts


CC1_AfterStep:
  sep #$20
  lda.b #STAGE_CC1_MODE
  beq CC1_AfterStep_Done
  cmp.b #$01
  beq CC1_AfterStep_ModeBurst
  jmp CC1_AfterStep_ModeBurstPause

CC1_AfterStep_ModeBurst:
  lda.w CC1_STEPS
  beq CC1_AfterStep_Done
  dec.w CC1_STEPS
  bne CC1_AfterStep_Done
  lda.b #$80
  sta.w CC1_STATE
  jmp CC1_AfterStep_Done

CC1_AfterStep_ModeBurstPause:
  lda.w CC1_STEPS
  beq CC1_AfterStep_Done
  dec.w CC1_STEPS
  bne CC1_AfterStep_Done
  lda.b #STAGE_CC1_PAUSE_FRAMES
  sta.w CC1_COOLDOWN

CC1_AfterStep_Done:
  rts


CC2_AfterStep:
  sep #$20
  lda.b #STAGE_CC2_MODE
  beq CC2_AfterStep_Done
  cmp.b #$01
  beq CC2_AfterStep_ModeBurst
  jmp CC2_AfterStep_ModeBurstPause

CC2_AfterStep_ModeBurst:
  lda.w CC2_STEPS
  beq CC2_AfterStep_Done
  dec.w CC2_STEPS
  bne CC2_AfterStep_Done
  lda.b #$80
  sta.w CC2_STATE
  jmp CC2_AfterStep_Done

CC2_AfterStep_ModeBurstPause:
  lda.w CC2_STEPS
  beq CC2_AfterStep_Done
  dec.w CC2_STEPS
  bne CC2_AfterStep_Done
  lda.b #STAGE_CC2_PAUSE_FRAMES
  sta.w CC2_COOLDOWN

CC2_AfterStep_Done:
  rts


CC3_AfterStep:
  sep #$20
  lda.b #STAGE_CC3_MODE
  beq CC3_AfterStep_Done
  cmp.b #$01
  beq CC3_AfterStep_ModeBurst
  jmp CC3_AfterStep_ModeBurstPause

CC3_AfterStep_ModeBurst:
  lda.w CC3_STEPS
  beq CC3_AfterStep_Done
  dec.w CC3_STEPS
  bne CC3_AfterStep_Done
  lda.b #$80
  sta.w CC3_STATE
  jmp CC3_AfterStep_Done

CC3_AfterStep_ModeBurstPause:
  lda.w CC3_STEPS
  beq CC3_AfterStep_Done
  dec.w CC3_STEPS
  bne CC3_AfterStep_Done
  lda.b #STAGE_CC3_PAUSE_FRAMES
  sta.w CC3_COOLDOWN

CC3_AfterStep_Done:
  rts

// Helpers de rotação CC para manter base reutilizável (CC0/CC1/novas instâncias).
macro CC_ROTATE_FORWARD_BEGIN(variable lenConst, variable idxTable, variable readRoutine, variable tmpLoAddr, variable tmpHiAddr, variable saveLoAddr, variable saveHiAddr) {
  php
  sep #$30

  lda.b #lenConst
  sec
  sbc.b #$01
  tax

  ldy.b #$00
  lda.w idxTable,y
  jsr readRoutine
  lda.w tmpLoAddr
  sta.w saveLoAddr
  lda.w tmpHiAddr
  sta.w saveHiAddr
}

macro CC_ROTATE_FORWARD_STEP(variable idxTable, variable readRoutine, variable writeRoutine) {
  lda.w idxTable+1,y
  jsr readRoutine
  lda.w idxTable,y
  jsr writeRoutine
}

macro CC_ROTATE_FORWARD_END(variable idxTable, variable writeRoutine, variable saveLoAddr, variable saveHiAddr, variable tmpLoAddr, variable tmpHiAddr) {
  lda.w saveLoAddr
  sta.w tmpLoAddr
  lda.w saveHiAddr
  sta.w tmpHiAddr
  lda.w idxTable,y
  jsr writeRoutine

  plp
  rts
}

macro CC_ROTATE_BACKWARD_BEGIN(variable lenConst, variable idxTable, variable readRoutine, variable tmpLoAddr, variable tmpHiAddr, variable saveLoAddr, variable saveHiAddr) {
  php
  sep #$30

  lda.b #lenConst
  sec
  sbc.b #$01
  tax
  tay

  lda.w idxTable,y
  jsr readRoutine
  lda.w tmpLoAddr
  sta.w saveLoAddr
  lda.w tmpHiAddr
  sta.w saveHiAddr
}

macro CC_ROTATE_BACKWARD_STEP(variable idxTable, variable readRoutine, variable writeRoutine) {
  dey
  lda.w idxTable,y
  jsr readRoutine

  iny
  lda.w idxTable,y
  jsr writeRoutine

  dey
}

macro CC_ROTATE_BACKWARD_END(variable idxTable, variable writeRoutine, variable saveLoAddr, variable saveHiAddr, variable tmpLoAddr, variable tmpHiAddr) {
  lda.w saveLoAddr
  sta.w tmpLoAddr
  lda.w saveHiAddr
  sta.w tmpHiAddr
  ldy.b #$00
  lda.w idxTable,y
  jsr writeRoutine

  plp
  rts
}

macro CC_READ_COLOR_BODY(variable tmpLoAddr, variable tmpHiAddr) {
  sep #$20
  sta CGADD
  lda CGDATAREAD
  sta.w tmpLoAddr
  lda CGDATAREAD
  and.b #$7F
  sta.w tmpHiAddr
  rts
}

macro CC_WRITE_COLOR_BODY(variable tmpLoAddr, variable tmpHiAddr) {
  sep #$20
  sta CGADD
  lda.w tmpLoAddr
  sta CGDATA
  lda.w tmpHiAddr
  sta CGDATA
  rts
}

// ---- CC0 rotate (LEN 2..6) ----
CC0_RotateForward:
  CC_ROTATE_FORWARD_BEGIN(STAGE_CC0_LEN, CC0_IdxTable, CC_Read0, CC0_TMPLO, CC0_TMPHI, CC0_SAVELO, CC0_SAVEHI)
CC0_FwdLoop:
  CC_ROTATE_FORWARD_STEP(CC0_IdxTable, CC_Read0, CC_Write0)

  iny
  dex
  bne CC0_FwdLoop

  CC_ROTATE_FORWARD_END(CC0_IdxTable, CC_Write0, CC0_SAVELO, CC0_SAVEHI, CC0_TMPLO, CC0_TMPHI)

CC0_RotateBackward:
  CC_ROTATE_BACKWARD_BEGIN(STAGE_CC0_LEN, CC0_IdxTable, CC_Read0, CC0_TMPLO, CC0_TMPHI, CC0_SAVELO, CC0_SAVEHI)
CC0_BwdLoop:
  CC_ROTATE_BACKWARD_STEP(CC0_IdxTable, CC_Read0, CC_Write0)

  dex
  bne CC0_BwdLoop

  CC_ROTATE_BACKWARD_END(CC0_IdxTable, CC_Write0, CC0_SAVELO, CC0_SAVEHI, CC0_TMPLO, CC0_TMPHI)

CC_Read0:
  CC_READ_COLOR_BODY(CC0_TMPLO, CC0_TMPHI)

CC_Write0:
  CC_WRITE_COLOR_BODY(CC0_TMPLO, CC0_TMPHI)

// ---- CC1 rotate (LEN 2..6) ----
CC1_RotateForward:
  CC_ROTATE_FORWARD_BEGIN(STAGE_CC1_LEN, CC1_IdxTable, CC_Read1, CC1_TMPLO, CC1_TMPHI, CC1_SAVELO, CC1_SAVEHI)
CC1_FwdLoop:
  CC_ROTATE_FORWARD_STEP(CC1_IdxTable, CC_Read1, CC_Write1)

  iny
  dex
  bne CC1_FwdLoop

  CC_ROTATE_FORWARD_END(CC1_IdxTable, CC_Write1, CC1_SAVELO, CC1_SAVEHI, CC1_TMPLO, CC1_TMPHI)

CC1_RotateBackward:
  CC_ROTATE_BACKWARD_BEGIN(STAGE_CC1_LEN, CC1_IdxTable, CC_Read1, CC1_TMPLO, CC1_TMPHI, CC1_SAVELO, CC1_SAVEHI)
CC1_BwdLoop:
  CC_ROTATE_BACKWARD_STEP(CC1_IdxTable, CC_Read1, CC_Write1)

  dex
  bne CC1_BwdLoop

  CC_ROTATE_BACKWARD_END(CC1_IdxTable, CC_Write1, CC1_SAVELO, CC1_SAVEHI, CC1_TMPLO, CC1_TMPHI)

CC_Read1:
  CC_READ_COLOR_BODY(CC1_TMPLO, CC1_TMPHI)

CC_Write1:
  CC_WRITE_COLOR_BODY(CC1_TMPLO, CC1_TMPHI)

// ---- CC2 rotate (LEN 2..6) ----
CC2_RotateForward:
  CC_ROTATE_FORWARD_BEGIN(STAGE_CC2_LEN, CC2_IdxTable, CC_Read2, CC2_TMPLO, CC2_TMPHI, CC2_SAVELO, CC2_SAVEHI)
CC2_FwdLoop:
  CC_ROTATE_FORWARD_STEP(CC2_IdxTable, CC_Read2, CC_Write2)

  iny
  dex
  bne CC2_FwdLoop

  CC_ROTATE_FORWARD_END(CC2_IdxTable, CC_Write2, CC2_SAVELO, CC2_SAVEHI, CC2_TMPLO, CC2_TMPHI)

CC2_RotateBackward:
  CC_ROTATE_BACKWARD_BEGIN(STAGE_CC2_LEN, CC2_IdxTable, CC_Read2, CC2_TMPLO, CC2_TMPHI, CC2_SAVELO, CC2_SAVEHI)
CC2_BwdLoop:
  CC_ROTATE_BACKWARD_STEP(CC2_IdxTable, CC_Read2, CC_Write2)

  dex
  bne CC2_BwdLoop

  CC_ROTATE_BACKWARD_END(CC2_IdxTable, CC_Write2, CC2_SAVELO, CC2_SAVEHI, CC2_TMPLO, CC2_TMPHI)

CC_Read2:
  CC_READ_COLOR_BODY(CC2_TMPLO, CC2_TMPHI)

CC_Write2:
  CC_WRITE_COLOR_BODY(CC2_TMPLO, CC2_TMPHI)

// ---- CC3 rotate (LEN 2..6) ----
CC3_RotateForward:
  CC_ROTATE_FORWARD_BEGIN(STAGE_CC3_LEN, CC3_IdxTable, CC_Read3, CC3_TMPLO, CC3_TMPHI, CC3_SAVELO, CC3_SAVEHI)
CC3_FwdLoop:
  CC_ROTATE_FORWARD_STEP(CC3_IdxTable, CC_Read3, CC_Write3)

  iny
  dex
  bne CC3_FwdLoop

  CC_ROTATE_FORWARD_END(CC3_IdxTable, CC_Write3, CC3_SAVELO, CC3_SAVEHI, CC3_TMPLO, CC3_TMPHI)

CC3_RotateBackward:
  CC_ROTATE_BACKWARD_BEGIN(STAGE_CC3_LEN, CC3_IdxTable, CC_Read3, CC3_TMPLO, CC3_TMPHI, CC3_SAVELO, CC3_SAVEHI)
CC3_BwdLoop:
  CC_ROTATE_BACKWARD_STEP(CC3_IdxTable, CC_Read3, CC_Write3)

  dex
  bne CC3_BwdLoop

  CC_ROTATE_BACKWARD_END(CC3_IdxTable, CC_Write3, CC3_SAVELO, CC3_SAVEHI, CC3_TMPLO, CC3_TMPHI)

CC_Read3:
  CC_READ_COLOR_BODY(CC3_TMPLO, CC3_TMPHI)

CC_Write3:
  CC_WRITE_COLOR_BODY(CC3_TMPLO, CC3_TMPHI)
