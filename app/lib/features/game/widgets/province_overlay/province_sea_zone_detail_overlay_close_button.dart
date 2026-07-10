part of 'province_sea_zone_detail_overlay.dart';

/// Pixel-art close control (non-Material) keyed for tests as
/// [kOverlayCloseKey]. Border colour resolves to `--accent-dim` and the
/// `×` glyph paints in `--muted` per
/// SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme chrome.
class _OverlayCloseButton extends StatelessWidget {
  const _OverlayCloseButton({this.onClose});

  static const Key kOverlayCloseKey = Key('overlay_close');

  /// Width of the brass-toned border around the glyph (matches catalog 1 px).
  static const double _borderWidth = 1;

  /// Font size of the `×` glyph (preserved from prior chrome so the close
  /// control retains its visual weight relative to the header title).
  static const double _glyphFontSize = 18;

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: kOverlayCloseKey,
      onTap: onClose,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CtSpacing.m,
          vertical: CtSpacing.m / 2,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: EditorialMonoclePalette.accentDim,
            width: _borderWidth,
          ),
        ),
        child: Text(
          '×',
          style: TextStyle(
            fontSize: _glyphFontSize,
            color: EditorialMonoclePalette.muted,
          ),
        ),
      ),
    );
  }
}
