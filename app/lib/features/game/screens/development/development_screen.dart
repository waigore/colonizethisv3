// Full-screen Development panel. SPEC/ui/development-panel.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_constants.dart';
import '../../../../config/routes.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../widgets/ct_action_text_button.dart';
import '../../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../../widgets/game_feature_screen_top_bar.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../widgets/shell/shell_player_guarded_body.dart';
import 'development_panel_keys.dart';
import 'development_shell_map_pause_scope.dart';
import 'development_screen_body.dart';

class DevelopmentScreen extends ConsumerWidget {
  const DevelopmentScreen({
    super.key,
    required this.game,
    required this.humanPlayerId,
  });

  /// SPEC/ui/development-panel.md — [UiScreenIds.developmentScreen].
  static const screenId = UiScreenIds.developmentScreen;

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarTitle = 'Development';

  static const String topBarIconAsset =
      '${kAppIconAssetPrefix}ui_icon_development.png';

  final Game game;
  final String humanPlayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = appL10n(context);
    final bus = ref.read(appEventBusProvider);
    return DevelopmentShellMapPauseScope(
      child: CtGameFeatureScreenShell(
        game: game,
        topBar: GameFeatureScreenTopBar.build(
          key: DevelopmentPanelKeys.topBarKey,
          title: topBarTitle,
          iconAsset: topBarIconAsset,
          trailing: CtActionTextButton(
            key: DevelopmentPanelKeys.counselButtonKey,
            onPressed: () {
              bus.emit(
                NavigateToRouteEvent(Routes.counsel, {
                  'game': game,
                  'humanPlayerId': humanPlayerId,
                  'counselTab': 'development',
                }),
              );
            },
            label: l10n.development_counsel,
          ),
        ),
        bodyBuilder: (context, shellRef, displayGame) {
          final shell = shellRef.read(shellPlayerContextProvider);
          final sentinel = observeNotDefinedSentinel(shell, 'Development');
          if (sentinel != null) return sentinel;
          return DevelopmentScreenBody(
            game: displayGame,
            humanPlayerId: humanPlayerId,
          );
        },
      ),
    );
  }
}
