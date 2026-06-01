// Deal Book tab body for the World Market Trade screen
// (Refs #2993 E6, split out from `trade_screen.dart` to keep the
// host file under the repo-lint non-comment line limit per
// `SPEC/program/dart-file-non-comment-line-size.md`).
//
// All classes here are library-private (`_DealBook*`) and consumed
// only by `_TradeScreenTabsBody` inside the parent library.

part of 'trade_screen.dart';

/// Live Deal Book tab body (Refs #2993 E6). Renders the player's
/// previous-turn buying and selling activity in a two-panel ledger
/// sourced from `Game.worldMarketState.lastTurnActivity[*].deals`
/// (filtered by `buyerFactionId` / `sellerFactionId`) and
/// `carryForward{Bids,Offers}ByFactionId[playerId]`.
///
/// Layout collapses to a single stacked column below
/// `TradeScreen.dealBookTwoPanelMinWidth` so the 320 dp minimum viewport
/// stays overflow-safe (`SPEC/ui/mobile-adaptation.md` § 7). On wider
/// viewports the bids panel sits left of the offers panel inside a
/// `Row`.
class _DealBookTabContent extends StatelessWidget {
  const _DealBookTabContent({
    super.key,
    required this.game,
    required this.playerId,
  });

  final Game game;
  final String playerId;

  @override
  Widget build(BuildContext context) {
    final _DealBookViewData data = _DealBookViewData.build(
      worldMarket: game.worldMarketState,
      playerId: playerId,
    );
    return Container(
      key: TradeScreen.dealBookContentKey,
      alignment: Alignment.topLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool wide =
              constraints.maxWidth >= TradeScreen.dealBookTwoPanelMinWidth;
          return _layoutPanels(
            bidsPanel: _buildBidsPanel(data),
            offersPanel: _buildOffersPanel(data),
            wide: wide,
          );
        },
      ),
    );
  }

  _DealBookPanel _buildBidsPanel(_DealBookViewData data) {
    return _DealBookPanel(
      key: TradeScreen.dealBookBidsPanelKey,
      panelTitle: TradeScreen.dealBookBidsPanelTitle,
      side: TradeScreen.dealBookSideBids,
      filledRows: data.filledBids,
      unfilledRows: data.unfilledBids,
      totalsKey: TradeScreen.dealBookBidsTotalsKey,
      emptyKey: TradeScreen.dealBookBidsEmptyKey,
      totalsLabel: TradeScreen.dealBookTotalSpentLabel,
      totalsAmount: data.totalSpent,
      emptyText: TradeScreen.dealBookBidsEmptyText,
    );
  }

  _DealBookPanel _buildOffersPanel(_DealBookViewData data) {
    return _DealBookPanel(
      key: TradeScreen.dealBookOffersPanelKey,
      panelTitle: TradeScreen.dealBookOffersPanelTitle,
      side: TradeScreen.dealBookSideOffers,
      filledRows: data.filledOffers,
      unfilledRows: data.unfilledOffers,
      totalsKey: TradeScreen.dealBookOffersTotalsKey,
      emptyKey: TradeScreen.dealBookOffersEmptyKey,
      totalsLabel: TradeScreen.dealBookTotalReceivedLabel,
      totalsAmount: data.totalReceived,
      emptyText: TradeScreen.dealBookOffersEmptyText,
    );
  }

  Widget _layoutPanels({
    required Widget bidsPanel,
    required Widget offersPanel,
    required bool wide,
  }) {
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: bidsPanel),
          const SizedBox(width: 12),
          Expanded(child: offersPanel),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        bidsPanel,
        const SizedBox(height: 12),
        offersPanel,
      ],
    );
  }
}

/// Pure value object built from `WorldMarketState` for the player's
/// Deal Book view. Holds the four per-side row lists (filled / unfilled
/// for bids and offers) and the two treasury totals. Pulled out so the
/// rendering widget tree stays declarative and unit-testable.
class _DealBookViewData {
  const _DealBookViewData({
    required this.filledBids,
    required this.filledOffers,
    required this.unfilledBids,
    required this.unfilledOffers,
    required this.totalSpent,
    required this.totalReceived,
  });

  factory _DealBookViewData.build({
    required WorldMarketState worldMarket,
    required String playerId,
  }) {
    final List<FilledDeal> bids = <FilledDeal>[];
    final List<FilledDeal> offers = <FilledDeal>[];
    for (final MarketActivity activity in worldMarket.lastTurnActivity.values) {
      for (final FilledDeal deal in activity.deals) {
        if (deal.buyerFactionId == playerId) bids.add(deal);
        if (deal.sellerFactionId == playerId) offers.add(deal);
      }
    }
    int spent = 0;
    for (final FilledDeal deal in bids) {
      spent += (deal.quantity * deal.pricePerUnit).round();
    }
    int received = 0;
    for (final FilledDeal deal in offers) {
      received += (deal.quantity * deal.pricePerUnit).round();
    }
    return _DealBookViewData(
      filledBids: List<FilledDeal>.unmodifiable(bids),
      filledOffers: List<FilledDeal>.unmodifiable(offers),
      unfilledBids:
          worldMarket.carryForwardBidsByFactionId[playerId] ??
              const <TradeOrder>[],
      unfilledOffers:
          worldMarket.carryForwardOffersByFactionId[playerId] ??
              const <TradeOrder>[],
      totalSpent: spent,
      totalReceived: received,
    );
  }

  final List<FilledDeal> filledBids;
  final List<FilledDeal> filledOffers;
  final List<TradeOrder> unfilledBids;
  final List<TradeOrder> unfilledOffers;
  final int totalSpent;
  final int totalReceived;
}

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
      padding: const EdgeInsets.all(12),
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
      Text(TradeScreen.dealBookFilledHeading, style: styles.sectionHeading),
      const SizedBox(height: 4),
      ..._buildFilledRows(styles),
      const SizedBox(height: 8),
      Text(TradeScreen.dealBookUnfilledHeading, style: styles.sectionHeading),
      const SizedBox(height: 4),
      ..._buildUnfilledRows(styles),
    ];
  }

  List<Widget> _buildFilledRows(_DealBookPanelStyles styles) {
    if (filledRows.isEmpty) {
      return <Widget>[
        Text(TradeScreen.dealBookFilledEmptyText, style: styles.muted),
      ];
    }
    return <Widget>[
      for (int i = 0; i < filledRows.length; i++)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
          child: _DealBookFilledRow(
            rowKey: TradeScreen.dealBookFilledRowKey(side, i),
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
        Text(TradeScreen.dealBookUnfilledEmptyText, style: styles.muted),
      ];
    }
    return <Widget>[
      for (int i = 0; i < unfilledRows.length; i++)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
          child: _DealBookUnfilledRow(
            rowKey: TradeScreen.dealBookUnfilledRowKey(side, i),
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

/// Single filled-deal row inside a Deal Book panel. Lays out
/// `commodity — qty × price = notional` with optional FRR / FTP tags so
/// the player can audit how the deal cleared per
/// `SPEC/game/world-market.md` § Matching + § First Right of Refusal.
class _DealBookFilledRow extends StatelessWidget {
  const _DealBookFilledRow({
    required this.rowKey,
    required this.deal,
    required this.rowStyle,
    required this.tagStyle,
  });

  final Key rowKey;
  final FilledDeal deal;
  final TextStyle rowStyle;
  final TextStyle tagStyle;

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String _frrTag = 'FRR';
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String _ftpTag = 'FTP';

  @override
  Widget build(BuildContext context) {
    final int notional = (deal.quantity * deal.pricePerUnit).round();
    final String priceText = deal.pricePerUnit.toStringAsFixed(1);
    final List<String> tags = <String>[
      if (deal.isFirstRightOfRefusalMatch) _frrTag,
      if (deal.isFtpMatch) _ftpTag,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      key: rowKey,
      children: <Widget>[
        Expanded(
          child: Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            '${deal.commodityId} — qty ${deal.quantity} × $priceText '
            '= $notional',
            style: rowStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (tags.isNotEmpty) ...<Widget>[
          const SizedBox(width: 6),
          Text(
            // ignore: avoid_hardcoded_strings_in_widgets
            tags.join(' '),
            style: tagStyle,
          ),
        ],
      ],
    );
  }
}

/// Single carry-forward order row inside a Deal Book panel. The order
/// has not cleared yet so there is no per-unit price or notional —
/// `commodity — qty N (priority P)` is the canonical readout.
class _DealBookUnfilledRow extends StatelessWidget {
  const _DealBookUnfilledRow({
    required this.rowKey,
    required this.order,
    required this.rowStyle,
  });

  final Key rowKey;
  final TradeOrder order;
  final TextStyle rowStyle;

  @override
  Widget build(BuildContext context) {
    return Text(
      // ignore: avoid_hardcoded_strings_in_widgets
      '${order.commodityId} — qty ${order.quantity} '
      '(priority ${order.priority})',
      key: rowKey,
      style: rowStyle,
      overflow: TextOverflow.ellipsis,
    );
  }
}
