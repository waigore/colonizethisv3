import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gradients.dart';
import '../../../../widgets/ct_spacing.dart';

/// Dark editorial-monocle dialog shell. Implements `Refs #2859` S4 / R3 by
/// painting a framed surface from the canonical palette tokens (no nine-patch
/// chrome, no Material `AlertDialog`/`Dialog` visuals).
///
/// **Visual contract:**
/// - **Frame:** Default 2px `--accent-dim` border on all four sides
///   ([EditorialMonoclePalette.accentDim]). Callers MAY override [borderColor]
///   and [borderWidth] for destructive-flow sub-dialogs (e.g. the move-army
///   war confirmation per `SPEC/ui/move-army-dialog.md` § Sub-dialog uses
///   `borderColor: --danger` and `borderWidth: 1`). All overrides MUST still
///   resolve from the canonical palette tokens; no hard-coded hex literals.
/// - **Background:** Top-to-bottom panel gradient sourced from
///   [CtGradients.panelGradient]. No hard-coded hex literals; gradient stops
///   resolve from the dark-theme tokens (`--surface` → `--bg`).
/// - **Default text style:** Falls back to [EditorialMonoclePalette.fg]
///   (the canonical `--fg` primary-text token) when the host theme's
///   `TextTheme.bodyMedium` is `null`. Hard-coded `Colors.white` fallbacks
///   are forbidden here (issue #2914 S3 — § Hard-coded color ban in
///   `SPEC/ui/pixel-art-ui-catalog.md`).
///
/// The modal barrier (scrim) is the caller's responsibility: pass
/// `barrierColor` to `showDialog` (or rely on the route's default). This
/// widget paints only the dialog content frame.
///
/// **Layout:** The framed area grows with body content up to [maxHeight]. When
/// content exceeds [maxHeight], a single outer vertical scroll on the shell
/// exposes the full body (see `SPEC/ui/pixel-art-ui-catalog.md` §
/// *CtDialogShell*). Avoid [Expanded] / vertical [Flexible] in [child]; use
/// `Column(mainAxisSize: MainAxisSize.min)` and let this shell scroll.
class CtDialogShell extends StatelessWidget {
  const CtDialogShell({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.maxHeight = 600,
    this.padding = const EdgeInsets.symmetric(
      horizontal: CtSpacing.l,
      vertical: CtSpacing.l,
    ),
    this.borderColor,
    this.borderWidth = defaultBorderWidth,
  });

  /// Dialog body content (title, text, actions column/rows).
  final Widget child;

  /// Maximum width of the dialog content area.
  final double maxWidth;

  /// Maximum height of the dialog content area.
  final double maxHeight;

  /// Inner padding between frame border and [child].
  final EdgeInsetsGeometry padding;

  /// Optional override for the frame border color. Defaults to
  /// [EditorialMonoclePalette.accentDim] when `null` (the canonical
  /// editorial-monocle dialog border per #2859 R3 / S4). Destructive-flow
  /// sub-dialogs SHOULD pass [EditorialMonoclePalette.danger] together with
  /// [borderWidth] `1` to mark the surface as dangerous (see
  /// `SPEC/ui/move-army-dialog.md` § Invade-confirm sub-dialog).
  final Color? borderColor;

  /// Frame border width. Defaults to [defaultBorderWidth] (2px) per #2859 R3 /
  /// S4. Destructive-flow sub-dialogs (red `--danger` border) SHOULD pass
  /// [dangerBorderWidth] (1px) per `SPEC/ui/move-army-dialog.md` AC.
  final double borderWidth;

  /// Default frame border width — 2px `--accent-dim` per #2859 R3 / S4.
  static const double defaultBorderWidth = 2;

  /// Frame border width for danger-variant sub-dialogs — 1px `--danger` per
  /// `SPEC/ui/move-army-dialog.md` AC (war confirmation).
  static const double dangerBorderWidth = 1;

  /// Defensive fallback applied to the body text style when the host theme's
  /// `TextTheme.bodyMedium` resolves to `null`. Anchored on
  /// [EditorialMonoclePalette.fg] (the canonical `--fg` primary-text token)
  /// to keep the surface honoring the dark editorial-monocle palette tokens
  /// even outside a fully-themed `MaterialApp`. Tests pin this to guard
  /// against regressions to `Colors.white` or other raw Material color
  /// literals — see `SPEC/ui/pixel-art-ui-catalog.md` § Hard-coded color ban
  /// (issue #2914 S3).
  @visibleForTesting
  static TextStyle get fallbackBodyTextStyle =>
      TextStyle(color: EditorialMonoclePalette.fg);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color resolvedBorderColor =
        borderColor ?? EditorialMonoclePalette.accentDim;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(CtSpacing.l),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: CtGradients.panelGradient,
              border: Border.all(
                color: resolvedBorderColor,
                width: borderWidth,
              ),
            ),
            child: CustomScrollView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: padding,
                    child: DefaultTextStyle(
                      style:
                          theme.textTheme.bodyMedium ?? fallbackBodyTextStyle,
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
