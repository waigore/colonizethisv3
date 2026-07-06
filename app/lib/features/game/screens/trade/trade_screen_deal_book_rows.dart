// Deal Book filled/unfilled row widgets for the World Market Trade screen.

part of 'trade_screen.dart';

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
    final int unitPrice = deal.pricePerUnit.floor();
    final int notional = deal.quantity * unitPrice;
    final String priceText = TradeScreen.formatFilledDealUnitPrice(
      deal.pricePerUnit,
    );
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
