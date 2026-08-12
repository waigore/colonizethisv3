// Empire-wide research funding summary for GAME40001 Slots (Refs #4335).
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'research_slot_preview.dart';
import 'research_slot_turn_preview_view_styles.dart';

/// Default header strip showing overall research gold/RP for this turn.
class ResearchTurnFundingHeader extends StatelessWidget {
  const ResearchTurnFundingHeader({super.key, required this.preview});

  final ResearchSlotsTurnPreview preview;

  /// Stable test key for the overall funding readout.
  static const Key summaryKey = ValueKey<String>('techResearchTurnFunding');

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final String label = preview.hasSpend
        ? l10n.technologyPanel_researchTurnFundingSummary(
            preview.totalGoldSpent,
            preview.totalRp,
          )
        : l10n.technologyPanel_researchTurnFundingEmpty;
    return Padding(
      key: summaryKey,
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: researchSlotTurnPreviewMonoStyle(
          preview.hasSpend
              ? EditorialMonoclePalette.accentBright
              : EditorialMonoclePalette.muted,
        ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
