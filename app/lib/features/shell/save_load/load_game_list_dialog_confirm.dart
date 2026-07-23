part of 'load_game_list_dialog.dart';

extension _LoadGameListDialogConfirm on _LoadGameListDialogState {
  List<Widget> _confirmBodyChildren({
    required AppLocalizations l10n,
    required TextStyle bodyStyle,
    required LoadableSaveEntry? pendingDelete,
    required LoadableSaveEntry? pendingLoad,
  }) {
    if (pendingDelete != null) {
      return [
        Text(
          l10n.loadGameList_deleteConfirm,
          key: LoadGameListDialog.deleteConfirmKey,
          style: bodyStyle,
        ),
        CtGap.l,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CtNinePatchButton(
              key: LoadGameListDialog.deleteCancelButtonKey,
              onPressed: _onDeleteCancel,
              child: Text(l10n.common_cancel),
            ),
            const SizedBox(width: CtSpacing.m),
            CtNinePatchButton(
              key: LoadGameListDialog.deleteConfirmButtonKey,
              onPressed: _onDeleteConfirm,
              child: Text(l10n.loadGameList_delete),
            ),
          ],
        ),
      ];
    }
    if (pendingLoad != null) {
      return [
        Text(
          l10n.loadGameList_discardConfirm,
          key: LoadGameListDialog.discardConfirmKey,
          style: bodyStyle,
        ),
        CtGap.l,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CtNinePatchButton(
              key: LoadGameListDialog.discardCancelButtonKey,
              onPressed: _onDiscardCancel,
              child: Text(l10n.common_cancel),
            ),
            const SizedBox(width: CtSpacing.m),
            CtNinePatchButton(
              key: LoadGameListDialog.discardConfirmButtonKey,
              onPressed: _onDiscardConfirm,
              child: Text(l10n.loadGameList_load),
            ),
          ],
        ),
      ];
    }
    return const <Widget>[];
  }
}
