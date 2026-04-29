import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/debug_console_api.dart'
    show
        kUnitTypeBuilder,
        kUnitTypeEngineer,
        kUnitTypeExplorer,
        kUnitTypeMerchant,
        kUnitTypeRailBuilder,
        kUnitTypeSpy,
        resolveCivilianSpawnTileKey;
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

import 'app_event_handler.dart';

part 'app_event_handler_scope_dialog_builders.dart';
part 'app_event_handler_scope_session_subscriptions.dart';

/// [OpenDialogEvent] id for [TrainCiviliansDialog]. SPEC/program/app-ui-wiring.md.
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
    startingResources: d.startingResources,
    preferredInitialMapZoomMultiplier: d.preferredInitialMapZoomMultiplier,
    initTownRoadWiringRegionIds: d.initTownRoadWiringRegionIds,
  );
}

/// [OpenDialogEvent] id for [CombatModeChoiceDialog]. SPEC/program/app-ui-wiring.md.
const String combatModeChoiceDialogId = 'combat_mode_choice';

/// [OpenDialogEvent] id for [QuickBattleResultDialog]. SPEC/program/app-ui-wiring.md.
const String quickBattleResultDialogId = 'quick_battle_result';

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

@visibleForTesting
({Game? game, String message}) applyDebugCivilianSpawnAtCapital({
  required Game? currentGame,
  required SpawnDebugCivilianAtCapitalEvent event,
}) {
  if (currentGame == null) {
    return (game: null, message: 'Debug spawn ignored: no active game.');
  }
  Player? player;
  for (final candidate in currentGame.players) {
    if (candidate.id == event.humanPlayerId) {
      player = candidate;
      break;
    }
  }
  if (player == null) {
    return (
      game: null,
      message: 'Debug spawn ignored: unknown player ${event.humanPlayerId}.',
    );
  }
  if (!_isAllowedDebugCivilianType(event.unitType)) {
    return (
      game: null,
      message:
          'Debug spawn ignored: unsupported civilian type ${event.unitType}.',
    );
  }
  if (event.count < 1) {
    return (game: null, message: 'Debug spawn ignored: count must be >= 1.');
  }
  final spawnTileKey = resolveCivilianSpawnTileKey(
    player: player,
    worldState: currentGame.worldState,
  );
  final spawnProvinceId = Unit.provinceIdFromTileKey(spawnTileKey);
  final spawnRegionId = Unit.regionIdFromTileKey(spawnTileKey);
  if (spawnTileKey == null ||
      spawnProvinceId == null ||
      spawnRegionId == null) {
    return (
      game: null,
      message: 'Debug spawn ignored: player has no valid capital tile.',
    );
  }
  final boundedCount = event.count > 25 ? 25 : event.count;
  final allUnits = <Unit>[
    ...currentGame.worldState.oldWorld.units,
    ...currentGame.worldState.newWorld.units,
  ];
  var nextDebugSeq = _nextDebugSpawnSequence(
    units: allUnits,
    playerId: event.humanPlayerId,
    unitType: event.unitType,
  );
  final spawned = <Unit>[];
  for (var i = 0; i < boundedCount; i++) {
    spawned.add(
      Unit(
        id: 'debug_${event.humanPlayerId}_${_unitTypeIdSegment(event.unitType)}_${nextDebugSeq++}',
        type: event.unitType,
        ownerId: event.humanPlayerId,
        locationProvinceId: spawnProvinceId,
        tileKey: spawnTileKey,
      ),
    );
  }
  final world = currentGame.worldState;
  final oldUnits = List<Unit>.from(world.oldWorld.units);
  final newUnits = List<Unit>.from(world.newWorld.units);
  if (spawnRegionId == kRegionNewWorld) {
    newUnits.addAll(spawned);
  } else {
    oldUnits.addAll(spawned);
  }
  final updatedWorld = world.copyWith(
    oldWorld: RegionData(provinces: world.oldWorld.provinces, units: oldUnits),
    newWorld: RegionData(provinces: world.newWorld.provinces, units: newUnits),
  );
  return (
    game: currentGame.copyWith(worldState: updatedWorld),
    message:
        'Spawned ${spawned.length} ${event.unitType} at ${player.displayName} capital.',
  );
}

String _unitTypeIdSegment(String unitType) {
  final lower = unitType.toLowerCase();
  return lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

int _nextDebugSpawnSequence({
  required List<Unit> units,
  required String playerId,
  required String unitType,
}) {
  final prefix = 'debug_${playerId}_${_unitTypeIdSegment(unitType)}_';
  var maxSeen = 0;
  for (final unit in units) {
    if (!unit.id.startsWith(prefix)) {
      continue;
    }
    final suffix = unit.id.substring(prefix.length);
    final seq = int.tryParse(suffix);
    if (seq != null && seq > maxSeen) {
      maxSeen = seq;
    }
  }
  return maxSeen + 1;
}

bool _isAllowedDebugCivilianType(String unitType) {
  switch (unitType) {
    case kUnitTypeExplorer:
    case kUnitTypeBuilder:
    case kUnitTypeEngineer:
    case kUnitTypeSpy:
    case kUnitTypeMerchant:
    case kUnitTypeRailBuilder:
      return true;
    default:
      return false;
  }
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
  bool _bound = false;
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
