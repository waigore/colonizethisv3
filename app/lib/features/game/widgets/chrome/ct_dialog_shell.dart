import 'package:colonizethis_app/package_logger.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';

/// Pixel-art dialog shell using a nine-patch frame. SPEC/ui/buttons-nine-patch.md (reuse canon).
///
/// Wraps arbitrary [child] content inside a constrained, centered dialog with
/// a transparent backdrop and nine-patch chrome. Use this instead of
/// [AlertDialog] or [Dialog] for all app dialogs.
///
/// **Layout:** The frame height follows content up to [maxHeight]. When content
/// exceeds [maxHeight], a single outer vertical scroll reaches the full body
/// (see SPEC/ui/pixel-art-ui-catalog.md). Avoid [Expanded] / vertical [Flexible]
/// in [child]; use [mainAxisSize]: [MainAxisSize.min] columns and let this shell
/// scroll.
class CtDialogShell extends StatelessWidget {
  const CtDialogShell({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.maxHeight = 600,
    this.destTileSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  });

  /// Dialog body content (title, text, actions column/rows).
  final Widget child;

  /// Maximum width of the dialog content area.
  final double maxWidth;

  /// Maximum height of the dialog content area.
  final double maxHeight;

  /// Rendered size of each tile edge (Flame destTileSize).
  final double destTileSize;

  /// Inner padding between nine-patch frame and [child].
  final EdgeInsetsGeometry padding;

  /// Filename only; Flame.images uses prefix 'assets/images/' so full key is assets/images/ui_button_nine_patch.png.
  static const String _kAssetPath = 'ui_button_nine_patch.png';
  static const double _tileSize = 16;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fallbackColor = theme.colorScheme.surface;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              return CustomScrollView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: NineTileBoxWidget.asset(
                      path: _kAssetPath,
                      tileSize: _tileSize,
                      destTileSize: destTileSize,
                      width: width,
                      height: null,
                      padding: padding,
                      child: DefaultTextStyle(
                        style:
                            theme.textTheme.bodyMedium ??
                            const TextStyle(color: Colors.white),
                        child: child,
                      ),
                      loadingBuilder: (_) => _FallbackDialogFrame(
                        color: fallbackColor,
                        padding: padding,
                        child: child,
                      ),
                      errorBuilder: (_) {
                        packageLogger('ui').w(
                          'dialog nine-patch asset not found, using fallback frame',
                        );
                        return _FallbackDialogFrame(
                          color: fallbackColor,
                          padding: padding,
                          child: child,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FallbackDialogFrame extends StatelessWidget {
  const _FallbackDialogFrame({
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
