import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../utils/tech_ui_helpers.dart';
import '../../../widgets/ct_brass_divider.dart';
import '../../../widgets/ct_progress_bar.dart';
import '../../../widgets/ct_section_label.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/strict_asset_icon.dart';
import 'chrome/ct_action_text_button.dart';
import 'chrome/ct_danger_text_button.dart';
import 'technology_panel_orders.dart';

/// Always-rendered slot count on the Slots tab.
///
/// SPEC/ui/technology-panel.md § Slot behaviour: "The Slots tab always
/// renders exactly four slot cards in slot-index order regardless of
/// `player.researchSlots`." Refs #2864 S0/S3.
const int kTechnologyResearchSlotCount = 4;

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

/// Technology panel (UXD 03k / GAME40001). Shows researched techs and
/// research slots for a player under the dark editorial-monocle theme.
class TechnologyPanel extends StatelessWidget {
  const TechnologyPanel({
    super.key,
    required this.game,
    required this.player,
    this.currentOrders = const Orders(),
    this.onOrdersChanged,
  });

  /// SPEC/ui/technology-panel.md — [UiScreenIds.technologyScreen]. Hosted by
  /// `TechnologyScreen`; shares its stable surface ID.
  static const screenId = UiScreenIds.technologyScreen;

  final Game game;
  final Player player;
  final Orders currentOrders;
  final void Function(Orders orders)? onOrdersChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final researchedIds = _sortedResearchedTechIds();
    final progress = player.researchProgressByTechId ?? const <String, int>{};
    final slots = player.researchSlots ?? 3;
    final humanPlayerId = player.id;
    final researchOrdersForPlayer = _researchOrdersForPlayer(humanPlayerId);
    final canEdit = onOrdersChanged != null;

    return Padding(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: _buildPanelContent(
        context: context,
        l10n: l10n,
        researchedIds: researchedIds,
        progress: progress,
        slots: slots,
        humanPlayerId: humanPlayerId,
        researchOrdersForPlayer: researchOrdersForPlayer,
        canEdit: canEdit,
      ),
    );
  }

  Widget _buildPanelContent({
    required BuildContext context,
    required AppLocalizations l10n,
    required List<String> researchedIds,
    required Map<String, int> progress,
    required int slots,
    required String humanPlayerId,
    required List<ResearchOrder> researchOrdersForPlayer,
    required bool canEdit,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // No dev-only panel header block: the per-player title and the
        // research-slot count line are intentionally omitted so the Slots
        // tab body opens directly with the Researched Techs heading, matching
        // the mockup (`SPEC/ui/mockups/GAME40001-technology-panel.html` opens
        // with `.researched-heading`). Player identity and the `Technology`
        // title are carried by the `CtTopBar` chrome. Refs #3510.
        // Researched Techs renders ABOVE Research Slots per
        // SPEC/ui/technology-panel.md § Layout / wireframe > Body section
        // ordering and matches the mockup body markup in
        // SPEC/ui/mockups/GAME40001-technology-panel.html where
        // `.researched-heading` precedes `.slots-heading`. Refs #2864 S0/S6.
        CtSectionLabel(l10n.technologyPanel_researchedTechsHeading),
        const SizedBox(height: 6),
        if (researchedIds.isEmpty)
          Text(
            l10n.technologyPanel_noneYet,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: EditorialMonoclePalette.muted,
                  fontStyle: FontStyle.italic,
                ),
          )
        else
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final id in researchedIds)
                ResearchedTechChip(techId: id),
            ],
          ),
        const SizedBox(height: 16),
        const CtBrassDivider(),
        const SizedBox(height: 12),
        CtSectionLabel(l10n.technologyPanel_researchSlotsHeading),
        const SizedBox(height: 6),
        // Stretch every slot card to the full panel content width so the
        // locked Slot 4 placeholder is the same width as the active Slots
        // 1–3 (mockup `.slot-card` is a full-width block element).
        // SPEC/ui/technology-panel.md § Slot behaviour > Locked slot 4.
        // Refs #3510.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(
            kTechnologyResearchSlotCount,
            (index) => _buildResearchSlot(
              context: context,
              l10n: l10n,
              index: index,
              slots: slots,
              progress: progress,
              humanPlayerId: humanPlayerId,
              researchOrdersForPlayer: researchOrdersForPlayer,
              canEdit: canEdit,
            ),
          ),
        ),
        if (progress.isNotEmpty) ...[
          const SizedBox(height: 12),
          CtSectionLabel(l10n.technologyPanel_inProgress),
          const SizedBox(height: 4),
          ...progress.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.technologyPanel_progressLine(
                  techDisplayName(entry.key),
                  entry.value,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EditorialMonoclePalette.muted,
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<String> _sortedResearchedTechIds() {
    final techUnlocked = player.techUnlocked ?? const <String, bool>{};
    final researchedIds = techUnlocked.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    researchedIds.sort(_sortTechIdsByEraThenName);
    return researchedIds;
  }

  int _sortTechIdsByEraThenName(String a, String b) {
    final eraA = techById(a)?.era ?? 999;
    final eraB = techById(b)?.era ?? 999;
    final eraCmp = eraA.compareTo(eraB);
    if (eraCmp != 0) {
      return eraCmp;
    }
    return techDisplayName(a).compareTo(techDisplayName(b));
  }

  List<ResearchOrder> _researchOrdersForPlayer(String playerId) {
    return currentOrders.researchOrdersByPlayerId[playerId] ??
        const <ResearchOrder>[];
  }

  Widget _buildResearchSlot({
    required BuildContext context,
    required AppLocalizations l10n,
    required int index,
    required int slots,
    required Map<String, int> progress,
    required String humanPlayerId,
    required List<ResearchOrder> researchOrdersForPlayer,
    required bool canEdit,
  }) {
    final isLockedFourthSlot =
        index == kTechnologyResearchSlotCount - 1 && slots < 4;
    if (isLockedFourthSlot) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: LockedResearchSlotCard(slotNumber: index + 1),
      );
    }
    final order = _researchOrderForSlot(researchOrdersForPlayer, index);
    final techId = _slotTechId(order);
    final tech = techId == null ? null : techById(techId);
    final techProgress = techId == null ? 0 : (progress[techId] ?? 0);
    final cost = tech?.cost ?? 0;
    final hasTech = techId != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ResearchSlotCard(
        slotIndex: index,
        techId: techId,
        progress: techProgress,
        cost: cost,
        canEdit: canEdit,
        onCancel: hasTech && canEdit
            ? () {
                applyCancelSlotOrder(
                  context: context,
                  slotIndex: index,
                  humanPlayerId: humanPlayerId,
                  currentOrders: currentOrders,
                  onOrdersChanged: onOrdersChanged!,
                );
              }
            : null,
        onChooseTech: canEdit
            ? () {
                showChooseTechDialog(
                  context: context,
                  game: game,
                  slotIndex: index,
                  humanPlayerId: humanPlayerId,
                  currentOrders: currentOrders,
                  player: player,
                  onOrdersChanged: onOrdersChanged!,
                );
              }
            : null,
      ),
    );
  }

  ResearchOrder? _researchOrderForSlot(List<ResearchOrder> orders, int index) {
    for (final order in orders) {
      if (order.slotIndex == index) {
        return order;
      }
    }
    return null;
  }

  String? _slotTechId(ResearchOrder? order) {
    if (order == null || order.techId.isEmpty) {
      return null;
    }
    return order.techId;
  }
}

/// Read-only researched-tech chip rendered in the Slots tab grid.
///
/// SPEC/ui/technology-panel.md § Layout / wireframe + mockup
/// `.tech-chip`: vertical `--bg-deep` → `--surface` gradient, 1 px
/// `--border` outline, 14 px tech-category icon, body-font tech name in
/// `--fg`. Refs #2864 S2.
class ResearchedTechChip extends StatelessWidget {
  const ResearchedTechChip({super.key, required this.techId});

  final String techId;

  @visibleForTesting
  static const double iconSize = 14;

  @override
  Widget build(BuildContext context) {
    final tech = techById(techId);
    final iconPath = techCategoryIconAssetPath(tech?.category);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _technologyDarkSurfaceGradient(),
        border: Border.all(
          color: EditorialMonoclePalette.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null) ...[
              StrictAssetIcon(
                assetPath: iconPath,
                width: iconSize,
                height: iconSize,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              techDisplayName(techId),
              style: TextStyle(
                color: EditorialMonoclePalette.fg,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Vertical `--bg-deep` → `--surface` gradient shared by the researched
// tech chip body and the slot card chrome. Mirrors the mockup
// `linear-gradient(180deg,var(--bg-deep),var(--surface))` and is the
// single source so future palette tweaks stay aligned across both
// surfaces (SPEC/ui/technology-panel.md § Layout / wireframe + mockup
// `.tech-chip` and `.slot-card`). Refs #2864 S2/S3.
LinearGradient _technologyDarkSurfaceGradient() {
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
  });

  final int slotIndex;
  final String? techId;
  final int progress;
  final int cost;
  final bool canEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onChooseTech;

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
              techId: techId!,
              progress: progress,
              cost: cost,
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
    required this.techId,
    required this.progress,
    required this.cost,
  });

  final String techId;
  final int progress;
  final int cost;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AssignedTechRow(techId: techId),
        const SizedBox(height: 4),
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
        gradient: _technologyDarkSurfaceGradient(),
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

