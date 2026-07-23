part of 'load_game_list_dialog.dart';

extension _LoadGameListDialogBody on _LoadGameListDialogState {
  List<Widget> _listAndPagerChildren({
    required AppLocalizations l10n,
    required TextStyle bodyStyle,
    required TextStyle mutedStyle,
    required List<LoadableSaveEntry> entries,
    required LoadableSaveEntry? autoSave,
    required List<LoadableSaveEntry> pageManuals,
    required bool showPager,
    required int pageIndex,
    required int pageCount,
  }) {
    return [
      if (entries.isEmpty)
        Text(
          l10n.loadGameList_empty,
          key: LoadGameListDialog.emptyStateKey,
          style: mutedStyle,
        )
      else
        ConstrainedBox(
          key: LoadGameListDialog.listKey,
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView(
            shrinkWrap: true,
            children: [
              if (autoSave != null) ...[
                Container(
                  key: LoadGameListDialog.autoSaveSectionKey,
                  padding: const EdgeInsets.all(CtSpacing.s),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: EditorialMonoclePalette.accent,
                      width: 2,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        EditorialMonoclePalette.surfaceLite,
                        EditorialMonoclePalette.surface,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.loadGameList_autoSaveBadge,
                        style: mutedStyle.copyWith(
                          color: EditorialMonoclePalette.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: CtSpacing.s),
                      _rowContent(
                        l10n: l10n,
                        bodyStyle: bodyStyle,
                        mutedStyle: mutedStyle,
                        entry: autoSave,
                      ),
                    ],
                  ),
                ),
                if (pageManuals.isNotEmpty) ...[
                  CtGap.m,
                  const CtBrassDivider(),
                  CtGap.m,
                ],
              ],
              for (var i = 0; i < pageManuals.length; i++) ...[
                if (i > 0) CtGap.m,
                _rowContent(
                  l10n: l10n,
                  bodyStyle: bodyStyle,
                  mutedStyle: mutedStyle,
                  entry: pageManuals[i],
                ),
              ],
            ],
          ),
        ),
      if (showPager) ...[
        CtGap.m,
        Row(
          key: LoadGameListDialog.pagerKey,
          children: [
            CtNinePatchButton(
              key: LoadGameListDialog.previousButtonKey,
              onPressed: pageIndex <= 0
                  ? null
                  : () => setState(() => _manualPageIndex = pageIndex - 1),
              child: Text(l10n.loadGameList_previous),
            ),
            Expanded(
              child: Text(
                l10n.loadGameList_pageOf(pageIndex + 1, pageCount),
                key: LoadGameListDialog.pageLabelKey,
                textAlign: TextAlign.center,
                style: mutedStyle,
              ),
            ),
            CtNinePatchButton(
              key: LoadGameListDialog.nextButtonKey,
              onPressed: pageIndex >= pageCount - 1
                  ? null
                  : () => setState(() => _manualPageIndex = pageIndex + 1),
              child: Text(l10n.loadGameList_next),
            ),
          ],
        ),
      ],
      CtGap.l,
      Align(
        alignment: Alignment.centerRight,
        child: CtNinePatchButton(
          key: LoadGameListDialog.closeButtonKey,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_close),
        ),
      ),
    ];
  }
}
