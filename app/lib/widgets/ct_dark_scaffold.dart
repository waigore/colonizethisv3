import 'package:flutter/material.dart';

/// Dark editorial-monocle screen scaffold: a [Scaffold] + [SafeArea] +
/// `Column(crossAxisAlignment: stretch)` that stacks a [topBar] above an
/// [Expanded] body.
///
/// Promoted from the private `_DarkChromeShell` inside
/// [`ct_game_feature_screen_shell.dart`] (issue #3279 §6) so other screens
/// that want the same dark-chrome wrapper can reuse it directly instead of
/// re-implementing the `Scaffold` + `SafeArea` + `Column(topBar + body)`
/// skeleton. [CtGameFeatureScreenShell] is the first consumer (dark-chrome
/// path); the widget carries no game/listener coupling so it is reusable by
/// any dark-theme screen.
///
/// Background defaults to `Theme.of(context).colorScheme.surface` — the same
/// token the panel-style game feature screens use. Screens that paint on a
/// per-screen mockup background (e.g. `EditorialMonoclePalette.bg`) pass
/// [backgroundColor] explicitly so the shell honours the mockup without the
/// consumer hand-rolling its own [Scaffold] (which would trip the
/// `repo.app_no_material_scaffold` lint).
///
/// SPEC: `SPEC/ui/components/ct-dark-scaffold.md`.
class CtDarkScaffold extends StatelessWidget {
  const CtDarkScaffold({
    super.key,
    required this.topBar,
    required this.body,
    this.backgroundColor,
  });

  /// Top chrome rendered above the body (typically a `CtTopBar`).
  final Widget topBar;

  /// Screen body placed inside the [Expanded] region below [topBar].
  final Widget body;

  /// Optional background colour for the [Scaffold]. Defaults to
  /// `Theme.of(context).colorScheme.surface` when `null`.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            topBar,
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
