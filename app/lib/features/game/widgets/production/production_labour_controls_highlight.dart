import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

/// Inbound highlight chrome + scroll-into-view for Labour Controls.
/// SPEC/ui/production-panel.md § Affordance → Labour Controls (Refs #4780).
class ProductionLabourControlsHighlight extends StatefulWidget {
  const ProductionLabourControlsHighlight({
    required this.focusToken,
    required this.child,
    super.key,
  });

  /// Increments on each labour-limited affordance tap. `0` means no highlight.
  final int focusToken;
  final Widget child;

  static const Key highlightKey = ValueKey<String>(
    'production_labour_controls_highlight',
  );

  @override
  State<ProductionLabourControlsHighlight> createState() =>
      _ProductionLabourControlsHighlightState();
}

class _ProductionLabourControlsHighlightState
    extends State<ProductionLabourControlsHighlight> {
  @override
  void initState() {
    super.initState();
    _ensureVisibleIfFocused();
  }

  @override
  void didUpdateWidget(ProductionLabourControlsHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusToken > 0 && widget.focusToken != oldWidget.focusToken) {
      _ensureVisibleIfFocused();
    }
  }

  void _ensureVisibleIfFocused() {
    if (widget.focusToken <= 0) return;
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
    if (widget.focusToken <= 0) return widget.child;
    return DecoratedBox(
      key: ProductionLabourControlsHighlight.highlightKey,
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
