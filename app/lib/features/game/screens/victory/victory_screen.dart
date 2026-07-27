// Full-screen Victory panel. SPEC/ui/victory-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_constants.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../../widgets/game_feature_screen_top_bar.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../widgets/shell/shell_player_guarded_body.dart';
import 'victory_screen_body.dart';
import 'victory_screen_keys.dart';

class VictoryScreen extends ConsumerWidget {
  const VictoryScreen({
    super.key,
    required this.game,
    required this.humanPlayerId,
  });

  /// SPEC/ui/victory-panel.md — [UiScreenIds.victoryScreen].
  static const screenId = UiScreenIds.victoryScreen;

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarTitle = 'Victory';

  static const String topBarIconAsset =
      '${kAppIconAssetPrefix}ui_icon_victory.png';

  final Game game;
  final String humanPlayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CtGameFeatureScreenShell(
      game: game,
      topBar: GameFeatureScreenTopBar.build(
        key: VictoryScreenKeys.topBarKey,
        title: topBarTitle,
        iconAsset: topBarIconAsset,
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        final shell = shellRef.read(shellPlayerContextProvider);
        final sentinel = observeNotDefinedSentinel(shell, 'Victory');
        if (sentinel != null) return sentinel;
        return VictoryScreenBody(
          game: displayGame,
          humanPlayerId: humanPlayerId,
        );
      },
    );
  }
}
