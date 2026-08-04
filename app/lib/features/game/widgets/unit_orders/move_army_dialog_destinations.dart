import 'package:colonizethis_orders/colonizethis_orders.dart'
    show ArmyMovePickerDestination;
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_section_label.dart';
import '../../../../widgets/ct_spacing.dart';
import '../province_overlay/province_panel_labels.dart';
import '../production/force_feeding_readiness_labels.dart';
import 'move_army_dialog.dart';
import '../units/military/general_command_capacity.dart';
import 'move_army_force_feeding.dart';
import 'move_army_invasion_intel.dart';
import 'move_army_invasion_intel_labels.dart';
import 'move_army_dialog_state_logic.dart';
import 'move_units_dialog_base.dart';

mixin MoveArmyDialogDestinations
    on MoveUnitsDialogState<MoveArmyDialog>, MoveArmyDialogStateLogic {
  Widget buildMoveDialogDestinationsBody(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final entries = destinationEntries();
    final owned = entries.where((e) => e.isPlayerOwned).toList();
    final invasion = entries.where((e) => !e.isPlayerOwned).toList();

    Widget sectionRows(
      List<ArmyMovePickerDestination> sectionEntries, {
      required bool showDeclareWarTrigger,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sectionEntries
            .map(
              (entry) => buildDestinationRow(
                theme,
                l10n,
                entry,
                showDeclareWarTrigger: showDeclareWarTrigger,
                showInvasionIntel: showDeclareWarTrigger,
              ),
            )
            .toList(),
      );
    }

    final intelMutedStyle = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.muted);
    final selected = selectedEntry(entries);
    final showInvasionCapacity =
        selected != null && !selected.isPlayerOwned;
    final invasionCount = showInvasionCapacity
        ? stagedInvasionCountForTurn(
            game: widget.game,
            humanPlayerId: widget.humanPlayerId,
            draftOrders: widget.draftOrders,
            previewArmyId: widget.army.id,
            previewDestinationProvinceId: armySelectedDestination,
          )
        : 0;
    final generalCount = humanGeneralCountForDisplay(
      widget.game,
      widget.humanPlayerId,
    );
    final invasionOverCapacity =
        showInvasionCapacity && invasionCount > generalCount;
    final forcesFeeding = humanForcesFeedingPreview(
      game: widget.game,
      topology: widget.topology,
      humanPlayerId: widget.humanPlayerId,
      draftOrders: widget.draftOrders,
    );
    final landUnderfedWarning = showInvasionCapacity
        ? landForceFeedingSoftWarning(l10n, forcesFeeding)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.moveArmy_yourArmyRegiments(moveArmyOwnRegimentCount(widget.army)),
          style: intelMutedStyle,
        ),
        if (showInvasionCapacity) ...[
          const SizedBox(height: CtSpacing.s),
          Text(
            l10n.moveArmy_invasionsThisTurn(invasionCount, generalCount),
            style: intelMutedStyle,
          ),
          if (invasionOverCapacity)
            Padding(
              padding: const EdgeInsets.only(top: CtSpacing.xs),
              child: Text(
                l10n.moveArmy_invasionOverGeneralCapacityWarning,
                style: intelMutedStyle.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (landUnderfedWarning != null)
            Padding(
              padding: const EdgeInsets.only(top: CtSpacing.xs),
              child: Text(
                landUnderfedWarning,
                style: intelMutedStyle.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
        const SizedBox(height: CtSpacing.ml),
        if (owned.isNotEmpty) ...[
          CtSectionLabel(l10n.moveArmy_groupYourProvinces),
          const SizedBox(height: CtSpacing.s),
          sectionRows(owned, showDeclareWarTrigger: false),
        ],
        if (invasion.isNotEmpty) ...[
          if (owned.isNotEmpty) const SizedBox(height: CtSpacing.ml),
          CtSectionLabel(l10n.moveArmy_groupInvasionTargets),
          const SizedBox(height: CtSpacing.s),
          sectionRows(invasion, showDeclareWarTrigger: true),
        ],
      ],
    );
  }

  /// Builds a single army destination row over the shared
  /// [MoveDialogDestinationRow] chrome. Invasion rows append a
  /// `declare war on …` trigger in `--danger` italic body style (#2867 R8).
  Widget buildDestinationRow(
    ThemeData theme,
    AppLocalizations l10n,
    ArmyMovePickerDestination entry, {
    required bool showDeclareWarTrigger,
    required bool showInvasionIntel,
  }) {
    final bool isSelected = armySelectedDestination == entry.fullProvinceId;
    final TextStyle labelStyle = moveDialogRowLabelStyle(
      theme,
      selected: isSelected,
    );
    final intelMutedStyle = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.muted);
    final String? triggerLabel =
        showDeclareWarTrigger && entry.requiresDeclareWarOnConfirm
        ? l10n.moveArmy_declareWarOnTrigger(
            moveArmyFactionGroupHeaderLabel(widget.game, entry, l10n),
          )
        : null;
    final TextStyle? triggerStyle = triggerLabel == null
        ? null
        : (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
            color: EditorialMonoclePalette.danger,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          );

    final invasionIntelSummary = showInvasionIntel
        ? computeMoveArmyInvasionIntelSummary(
            game: widget.game,
            playerView: widget.playerView,
            humanPlayerId: widget.humanPlayerId,
            destinationProvinceId: entry.fullProvinceId,
          )
        : null;
    final invasionIntelLines = invasionIntelSummary == null
        ? const <String>[]
        : moveArmyInvasionIntelSummaryLines(l10n, invasionIntelSummary);
    final invasionDetailLines =
        showInvasionIntel && isSelected && invasionIntelSummary != null
        ? moveArmyInvasionIntelDetailTypeLines(
            l10n: l10n,
            summary: invasionIntelSummary,
            ownTypesByRegimentId: moveArmyOwnRegimentTypesById(
              army: widget.army,
              game: widget.game,
            ),
            regimentLabel: (id) => regimentTypeDisplayLabel(l10n, id),
          )
        : const <String>[];

    return MoveDialogDestinationRow(
      selected: isSelected,
      semanticsLabel: entry.provinceLabel,
      onTap: () => setState(() => armySelectedDestination = entry.fullProvinceId),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(entry.provinceLabel, style: labelStyle),
          for (final line in invasionIntelLines)
            Text(line, style: intelMutedStyle),
          for (final line in invasionDetailLines)
            Text(line, style: intelMutedStyle),
          if (triggerLabel != null && triggerStyle != null)
            Text(triggerLabel, style: triggerStyle),
        ],
      ),
    );
  }
}
