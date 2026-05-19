import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_dialogs.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_order_helpers.dart';
import 'package:colonizethis_app/features/game/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/turn_news_dialog.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_flow.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/turn_resolution_blocking_provider.dart';

import 'app_event_handler.dart';
import 'app_event_handler_debug_flip_province.dart'
    show applyDebugFlipProvinceOwnership;
import 'app_event_handler_debug_reveal_province.dart'
    show applyDebugRevealProvince;
import 'app_event_handler_debug_spawn_civilian.dart'
    show applyDebugCivilianSpawnAtCapital;
import 'app_event_handler_debug_spawn_regiment.dart'
    show applyDebugRegimentSpawnAtCapital;
import 'app_event_handler_debug_spawn_ship.dart'
    show applyDebugShipSpawnAtCapitalHomeFleet;
import 'app_event_handler_debug_stockpile.dart' show applyDebugStockpileCredit;
import 'app_event_handler_debug_treasury.dart' show applyDebugTreasuryCredit;
import 'app_event_handler_debug_worker_pool.dart'
    show applyDebugWorkerPoolCredit;
import 'debug_command_helpers.dart' show DebugCommandResult;

/// [OpenDialogEvent] id for [TrainCiviliansDialog]. SPEC/program/app-ui-wiring.md.

part 'app_event_handler_scope_dialog_builders.dart';
part 'app_event_handler_scope_session_subscriptions.dart';

const String trainCiviliansDialogId = 'train_civilians';

/// [OpenDialogEvent] id for [TrainMilitaryDialog]. SPEC/program/app-ui-wiring.md.
const String trainMilitaryDialogId = 'train_military';

/// [OpenDialogEvent] id for [GrantOrSubsidyDialog]. SPEC/program/app-ui-wiring.md.
const String grantOrSubsidyDialogId = 'grant_or_subsidy';

/// [OpenDialogEvent] id for [NewGameLeaderSelectionDialog]. SPEC/program/app-ui-wiring.md.
const String newGameLeaderSelectionDialogId = 'new_game_leader_selection';

/// Smaller than [GameSetupConfig.defaultConfig]: integration tests compile with
/// `CT_E2E=true` and must stay inside CI wall clocks (not the locked full-init
/// 60/30 profile). Production `main` / widget tests use [GameSetupConfig.defaultConfig].
GameSetupConfig _ctE2eNewGameLeaderTemplateConfig() {
  final d = GameSetupConfig.defaultConfig;
  return GameSetupConfig(
    selectedGreatPowerIds: d.selectedGreatPowerIds,
    leaderVariantByGpId: d.leaderVariantByGpId,
    continentCount: 2,
    minorNationCount: 2,
    tribeCount: 4,
    numProvincesOldWorld: 24,
    numProvincesNewWorld: 12,
    minProvincesPerMinor: 2,
    seed: d.seed,
    infiniteMode: d.infiniteMode,
    startingResources: d.startingResources,
    preferredInitialMapZoomMultiplier: d.preferredInitialMapZoomMultiplier,
    initTownRoadWiringRegionIds: d.initTownRoadWiringRegionIds,
  );
}

/// [OpenDialogEvent] id for [CombatModeChoiceDialog]. SPEC/program/app-ui-wiring.md.
const String combatModeChoiceDialogId = 'combat_mode_choice';

/// [OpenDialogEvent] id for [QuickBattleResultDialog]. SPEC/program/app-ui-wiring.md.
const String quickBattleResultDialogId = 'quick_battle_result';

/// [OpenDialogEvent] id for [TurnNewsDialog]. SPEC/program/app-ui-wiring.md.
const String turnNewsDialogId = 'turn_news';

final _logShell = packageLogger('shell');
final _logEvent = packageLogger('event');

/// Applies a chosen combat mode to the current game session state.
@visibleForTesting
Game? applyCombatModeChoiceToGame(Game? currentGame, CombatMode chosenMode) {
  if (currentGame == null) {
    return null;
  }
  if (currentGame.defaultCombatMode == chosenMode) {
    return currentGame;
  }
  return currentGame.copyWith(defaultCombatMode: chosenMode);
}

/// Replaces pending train-at-capital civilian [BuildUnitOrder]s for [humanPlayerId];
/// keeps military, naval, and other build orders. Matches [TrainCiviliansDialog] semantics.
Orders _mergeTrainCivilianOrdersForPlayer({
  required Orders current,
  required Game game,
  required String humanPlayerId,
  required List<BuildUnitOrder> newFromDialog,
}) {
  Player? player;
  for (final p in game.players) {
    if (p.id == humanPlayerId) {
      player = p;
      break;
    }
  }
  final capital = player?.capitalProvinceId;
  final civilianUnitIds = CivilianEconomyCatalog.byId.keys.toSet();
  final existingList =
      current.buildUnitOrdersByPlayerId[humanPlayerId] ??
      const <BuildUnitOrder>[];
  final kept = <BuildUnitOrder>[];
  for (final order in existingList) {
    final isDialogManaged =
        !order.isMilitary &&
        civilianUnitIds.contains(order.unitType) &&
        capital != null &&
        order.spawnProvinceId == capital;
    if (isDialogManaged) {
      continue;
    }
    kept.add(order);
  }
  return current.copyWith(
    buildUnitOrdersByPlayerId: {
      ...current.buildUnitOrdersByPlayerId,
      humanPlayerId: [...kept, ...newFromDialog],
    },
  );
}

/// Replaces pending train-at-capital military [BuildUnitOrder]s for [humanPlayerId];
/// keeps civilian, naval, and other build orders. Matches [TrainMilitaryDialog] semantics.
Orders _mergeTrainMilitaryOrdersForPlayer({
  required Orders current,
  required Game game,
  required String humanPlayerId,
  required List<BuildUnitOrder> newFromDialog,
}) {
  Player? player;
  for (final p in game.players) {
    if (p.id == humanPlayerId) {
      player = p;
      break;
    }
  }
  final capital = player?.capitalProvinceId;
  final regimentIds = RegimentEconomyCatalog.byId.keys.toSet();
  final existingList =
      current.buildUnitOrdersByPlayerId[humanPlayerId] ??
      const <BuildUnitOrder>[];
  final kept = <BuildUnitOrder>[];
  for (final order in existingList) {
    final isDialogManaged =
        order.isMilitary &&
        regimentIds.contains(order.unitType) &&
        capital != null &&
        order.spawnProvinceId == capital;
    if (isDialogManaged) {
      continue;
    }
    kept.add(order);
  }
  return current.copyWith(
    buildUnitOrdersByPlayerId: {
      ...current.buildUnitOrdersByPlayerId,
      humanPlayerId: [...kept, ...newFromDialog],
    },
  );
}

/// Binds [AppEventHandler] to [appNavigatorKey] for the app lifetime.
/// SPEC/program/app-event-bus.md (handler); SPEC/program/app-ui-wiring.md (dialog registration).
class AppEventHandlerScope extends ConsumerStatefulWidget {
  const AppEventHandlerScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppEventHandlerScope> createState() =>
      _AppEventHandlerScopeState();
}

class _AppEventHandlerScopeState extends ConsumerState<AppEventHandlerScope> {
  AppEventHandler? _handler;
  var _bound = false;
  final List<StreamSubscription<dynamic>> _sessionCommandSubs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bound) {
      return;
    }
    _bound = true;
    final bus = ref.read(appEventBusProvider);
    _handler = AppEventHandler(
      bus: bus,
      navigatorKey: appNavigatorKey,
      dialogBuilders: _dialogBuilders(),
      onShowSnackBar: _showSnackBar,
    );
    _handler!.bind();
    _sessionCommandSubs.addAll(_sessionCommandListeners(bus));
    _logEvent.d('AppEventHandler bound; session command listeners attached');
  }

  void _showSnackBar(ShowSnackBarEvent event) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(event.message),
        action: event.actionLabel != null && event.action != null
            ? SnackBarAction(
                label: event.actionLabel!,
                onPressed: event.action!,
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    for (final s in _sessionCommandSubs) {
      s.cancel();
    }
    _sessionCommandSubs.clear();
    _handler?.unbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  static String _humanPlayerId(Game game) {
    for (final p in game.players) {
      if (p.isHuman) return p.id;
    }
    return game.players.first.id;
  }
}
