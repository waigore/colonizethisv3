// Shared constants and chrome helpers for technology panel widgets.
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

/// Opacity applied to the locked fourth-slot card body when
/// `player.researchSlots < 4`.
///
/// SPEC/ui/technology-panel.md § Slot behaviour > Locked slot 4
/// (University). Refs #2864 S0/S3.
const double kTechnologyLockedSlotOpacity = 0.45;

/// Viewport width (logical px) below which the compact slot action controls
/// (`CtActionTextButton` / `CtDangerTextButton`) guarantee a
/// [kMinTouchTargetSize] (44 dp) tap target in both dimensions.
///
/// Mirrors the in-game shell narrow breakpoint (`< 600 dp`) in
/// `SPEC/ui/mobile-adaptation.md` § 4. At or above this width the slot action
/// controls render at their compact mockup size
/// (`SPEC/ui/mockups/GAME40001-technology-panel.html` `.slot-actions button`);
/// below it the controls expand so they satisfy the mobile minimum
/// touch-target rule (§ 1). SPEC/ui/technology-panel.md § Slot behaviour.
/// Refs #3510.
const double kTechnologySlotActionTouchTargetBreakpoint = 600;

// Vertical `--bg-deep` → `--surface` gradient shared by the researched
// tech chip body and the slot card chrome. Mirrors the mockup
// `linear-gradient(180deg,var(--bg-deep),var(--surface))` and is the
// single source so future palette tweaks stay aligned across both
// surfaces (SPEC/ui/technology-panel.md § Layout / wireframe + mockup
// `.tech-chip` and `.slot-card`). Refs #2864 S2/S3.
LinearGradient technologyDarkSurfaceGradient() {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.bgDeep,
      EditorialMonoclePalette.surface,
    ],
  );
}
