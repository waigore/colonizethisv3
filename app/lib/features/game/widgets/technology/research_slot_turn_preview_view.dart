// Per-slot research turn-preview view for the GAME40001 Technology panel
// (Refs #3512): dual-segment progress bar (committed + anticipated), the
// monospace RP progress label, a green anticipated-RP delta that opens a
// breakdown dialog, and a treasury (gold) row with a signed per-turn delta.
//
// Split out of `technology_panel.dart` so that file stays under the
// `repo.game_widgets_file_size` cap.
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_gap.dart';
import 'research_slot_finish_estimate.dart';
import 'research_slot_preview.dart';
import 'research_slot_turn_preview_view_bar.dart';
import 'research_slot_turn_preview_view_controls.dart';
import 'research_slot_turn_preview_view_styles.dart';

export 'research_slot_turn_preview_view_breakdown.dart'
    show ResearchFundingBreakdownDialog;

/// Renders the committed/anticipated progress bar, RP progress label + delta,
/// the finish-time estimate, and the treasury (gold) row for one assigned,
/// editable research slot.
class ResearchSlotTurnPreviewView extends StatelessWidget {
  const ResearchSlotTurnPreviewView({
    super.key,
    required this.slotIndex,
    required this.preview,
    this.calendar,
  });

  final int slotIndex;
  final ResearchSlotTurnPreview preview;
  final ResearchFinishCalendar? calendar;

  /// Stable test key for the green anticipated-RP delta control.
  static Key rpDeltaKey(int slotIndex) =>
      ValueKey<String>('techSlotRpDelta_$slotIndex');

  /// Stable test key for the treasury (gold) preview row.
  static Key goldRowKey(int slotIndex) =>
      ValueKey<String>('techSlotGoldRow_$slotIndex');

  /// Stable test key for the anticipated (segment B) progress fill.
  static Key anticipatedSegmentKey(int slotIndex) =>
      ValueKey<String>('techSlotAnticipatedSegment_$slotIndex');

  /// Stable test key for the finish-time estimate line (Refs #4511).
  static Key finishLineKey(int slotIndex) =>
      ValueKey<String>('techSlotFinishLine_$slotIndex');

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final estimate = researchFinishEstimate(preview);
    final int? year = estimate == null || calendar == null
        ? null
        : researchFinishCalendarYear(estimate: estimate, calendar: calendar!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ResearchDualSegmentBar(
                committedFraction: preview.committedFraction,
                anticipatedFraction: preview.anticipatedFraction,
                anticipatedSegmentKey: anticipatedSegmentKey(slotIndex),
              ),
            ),
            CtGap.wm,
            Text(
              l10n.technologyPanel_slotRpProgress(
                preview.committedProgress,
                preview.cost,
              ),
              style: researchSlotTurnPreviewMonoStyle(
                EditorialMonoclePalette.accentDim,
              ),
            ),
            if (preview.showsAnticipatedSegment) ...[
              const SizedBox(width: 6),
              RpDeltaControl(key: rpDeltaKey(slotIndex), preview: preview),
            ],
          ],
        ),
        if (estimate != null) ...[
          const SizedBox(height: 2),
          Text(
            researchFinishLineLabel(
              l10n: l10n,
              estimate: estimate,
              calendarYear: year,
            ),
            key: finishLineKey(slotIndex),
            style: TextStyle(
              color: EditorialMonoclePalette.muted,
              fontSize: 10,
              height: 1.25,
            ),
          ),
        ],
        const SizedBox(height: 4),
        GoldPreviewRow(key: goldRowKey(slotIndex), preview: preview),
      ],
    );
  }
}

/// Player-facing finish-time copy for a slot card or breakdown restatement.
String researchFinishLineLabel({
  required AppLocalizations l10n,
  required ResearchFinishEstimate estimate,
  int? calendarYear,
}) {
  if (estimate.completesNextTurn) {
    return calendarYear == null
        ? l10n.technologyPanel_finishCompletesNextTurn
        : l10n.technologyPanel_finishCompletesNextTurnWithYear(calendarYear);
  }
  return calendarYear == null
      ? l10n.technologyPanel_finishInTurns(estimate.turnsRemaining)
      : l10n.technologyPanel_finishInTurnsWithYear(
          estimate.turnsRemaining,
          calendarYear,
        );
}
