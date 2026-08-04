// Choose-tech dialog widgets for the technology panel.
// Split out of `technology_panel_orders.dart` to keep host files under the
// repo file-size target (Refs #3878).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import 'technology_panel_choose_tech_dialog_rows.dart';
import 'technology_panel_order_mutations.dart';

export 'technology_panel_choose_tech_dialog_rows.dart'
    show kChooseTechDialogIconSize;
import 'package:colonizethis_world/colonizethis_world.dart';

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
        game: game,
        contextPlayerId: player.id,
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
/// `CtDialogShell` + a vertical column of [ChooseTechOptionRow]
/// entries (or the empty-state line) plus a single full-width Close
/// `CtNinePatchButton`. Refs #2864 S4.
@visibleForTesting
class ChooseTechDialog extends StatelessWidget {
  const ChooseTechDialog({
    super.key,
    required this.game,
    required this.contextPlayerId,
    required this.slotIndex,
    required this.availableTechs,
    required this.onSelect,
  });

  final Game game;
  final String contextPlayerId;
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
          CtGap.m,
          if (isEmpty)
            const ChooseTechEmptyMessage()
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final tech in availableTechs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ChooseTechOptionRow(
                      game: game,
                      contextPlayerId: contextPlayerId,
                      tech: tech,
                      onAssign: () => onSelect(tech),
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
