part of 'technology_panel_widgets.dart';

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
    return _SlotCardChrome(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SlotHeaderRow(
            slotIndex: slotIndex,
            canEdit: canEdit,
            hasTech: _hasTech,
            onCancel: onCancel,
            onChooseTech: onChooseTech,
          ),
          const SizedBox(height: 4),
          if (!_hasTech)
            const _SlotEmptyBody()
          else
            _SlotAssignedBody(
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
