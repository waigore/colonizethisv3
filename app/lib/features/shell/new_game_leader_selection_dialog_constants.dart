// New game leader-selection dialog layout constants.
// SPEC/ui/new-game-leader-selection-dialog.md.

import 'package:flutter/material.dart';

import 'package:colonizethis_app/widgets/ct_spacing.dart';

/// Six player slots (human + five AI). SPEC/ui/new-game-leader-selection-dialog.md.
const int kNewGameLeaderSelectionDialogNumSlots = 6;

/// Vertical gap between slot rows. Matches the mockup `.slots-list{gap:6px}`.
const double kNewGameLeaderSelectionDialogSlotListGap = CtSpacing.s;

/// Slot-row inner padding. Matches the mockup `.slot-row{padding:8px 10px}`
/// (vertical 8 dp = [CtSpacing.m]; horizontal 10 dp is a per-component override
/// not on the canonical spacing scale).
const EdgeInsets kNewGameLeaderSelectionDialogSlotRowPadding = EdgeInsets.symmetric(
  vertical: CtSpacing.m,
  horizontal: 10,
);

/// Horizontal gap between the infinite-mode toggle and its label, also used to
/// indent the helper text. Matches the mockup `.toggle-row{gap:10px}`.
const double kNewGameLeaderSelectionDialogToggleLabelGap = 10;

/// Sentinel dropdown value for the default (non-blessed) AI profile choice.
const String kNewGameLeaderSelectionDialogNormalProfileChoiceId = '';
