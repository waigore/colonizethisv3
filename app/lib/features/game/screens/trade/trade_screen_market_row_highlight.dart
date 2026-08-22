import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

/// Counsel-star highlight chrome plus first-frame scroll for Production inbound.
///
/// SPEC/ui/trade-screen.md `highlightCommodityId` (Refs #4581).
class MarketCommodityRowHighlight extends StatefulWidget {
  const MarketCommodityRowHighlight({
    required this.commodityId,
    required this.highlighted,
    required this.child,
    super.key,
  });

  final CommodityId commodityId;
  final bool highlighted;
  final Widget child;

  static Key highlightKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRowHighlight:$commodityId');

  @override
  State<MarketCommodityRowHighlight> createState() =>
      _MarketCommodityRowHighlightState();
}

class _MarketCommodityRowHighlightState
    extends State<MarketCommodityRowHighlight> {
  @override
  void initState() {
    super.initState();
    if (!widget.highlighted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.15,
        duration: Duration.zero,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.highlighted) return widget.child;
    return DecoratedBox(
      key: MarketCommodityRowHighlight.highlightKey(widget.commodityId),
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.accentDim.withValues(alpha: 0.2),
        border: Border.all(
          color: EditorialMonoclePalette.accentBright,
          width: 2,
        ),
      ),
      child: widget.child,
    );
  }
}
