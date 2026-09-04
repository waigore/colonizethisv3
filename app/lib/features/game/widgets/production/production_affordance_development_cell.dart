import 'package:flutter/material.dart';

/// Tappable Allocation affordance hit target (≥44 dp) for Development deep-link.
/// SPEC/ui/production-panel.md § Affordance → Development (Refs #4725).
class ProductionAffordanceDevelopmentCell extends StatelessWidget {
  const ProductionAffordanceDevelopmentCell({
    required this.child,
    required this.onOpenDevelopment,
    required this.tooltip,
    required this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback onOpenDevelopment;
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
              onTap: onOpenDevelopment,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
