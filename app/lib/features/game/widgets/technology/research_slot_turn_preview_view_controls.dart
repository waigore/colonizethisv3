import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_resource_cell.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'research_slot_preview.dart';
import 'research_slot_turn_preview_view_breakdown.dart';
import 'research_slot_turn_preview_view_styles.dart';

/// Green `+N RP` anticipated-delta chip that opens the breakdown dialog.
class RpDeltaControl extends StatelessWidget {
  const RpDeltaControl({super.key, required this.preview});

  final ResearchSlotTurnPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return InkWell(
      onTap: () => showResearchFundingBreakdownDialog(
        context: context,
        preview: preview,
      ),
      child: Text(
        l10n.technologyPanel_rpDeltaPreview(preview.anticipatedRpPerTurn),
        style: researchSlotTurnPreviewMonoStyle(EditorialMonoclePalette.success),
      ),
    );
  }
}

/// Treasury (gold) per-turn cost row with a signed delta.
class GoldPreviewRow extends StatelessWidget {
  const GoldPreviewRow({super.key, required this.preview});

  final ResearchSlotTurnPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    if (preview.isNoneFunding) {
      return const SizedBox.shrink();
    }
    final bool spends = preview.goldSpentThisTurn > 0;
    final Color color = spends
        ? (CtResourceCell.deltaColor(-preview.goldSpentThisTurn) ??
              EditorialMonoclePalette.muted)
        : EditorialMonoclePalette.muted;
    final String label = spends
        ? l10n.technologyPanel_goldSpendPerTurn(preview.goldCostPerTurn)
        : l10n.technologyPanel_goldNoSpendPerTurn(preview.goldCostPerTurn);
    return Row(
      children: [
        StrictAssetIcon(
          assetPath: kResearchSlotTurnPreviewTreasuryCoinAsset,
          width: 14,
          height: 14,
        ),
        const SizedBox(width: 5),
        Text(label, style: researchSlotTurnPreviewMonoStyle(color)),
      ],
    );
  }
}
