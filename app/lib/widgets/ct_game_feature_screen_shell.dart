import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/games_provider.dart';
import 'ct_screen_shell.dart';
import 'game_to_ui_bus_listener.dart';

typedef GameFeatureBodyBuilder =
    Widget Function(BuildContext context, WidgetRef ref, Game displayGame);

/// Shared shell/listener orchestration for game-bound feature screens.
class CtGameFeatureScreenShell extends ConsumerWidget {
  const CtGameFeatureScreenShell({
    super.key,
    required this.game,
    required this.title,
    required this.bodyBuilder,
    this.showBackButton = true,
    this.attachGameToUiListener = true,
  });

  final Game game;
  final String title;
  final GameFeatureBodyBuilder bodyBuilder;
  final bool showBackButton;
  final bool attachGameToUiListener;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = attachGameToUiListener ? ref.watch(currentGameProvider) : null;
    final displayGame = live != null && live.id == game.id ? live : game;

    final shell = CtScreenShell(
      title: title,
      showBackButton: showBackButton,
      child: bodyBuilder(context, ref, displayGame),
    );
    if (!attachGameToUiListener) {
      return shell;
    }
    return GameToUIBusListener(gameId: game.id, child: shell);
  }
}
