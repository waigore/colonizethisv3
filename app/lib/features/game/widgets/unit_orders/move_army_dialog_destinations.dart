import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_section_label.dart';
import '../../../../widgets/ct_spacing.dart';
import 'move_army_dialog.dart';
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
              ),
            )
            .toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
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
  }) {
    final bool isSelected = armySelectedDestination == entry.fullProvinceId;
    final TextStyle labelStyle = moveDialogRowLabelStyle(
      theme,
      selected: isSelected,
    );
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

    return MoveDialogDestinationRow(
      selected: isSelected,
      semanticsLabel: entry.provinceLabel,
      onTap: () => setState(() => armySelectedDestination = entry.fullProvinceId),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(entry.provinceLabel, style: labelStyle),
          if (triggerLabel != null && triggerStyle != null)
            Text(triggerLabel, style: triggerStyle),
        ],
      ),
    );
  }
}
