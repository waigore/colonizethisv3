import 'package:flutter/material.dart';

class ProductionAvailableTradeCell extends StatelessWidget {
  const ProductionAvailableTradeCell({
    required this.cell,
    required this.onOpenTrade,
    required this.tooltip,
    required this.semanticLabel,
    super.key,
  });

  final Widget cell;
  final VoidCallback onOpenTrade;
  final String tooltip;
  final String semanticLabel;

  static const double minHitExtent = 44;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: minHitExtent,
            minHeight: minHitExtent,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpenTrade,
              child: cell,
            ),
          ),
        ),
      ),
    );
  }
}
