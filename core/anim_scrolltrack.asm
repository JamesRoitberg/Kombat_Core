// anim_scrolltrack.asm
// -----------------------------------------------------------------------------
// ============================================================================
// ScrollTracks helpers (S1) — comportamento idêntico ao baseline atual
// - Aplica em BG1/BG2, banda = track (0..4)
// - X = offset da banda (0,2,4,6,8)
// - MOTOR_SCROLL_ACC_TMP = delta (word)
// ============================================================================
ScrollTrack_WrapMaskTable:
  dw STAGE_SCROLL_TRACK0_WRAP_MASK
  dw STAGE_SCROLL_TRACK1_WRAP_MASK
  dw STAGE_SCROLL_TRACK2_WRAP_MASK
  dw STAGE_SCROLL_TRACK3_WRAP_MASK
  dw STAGE_SCROLL_TRACK4_WRAP_MASK

// X = track offset (0,2,4,6,8)  -> indexa WrapMaskTable
// Y = band offset  (0,2,4,6,8)  -> indexa BGx_HOFS_B0..B4
ScrollTrack_ApplyBG1_ByTrackAndBand:
  rep #$30
  lda.w BG1_HOFS_B0,y
  clc
  adc.w MOTOR_SCROLL_ACC_TMP
  and.w ScrollTrack_WrapMaskTable,x
  sta.w BG1_HOFS_B0,y
  rts

ScrollTrack_ApplyBG2_ByTrackAndBand:
  rep #$30
  lda.w BG2_HOFS_B0,y
  clc
  adc.w MOTOR_SCROLL_ACC_TMP
  and.w ScrollTrack_WrapMaskTable,x
  sta.w BG2_HOFS_B0,y
  rts

ScrollTrack_SetBG1_ByTrackAndBand:
  rep #$30
  lda.w MOTOR_SCROLL_ACC_TMP
  and.w ScrollTrack_WrapMaskTable,x
  sta.w BG1_HOFS_B0,y
  rts

ScrollTrack_SetBG2_ByTrackAndBand:
  rep #$30
  lda.w MOTOR_SCROLL_ACC_TMP
  and.w ScrollTrack_WrapMaskTable,x
  sta.w BG2_HOFS_B0,y
  rts

// Helpers de refactor (compile-time) para reduzir duplicação por track.
macro SCROLLTRACK_ACCUM_FORWARD(variable accAddr, variable fracAddr, variable speedInt, variable speedFrac, variable wrapMask, variable applyLabel) {
  rep #$20
  lda.w accAddr
  clc
  adc.w #speedInt
  and.w #wrapMask
  sta.w accAddr

  sep #$20
  lda.w fracAddr
  clc
  adc.b #speedFrac
  sta.w fracAddr
  bcc applyLabel

  rep #$20
  lda.w accAddr
  clc
  adc.w #$0001
  and.w #wrapMask
  sta.w accAddr
  sep #$20
  jmp applyLabel
}

macro SCROLLTRACK_ACCUM_BACKWARD(variable accAddr, variable fracAddr, variable speedInt, variable speedFrac, variable wrapMask, variable applyLabel) {
  rep #$20
  lda.w accAddr
  sec
  sbc.w #speedInt
  and.w #wrapMask
  sta.w accAddr

  sep #$20
  lda.w fracAddr
  sec
  sbc.b #speedFrac
  sta.w fracAddr
  bcs applyLabel

  rep #$20
  lda.w accAddr
  sec
  sbc.w #$0001
  and.w #wrapMask
  sta.w accAddr
  sep #$20
}

macro SCROLLTRACK_APPLY_BEGIN(variable accAddr, variable trackOffset, variable bandConst, variable targetBgConst, variable applyDoneLabel, variable applyBg1Label, variable applyBg2Label) {
  rep #$30
  lda.w accAddr
  sta.w MOTOR_SCROLL_ACC_TMP

  ldx.w #trackOffset

  lda.w #bandConst
  cmp.w #$0005
  bcs applyDoneLabel
  asl
  tay

  sep #$20
  lda.b #targetBgConst
  cmp.b #$01
  beq applyBg1Label
  cmp.b #$02
  beq applyBg2Label
  jmp applyDoneLabel
}

macro SCROLLTRACK_APPLY_MODE_DISPATCH(variable applyModeConst, variable addLabel, variable setLabel, variable doneLabel) {
  lda.b #applyModeConst
  beq addLabel
  cmp.b #$01
  beq setLabel
  jmp doneLabel
}
// ============================================================================
// ScrollTracks (HOFS por banda, BG1/BG2) — subpixel
// - Track0->Band0 ... Track4->Band4 (destino via TARGET_BG)
// - Cada track respeita STAGE_SCROLL_TRACKn_ENABLE
// - DIR: 0=+ (Forward), 1=- (Backward)
// ============================================================================
Motor_ScrollTracks_Tick:
  php

  jsr ScrollTrack0_Tick
  jsr ScrollTrack1_Tick
  jsr ScrollTrack2_Tick
  jsr ScrollTrack3_Tick
  jsr ScrollTrack4_Tick

  plp
  rts

ScrollTrack0_Tick:
  sep #$20
  lda.b #STAGE_SCROLL_TRACK0_ENABLE
  bne ST0_Do_B
  rts
ST0_Do_B:
  jmp ST0_Do

ST0_Do:
  lda.b #STAGE_SCROLL_TRACK0_DIR
  beq ST0_Forward
  jmp ST0_Backward

ST0_Forward:
  SCROLLTRACK_ACCUM_FORWARD(MOTOR_TRACK0_ACC, MOTOR_TRACK0_FRAC, STAGE_SCROLL_TRACK0_SPEED_INT, STAGE_SCROLL_TRACK0_SPEED_FRAC, STAGE_SCROLL_TRACK0_WRAP_MASK, ST0_Apply)

ST0_Backward:
  SCROLLTRACK_ACCUM_BACKWARD(MOTOR_TRACK0_ACC, MOTOR_TRACK0_FRAC, STAGE_SCROLL_TRACK0_SPEED_INT, STAGE_SCROLL_TRACK0_SPEED_FRAC, STAGE_SCROLL_TRACK0_WRAP_MASK, ST0_Apply)

ST0_Apply:
  SCROLLTRACK_APPLY_BEGIN(MOTOR_TRACK0_ACC, $0000, STAGE_SCROLL_TRACK0_BAND, STAGE_SCROLL_TRACK0_TARGET_BG, ST0_Apply_Done, ST0_Apply_BG1, ST0_Apply_BG2)

ST0_Apply_BG1:
  SCROLLTRACK_APPLY_MODE_DISPATCH(STAGE_SCROLL_TRACK0_APPLY_MODE, ST0_Apply_BG1_Add, ST0_Apply_BG1_Set, ST0_Apply_Done)
ST0_Apply_BG1_Add:
  jsr ScrollTrack_ApplyBG1_ByTrackAndBand
  rts
ST0_Apply_BG1_Set:
  jsr ScrollTrack_SetBG1_ByTrackAndBand
  rts

ST0_Apply_BG2:
  SCROLLTRACK_APPLY_MODE_DISPATCH(STAGE_SCROLL_TRACK0_APPLY_MODE, ST0_Apply_BG2_Add, ST0_Apply_BG2_Set, ST0_Apply_Done)
ST0_Apply_BG2_Add:
  jsr ScrollTrack_ApplyBG2_ByTrackAndBand
  rts
ST0_Apply_BG2_Set:
  jsr ScrollTrack_SetBG2_ByTrackAndBand
  rts

ST0_Apply_Done:
  rts

ScrollTrack1_Tick:
  sep #$20
  lda.b #STAGE_SCROLL_TRACK1_ENABLE
  bne ST1_Do_B
  rts
ST1_Do_B:
  jmp ST1_Do

ST1_Do:
  lda.b #STAGE_SCROLL_TRACK1_DIR
  beq ST1_Forward
  jmp ST1_Backward

ST1_Forward:
  SCROLLTRACK_ACCUM_FORWARD(MOTOR_TRACK1_ACC, MOTOR_TRACK1_FRAC, STAGE_SCROLL_TRACK1_SPEED_INT, STAGE_SCROLL_TRACK1_SPEED_FRAC, STAGE_SCROLL_TRACK1_WRAP_MASK, ST1_Apply)

ST1_Backward:
  SCROLLTRACK_ACCUM_BACKWARD(MOTOR_TRACK1_ACC, MOTOR_TRACK1_FRAC, STAGE_SCROLL_TRACK1_SPEED_INT, STAGE_SCROLL_TRACK1_SPEED_FRAC, STAGE_SCROLL_TRACK1_WRAP_MASK, ST1_Apply)

ST1_Apply:
  SCROLLTRACK_APPLY_BEGIN(MOTOR_TRACK1_ACC, $0002, STAGE_SCROLL_TRACK1_BAND, STAGE_SCROLL_TRACK1_TARGET_BG, ST1_Apply_Done, ST1_Apply_BG1, ST1_Apply_BG2)

ST1_Apply_BG1:
  SCROLLTRACK_APPLY_MODE_DISPATCH(STAGE_SCROLL_TRACK1_APPLY_MODE, ST1_Apply_BG1_Add, ST1_Apply_BG1_Set, ST1_Apply_Done)
ST1_Apply_BG1_Add:
  jsr ScrollTrack_ApplyBG1_ByTrackAndBand
  rts
ST1_Apply_BG1_Set:
  jsr ScrollTrack_SetBG1_ByTrackAndBand
  rts

ST1_Apply_BG2:
  SCROLLTRACK_APPLY_MODE_DISPATCH(STAGE_SCROLL_TRACK1_APPLY_MODE, ST1_Apply_BG2_Add, ST1_Apply_BG2_Set, ST1_Apply_Done)
ST1_Apply_BG2_Add:
  jsr ScrollTrack_ApplyBG2_ByTrackAndBand
  rts
ST1_Apply_BG2_Set:
  jsr ScrollTrack_SetBG2_ByTrackAndBand
  rts

ST1_Apply_Done:
  rts

ScrollTrack2_Tick:
  sep #$20
  lda.b #STAGE_SCROLL_TRACK2_ENABLE
  bne ST2_Do_B
  rts
ST2_Do_B:
  jmp ST2_Do

ST2_Do:
  lda.b #STAGE_SCROLL_TRACK2_DIR
  beq ST2_Forward
  jmp ST2_Backward

ST2_Forward:
  SCROLLTRACK_ACCUM_FORWARD(MOTOR_TRACK2_ACC, MOTOR_TRACK2_FRAC, STAGE_SCROLL_TRACK2_SPEED_INT, STAGE_SCROLL_TRACK2_SPEED_FRAC, STAGE_SCROLL_TRACK2_WRAP_MASK, ST2_Apply)

ST2_Backward:
  SCROLLTRACK_ACCUM_BACKWARD(MOTOR_TRACK2_ACC, MOTOR_TRACK2_FRAC, STAGE_SCROLL_TRACK2_SPEED_INT, STAGE_SCROLL_TRACK2_SPEED_FRAC, STAGE_SCROLL_TRACK2_WRAP_MASK, ST2_Apply)

ST2_Apply:
  SCROLLTRACK_APPLY_BEGIN(MOTOR_TRACK2_ACC, $0004, STAGE_SCROLL_TRACK2_BAND, STAGE_SCROLL_TRACK2_TARGET_BG, ST2_Apply_Done, ST2_Apply_BG1, ST2_Apply_BG2)

ST2_Apply_BG1:
  SCROLLTRACK_APPLY_MODE_DISPATCH(STAGE_SCROLL_TRACK2_APPLY_MODE, ST2_Apply_BG1_Add, ST2_Apply_BG1_Set, ST2_Apply_Done)
ST2_Apply_BG1_Add:
  jsr ScrollTrack_ApplyBG1_ByTrackAndBand
  rts
ST2_Apply_BG1_Set:
  jsr ScrollTrack_SetBG1_ByTrackAndBand
  rts

ST2_Apply_BG2:
  SCROLLTRACK_APPLY_MODE_DISPATCH(STAGE_SCROLL_TRACK2_APPLY_MODE, ST2_Apply_BG2_Add, ST2_Apply_BG2_Set, ST2_Apply_Done)
ST2_Apply_BG2_Add:
  jsr ScrollTrack_ApplyBG2_ByTrackAndBand
  rts
ST2_Apply_BG2_Set:
  jsr ScrollTrack_SetBG2_ByTrackAndBand
  rts

ST2_Apply_Done:
  rts

ScrollTrack3_Tick:
  sep #$20
  lda.b #STAGE_SCROLL_TRACK3_ENABLE
  bne ST3_Do_B
  rts
ST3_Do_B:
  jmp ST3_Do

ST3_Do:
  lda.b #STAGE_SCROLL_TRACK3_DIR
  beq ST3_Forward
  jmp ST3_Backward

ST3_Forward:
  SCROLLTRACK_ACCUM_FORWARD(MOTOR_TRACK3_ACC, MOTOR_TRACK3_FRAC, STAGE_SCROLL_TRACK3_SPEED_INT, STAGE_SCROLL_TRACK3_SPEED_FRAC, STAGE_SCROLL_TRACK3_WRAP_MASK, ST3_Apply)

ST3_Backward:
  SCROLLTRACK_ACCUM_BACKWARD(MOTOR_TRACK3_ACC, MOTOR_TRACK3_FRAC, STAGE_SCROLL_TRACK3_SPEED_INT, STAGE_SCROLL_TRACK3_SPEED_FRAC, STAGE_SCROLL_TRACK3_WRAP_MASK, ST3_Apply)

ST3_Apply:
  SCROLLTRACK_APPLY_BEGIN(MOTOR_TRACK3_ACC, $0006, STAGE_SCROLL_TRACK3_BAND, STAGE_SCROLL_TRACK3_TARGET_BG, ST3_Apply_Done, ST3_Apply_BG1, ST3_Apply_BG2)

ST3_Apply_BG1:
  SCROLLTRACK_APPLY_MODE_DISPATCH(STAGE_SCROLL_TRACK3_APPLY_MODE, ST3_Apply_BG1_Add, ST3_Apply_BG1_Set, ST3_Apply_Done)
ST3_Apply_BG1_Add:
  jsr ScrollTrack_ApplyBG1_ByTrackAndBand
  rts
ST3_Apply_BG1_Set:
  jsr ScrollTrack_SetBG1_ByTrackAndBand
  rts

ST3_Apply_BG2:
  SCROLLTRACK_APPLY_MODE_DISPATCH(STAGE_SCROLL_TRACK3_APPLY_MODE, ST3_Apply_BG2_Add, ST3_Apply_BG2_Set, ST3_Apply_Done)
ST3_Apply_BG2_Add:
  jsr ScrollTrack_ApplyBG2_ByTrackAndBand
  rts
ST3_Apply_BG2_Set:
  jsr ScrollTrack_SetBG2_ByTrackAndBand
  rts

ST3_Apply_Done:
  rts

ScrollTrack4_Tick:
  sep #$20
  lda.b #STAGE_SCROLL_TRACK4_ENABLE
  bne ST4_Do_B
  rts
ST4_Do_B:
  jmp ST4_Do

ST4_Do:
  lda.b #STAGE_SCROLL_TRACK4_DIR
  beq ST4_Forward
  jmp ST4_Backward

ST4_Forward:
  SCROLLTRACK_ACCUM_FORWARD(MOTOR_TRACK4_ACC, MOTOR_TRACK4_FRAC, STAGE_SCROLL_TRACK4_SPEED_INT, STAGE_SCROLL_TRACK4_SPEED_FRAC, STAGE_SCROLL_TRACK4_WRAP_MASK, ST4_Apply)

ST4_Backward:
  SCROLLTRACK_ACCUM_BACKWARD(MOTOR_TRACK4_ACC, MOTOR_TRACK4_FRAC, STAGE_SCROLL_TRACK4_SPEED_INT, STAGE_SCROLL_TRACK4_SPEED_FRAC, STAGE_SCROLL_TRACK4_WRAP_MASK, ST4_Apply)

ST4_Apply:
  SCROLLTRACK_APPLY_BEGIN(MOTOR_TRACK4_ACC, $0008, STAGE_SCROLL_TRACK4_BAND, STAGE_SCROLL_TRACK4_TARGET_BG, ST4_Apply_Done, ST4_Apply_BG1, ST4_Apply_BG2)

ST4_Apply_BG1:
  SCROLLTRACK_APPLY_MODE_DISPATCH(STAGE_SCROLL_TRACK4_APPLY_MODE, ST4_Apply_BG1_Add, ST4_Apply_BG1_Set, ST4_Apply_Done)
ST4_Apply_BG1_Add:
  jsr ScrollTrack_ApplyBG1_ByTrackAndBand
  rts
ST4_Apply_BG1_Set:
  jsr ScrollTrack_SetBG1_ByTrackAndBand
  rts

ST4_Apply_BG2:
  SCROLLTRACK_APPLY_MODE_DISPATCH(STAGE_SCROLL_TRACK4_APPLY_MODE, ST4_Apply_BG2_Add, ST4_Apply_BG2_Set, ST4_Apply_Done)
ST4_Apply_BG2_Add:
  jsr ScrollTrack_ApplyBG2_ByTrackAndBand
  rts
ST4_Apply_BG2_Set:
  jsr ScrollTrack_SetBG2_ByTrackAndBand
  rts

ST4_Apply_Done:
  rts
