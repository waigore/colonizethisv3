// Deal Book panel chrome + resolved styles for the World Market Trade screen.

/// Single ledger panel (one of `Your bids` / `Your offers`). Wraps the
/// rows in a [CtPanel] so the dark editorial-monocle surface matches the
/// sibling panels on this screen. Sections inside the panel:
///
/// * Title row (`titleMedium`, `--accent`).
/// * Filled section heading + rows (or in-panel empty placeholder).
/// * Unfilled section heading + rows (or in-panel empty placeholder).
/// * Totals row pinned by [totalsKey].
///
/// When **filledRows**, **stillOpenRows**, and **didNotStayOpenRows**
/// are all empty, the per-section headings collapse and a single
/// empty-state line keyed [emptyKey] is rendered. The totals row remains
/// mounted regardless so widget tests can pin the affordance.
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/ct_spacing.dart';
import 'trade_screen_contract_deal_book.dart';
import 'trade_screen_deal_book_leftover_row.dart';
import 'trade_screen_deal_book_panel_rows.dart';
import 'trade_screen_deal_book_reasons.dart';

export 'trade_screen_deal_book_panel_rows.dart';

class DealBookPanel extends StatelessWidget {
  const DealBookPanel({
    super.key,
    required this.panelTitle,
    required this.side,
    required this.filledRows,
    required this.stillOpenRows,
    required this.didNotStayOpenRows,
    required this.totalsKey,
    required this.emptyKey,
    required this.totalsLabel,
    required this.totalsAmount,
    required this.emptyText,
    required this.matchTagFirstRight,
    required this.matchTagFavoredPartner,
  });

  final String panelTitle;
  final String side;
  final List<FilledDeal> filledRows;
  final List<DealBookStillOpenRowData> stillOpenRows;
  final List<DealBookDidNotStayOpenRowData> didNotStayOpenRows;
  final Key totalsKey;
  final Key emptyKey;
  final String totalsLabel;
  final int totalsAmount;
  final String emptyText;
  final String matchTagFirstRight;
  final String matchTagFavoredPartner;

  @override
  Widget build(BuildContext context) {
    final DealBookPanelStyles styles = DealBookPanelStyles.of(context);
    final AppLocalizations l10n = appL10n(context);
    final bool panelEmpty =
        filledRows.isEmpty &&
        stillOpenRows.isEmpty &&
        didNotStayOpenRows.isEmpty;
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
            ..._buildSections(styles, l10n),
          const SizedBox(height: 12),
          Text(
            l10n.tradeDealBook_totalsLine(totalsLabel, totalsAmount),
            key: totalsKey,
            style: styles.totals,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections(
    DealBookPanelStyles styles,
    AppLocalizations l10n,
  ) {
    return <Widget>[
      Text(
        TradeScreenDealBookKeys.dealBookFilledHeading,
        style: styles.sectionHeading,
      ),
      const SizedBox(height: 4),
      ..._buildFilledRows(styles),
      const SizedBox(height: 8),
      Text(l10n.tradeDealBook_unfilledHeading, style: styles.sectionHeading),
      const SizedBox(height: 4),
      ..._buildStillOpenRows(styles, l10n),
      if (didNotStayOpenRows.isNotEmpty) ...<Widget>[
        const SizedBox(height: 8),
        Text(
          l10n.tradeDealBook_didNotStayOpenHeading,
          style: styles.sectionHeading,
        ),
        const SizedBox(height: 4),
        ..._buildDidNotStayOpenRows(styles),
      ],
    ];
  }

  List<Widget> _buildFilledRows(DealBookPanelStyles styles) {
    if (filledRows.isEmpty) {
      return <Widget>[
        Text(
          TradeScreenDealBookKeys.dealBookFilledEmptyText,
          style: styles.muted,
        ),
      ];
    }
    return <Widget>[
      for (int i = 0; i < filledRows.length; i++)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
          child: DealBookFilledRow(
            rowKey: TradeScreenDealBookKeys.dealBookFilledRowKey(side, i),
            deal: filledRows[i],
            rowStyle: styles.body,
            tagStyle: styles.muted,
            matchTagFirstRight: matchTagFirstRight,
            matchTagFavoredPartner: matchTagFavoredPartner,
          ),
        ),
    ];
  }

  List<Widget> _buildStillOpenRows(
    DealBookPanelStyles styles,
    AppLocalizations l10n,
  ) {
    if (stillOpenRows.isEmpty) {
      return <Widget>[
        Text(l10n.tradeDealBook_unfilledEmpty, style: styles.muted),
      ];
    }
    return <Widget>[
      for (int i = 0; i < stillOpenRows.length; i++)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
          child: DealBookStillOpenRow(
            rowKey: TradeScreenDealBookKeys.dealBookUnfilledRowKey(side, i),
            rowData: stillOpenRows[i],
            rowStyle: styles.body,
            mutedStyle: styles.muted,
          ),
        ),
    ];
  }

  List<Widget> _buildDidNotStayOpenRows(DealBookPanelStyles styles) {
    return <Widget>[
      for (int i = 0; i < didNotStayOpenRows.length; i++)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
          child: DealBookDidNotStayOpenRow(
            rowKey: TradeScreenDealBookKeys.dealBookDidNotStayOpenRowKey(
              side,
              i,
            ),
            rowData: didNotStayOpenRows[i],
            rowStyle: styles.body,
            mutedStyle: styles.muted,
          ),
        ),
    ];
  }
}
