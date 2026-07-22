import 'dart:async';

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_dialogs.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_naval_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/game/widgets/shell/shell_player_context.dart';
import 'app_event_handler.dart';
import 'app_event_handler_scope.dart';
import 'app_event_handler_scope_session_helpers.dart';
import 'app_event_handler_scope_session_subscriptions.dart';

/// Binds [AppEventHandler] once and tears down session listeners on dispose.
mixin AppEventHandlerScopeLifecycle
    on
        AppEventHandlerScopeSessionHelpers,
        AppEventHandlerScopeDialogBuilders,
        AppEventHandlerScopeSessionCommands {
  AppEventHandler? handler;
  var bound = false;
  final List<StreamSubscription<dynamic>> sessionCommandSubs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (bound) {
      return;
    }
    bound = true;
    final bus = ref.read(appEventBusProvider);
    handler = AppEventHandler(
      bus: bus,
      navigatorKey: appNavigatorKey,
      dialogBuilders: dialogBuilders(),
      onShowSnackBar: showSnackBarForEvent,
    );
    handler!.bind();
    sessionCommandSubs.addAll(sessionCommandListeners(bus));
    appEventHandlerScopeLog.d(
      'AppEventHandler bound; session command listeners attached',
    );
  }

  @override
  void dispose() {
    for (final s in sessionCommandSubs) {
      s.cancel();
    }
    sessionCommandSubs.clear();
    handler?.unbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

mixin AppEventHandlerScopeDialogBuilders on ConsumerState<AppEventHandlerScope> {
  Map<String, DialogBuilder> dialogBuilders() {
    return {
      trainCiviliansDialogId: buildTrainCiviliansDialog,
      trainMilitaryDialogId: buildTrainMilitaryDialog,
      trainNavalDialogId: buildTrainNavalDialog,
      grantOrSubsidyDialogId: buildGrantOrSubsidyDialog,
      combatModeChoiceDialogId: buildCombatModeChoiceDialog,
      quickBattleResultDialogId: buildQuickBattleResultDialog,
      turnNewsDialogId: buildTurnNewsDialog,
      // Feature builders merged last (Refs #3546, app-ui-wiring.md).
      for (final entry in widget.extraDialogBuilders.entries)
        entry.key: entry.value(appNavigatorKey),
    };
  }

  Widget buildTrainCiviliansDialog(BuildContext ctx, Map<String, Object?>? _) {
    final container = ProviderScope.containerOf(ctx);
    final game = container.read(currentGameProvider);
    if (game == null) {
      return const SizedBox.shrink();
    }
    return TrainCiviliansDialog(
      game: game,
      humanPlayerId: resolveShellPanelPlayerId(
        container.read(shellPlayerContextProvider),
        game,
      ),
      currentOrders: container.read(currentOrdersProvider),
      bus: container.read(appEventBusProvider),
    );
  }

  Widget buildTrainMilitaryDialog(BuildContext ctx, Map<String, Object?>? _) {
    final container = ProviderScope.containerOf(ctx);
    final game = container.read(currentGameProvider);
    if (game == null) {
      return const SizedBox.shrink();
    }
    return TrainMilitaryDialog(
      game: game,
      humanPlayerId: resolveShellPanelPlayerId(
        container.read(shellPlayerContextProvider),
        game,
      ),
      currentOrders: container.read(currentOrdersProvider),
      bus: container.read(appEventBusProvider),
    );
  }

  Widget buildTrainNavalDialog(BuildContext ctx, Map<String, Object?>? _) {
    final container = ProviderScope.containerOf(ctx);
    final game = container.read(currentGameProvider);
    if (game == null) {
      return const SizedBox.shrink();
    }
    return TrainNavalDialog(
      game: game,
      humanPlayerId: resolveShellPanelPlayerId(
        container.read(shellPlayerContextProvider),
        game,
      ),
      currentOrders: container.read(currentOrdersProvider),
      bus: container.read(appEventBusProvider),
    );
  }

  Widget buildGrantOrSubsidyDialog(
    BuildContext ctx,
    Map<String, Object?>? params,
  ) {
    final container = ProviderScope.containerOf(ctx);
    final game = container.read(currentGameProvider);
    if (game == null) {
      return const SizedBox.shrink();
    }
    return GrantOrSubsidyDialog(
      game: game,
      humanPlayerId: resolveShellPanelPlayerId(
        container.read(shellPlayerContextProvider),
        game,
      ),
      targetFactionId: params?['targetFactionId'] as String? ?? '',
      isSubsidy: params?['isSubsidy'] == true,
      bus: container.read(appEventBusProvider),
    );
  }

  Widget buildCombatModeChoiceDialog(
    BuildContext ctx,
    Map<String, Object?>? params,
  ) {
    final container = ProviderScope.containerOf(ctx);
    return CombatModeChoiceDialog(
      bus: container.read(appEventBusProvider),
      provinceName: params?['provinceName'] as String? ?? '',
      isCapitalSiege: params?['isCapitalSiege'] == true,
    );
  }

  Widget buildQuickBattleResultDialog(
    BuildContext _,
    Map<String, Object?>? params,
  ) {
    final result = params?['result'] as QuickBattleResult?;
    if (result == null) {
      return const SizedBox.shrink();
    }
    return QuickBattleResultDialog(
      result: result,
      attackerName: params?['attackerName'] as String? ?? 'Attacker',
      defenderName: params?['defenderName'] as String? ?? 'Defender',
    );
  }

  Widget buildTurnNewsDialog(BuildContext ctx, Map<String, Object?>? params) {
    final container = ProviderScope.containerOf(ctx);
    final game = container.read(currentGameProvider);
    final digest = params?['digest'] as TurnNewsDigest?;
    final newTurnNumber = params?['newTurnNumber'] as int?;
    if (game == null || digest == null || newTurnNumber == null) {
      return const SizedBox.shrink();
    }
    return TurnNewsDialog(
      game: game,
      digest: digest,
      newTurnNumber: newTurnNumber,
    );
  }
}
