// Research slot card widgets for the GAME40001 Technology panel Slots tab.
//
// Split out of `technology_panel.dart` so that file stays under the
// `repo.game_widgets_file_size` cap. Contains the active slot card chrome
// (`ResearchSlotCard` + its header/body sub-widgets), the locked fourth-slot
// placeholder, the shared slot-card chrome, and the shared dark-surface
// gradient. Refs #2864 S3 / #3512.
//
// SPEC: SPEC/ui/technology-panel.md § Slot behaviour.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';
import '../utils/research_slot_preview.dart';
import '../utils/tech_ui_helpers.dart';
import '../../../widgets/ct_progress_bar.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'chrome/ct_action_text_button.dart';
import 'chrome/ct_danger_text_button.dart';
import 'research_slot_turn_preview_view.dart';
import 'technology_slot_funding_toggles.dart';

/// Opacity applied to the locked fourth-slot card body when
/// `player.researchSlots < 4`.
///
/// SPEC/ui/technology-panel.md § Slot behaviour > Locked slot 4
/// (University). Refs #2864 S0/S3.
const double kTechnologyLockedSlotOpacity = 0.45;

/// Viewport width (logical px) below which the compact slot action controls
/// (`CtActionTextButton` / `CtDangerTextButton`) guarantee a
/// [kMinTouchTargetSize] (44 dp) tap target in both dimensions.
///
/// Mirrors the in-game shell narrow breakpoint (`< 600 dp`) in
/// `SPEC/ui/mobile-adaptation.md` § 4. At or above this width the slot action
/// controls render at their compact mockup size
/// (`SPEC/ui/mockups/GAME40001-technology-panel.html` `.slot-actions button`);
/// below it the controls expand so they satisfy the mobile minimum
/// touch-target rule (§ 1). SPEC/ui/technology-panel.md § Slot behaviour.
/// Refs #3510.
const double kTechnologySlotActionTouchTargetBreakpoint = 600;

/// Vertical `--bg-deep` → `--surface` gradient shared by the researched
/// tech chip body and the slot card chrome. Mirrors the mockup
/// `linear-gradient(180deg,var(--bg-deep),var(--surface))` and is the
/// single source so future palette tweaks stay aligned across both
/// surfaces (SPEC/ui/technology-panel.md § Layout / wireframe + mockup
/// `.tech-chip` and `.slot-card`). Refs #2864 S2/S3.
LinearGradient technologyDarkSurfaceGradient() {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.bgDeep,
      EditorialMonoclePalette.surface,
    ],
  );
}

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

  /// Computed next-turn preview for the assigned tech (RP/gold deltas, debt
  /// block). `null` when the slot has no resolvable tech. Refs #3512.
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
              const SizedBox(width: 8),
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

/// Locked fourth-slot placeholder card rendered when
/// `player.researchSlots < 4`.
///
/// SPEC/ui/technology-panel.md § Slot behaviour > Locked slot 4
/// (University). Refs #2864 S0/S3.
class LockedResearchSlotCard extends StatelessWidget {
  const LockedResearchSlotCard({super.key, required this.slotNumber});

  final int slotNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Opacity(
      opacity: kTechnologyLockedSlotOpacity,
      child: _SlotCardChrome(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.technologyPanel_lockedSlotLabel(slotNumber),
              style: TextStyle(
                color: EditorialMonoclePalette.fg,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.04,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.technologyPanel_lockedSlotFootnote,
                style: TextStyle(
                  color: EditorialMonoclePalette.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotCardChrome extends StatelessWidget {
  const _SlotCardChrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: technologyDarkSurfaceGradient(),
        border: Border.all(
          color: EditorialMonoclePalette.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: CtSpacing.m,
        ),
        child: child,
      ),
    );
  }
}
