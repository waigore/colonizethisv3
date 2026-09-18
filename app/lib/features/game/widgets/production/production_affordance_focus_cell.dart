import 'package:flutter/material.dart';

/// Tappable Allocation affordance hit target (≥44 dp).
/// SPEC/ui/production-panel.md § Affordance → Development (Refs #4725)
/// and § Affordance → Labour Controls (Refs #4780).
class ProductionAffordanceFocusCell extends StatelessWidget {
  const ProductionAffordanceFocusCell({
    required this.child,
    required this.onTap,
    required this.tooltip,
    required this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
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
            alignment: Alignment.centerRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
