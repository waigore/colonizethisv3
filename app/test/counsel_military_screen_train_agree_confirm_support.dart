// Screen-level harness for counsel military train-Agree confirm tests (Refs #4734 Slice E, #4307).

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/counsel/counsel_screen.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'panel_fixtures/core.dart';
import 'widget_test_pumps.dart';

const kCounselMilitaryTrainConfirmGameId = 'train-panel-widget-test';

final MapTopology _trainCounselTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|cap',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

class CounselMilitaryTrainMapGameServiceConfirm extends GameService {
  CounselMilitaryTrainMapGameServiceConfirm(super.box, super.adapter);

  @override
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String gameId) {
    if (gameId != kCounselMilitaryTrainConfirmGameId) return null;
    return (
      combinedTopology: _trainCounselTopology,
      tileMapByRegion: const {},
      topologyByRegion: const {},
      warpLinks: null,
    );
  }
}

List<Override> counselMilitaryTrainConfirmOverrides({
  required Box<dynamic> gamesBox,
  required Game game,
  required AppEventBus bus,
  Orders initialOrders = const Orders(),
  CurrentOrdersNotifier? ordersNotifier,
  GameService? gameService,
  bool canMutateViaUi = true,
}) {
  final playerId = game.players.first.id;
  final ordersState = ordersNotifier ?? CurrentOrdersNotifier(initialOrders);
  return [
    gamesBoxProvider.overrideWith((ref) => gamesBox),
    gameServiceProvider.overrideWith(
      (ref) => gameService ?? GameService(gamesBox, GameSaveAdapter()),
    ),
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(() => ordersState),
    appEventBusProvider.overrideWith((ref) => bus),
    shellPlayerContextProvider.overrideWithValue(
      ShellPlayerContext(
        effectiveHumanPlayerId: playerId,
        viewingPlayerId: playerId,
        mapVisibilityMode: CtMapVisibilityMode.full,
        playerView: null,
        omniscientDetail: false,
        showPlayerChrome: true,
        canMutateViaUi: canMutateViaUi,
        debugCommandTargetPlayerId: playerId,
        inObservePhase: !canMutateViaUi,
        observeBannerLabel: canMutateViaUi ? null : 'Observing',
        treasuryNotDefined: false,
        cargoNotDefined: false,
      ),
    ),
  ];
}

Future<void> pumpCounselMilitaryTrainConfirmScreen(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
  required Game game,
  required AppEventBus bus,
  CounselTab initialTab = CounselTab.industry,
  CurrentOrdersNotifier? ordersNotifier,
  GameService? gameService,
  bool canMutateViaUi = true,
}) async {
  final playerId = game.players.first.id;
  await pumpAppShell(
    tester,
    overrides: counselMilitaryTrainConfirmOverrides(
      gamesBox: gamesBox,
      game: game,
      bus: bus,
      ordersNotifier: ordersNotifier,
      gameService: gameService,
      canMutateViaUi: canMutateViaUi,
    ),
    navigatorKey: appNavigatorKey,
    onGenerateRoute: Routes.generate,
    shellWrapper: (app) => AppEventHandlerScope(child: app),
    child: CounselScreen(
      game: game,
      humanPlayerId: playerId,
      initialTab: initialTab,
    ),
  );
  await pumpSettleCapped(tester);
}

Game buildCounselMilitaryTrainConfirmGame({required int peasants}) {
  const human = kPanelTestHumanPlayerId;
  const capProvince = 'oldWorld|cap';
  const unitType = 'peasant_levies';
  final econ = RegimentEconomyCatalog.byId[unitType]!;
  var stockpile = const Stockpile();
  for (final entry in econ.buildInputs.entries) {
    stockpile = stockpile.applyDelta(entry.key, entry.value * 4);
  }
  final techUnlocked = <String, bool>{
    for (final techId in unlockingTechByRegimentId.values) techId: true,
  };
  return buildPanelTestGame(
    id: kCounselMilitaryTrainConfirmGameId,
    players: [
      Player(
        id: human,
        displayName: 'Train GP',
        isHuman: true,
        capitalProvinceId: capProvince,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: capProvince,
          x: 0,
          y: 0,
        ),
        treasury: econ.buildTreasuryCost * 4,
        workerPool: WorkerPool(peasants: peasants),
        stockpile: stockpile,
        techUnlocked: techUnlocked,
      ),
    ],
    oldWorldProvinces: const [
      Province(
        id: capProvince,
        regionId: 'oldWorld',
        ownerId: human,
        townTileKey: 'oldWorld|cap|0|0',
      ),
    ],
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        capProvince: ['oldWorld|cap|0|0'],
      },
    },
  );
}
