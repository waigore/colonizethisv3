import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'research_slot_preview.dart';
import 'technology_panel_slot_card_chrome.dart';
import 'technology_panel_widgets_slot_cards_body.dart';
import 'technology_panel_widgets_slot_cards_header.dart';

/// Active research slot card chrome (flat editorial-monocle surface +
/// `Slot N` header + Cancel / Choose tech actions + progress visual).
///
/// SPEC/ui/technology-panel.md § Slot behaviour. Refs #2864 S3.
class ResearchSlotCard extends StatelessWidget {
  const ResearchSlotCard({
    super.key,
    required this.slotIndex,
    required this.techId,
    required this.progress,
    required this.cost,
    required this.canEdit,
    required this.onCancel,
    required this.onChooseTech,
    this.funding = ResearchFundingLevel.medium,
    this.onFundingChanged,
    this.turnPreview,
  });

  final int slotIndex;
  final String? techId;
  final int progress;
  final int cost;
  final bool canEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onChooseTech;
  final ResearchFundingLevel funding;
  final ValueChanged<ResearchFundingLevel>? onFundingChanged;
  final ResearchSlotTurnPreview? turnPreview;

  bool get _hasTech => techId != null;

  @override
  Widget build(BuildContext context) {
    return TechnologyPanelSlotCardChrome(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TechnologyPanelSlotHeaderRow(
            slotIndex: slotIndex,
            canEdit: canEdit,
            hasTech: _hasTech,
            onCancel: onCancel,
            onChooseTech: onChooseTech,
          ),
          const SizedBox(height: 4),
          if (!_hasTech)
            const TechnologyPanelSlotEmptyBody()
          else
            TechnologyPanelSlotAssignedBody(
              slotIndex: slotIndex,
              techId: techId!,
              progress: progress,
              cost: cost,
              funding: funding,
              onFundingChanged: onFundingChanged,
              turnPreview: turnPreview,
            ),
        ],
      ),
    );
  }
}
