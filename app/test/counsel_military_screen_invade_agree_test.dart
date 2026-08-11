// Counsel screen Military invade Agree integration (Refs #4307).
// SPEC/ui/counsel-panel.md — at-war move without declare-war dialog.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/counsel/counsel_screen.dart';
import 'package:colonizethis_app/features/game/screens/counsel/counsel_screen_tabs.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'panel_fixtures/core.dart';
import 'widget_test_pumps.dart';

const _counselMilitaryInvadeGameId = 'counsel-military-invade-screen-test';
const _rivalId = 'gp2';
const _fromProvince = 'oldWorld|p1';
const _invadeProvince = 'oldWorld|p2';

final MapTopology _counselMilitaryInvadeTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: _fromProvince,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: _invadeProvince,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [
    TopologyEdge(id1: _fromProvince, id2: _invadeProvince),
  ],
);

class CounselMilitaryInvadeMapGameService extends GameService {
  CounselMilitaryInvadeMapGameService(super.box, super.adapter);

  @override
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String gameId) {
    if (gameId != _counselMilitaryInvadeGameId) return null;
    return (
      combinedTopology: _counselMilitaryInvadeTopology,
      tileMapByRegion: const {},
      topologyByRegion: const {},
      warpLinks: null,
    );
  }
}

Game buildCounselMilitaryInvadeScreenGame({required bool atWar}) {
  const human = kPanelTestHumanPlayerId;
  final armyId = fieldArmyIdFor(human, _fromProvince);
  return buildPanelTestGame(
    id: _counselMilitaryInvadeGameId,
    players: [
      Player(
        id: human,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: _fromProvince,
        stockpile: const Stockpile()
            .applyDelta('grain', 20)
            .applyDelta('meat', 20),
      ),
      const Player(id: _rivalId, displayName: 'Rival', isHuman: false),
    ],
    oldWorldProvinces: const [
      Province(
        id: _fromProvince,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Origin',
      ),
      Province(
        id: _invadeProvince,
        regionId: 'oldWorld',
        ownerId: _rivalId,
        displayName: 'Enemy Border',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'u1',
        type: kPanelTestRegimentType,
        ownerId: human,
        locationProvinceId: _fromProvince,
      ),
    ],
    armies: [
      Army(
        id: armyId,
        ownerId: human,
        regionId: 'oldWorld',
        stationedProvinceId: _fromProvince,
        regimentUnitIds: const ['u1'],
        isHomeArmy: false,
      ),
    ],
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        _fromProvince: ['oldWorld|p1|0|0'],
        _invadeProvince: ['oldWorld|p2|0|0'],
      },
    },
    playerVisibilityByTile: const {
      human: {
        'oldWorld|p1|0|0': 'fullyVisible',
        'oldWorld|p2|0|0': 'fullyVisible',
      },
    },
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: human,
        factionId2: _rivalId,
        state: atWar ? RelationState.atWar : RelationState.atPeace,
        score: atWar ? 20 : 50,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
    ],
  );
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_counsel_military_invade_agree');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  List<Override> counselInvadeOverrides({
    required Game game,
    required AppEventBus bus,
  }) {
    final playerId = game.players.first.id;
    return [
      gamesBoxProvider.overrideWith((ref) => gamesBox),
      gameServiceProvider.overrideWith(
        (ref) => CounselMilitaryInvadeMapGameService(gamesBox, GameSaveAdapter()),
      ),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(CurrentOrdersNotifier.new),
      appEventBusProvider.overrideWith((ref) => bus),
      shellPlayerContextProvider.overrideWithValue(
        ShellPlayerContext(
          effectiveHumanPlayerId: playerId,
          viewingPlayerId: playerId,
          mapVisibilityMode: CtMapVisibilityMode.full,
          playerView: null,
          omniscientDetail: false,
          showPlayerChrome: true,
          canMutateViaUi: true,
          debugCommandTargetPlayerId: playerId,
          inObservePhase: false,
          observeBannerLabel: null,
          treasuryNotDefined: false,
          cargoNotDefined: false,
        ),
      ),
    ];
  }

  Future<void> pumpCounselMilitaryScreen(
    WidgetTester tester, {
    required ProviderContainer container,
    required Game game,
    required AppEventBus bus,
  }) async {
    final playerId = game.players.first.id;
    await pumpAppShellWithContainer(
      tester,
      container: container,
      navigatorKey: appNavigatorKey,
      onGenerateRoute: Routes.generate,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: CounselScreen(
        game: game,
        humanPlayerId: playerId,
        initialTab: CounselTab.military,
      ),
    );
    await pumpSettleCapped(tester);
  }

  Finder invadeAgreeFinder(String armyId) {
    return find.byKey(
      ValueKey<String>('counsel_agree_military_invade_invade:$armyId:$_invadeProvince'),
    );
  }

  testWidgets(
    'at-war invade Agree stages army move without declare-war dialog (Refs #4307)',
    (WidgetTester tester) async {
      const human = kPanelTestHumanPlayerId;
      final game = buildCounselMilitaryInvadeScreenGame(atWar: true);
      final armyId = fieldArmyIdFor(human, _fromProvince);
      final bus = AppEventBus.create();
      final container = ProviderContainer(
        overrides: counselInvadeOverrides(game: game, bus: bus),
      );
      addTearDown(container.dispose);

      await pumpCounselMilitaryScreen(
        tester,
        container: container,
        game: game,
        bus: bus,
      );

      final agree = invadeAgreeFinder(armyId);
      expect(agree, findsOneWidget);

      await tester.tap(agree);
      await pumpSettleCapped(tester);

      expect(find.text('Declare war?'), findsNothing);

      final orders = container.read(currentOrdersProvider);
      final moves = orders.armyMoveOrdersByPlayerId[human] ?? const [];
      expect(moves, hasLength(1));
      expect(moves.single.armyId, armyId);
      expect(moves.single.destinationProvinceId, _invadeProvince);
      expect(orders.diplomaticOrdersByPlayerId[human], isNull);
    },
  );

  testWidgets(
    'peace invade Agree shows declare-war dialog before staging (Refs #4307)',
    (WidgetTester tester) async {
      const human = kPanelTestHumanPlayerId;
      final game = buildCounselMilitaryInvadeScreenGame(atWar: false);
      final armyId = fieldArmyIdFor(human, _fromProvince);
      final bus = AppEventBus.create();
      final container = ProviderContainer(
        overrides: counselInvadeOverrides(game: game, bus: bus),
      );
      addTearDown(container.dispose);

      await pumpCounselMilitaryScreen(
        tester,
        container: container,
        game: game,
        bus: bus,
      );

      final agree = invadeAgreeFinder(armyId);
      expect(agree, findsOneWidget);

      await tester.tap(agree);
      await pumpSettleCapped(tester);

      expect(find.text('Declare war?'), findsOneWidget);

      await tester.tap(find.text('Declare war and move'));
      await pumpSettleCapped(tester);

      final orders = container.read(currentOrdersProvider);
      final diplo = orders.diplomaticOrdersByPlayerId[human] ?? const [];
      expect(diplo, hasLength(1));
      expect(diplo.single.type, DiplomaticOrderType.declareWar);
      expect(diplo.single.targetFactionId, _rivalId);

      final moves = orders.armyMoveOrdersByPlayerId[human] ?? const [];
      expect(moves, hasLength(1));
      expect(moves.single.destinationProvinceId, _invadeProvince);
    },
  );
}
