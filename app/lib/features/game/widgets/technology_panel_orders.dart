// Order helpers + Choose-tech dialog for `TechnologyPanel`.
// Split out of `technology_panel.dart` to keep that file under the
// 700-line `repo.game_widgets_file_size` cap (Refs #2864 S2/S3 + repo
// lint cap).
//
// Choose-tech dialog (Refs #2864 S4): dark editorial-monocle modal
// dismissible by the close button. Backed by `CtDialogShell` plus the
// canonical `EditorialMonoclePalette.dialogScrim` `barrierColor` per
// `SPEC/ui/technology-panel.md` § Choose-tech dialog and
// `SPEC/ui/pixel-art-ui-catalog.md` § Dialog scrim.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_confirm_dialog.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../utils/tech_ui_helpers.dart';

/// Icon size used in Choose-tech dialog rows. Mirrors the mockup
/// `.tech-option img` width/height (22 px). Refs #2864 S4.
const double kChooseTechDialogIconSize = 22;

/// Opens the dark editorial-monocle Choose-tech dialog for [slotIndex]
/// and dispatches `onOrdersChanged` with the updated `Orders` when the
/// user selects a row. Empty-state message is
/// `"No techs available to research"`. The footer Close button pops the
/// route without mutating orders.
///
/// SPEC: `SPEC/ui/technology-panel.md` § Choose-tech dialog. Refs #2864 S4.
void showChooseTechDialog({
  required BuildContext context,
  required Game game,
  required int slotIndex,
  required String humanPlayerId,
  required Orders currentOrders,
  required Player player,
  required void Function(Orders orders) onOrdersChanged,
}) {
  final techUnlocked = player.techUnlocked ?? {};
  final existingOrders =
      currentOrders.researchOrdersByPlayerId[humanPlayerId] ??
      const <ResearchOrder>[];
  final currentlyAssignedIds = existingOrders
      .where((o) => o.techId.isNotEmpty)
      .map((o) => o.techId)
      .toSet();

  final researchableIds = researchableTechIds(
    techUnlocked,
    hasDiscoveredResource: (r) =>
        hasRevealedResourceForPlayer(game, player.id, r),
  );
  final choosableIds = researchableIds
      .where((id) => !currentlyAssignedIds.contains(id))
      .toList();
  final availableTechs =
      choosableIds
          .map((id) => techById(id))
          .whereType<TechDefinition>()
          .toList()
        ..sort((a, b) {
          final eraCmp = a.era.compareTo(b.era);
          if (eraCmp != 0) return eraCmp;
          return techDisplayName(a.id).compareTo(techDisplayName(b.id));
        });

  showDialog<void>(
    context: context,
    barrierColor: EditorialMonoclePalette.dialogScrim,
    builder: (ctx) {
      return ChooseTechDialog(
        slotIndex: slotIndex,
        availableTechs: availableTechs,
        onSelect: (tech) {
          final updatedOrders = applyAssignTechToSlot(
            currentOrders: currentOrders,
            humanPlayerId: humanPlayerId,
            slotIndex: slotIndex,
            techId: tech.id,
            existingOrders: existingOrders,
          );
          onOrdersChanged(updatedOrders);
          Navigator.of(ctx).pop();
        },
      );
    },
  );
}

/// Dark editorial-monocle Choose-tech dialog body. Composes
/// `CtDialogShell` + a vertical column of [_ChooseTechOptionRow]
/// entries (or the empty-state line) plus a single full-width Close
/// `CtNinePatchButton`. Refs #2864 S4.
@visibleForTesting
class ChooseTechDialog extends StatelessWidget {
  const ChooseTechDialog({
    super.key,
    required this.slotIndex,
    required this.availableTechs,
    required this.onSelect,
  });

  final int slotIndex;
  final List<TechDefinition> availableTechs;
  final void Function(TechDefinition tech) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final isEmpty = availableTechs.isEmpty;
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.technologyPanel_chooseTechDialogTitle(slotIndex + 1),
            style: theme.textTheme.titleMedium?.copyWith(
              color: EditorialMonoclePalette.accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 8),
          if (isEmpty)
            _ChooseTechEmptyMessage()
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final tech in availableTechs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _ChooseTechOptionRow(
                      tech: tech,
                      onTap: () => onSelect(tech),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          CtNinePatchButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }
}

class _ChooseTechEmptyMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CtSpacing.ml),
      child: Text(
        l10n.technologyPanel_noTechsAvailable,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: EditorialMonoclePalette.muted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _ChooseTechOptionRow extends StatelessWidget {
  const _ChooseTechOptionRow({required this.tech, required this.onTap});

  final TechDefinition tech;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconPath = techCategoryIconAssetPath(tech.category);
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: EditorialMonoclePalette.border,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (iconPath != null) ...[
                StrictAssetIcon(
                  assetPath: iconPath,
                  width: kChooseTechDialogIconSize,
                  height: kChooseTechDialogIconSize,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(child: _ChooseTechOptionLabels(tech: tech)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChooseTechOptionLabels extends StatelessWidget {
  const _ChooseTechOptionLabels({required this.tech});

  final TechDefinition tech;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          techDisplayName(tech.id),
          style: TextStyle(
            color: EditorialMonoclePalette.fg,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.technologyPanel_pickSubtitle(
            eraRoman(tech.era),
            techCategoryLabelL10n(l10n, tech.category),
            tech.cost,
          ),
          style: TextStyle(
            color: EditorialMonoclePalette.muted,
            fontSize: 10,
            fontFamilyFallback: const <String>[
              'SF Mono',
              'Menlo',
              'monospace',
            ],
            fontFeatures: const <FontFeature>[
              FontFeature.tabularFigures(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Returns an `Orders` value with `slotIndex` set to [techId] for
/// [humanPlayerId]. Funding for the slot is preserved when an order
/// already exists there, otherwise defaults to `ResearchFundingLevel.medium`.
Orders applyAssignTechToSlot({
  required Orders currentOrders,
  required String humanPlayerId,
  required int slotIndex,
  required String techId,
  required List<ResearchOrder> existingOrders,
}) {
  final ordersForPlayer = List<ResearchOrder>.from(existingOrders);
  final existingIndex = ordersForPlayer.indexWhere(
    (o) => o.slotIndex == slotIndex,
  );
  // Preserve funding only when an existing *assigned* order occupies the slot;
  // an empty-techId cancel signal at this slot is treated as a fresh
  // assignment and defaults to Medium. Refs #3512.
  final funding =
      existingIndex >= 0 && ordersForPlayer[existingIndex].techId.isNotEmpty
      ? ordersForPlayer[existingIndex].funding
      : ResearchFundingLevel.medium;
  final newOrder = ResearchOrder(
    slotIndex: slotIndex,
    techId: techId,
    funding: funding,
  );
  if (existingIndex >= 0) {
    ordersForPlayer[existingIndex] = newOrder;
  } else {
    ordersForPlayer.add(newOrder);
  }

  final updatedMap = {
    ...currentOrders.researchOrdersByPlayerId,
    humanPlayerId: ordersForPlayer,
  };
  return currentOrders.copyWith(researchOrdersByPlayerId: updatedMap);
}

/// Returns an `Orders` value with the `ResearchOrder` at [slotIndex] for
/// [humanPlayerId] updated to use [funding], preserving the slot's `techId`.
///
/// When an assigned order already occupies [slotIndex] its funding is updated
/// in place. When no assigned order exists at [slotIndex] but the slot is
/// occupied by a persisted `Player.researchSlotAssignments` entry, the caller
/// passes that tech via [techId] so a fresh order is created carrying the
/// persisted tech (otherwise the resolver would not apply the funding change to
/// a slot with no fresh order). When neither an assigned order nor a [techId]
/// is available (a genuinely empty slot) the orders are returned unchanged so
/// funding cannot be set on an unassigned slot.
///
/// SPEC/ui/technology-panel.md § Slot behaviour > Slot funding controls
/// (Refs #3512).
Orders applySetSlotFunding({
  required Orders currentOrders,
  required String humanPlayerId,
  required int slotIndex,
  required ResearchFundingLevel funding,
  String? techId,
}) {
  final existing =
      currentOrders.researchOrdersByPlayerId[humanPlayerId] ??
      const <ResearchOrder>[];
  final ordersForPlayer = List<ResearchOrder>.from(existing);
  final existingIndex = ordersForPlayer.indexWhere(
    (o) => o.slotIndex == slotIndex,
  );
  final hasAssignedOrder =
      existingIndex >= 0 && ordersForPlayer[existingIndex].techId.isNotEmpty;
  if (hasAssignedOrder) {
    final previous = ordersForPlayer[existingIndex];
    ordersForPlayer[existingIndex] = ResearchOrder(
      slotIndex: previous.slotIndex,
      techId: previous.techId,
      funding: funding,
    );
  } else if (techId != null && techId.isNotEmpty) {
    final newOrder = ResearchOrder(
      slotIndex: slotIndex,
      techId: techId,
      funding: funding,
    );
    if (existingIndex >= 0) {
      ordersForPlayer[existingIndex] = newOrder;
    } else {
      ordersForPlayer.add(newOrder);
    }
  } else {
    return currentOrders;
  }
  final updatedMap = {
    ...currentOrders.researchOrdersByPlayerId,
    humanPlayerId: ordersForPlayer,
  };
  return currentOrders.copyWith(researchOrdersByPlayerId: updatedMap);
}

/// Frees [slotIndex] for [humanPlayerId] by emitting an **empty-`techId`**
/// `ResearchOrder` cancel signal (rather than simply dropping the slot's
/// order). The resolver merges persisted `Player.researchSlotAssignments` with
/// this turn's orders, so an empty-`techId` order is the only way to free a
/// slot whose occupancy is persisted from a previous turn; merely removing the
/// order would leave the persisted assignment researching. Any existing order
/// at [slotIndex] is replaced by the cancel signal.
///
/// SPEC/program/research-resolution.md § Slot occupancy persistence;
/// SPEC/ui/technology-panel.md § Slot behaviour > Cancel. Refs #3512.
Orders _applyFreeSlotOrders({
  required Orders currentOrders,
  required String humanPlayerId,
  required int slotIndex,
}) {
  final existing =
      currentOrders.researchOrdersByPlayerId[humanPlayerId] ??
      const <ResearchOrder>[];
  final ordersForPlayer = List<ResearchOrder>.from(existing);
  final cancelOrder = ResearchOrder(
    slotIndex: slotIndex,
    techId: '',
    funding: ResearchFundingLevel.none,
  );
  final existingIndex = ordersForPlayer.indexWhere(
    (o) => o.slotIndex == slotIndex,
  );
  if (existingIndex >= 0) {
    ordersForPlayer[existingIndex] = cancelOrder;
  } else {
    ordersForPlayer.add(cancelOrder);
  }
  final updatedMap = {
    ...currentOrders.researchOrdersByPlayerId,
    humanPlayerId: ordersForPlayer,
  };
  return currentOrders.copyWith(researchOrdersByPlayerId: updatedMap);
}

/// Cancels the research slot at [slotIndex] for [humanPlayerId].
///
/// When the slot's tech has accrued progress ([accruedProgress] `> 0`), a
/// forfeiture-warning `CtConfirmDialog` is shown first; the cancel only
/// proceeds when the player confirms. When there is no accrued progress the
/// slot is freed immediately with no dialog. Freeing emits an empty-`techId`
/// cancel signal (see [_applyFreeSlotOrders]) so a persisted slot assignment is
/// released and its accrued RP forfeited on resolution. A transient snackbar
/// confirmation is shown when a `ScaffoldMessenger` is in scope.
///
/// SPEC/ui/technology-panel.md § Slot behaviour > Cancel. Refs #3512.
Future<void> applyCancelSlotOrder({
  required BuildContext context,
  required int slotIndex,
  required String humanPlayerId,
  required Orders currentOrders,
  required void Function(Orders orders) onOrdersChanged,
  String? techId,
  int accruedProgress = 0,
}) async {
  final l10n = appL10n(context);
  if (accruedProgress > 0) {
    final techName = (techId != null && techId.isNotEmpty)
        ? techDisplayName(techId)
        : l10n.technologyPanel_noTechAssigned;
    final confirmed = await showCtConfirmDialog(
      context,
      title: l10n.technologyPanel_cancelWarningTitle,
      message: l10n.technologyPanel_cancelWarningMessage(
        techName,
        accruedProgress,
      ),
      confirmLabel: l10n.technologyPanel_cancelWarningConfirm,
      cancelLabel: l10n.technologyPanel_cancelWarningKeep,
      useRootNavigator: false,
    );
    if (!confirmed) return;
    if (!context.mounted) return;
  }
  final updated = _applyFreeSlotOrders(
    currentOrders: currentOrders,
    humanPlayerId: humanPlayerId,
    slotIndex: slotIndex,
  );
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    SnackBar(content: Text(l10n.technologyPanel_slotCancelled)),
  );
  onOrdersChanged(updated);
}
