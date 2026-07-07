part of 'move_army_dialog.dart';

extension _MoveArmyDialogDeclareWar on _MoveArmyDialogState {
  Future<void> _onConfirmPressed() async {
    final entries = _destinationEntries();
    final entry = _selectedEntry(entries);
    if (entry == null) return;
    final l10n = appL10n(context);

    if (!entry.requiresDeclareWarOnConfirm) {
      _emitAndClose(entry);
      return;
    }

    final ownerLabel = moveArmyFactionGroupHeaderLabel(
      widget.game,
      entry,
      l10n,
    );
    final ok = await _showDeclareWarConfirmDialog(ownerLabel, l10n);
    if (ok == true && context.mounted) {
      _emitAndClose(entry);
    }
  }

  Future<bool?> _showDeclareWarConfirmDialog(
    String ownerLabel,
    AppLocalizations l10n,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
            .copyWith(color: EditorialMonoclePalette.danger);
        final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: EditorialMonoclePalette.fg);
        return CtDialogShell(
          borderColor: EditorialMonoclePalette.danger,
          borderWidth: CtDialogShell.dangerBorderWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.moveArmy_invadeProvinceTitle, style: titleStyle),
              const SizedBox(height: CtSpacing.m),
              Text(
                l10n.moveArmy_invadeProvinceBody(ownerLabel),
                style: bodyStyle,
              ),
              const SizedBox(height: CtSpacing.l),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: CtSpacing.m,
                runSpacing: CtSpacing.m,
                children: [
                  CtNinePatchButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.common_cancel),
                  ),
                  CtNinePatchButton(
                    dangerVariant: true,
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n.moveArmy_declareWarAndMove),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
