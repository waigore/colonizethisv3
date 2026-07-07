part of 'move_army_dialog.dart';

extension _MoveArmyDialogDestinations on _MoveArmyDialogState {
  Widget _buildMoveDialogDestinationsBody(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final entries = _destinationEntries();
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
              (entry) => _buildDestinationRow(
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
  Widget _buildDestinationRow(
    ThemeData theme,
    AppLocalizations l10n,
    ArmyMovePickerDestination entry, {
    required bool showDeclareWarTrigger,
  }) {
    final bool selected = _selected == entry.fullProvinceId;
    final TextStyle labelStyle = moveDialogRowLabelStyle(
      theme,
      selected: selected,
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
      selected: selected,
      semanticsLabel: entry.provinceLabel,
      onTap: () => setState(() => _selected = entry.fullProvinceId),
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
