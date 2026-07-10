import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:colonizethis_app_fixtures/runtime/app_display_strings.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../config/routes.dart';
import '../../config/ui_screen_ids.dart';
import '../../core/services/app_event_handler/app_event_handler_scope.dart';
import '../../providers/app_event_bus_provider.dart';
import '../../providers/game_service_provider.dart';
import '../../providers/games_provider.dart';
import '../../providers/observe_session_provider.dart';
import '../../providers/production_allocation_provider.dart';
import '../../widgets/main_menu.dart';

/// App shell. Shows CtMainMenu per SPEC/ui/main-menu.md. Phase 1: wired to resolve and persist.
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  /// SPEC/ui/shell-screen.md — [UiScreenIds.shellScreen].
  static const screenId = UiScreenIds.shellScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bus = ref.watch(appEventBusProvider);
    final resumeAvailable = ref.watch(mainMenuAutoSaveAvailableProvider);
    return CtMainMenu(
      // S8 (#2860): the live shell renders the mockup-matching pixelArt
      // chrome (compass rose, fleur-de-lis, wood-panel buttons, quit chip).
      // MainMenuVariant.plain is retained as a minimal fallback variant.
      variant: MainMenuVariant.pixelArt,
      state: MainMenuState.default_,
      version: appDisplayVersion(),
      onNewGame: () =>
          bus.emit(const OpenDialogEvent(newGameLeaderSelectionDialogId)),
      resumeGameVisible: resumeAvailable,
      onResumeGame: () {
        final service = ref.read(gameServiceProvider);
        final session = service.loadAutoSaveSession();
        if (session != null && context.mounted) {
          ref.read(observeSessionProvider.notifier).reset();
          ref.read(currentGameProvider.notifier).setGame(session.game);
          ref
              .read(currentOrdersProvider.notifier)
              .replaceAll(session.draftOrders);
          ref
              .read(productionDesiredOutputProvider.notifier)
              .replaceAll(session.productionDesiredOutputByRecipe);
          bus.emit(const NavigateToRouteEvent(Routes.game));
        }
      },
      onLoadGame: () =>
          bus.emit(const OpenDialogEvent(loadGameListDialogId)),
      onSettings: () {},
      onQuit: () {
        SystemNavigator.pop();
      },
    );
  }
}
