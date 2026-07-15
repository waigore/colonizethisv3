// Deal Book panel chrome + resolved styles for the World Market Trade screen.

part of 'trade_screen.dart';

/// Single ledger panel (one of `Your bids` / `Your offers`). Wraps the
/// rows in a [CtPanel] so the dark editorial-monocle surface matches the
/// sibling panels on this screen. Sections inside the panel:
///
/// * Title row (`titleMedium`, `--accent`).
/// * Filled section heading + rows (or in-panel empty placeholder).
/// * Unfilled section heading + rows (or in-panel empty placeholder).
/// * Totals row pinned by [totalsKey].
///
/// When **both** `filledRows.isEmpty` and `unfilledRows.isEmpty`, the
/// per-section headings collapse and a single empty-state line keyed
/// [emptyKey] is rendered. The totals row remains mounted regardless so
/// widget tests can pin the affordance.
class _DealBookPanel extends StatelessWidget {
  const _DealBookPanel({
    super.key,
    required this.panelTitle,
    required this.side,
    required this.filledRows,
    required this.unfilledRows,
    required this.totalsKey,
    required this.emptyKey,
    required this.totalsLabel,
    required this.totalsAmount,
    required this.emptyText,
  });

  final String panelTitle;
  final String side;
  final List<FilledDeal> filledRows;
  final List<TradeOrder> unfilledRows;
  final Key totalsKey;
  final Key emptyKey;
  final String totalsLabel;
  final int totalsAmount;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final _DealBookPanelStyles styles = _DealBookPanelStyles.of(context);
    final bool panelEmpty = filledRows.isEmpty && unfilledRows.isEmpty;
    return CtPanel(
      padding: const EdgeInsets.all(CtSpacing.ml),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(panelTitle, style: styles.title),
          const SizedBox(height: 8),
          if (panelEmpty)
            Text(emptyText, key: emptyKey, style: styles.muted)
          else
            ..._buildSections(styles),
          const SizedBox(height: 12),
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            '$totalsLabel: $totalsAmount',
            key: totalsKey,
            style: styles.totals,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections(_DealBookPanelStyles styles) {
    return <Widget>[
      Text(TradeScreenDealBookKeys.dealBookFilledHeading, style: styles.sectionHeading),
      const SizedBox(height: 4),
      ..._buildFilledRows(styles),
      const SizedBox(height: 8),
      Text(TradeScreenDealBookKeys.dealBookUnfilledHeading, style: styles.sectionHeading),
      const SizedBox(height: 4),
      ..._buildUnfilledRows(styles),
    ];
  }

  List<Widget> _buildFilledRows(_DealBookPanelStyles styles) {
    if (filledRows.isEmpty) {
      return <Widget>[
        Text(TradeScreenDealBookKeys.dealBookFilledEmptyText, style: styles.muted),
      ];
    }
    return <Widget>[
      for (int i = 0; i < filledRows.length; i++)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
          child: _DealBookFilledRow(
            rowKey: TradeScreenDealBookKeys.dealBookFilledRowKey(side, i),
            deal: filledRows[i],
            rowStyle: styles.body,
            tagStyle: styles.muted,
          ),
        ),
    ];
  }

  List<Widget> _buildUnfilledRows(_DealBookPanelStyles styles) {
    if (unfilledRows.isEmpty) {
      return <Widget>[
        Text(TradeScreenDealBookKeys.dealBookUnfilledEmptyText, style: styles.muted),
      ];
    }
    return <Widget>[
      for (int i = 0; i < unfilledRows.length; i++)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
          child: _DealBookUnfilledRow(
            rowKey: TradeScreenDealBookKeys.dealBookUnfilledRowKey(side, i),
            order: unfilledRows[i],
            rowStyle: styles.body,
          ),
        ),
    ];
  }
}

/// Resolved per-panel text styles, isolated as a value object so the
/// [_DealBookPanel] build path stays under the 60-line cap.
class _DealBookPanelStyles {
  const _DealBookPanelStyles({
    required this.title,
    required this.sectionHeading,
    required this.body,
    required this.muted,
    required this.totals,
  });

  factory _DealBookPanelStyles.of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return _DealBookPanelStyles(
      title: (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
          .copyWith(color: EditorialMonoclePalette.accent),
      sectionHeading:
          (theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12))
              .copyWith(color: EditorialMonoclePalette.accentDim),
      body: (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
          .copyWith(color: EditorialMonoclePalette.fg),
      muted: (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
          .copyWith(color: EditorialMonoclePalette.muted),
      totals: (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
          .copyWith(color: EditorialMonoclePalette.accentBright),
    );
  }

  final TextStyle title;
  final TextStyle sectionHeading;
  final TextStyle body;
  final TextStyle muted;
  final TextStyle totals;
}
