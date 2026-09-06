// Shared map-backed fixtures for Development panel layout/golden tests (Refs #4175).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'development_panel_map_game_service.dart';
import 'panel_fixtures/core.dart';

Game buildDevelopmentPanelGoldenGame() {
  const human = kPanelTestHumanPlayerId;
  const p1 = 'oldWorld|p1';
  const p2 = 'oldWorld|p2';
  const tileA = 'oldWorld|p1|0|0';
  const tileB = 'oldWorld|p1|1|0';
  const tileP2 = 'oldWorld|p2|0|1';

  final base = buildPanelTestGame(
    id: kDevelopmentPanelMapTestGameId,
    players: [
      Player(
        id: human,
        displayName: 'England',
        isHuman: true,
        capitalProvinceId: p1,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'p1',
          x: 0,
          y: 0,
        ),
        stockpile: const Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
        techUnlocked: const {kTechIdCircularSaw: true},
      ),
    ],
    oldWorldProvinces: const [
      Province(
        id: p1,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Avalon',
        townTileKey: tileA,
      ),
      Province(
        id: p2,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Barren',
        townTileKey: tileP2,
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: tileA,
        status: UnitStatus.idle,
      ),
      Unit(
        id: 'e1',
        type: kUnitTypeEngineer,
        ownerId: human,
        locationProvinceId: p1,
        tileKey: tileA,
        status: UnitStatus.idle,
      ),
    ],
    tileKeysByRegionAndProvince: {
      'oldWorld': {
        p1: [tileA, tileB],
        p2: [tileP2],
      },
    },
    resourceByTileKey: {
      tileA: 'grain',
      tileB: 'grain',
    },
    playerVisibilityByTile: {
      human: {
        tileA: 'fullyVisible',
        tileB: 'fullyVisible',
        tileP2: 'fullyVisible',
      },
    },
  );

  return base.copyWith(
    worldState: base.worldState.copyWith(
      tileState: const TileMapState(
        improvementByTile: {
          tileA: 0,
          tileB: 0,
        },
      ),
    ),
  );
}

Future<Box<dynamic>> openDevelopmentPanelTestHiveBox({
  required String suiteId,
}) async {
  return openAppTestHiveBox(suiteId: 'development_panel_$suiteId');
}

Future<void> pumpDevelopmentPanelReady(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

ShellPlayerContext developmentPanelProjectionShellContext() {
  return const ShellPlayerContext(
    effectiveHumanPlayerId: kPanelTestHumanPlayerId,
    viewingPlayerId: kPanelTestHumanPlayerId,
    mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
    playerView: null,
    omniscientDetail: false,
    showPlayerChrome: true,
    canMutateViaUi: true,
    debugCommandTargetPlayerId: kPanelTestHumanPlayerId,
    inObservePhase: false,
    observeBannerLabel: null,
    treasuryNotDefined: false,
    cargoNotDefined: false,
  );
}

List<Override> developmentPanelProjectionProviderOverrides(
  Game game, {
  CurrentOrdersNotifier? ordersNotifier,
}) {
  return [
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(
      () => ordersNotifier ?? CurrentOrdersNotifier(const Orders()),
    ),
    shellPlayerContextProvider.overrideWithValue(
      developmentPanelProjectionShellContext(),
    ),
    gameServiceProvider.overrideWith(
      (ref) => DevelopmentPanelMapGameService(
        Hive.box<dynamic>(HiveBoxNames.games),
        GameSaveAdapter(),
      ),
    ),
  ];
}
