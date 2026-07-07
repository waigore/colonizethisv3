part of 'technology_panel_widgets.dart';

class _SlotEmptyBody extends StatelessWidget {
  const _SlotEmptyBody();

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

class _SlotAssignedBody extends StatelessWidget {
  const _SlotAssignedBody({
    required this.slotIndex,
    required this.techId,
    required this.progress,
    required this.cost,
    required this.funding,
    required this.onFundingChanged,
    required this.turnPreview,
  });

  final int slotIndex;
  final String techId;
  final int progress;
  final int cost;
  final ResearchFundingLevel funding;
  final ValueChanged<ResearchFundingLevel>? onFundingChanged;
  final ResearchSlotTurnPreview? turnPreview;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final onFundingChanged = this.onFundingChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AssignedTechRow(techId: techId),
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
          )
        else
          Row(
            children: [
              Expanded(
                child: CtProgressBar(
                  value: cost > 0 ? progress / cost : 0,
                ),
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

class _AssignedTechRow extends StatelessWidget {
  const _AssignedTechRow({required this.techId});

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
