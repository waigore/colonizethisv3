import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

/// Pixel-art close control (non-Material) keyed for tests as
/// [kOverlayCloseKey]. Border colour resolves to `--accent-dim` and the
/// `×` glyph paints in `--muted` per
/// SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme chrome.
class OverlayCloseButton extends StatelessWidget {
  const OverlayCloseButton({this.onClose});

  static const Key kOverlayCloseKey = Key('overlay_close');

  static const double _borderWidth = 1;
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
