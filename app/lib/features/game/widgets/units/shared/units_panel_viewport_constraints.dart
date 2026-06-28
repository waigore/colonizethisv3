// Shared viewport-adaptive sizing for the three in-game unit-panel bottom-sheet
// hosts (Civilian `UNIT10001`, Military `UNIT20001`, Naval `UNIT30001`).
//
// SPEC/ui/components/units-panel-shell.md § Bottom-sheet sizing,
// SPEC/ui/civilian-units-panel.md, SPEC/ui/military-units-panel.md,
// SPEC/ui/naval-units-panel.md, SPEC/ui/mobile-adaptation.md § 7. Refs #3627.

import 'package:flutter/widgets.dart';

import '../../../../../config/constants.dart';

/// Fixed bottom-sheet height cap on narrow viewports (`width < kNarrowBreakpoint`):
/// `0.50 × viewport height`. SPEC/ui/components/units-panel-shell.md.
const double kUnitsPanelNarrowHeightFactor = 0.50;

/// Bottom-sheet width on wide viewports (`width >= kNarrowBreakpoint`):
/// `0.70 × viewport width`. Applied uniformly to all three unit panels (naval
/// no longer uses a separate fixed sidebar width). Refs #3627.
const double kUnitsPanelWideWidthFactor = 0.70;

/// Bottom-sheet height cap on wide viewports: `0.55 × viewport height`,
/// matching the civilian mockup `max-height: 55vh`
/// (`SPEC/ui/mockups/UNIT10001-civilian-units-panel.html`) and applied to the
/// military and naval hosts for aligned sizing. Refs #3627.
const double kUnitsPanelWideHeightFactor = 0.55;

/// Viewport-adaptive [BoxConstraints] for a unit-panel bottom-sheet host.
///
/// The three unit panels share one sizing contract so the empire-rail panels
/// size consistently across mobile and desktop:
///
/// - **Narrow** (`viewport.width < kNarrowBreakpoint`, i.e. `< 600` dp):
///   `maxWidth = viewport.width` (full width, minus the sheet inset the host
///   applies) and `maxHeight = viewport.height * kUnitsPanelNarrowHeightFactor`
///   (a fixed `50%` cap).
/// - **Wide** (`viewport.width >= kNarrowBreakpoint`):
///   `maxWidth = viewport.width * kUnitsPanelWideWidthFactor` (`70%`) and
///   `maxHeight = viewport.height * kUnitsPanelWideHeightFactor` (`55vh`).
///
/// Callers (the `app_event_handler` openers) wrap the panel in a
/// `ConstrainedBox(constraints: ...)` inside `UnitsPanelSheetSurface`. The
/// function is pure on [viewport] so the sizing contract is unit-testable
/// without mounting a modal sheet.
BoxConstraints unitsPanelSheetConstraints(Size viewport) {
  final bool narrow = viewport.width < kNarrowBreakpoint;
  if (narrow) {
    return BoxConstraints(
      maxWidth: viewport.width,
      maxHeight: viewport.height * kUnitsPanelNarrowHeightFactor,
    );
  }
  return BoxConstraints(
    maxWidth: viewport.width * kUnitsPanelWideWidthFactor,
    maxHeight: viewport.height * kUnitsPanelWideHeightFactor,
  );
}
