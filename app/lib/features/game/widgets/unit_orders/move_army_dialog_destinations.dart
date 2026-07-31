import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_section_label.dart';
import '../../../../widgets/ct_spacing.dart';
import '../province_overlay/province_panel_labels.dart';
import 'move_army_dialog.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.moveArmy_yourArmyRegiments(moveArmyOwnRegimentCount(widget.army)),
          style: intelMutedStyle,
        ),
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
