import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/games_provider.dart';
import 'ct_screen_shell.dart';
import 'game_to_ui_bus_listener.dart';

typedef GameFeatureBodyBuilder =
    Widget Function(BuildContext context, WidgetRef ref, Game displayGame);

/// Shared shell/listener orchestration for game-bound feature screens.
///
/// Two chrome paths:
///
/// * Default ([topBar] is `null`) — wraps [bodyBuilder]'s output in
///   [CtScreenShell] which renders the legacy light title bar. Used by
///   screens that have not yet migrated to the dark editorial-monocle top
///   bar.
/// * Opt-in ([topBar] non-null) — renders a [Scaffold] using the active
///   theme's `colorScheme.surface`, stacks the supplied [topBar] above the
///   body. Screens supply the dark `CtTopBar` here when migrating to the
///   per-screen dark chrome (e.g. issue #2862 S1 for the production
///   screen). When [topBar] is provided, [title] is unused at the chrome
///   level and is therefore optional.
class CtGameFeatureScreenShell extends ConsumerWidget {
  const CtGameFeatureScreenShell({
    super.key,
    required this.game,
    required this.bodyBuilder,
    this.title,
    this.topBar,
    this.showBackButton = true,
    this.attachGameToUiListener = true,
  }) : assert(
         topBar != null || title != null,
         'CtGameFeatureScreenShell requires either a topBar widget '
         '(dark editorial-monocle chrome) or a title string (legacy '
         'CtScreenShell chrome).',
       );

  final Game game;

  /// Title used by the legacy [CtScreenShell] chrome. Required when
  /// [topBar] is `null`; ignored when [topBar] is provided.
  final String? title;

  /// Optional opt-in dark editorial-monocle top bar (typically a
  /// `CtTopBar`). When non-null the shell renders a [Scaffold] with this
  /// bar above the body and skips the legacy [CtScreenShell] chrome.
  final Widget? topBar;

  final GameFeatureBodyBuilder bodyBuilder;
  final bool showBackButton;
  final bool attachGameToUiListener;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = attachGameToUiListener ? ref.watch(currentGameProvider) : null;
    final displayGame = live != null && live.id == game.id ? live : game;

    final Widget body = bodyBuilder(context, ref, displayGame);
    final Widget shell = topBar != null
        ? _DarkChromeShell(topBar: topBar!, body: body)
        : CtScreenShell(
            title: title!,
            showBackButton: showBackButton,
            child: body,
          );
    if (!attachGameToUiListener) {
      return shell;
    }
    return GameToUIBusListener(gameId: game.id, child: shell);
  }
}

class _DarkChromeShell extends StatelessWidget {
  const _DarkChromeShell({required this.topBar, required this.body});

  final Widget topBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
