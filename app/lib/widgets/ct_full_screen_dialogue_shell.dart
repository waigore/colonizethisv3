import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';
import 'ct_dialog_shell.dart';
import 'ct_spacing.dart';

/// Reusable full-screen scrim + centered [CtDialogShell] wrapper for blocking
/// dialogue overlays (overture, call-to-arms, intervention, game-start intro
/// per `SPEC/ui/dialogue-presentation.md`). Consolidates the previously
/// duplicated `Stack` -> `Material(dialogScrim)` -> `Center` -> `CtDialogShell`
/// -> `Padding` scaffold from four feature files (issue #2914 S2).
///
/// **Visual contract** (per `SPEC/ui/pixel-art-ui-catalog.md` §
/// *CtFullScreenDialogueShell*):
///
/// 1. Outer [Stack] paints [backdrop] at the bottom — typically the
///    underlying game canvas / app shell the overlay is dimming.
/// 2. Above the backdrop, a full-screen [Material] is painted with the
///    canonical [EditorialMonoclePalette.dialogScrim] token from §
///    *Dialog scrim* (no hard-coded `Colors.black54` / hex literal).
/// 3. The scrim hosts a centered [CtDialogShell] sized by [maxWidth] /
///    [maxHeight]; the [CtDialogShell] inherits its canonical 2px
///    `--accent-dim` border and `CtGradients.panelGradient` background.
/// 4. Inside the dialog frame, [body] is wrapped in a single [Padding]
///    so per-overlay padding (typically 16 px for error states, 20 px
///    for regular Yarn / list bodies) can flow through unchanged.
///
/// The shell intentionally renders **no** title, brass divider, or
/// internal layout chrome. Callers compose those above [body] so each
/// overlay can preserve its own title-ordering and divider placement
/// (overture lists the intro between divider and rows; call-to-arms
/// places the intro before the divider; intervention/intro keep the
/// divider directly under the title).
class CtFullScreenDialogueShell extends StatelessWidget {
  const CtFullScreenDialogueShell({
    super.key,
    required this.backdrop,
    required this.body,
    this.maxWidth = defaultMaxWidth,
    this.maxHeight = defaultMaxHeight,
    this.padding = defaultPadding,
    this.wrapBodyInDialogShell = true,
  });

  /// Widget painted underneath the scrim (typically the underlying game
  /// canvas / app shell the overlay is blocking).
  final Widget backdrop;

  /// Dialog body placed inside the centered [CtDialogShell].
  final Widget body;

  /// Maximum width forwarded to the inner [CtDialogShell].
  final double maxWidth;

  /// Maximum height forwarded to the inner [CtDialogShell].
  final double maxHeight;

  /// Inner padding wrapping [body] inside the dialog frame.
  final EdgeInsetsGeometry padding;

  /// When `true` (default), [body] is hosted inside a centered
  /// [CtDialogShell]. When `false`, [body] is centered directly under the
  /// scrim — for overlays such as [VictoryOverlay] whose body widget
  /// supplies its own ceremonial frame (issue #3279 §3).
  final bool wrapBodyInDialogShell;

  /// Canonical dialog-shell max width for full-screen dialogue overlays
  /// (520 dp — matches the existing overture / call-to-arms / intervention
  /// / game-start intro call sites).
  static const double defaultMaxWidth = 520;

  /// Canonical dialog-shell max height matching the [CtDialogShell]
  /// default. Call sites that previously specified a custom max height
  /// (e.g. overture phase-2 / call-to-arms at 500) pass it explicitly.
  static const double defaultMaxHeight = 600;

  /// Canonical inner padding for dialogue overlay bodies (`CtSpacing.xl`
  /// = 20 dp on each side — matches the dominant call-site pattern).
  /// Error fallbacks may override with `EdgeInsets.all(CtSpacing.l)`.
  static const EdgeInsetsGeometry defaultPadding = EdgeInsets.all(
    CtSpacing.xl,
  );

  @override
  Widget build(BuildContext context) {
    final Widget centeredBody = wrapBodyInDialogShell
        ? CtDialogShell(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            child: Padding(padding: padding, child: body),
          )
        : Padding(padding: padding, child: body);
    return Stack(
      children: [
        backdrop,
        Material(
          color: EditorialMonoclePalette.dialogScrim,
          child: Center(child: centeredBody),
        ),
      ],
    );
  }
}
