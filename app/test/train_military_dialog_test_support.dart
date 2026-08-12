// Shared pump / fixture helpers for TrainMilitaryDialog widget tests.
// Used by `train_military_dialog_test.dart` and sibling suites (Refs #4305).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

/// Stub map service: dialog builder only needs [getMapData] (empty topology OK).
class _TrainMilitaryDialogMapGameService extends GameService {
  _TrainMilitaryDialogMapGameService(super.box, super.adapter);

  @override
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String gameId) => null;
}

class TrainMilitaryDialogTestHarness {
  TrainMilitaryDialogTestHarness() : game = buildTrainPanelTestGame() {
    humanPlayerId = game.players.isNotEmpty
        ? game.players.firstWhere((p) => p.isHuman).id
        : game.players.first.id;
  }

  final Game game;
  late final String humanPlayerId;
  Box<dynamic>? _gamesBox;
  GameService? _mapService;

  Player player(String pid) => game.players.firstWhere((p) => p.id == pid);

  /// Opens Hive for bus-driven UNIT50001 open (dialog builder reads GameService).
  Future<void> ensureHandlerHive() async {
    if (_gamesBox != null) return;
    Hive.init('./.dart_tool/test_hive_train_military_dialog');
    _gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
    _mapService = _TrainMilitaryDialogMapGameService(
      _gamesBox!,
      GameSaveAdapter(),
    );
  }

  Future<void> closeHandlerHive() async {
    await _gamesBox?.close();
    _gamesBox = null;
    _mapService = null;
  }

  Game gameWithMilitaryResources() {
    final p = player(humanPlayerId);
    final techUnlocked = Map<String, bool>.from(p.techUnlocked ?? {});
    for (final techId in unlockingTechByRegimentId.values) {
      techUnlocked[techId] = true;
    }
    return game.copyWith(
      players: [
        p.copyWith(
          treasury: 10000,
          workerPool: p.workerPool.copyWith(peasants: 20),
          techUnlocked: techUnlocked,
          stockpile: p.stockpile.merge(
            const Stockpile(
              quantities: {
                'fabric': 100,
                'castIron': 100,
                'lumber': 100,
                'horses': 100,
                'steel': 100,
                'bronze': 100,
              },
            ),
          ),
        ),
        ...game.players.where((x) => x.id != humanPlayerId),
      ],
    );
  }

  Widget buildDialog({
    required Game panelGame,
    Orders currentOrders = const Orders(),
    AppEventBus? bus,
  }) {
    return buildAppShell(
      child: Scaffold(
        body: TrainMilitaryDialog(
          game: panelGame,
          humanPlayerId: humanPlayerId,
          currentOrders: currentOrders,
          bus: bus ?? AppEventBus.create(),
        ),
      ),
    );
  }

  /// Shell + [AppEventHandlerScope] for bus-driven open of UNIT50001.
  /// Requires [ensureHandlerHive] first: observe-gate + dialog builder both
  /// touch providers that otherwise open Hive.
  Widget handlerShell({
    required Game panelGame,
    Orders orders = const Orders(),
    required Widget body,
  }) {
    final gamesBox = _gamesBox;
    final mapService = _mapService;
    assert(
      gamesBox != null && mapService != null,
      'Call ensureHandlerHive() in setUpAll before handlerShell',
    );
    return buildAppShell(
      overrides: [
        gamesBoxProvider.overrideWith((ref) => gamesBox!),
        gameServiceProvider.overrideWith((ref) => mapService!),
        currentGameProvider.overrideWith(() => CurrentGameNotifier(panelGame)),
        currentOrdersProvider.overrideWith(() => CurrentOrdersNotifier(orders)),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
        shellPlayerContextProvider.overrideWithValue(
          ShellPlayerContext(
            effectiveHumanPlayerId: humanPlayerId,
            viewingPlayerId: humanPlayerId,
            mapVisibilityMode: CtMapVisibilityMode.full,
            playerView: null,
            omniscientDetail: false,
            showPlayerChrome: true,
            canMutateViaUi: true,
            debugCommandTargetPlayerId: humanPlayerId,
            inObservePhase: false,
            observeBannerLabel: null,
            treasuryNotDefined: false,
            cargoNotDefined: false,
          ),
        ),
      ],
      navigatorKey: appNavigatorKey,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: Scaffold(body: body),
    );
  }
}
