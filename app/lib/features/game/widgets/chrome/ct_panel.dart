import 'package:colonizethis_app/package_logger.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';

/// Pixel-art panel using the same nine-patch as buttons/dialogs.
/// Replace [Card] with this for framed content sections.
class CtPanel extends StatelessWidget {
  const CtPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.destTileSize = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double destTileSize;

  /// Filename only; Flame.images uses prefix 'assets/images/' so full key is assets/images/ui_button_nine_patch.png.
  static const String _kAssetPath = 'ui_button_nine_patch.png';
  static const double _tileSize = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallbackColor = theme.colorScheme.surface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : null;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : null;
        return NineTileBoxWidget.asset(
          path: _kAssetPath,
          tileSize: _tileSize,
          destTileSize: destTileSize,
          width: width,
          height: height,
          padding: padding,
          child: child,
          loadingBuilder: (_) => _FallbackPanel(
            color: fallbackColor,
            padding: padding,
            child: child,
          ),
          errorBuilder: (_) {
            packageLogger(
              'ui',
            ).w('panel nine-patch asset not found, using fallback');
            return _FallbackPanel(
              color: fallbackColor,
              padding: padding,
              child: child,
            );
          },
        );
      },
    );
  }
}

class _FallbackPanel extends StatelessWidget {
  const _FallbackPanel({
    required this.color,
    required this.padding,
    required this.child,
  });

  final Color color;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black87, width: 2),
      ),
      child: child,
    );
  }
}
