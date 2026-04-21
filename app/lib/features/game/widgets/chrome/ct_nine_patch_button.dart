import 'package:colonizethis_app/package_logger.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';

/// Nine-patch button using Flame's [NineTileBoxWidget]. SPEC/ui/buttons-nine-patch.md.
///
/// Use for all app buttons that should scale with consistent corners/edges.
/// Minimum touch target 44 dp. When the asset is missing, falls back to a solid
/// theme primary background.
class CtNinePatchButton extends StatelessWidget {
  const CtNinePatchButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.enabled = true,
    this.padding,
    this.destTileSize = 16,
    this.minHeight = 48,
  });

  /// Callback when the button is tapped (only when [enabled] is true).
  final VoidCallback? onPressed;

  /// Button content (label, icon, or both).
  final Widget child;

  /// When false, button is not tappable and visually subdued.
  final bool enabled;

  /// Padding inside the nine-patch frame. Defaults to symmetric 16 horizontal, 12 vertical.
  final EdgeInsetsGeometry? padding;

  /// Rendered size of each tile edge (Flame destTileSize). Larger = chunkier corners/edges.
  final double destTileSize;

  /// Minimum height; respects 44 dp touch target.
  final double minHeight;

  /// Filename only; Flame.images uses prefix 'assets/images/' so full key is assets/images/ui_button_nine_patch.png.
  static const String _kAssetPath = 'ui_button_nine_patch.png';
  static const double _tileSize = 16;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fallbackColor = theme.colorScheme.primary;
    final Color foregroundColor = theme.colorScheme.onPrimary.withValues(
      alpha: enabled ? 1 : 0.5,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: NineTileBoxWidget.asset(
            path: _kAssetPath,
            tileSize: _tileSize,
            destTileSize: destTileSize,
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: DefaultTextStyle(
                style:
                    (theme.textTheme.titleSmall ??
                            theme.textTheme.bodyLarge ??
                            const TextStyle())
                        .copyWith(color: foregroundColor),
                child: IconTheme(
                  data: IconThemeData(color: foregroundColor, size: 20),
                  child: child,
                ),
              ),
            ),
            loadingBuilder: (_) => _FallbackButton(
              color: fallbackColor,
              padding:
                  padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: child,
            ),
            errorBuilder: (_) {
              packageLogger(
                'ui',
              ).w('nine-patch button asset not found, using fallback');
              return _FallbackButton(
                color: fallbackColor,
                padding:
                    padding ??
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Solid-colour fallback when nine-patch asset is missing. SPEC/ui/buttons-nine-patch.md.
class _FallbackButton extends StatelessWidget {
  const _FallbackButton({
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
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}
