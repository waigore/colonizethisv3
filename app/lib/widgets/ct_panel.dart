import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';
import 'ct_gradients.dart';
import 'ct_spacing.dart';

/// Dark editorial-monocle framed panel.
///
/// Implements `Refs #2859` S3 / R2 by painting a token-resolved
/// [CtGradients.panelGradient] surface bracketed by 1.5 px
/// [EditorialMonoclePalette.accentDim] horizontal border strips along the top
/// and bottom edges. The chrome no longer depends on the legacy
/// `ui_button_nine_patch.png` parchment asset; the public class name
/// `CtPanel` is preserved so existing call sites continue to compile.
///
/// **Visual contract (per #2859 R2 / S3):**
/// - **Background:** [CtGradients.panelGradient] (top→bottom `--surface` →
///   `--bg`) painted across the full panel area.
/// - **Edge bracket strips:** 1.5 px ([accentEdgeWidth]) horizontal strips
///   coloured [EditorialMonoclePalette.accentDim] along the top and bottom
///   edges of the panel. The left and right edges intentionally render no
///   border so the panel reads as a horizontally-banded section rather than a
///   full frame (`CtDialogShell` owns the four-sided frame contract per
///   #2859 R3).
/// - **Padding:** Configurable inner padding around [child]; defaults to
///   `CtSpacing.ml` (12 px) on all sides matching the legacy parchment
///   panel's content inset.
/// - **No nine-patch asset dependency:** All chrome is painted programmatically
///   from canonical palette tokens — no hard-coded hex literals, no asset
///   bundle lookup, no async image-decode pipeline.
///
/// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § *CtPanel* (R2 visual contract).
class CtPanel extends StatelessWidget {
  const CtPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CtSpacing.ml),
    this.destTileSize = 16,
  });

  /// Panel body content.
  final Widget child;

  /// Inner padding between the [accentEdgeWidth] border strips and [child].
  final EdgeInsetsGeometry padding;

  /// Retained for backward compatibility with the legacy nine-patch
  /// rendering. The dark editorial-monocle visual contract no longer
  /// rasterises a nine-patch image, so this argument has **no effect** on
  /// rendering; it remains in the constructor signature so existing call
  /// sites continue to compile without churn. Removal is deferred to a
  /// follow-up cleanup slice once all `destTileSize:` arguments are
  /// dropped (mirrors the equivalent deprecation in
  /// [`CtNinePatchButton`](../chrome/ct_nine_patch_button.dart)).
  final double destTileSize;

  /// Stroke width of the top and bottom `--accent-dim` edge strips per
  /// #2859 R2 / S3.
  static const double accentEdgeWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final Color edgeColor = EditorialMonoclePalette.accentDim;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: CtGradients.panelGradient,
        border: Border(
          top: BorderSide(color: edgeColor, width: accentEdgeWidth),
          bottom: BorderSide(color: edgeColor, width: accentEdgeWidth),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
