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
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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
          padding: const EdgeInsets.all(8),
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
  final funding = existingIndex >= 0
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

/// Removes the `ResearchOrder` at [slotIndex] for [humanPlayerId], shows
/// a transient snackbar confirmation when a `ScaffoldMessenger` is in
/// scope, and dispatches the updated `Orders` via `onOrdersChanged`.
void applyCancelSlotOrder({
  required BuildContext context,
  required int slotIndex,
  required String humanPlayerId,
  required Orders currentOrders,
  required void Function(Orders orders) onOrdersChanged,
}) {
  final l10n = appL10n(context);
  final existingOrders =
      currentOrders.researchOrdersByPlayerId[humanPlayerId] ??
      const <ResearchOrder>[];
  final remaining = existingOrders
      .where((o) => o.slotIndex != slotIndex)
      .toList(growable: false);
  final updatedMap = {
    ...currentOrders.researchOrdersByPlayerId,
    humanPlayerId: remaining,
  };
  final updated = currentOrders.copyWith(researchOrdersByPlayerId: updatedMap);
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    SnackBar(content: Text(l10n.technologyPanel_slotCancelled)),
  );
  onOrdersChanged(updated);
}
