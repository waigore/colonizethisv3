// Expandable Deal Book leftover rows (Refs #4500).

library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/commodity_display_name.dart';
import 'trade_screen_contract_deal_book.dart';
import 'trade_screen_deal_book_reasons.dart';

/// Still open leftover row with optional reason and on-request detail.
class DealBookStillOpenRow extends StatefulWidget {
  const DealBookStillOpenRow({
    super.key,
    required this.rowKey,
    required this.rowData,
    required this.rowStyle,
    required this.mutedStyle,
  });

  final Key rowKey;
  final DealBookStillOpenRowData rowData;
  final TextStyle rowStyle;
  final TextStyle mutedStyle;

  @override
  State<DealBookStillOpenRow> createState() => _DealBookStillOpenRowState();
}

class _DealBookStillOpenRowState extends State<DealBookStillOpenRow> {
  bool _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = appL10n(context);
    final DealBookStillOpenRowData rowData = widget.rowData;
    final String name = commodityDisplayName(l10n, rowData.order.commodityId);
    final String mainLine = l10n.tradeDealBook_unfilledRow(
      name,
      rowData.order.quantity,
    );
    final String? reasonLine = _reasonLine(l10n, rowData.reasonKind);
    final String? detailLine = _detailLine(l10n, rowData.reasonKind);
    final bool hasDetails = detailLine != null;

    return Column(
      key: widget.rowKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          onTap: hasDetails ? _toggleDetails : null,
          onLongPress: hasDetails ? _toggleDetails : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(mainLine, style: widget.rowStyle),
              if (reasonLine != null)
                Text(
                  reasonLine,
                  key: TradeScreenDealBookKeys.dealBookUnfilledReasonKey(
                    rowData.order.commodityId,
                  ),
                  style: widget.mutedStyle,
                ),
              if (hasDetails && !_detailsExpanded)
                Text(
                  l10n.tradeDealBook_detailsAffordance,
                  key: TradeScreenDealBookKeys.dealBookDetailsAffordanceKey(
                    TradeScreenDealBookKeys.dealBookRowKindStillOpen,
                    rowData.order.commodityId,
                  ),
                  style: widget.mutedStyle,
                ),
            ],
          ),
        ),
        if (_detailsExpanded && detailLine != null)
          Text(
            detailLine,
            key: TradeScreenDealBookKeys.dealBookDetailsExpandedKey(
              TradeScreenDealBookKeys.dealBookRowKindStillOpen,
              rowData.order.commodityId,
            ),
            style: widget.mutedStyle,
          ),
      ],
    );
  }

  void _toggleDetails() {
    setState(() => _detailsExpanded = !_detailsExpanded);
  }

  String? _reasonLine(
    AppLocalizations l10n,
    DealBookStillOpenReasonKind? kind,
  ) {
    return switch (kind) {
      DealBookStillOpenReasonKind.treasuryInsufficient =>
        l10n.tradeDealBook_reasonTreasuryShort,
      DealBookStillOpenReasonKind.noMatchingSales =>
        l10n.tradeDealBook_reasonNoMatchingSales,
      DealBookStillOpenReasonKind.noMatchingBuys =>
        l10n.tradeDealBook_reasonNoMatchingBuys,
      null => null,
    };
  }

  String? _detailLine(
    AppLocalizations l10n,
    DealBookStillOpenReasonKind? kind,
  ) {
    return switch (kind) {
      DealBookStillOpenReasonKind.treasuryInsufficient =>
        l10n.tradeDealBook_detailFreeTreasury,
      DealBookStillOpenReasonKind.noMatchingSales =>
        l10n.tradeDealBook_detailNoMatchingSales,
      DealBookStillOpenReasonKind.noMatchingBuys =>
        l10n.tradeDealBook_detailNoMatchingBuys,
      null => null,
    };
  }
}

/// Did not stay open row for a dropped carry-forward.
class DealBookDidNotStayOpenRow extends StatefulWidget {
  const DealBookDidNotStayOpenRow({
    super.key,
    required this.rowKey,
    required this.rowData,
    required this.rowStyle,
    required this.mutedStyle,
  });

  final Key rowKey;
  final DealBookDidNotStayOpenRowData rowData;
  final TextStyle rowStyle;
  final TextStyle mutedStyle;

  @override
  State<DealBookDidNotStayOpenRow> createState() =>
      _DealBookDidNotStayOpenRowState();
}

class _DealBookDidNotStayOpenRowState extends State<DealBookDidNotStayOpenRow> {
  bool _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = appL10n(context);
    final DealBookDidNotStayOpenRowData rowData = widget.rowData;
    final String name = commodityDisplayName(l10n, rowData.commodityId);
    final String mainLine = switch (rowData.reasonKind) {
      DealBookDropReasonKind.cargoInsufficient =>
        l10n.tradeDealBook_droppedBidRow(name, rowData.quantity),
      DealBookDropReasonKind.stockpileInsufficient =>
        l10n.tradeDealBook_droppedOfferRow(name, rowData.quantity),
    };
    final String detailLine = switch (rowData.reasonKind) {
      DealBookDropReasonKind.cargoInsufficient =>
        l10n.tradeDealBook_detailAddCargo,
      DealBookDropReasonKind.stockpileInsufficient =>
        l10n.tradeDealBook_detailKeepStock,
    };

    return Column(
      key: widget.rowKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          onTap: _toggleDetails,
          onLongPress: _toggleDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(mainLine, style: widget.rowStyle),
              if (!_detailsExpanded)
                Text(
                  l10n.tradeDealBook_detailsAffordance,
                  key: TradeScreenDealBookKeys.dealBookDetailsAffordanceKey(
                    TradeScreenDealBookKeys.dealBookRowKindDidNotStayOpen,
                    rowData.commodityId,
                  ),
                  style: widget.mutedStyle,
                ),
            ],
          ),
        ),
        if (_detailsExpanded)
          Text(
            detailLine,
            key: TradeScreenDealBookKeys.dealBookDetailsExpandedKey(
              TradeScreenDealBookKeys.dealBookRowKindDidNotStayOpen,
              rowData.commodityId,
            ),
            style: widget.mutedStyle,
          ),
      ],
    );
  }

  void _toggleDetails() {
    setState(() => _detailsExpanded = !_detailsExpanded);
  }
}
