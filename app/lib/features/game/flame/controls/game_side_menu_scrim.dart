import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

/// Tappable scrim behind [GameSideMenu] when it is open.
///
/// Lives alongside [GameSideMenu] so the side menu and its scrim share a
/// single visual contract (SPEC:
/// `SPEC/ui/in-game-shell-narrow.md` § Modal behaviour). Resolves the
/// scrim colour from [EditorialMonoclePalette.dialogScrim] — the canonical
/// `--dialog-scrim` token (`oklch(8% 0.01 30 / 0.70)`) shared with every
/// other dark-theme modal scrim (exit-confirm dialog, overture, victory,
/// call to arms, intervention) per
/// `SPEC/ui/pixel-art-ui-catalog.md` § Dialog scrim.
///
/// Hard-coded literals such as `Colors.black54` are regressions; the
/// associated `app/test/game_side_menu_scrim_test.dart` pins this contract.
class GameSideMenuScrim extends StatelessWidget {
  const GameSideMenuScrim({required this.onDismiss, super.key});

  /// Invoked when the user taps the scrim (closes the side menu). The host
  /// (`GameMapArea`) clears its own `_sideMenuOpen` flag.
  final VoidCallback onDismiss;

  /// Stable widget key for the scrim surface — surfaced for widget tests
  /// so the scrim `Container.color` can be asserted without re-implementing
  /// the host's `if (sideMenuOpen) ...` mounting.
  static const Key surfaceKey = Key('game_side_menu_scrim_surface');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: Container(
        key: surfaceKey,
        color: EditorialMonoclePalette.dialogScrim,
      ),
    );
  }
}
