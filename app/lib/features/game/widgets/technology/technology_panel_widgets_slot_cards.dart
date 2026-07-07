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

class _SlotHeaderRow extends StatelessWidget {
  const _SlotHeaderRow({
    required this.slotIndex,
    required this.canEdit,
    required this.hasTech,
    required this.onCancel,
    required this.onChooseTech,
  });

  final int slotIndex;
  final bool canEdit;
  final bool hasTech;
  final VoidCallback? onCancel;
  final VoidCallback? onChooseTech;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    // SPEC/ui/technology-panel.md § Slot behaviour: below the narrow
    // breakpoint the compact slot action controls expand to a 44 dp minimum
    // tap target (mobile-adaptation § 1); at or above it they keep the
    // compact mockup size (`.slot-actions button`). Refs #3510.
    final bool enforceMobileTouchTarget = MediaQuery.sizeOf(context).width <
        kTechnologySlotActionTouchTargetBreakpoint;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.technologyPanel_slot(slotIndex + 1),
            style: TextStyle(
              color: EditorialMonoclePalette.fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.04,
            ),
          ),
        ),
        if (canEdit) ...[
          if (hasTech && onCancel != null) ...[
            _wrapSlotActionTouchTarget(
              enforce: enforceMobileTouchTarget,
              child: CtDangerTextButton(
                onPressed: onCancel,
                label: l10n.common_cancel,
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (onChooseTech != null)
            _wrapSlotActionTouchTarget(
              enforce: enforceMobileTouchTarget,
              child: CtActionTextButton(
                onPressed: onChooseTech,
                label: l10n.technologyPanel_chooseTech,
              ),
            ),
        ],
      ],
    );
  }

  /// Guarantees a [kMinTouchTargetSize] (44 dp) minimum tap target around a
  /// compact slot action control when [enforce] is `true` (narrow / mobile
  /// viewports). The min constraints propagate through the button's
  /// `InkWell`, so the whole 44 dp region becomes tappable while the visible
  /// chrome stays the compact mockup control on wider viewports.
  /// SPEC/ui/technology-panel.md § Slot behaviour. Refs #3510.
  static Widget _wrapSlotActionTouchTarget({
    required bool enforce,
    required Widget child,
  }) {
    if (!enforce) {
      return child;
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: kMinTouchTargetSize,
        minHeight: kMinTouchTargetSize,
      ),
      child: child,
    );
  }
}

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
