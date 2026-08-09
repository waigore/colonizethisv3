import 'package:flutter/material.dart';

import 'package:colonizethis_app/widgets/ct_spacing.dart';

/// Shared layout constants for [NewGameLeaderSelectionDialog] (Refs #4117).
const int kNewGameLeaderSelectionNumSlots = 6;

/// Vertical gap between slot rows. Matches the mockup `.slots-list{gap:6px}`.
const double kNewGameLeaderSelectionSlotListGap = CtSpacing.s;

/// Slot-row inner padding. Matches the mockup `.slot-row{padding:8px 10px}`
/// (vertical 8 dp = [CtSpacing.m]; horizontal 10 dp is a per-component override
/// not on the canonical spacing scale).
const EdgeInsets kNewGameLeaderSelectionSlotRowPadding = EdgeInsets.symmetric(
  vertical: CtSpacing.m,
  horizontal: 10,
);

/// Horizontal gap between the infinite-mode toggle and its label, also used to
/// indent the helper text. Matches the mockup `.toggle-row{gap:10px}`.
const double kNewGameLeaderSelectionToggleLabelGap = 10;

const String kNewGameLeaderSelectionNormalProfileChoiceId = '';

/// Resolved text styles for the leader-selection dialog chrome.
class NewGameLeaderDialogTextStyles {
  const NewGameLeaderDialogTextStyles({
    required this.title,
    required this.intro,
    required this.fieldLabel,
    required this.helper,
    required this.slotLabel,
    required this.slotYouTag,
    required this.profileInlineLabel,
  });

  final TextStyle title;
  final TextStyle intro;
  final TextStyle fieldLabel;
  final TextStyle helper;
  final TextStyle slotLabel;
  final TextStyle slotYouTag;
  final TextStyle profileInlineLabel;
}
