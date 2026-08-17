// Tree-only assign controls for the tech definition detail dialog (Refs #4498).

import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_action_text_button.dart';
import '../../../../widgets/ct_confirm_dialog.dart';
import 'tech_tree_assign.dart';
import 'technology_panel_order_mutations.dart';

/// Optional Tree-only assignment wiring. Null for Choose-tech Details.
/// When [onOrdersChanged] is null, the dialog shows observe-only refusal copy.
class TechTreeAssignConfig {
  const TechTreeAssignConfig({
    required this.currentOrders,
    this.onOrdersChanged,
  });

  final Orders currentOrders;
  final void Function(Orders orders)? onOrdersChanged;

  bool get canEdit => onOrdersChanged != null;
}

/// Research this / replace-seat / refusal copy for Tree-opened detail dialogs.
class TechTreeAssignSection extends StatelessWidget {
  const TechTreeAssignSection({
    super.key,
    required this.game,
    required this.player,
    required this.tech,
    required this.config,
    required this.l10n,
    required this.theme,
    required this.dialogContext,
  });

  final Game game;
  final Player player;
  final TechDefinition tech;
  final TechTreeAssignConfig config;
  final AppLocalizations l10n;
  final ThemeData theme;
  final BuildContext dialogContext;

  @override
  Widget build(BuildContext context) {
    final occupancy = techTreeSeatOccupancy(
      player: player,
      currentOrders: config.currentOrders,
    );
    final decision = evaluateTechTreeAssign(
      game: game,
      player: player,
      tech: tech,
      occupancy: occupancy,
      canEdit: config.canEdit,
    );
    if (!decision.choosable) {
      return Text(
        techTreeAssignReasonMessage(l10n, decision),
        key: const Key('techTreeAssignReason'),
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      );
    }
    final emptyIndex = occupancy.lowestEmptySeatIndex;
    if (emptyIndex != null) {
      return CtActionTextButton(
        key: const Key('techTreeResearchThis'),
        label: l10n.techTree_researchThis,
        onPressed: () {
          unawaited(
            _assignToSeat(
              context: context,
              slotIndex: emptyIndex,
              replacing: null,
            ),
          );
        },
      );
    }
    return _TechTreeReplaceSeatList(
      occupancy: occupancy,
      l10n: l10n,
      theme: theme,
      onReplace: (slotIndex, techId) {
        unawaited(
          _assignToSeat(
            context: context,
            slotIndex: slotIndex,
            replacing: techId,
          ),
        );
      },
    );
  }

  Future<void> _assignToSeat({
    required BuildContext context,
    required int slotIndex,
    required String? replacing,
  }) async {
    final onOrdersChanged = config.onOrdersChanged;
    if (onOrdersChanged == null) return;
    if (replacing != null && replacing.isNotEmpty) {
      final progress = player.researchProgressByTechId?[replacing] ?? 0;
      if (progress > 0) {
        final confirmed = await showCtConfirmDialog(
          context,
          title: l10n.technologyPanel_cancelWarningTitle,
          message: l10n.technologyPanel_cancelWarningMessage(
            techDisplayName(replacing),
            progress,
          ),
          confirmLabel: l10n.technologyPanel_cancelWarningConfirm,
          cancelLabel: l10n.technologyPanel_cancelWarningKeep,
          useRootNavigator: false,
        );
        if (!confirmed) return;
        if (!context.mounted) return;
      }
    }
    final existing =
        config.currentOrders.researchOrdersByPlayerId[player.id] ??
        const <ResearchOrder>[];
    final updated = applyAssignTechToSlot(
      currentOrders: config.currentOrders,
      humanPlayerId: player.id,
      slotIndex: slotIndex,
      techId: tech.id,
      existingOrders: existing,
    );
    onOrdersChanged(updated);
    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
  }
}

class _TechTreeReplaceSeatList extends StatelessWidget {
  const _TechTreeReplaceSeatList({
    required this.occupancy,
    required this.l10n,
    required this.theme,
    required this.onReplace,
  });

  final TechTreeSeatOccupancy occupancy;
  final AppLocalizations l10n;
  final ThemeData theme;
  final void Function(int slotIndex, String techId) onReplace;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.techTree_replaceSeatPrompt,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        for (final entry in occupancy.assignmentBySeat.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: CtActionTextButton(
              key: Key('techTreeReplaceSeat_${entry.key}'),
              label: l10n.techTree_replaceSeatLabel(
                entry.key + 1,
                techDisplayName(entry.value.techId),
              ),
              onPressed: () => onReplace(entry.key, entry.value.techId),
            ),
          ),
      ],
    );
  }
}
