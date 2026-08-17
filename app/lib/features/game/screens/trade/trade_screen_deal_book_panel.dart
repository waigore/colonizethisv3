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
/// When **both** `filledRows.isEmpty` and `unfilledRows.isEmpty`, the
/// per-section headings collapse and a single empty-state line keyed
/// [emptyKey] is rendered. The totals row remains mounted regardless so
/// widget tests can pin the affordance.
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/commodity_display_name.dart';
import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/ct_spacing.dart';
import 'trade_screen_contract_deal_book.dart';
import 'trade_screen_deal_book_leftover_row.dart';
import 'trade_screen_deal_book_reasons.dart';

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
    final bool panelEmpty = filledRows.isEmpty &&
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

/// Resolved per-panel text styles, isolated as a value object so the
/// [DealBookPanel] build path stays under the 60-line cap.
class DealBookPanelStyles {
  const DealBookPanelStyles({
    required this.title,
    required this.sectionHeading,
    required this.body,
    required this.muted,
    required this.totals,
  });

  factory DealBookPanelStyles.of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DealBookPanelStyles(
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
/// `{displayName} — qty at £price = £notional` with optional FRR / FTP
/// tags so the player can audit how the deal cleared per
/// `SPEC/game/world-market.md` § Matching + § First Right of Refusal.
class DealBookFilledRow extends StatelessWidget {
  const DealBookFilledRow({
    super.key,
    required this.rowKey,
    required this.deal,
    required this.rowStyle,
    required this.tagStyle,
    required this.matchTagFirstRight,
    required this.matchTagFavoredPartner,
  });

  final Key rowKey;
  final FilledDeal deal;
  final TextStyle rowStyle;
  final TextStyle tagStyle;
  final String matchTagFirstRight;
  final String matchTagFavoredPartner;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = appL10n(context);
    final int unitPrice = deal.pricePerUnit.floor();
    final int notional = deal.quantity * unitPrice;
    final String name = commodityDisplayName(l10n, deal.commodityId);
    final List<String> tags = <String>[
      if (deal.isFirstRightOfRefusalMatch) matchTagFirstRight,
      if (deal.isFtpMatch) matchTagFavoredPartner,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      key: rowKey,
      children: <Widget>[
        Expanded(
          child: Text(
            l10n.tradeDealBook_filledRow(
              name,
              deal.quantity,
              unitPrice,
              notional,
            ),
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

