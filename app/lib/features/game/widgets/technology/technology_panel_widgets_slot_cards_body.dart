import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_progress_bar.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'research_slot_finish_estimate.dart';
import 'research_slot_preview.dart';
import 'research_slot_turn_preview_view.dart';
import 'tech_ui_helpers.dart';
import 'technology_slot_funding_toggles.dart';

class TechnologyPanelSlotEmptyBody extends StatelessWidget {
  const TechnologyPanelSlotEmptyBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        l10n.technologyPanel_noTechAssigned,
        style: TextStyle(
          color: EditorialMonoclePalette.muted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class TechnologyPanelSlotAssignedBody extends StatelessWidget {
  const TechnologyPanelSlotAssignedBody({
    super.key,
    required this.slotIndex,
    required this.techId,
    required this.progress,
    required this.cost,
    required this.funding,
    required this.onFundingChanged,
    required this.turnPreview,
    this.finishCalendar,
  });

  final int slotIndex;
  final String techId;
  final int progress;
  final int cost;
  final ResearchFundingLevel funding;
  final ValueChanged<ResearchFundingLevel>? onFundingChanged;
  final ResearchSlotTurnPreview? turnPreview;
  final ResearchFinishCalendar? finishCalendar;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final onFundingChanged = this.onFundingChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TechnologyPanelAssignedTechRow(techId: techId),
        if (onFundingChanged != null) ...[
          const SizedBox(height: 6),
          SlotFundingToggleRow(
            slotIndex: slotIndex,
            selected: funding,
            onChanged: onFundingChanged,
          ),
        ],
        const SizedBox(height: 4),
        if (turnPreview != null)
          ResearchSlotTurnPreviewView(
            slotIndex: slotIndex,
            preview: turnPreview!,
            calendar: finishCalendar,
          )
        else
          Row(
            children: [
              Expanded(
                child: CtProgressBar(value: cost > 0 ? progress / cost : 0),
              ),
              CtGap.wm,
              Text(
                l10n.technologyPanel_slotRpProgress(progress, cost),
                style: TextStyle(
                  color: EditorialMonoclePalette.accentDim,
                  fontFamilyFallback: const <String>[
                    'SF Mono',
                    'Menlo',
                    'monospace',
                  ],
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                  fontSize: 10,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class TechnologyPanelAssignedTechRow extends StatelessWidget {
  const TechnologyPanelAssignedTechRow({super.key, required this.techId});

  final String techId;

  @override
  Widget build(BuildContext context) {
    final tech = techById(techId);
    final iconPath = techCategoryIconAssetPath(tech?.category);
    return Row(
      children: [
        if (iconPath != null) ...[
          StrictAssetIcon(assetPath: iconPath, width: 20, height: 20),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            techDisplayName(techId),
            style: TextStyle(
              color: EditorialMonoclePalette.fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
