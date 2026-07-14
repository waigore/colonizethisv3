part of 'load_game_list_dialog.dart';

extension on _LoadGameListDialogState {
  String? _secondaryMetaLine(AppLocalizations l10n, LoadableSaveEntry entry) {
    final turn = entry.turnNumber;
    final year = entry.calendarYear;
    final nation = entry.humanNation;
    if (turn != null && year != null && nation != null && nation.isNotEmpty) {
      return l10n.loadGameList_metaLine(turn, year, nation);
    }
    return turn == null ? null : l10n.loadGameList_turnSubtitle(turn);
  }

  String? _lastSavedLine(LoadableSaveEntry entry) {
    final at = entry.lastSavedAt;
    return at == null ? null : DateFormat.yMd().add_jm().format(at.toLocal());
  }

  Widget _rowContent({
    required AppLocalizations l10n,
    required TextStyle bodyStyle,
    required TextStyle mutedStyle,
    required LoadableSaveEntry entry,
  }) {
    final meta = _secondaryMetaLine(l10n, entry);
    final savedAt = _lastSavedLine(entry);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CtNinePatchButton(
            key: LoadGameListDialog.rowKey(entry.storageId),
            onPressed: () => _onSelect(entry),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.label, style: bodyStyle),
                if (meta != null)
                  Text(
                    meta,
                    key: LoadGameListDialog.rowMetaKey(entry.storageId),
                    style: mutedStyle,
                  ),
                if (savedAt != null)
                  Text(
                    savedAt,
                    key: LoadGameListDialog.rowSavedAtKey(entry.storageId),
                    style: mutedStyle,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: CtSpacing.s),
        CtNinePatchButton(
          key: LoadGameListDialog.deleteButtonKey(entry.storageId),
          onPressed: () => _onDeleteRequest(entry),
          child: Text(l10n.loadGameList_delete),
        ),
      ],
    );
  }
}
