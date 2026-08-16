// Golden + widget checks for MAP20001 Purchase land shortcut (Refs #4274).
// Wide side panel uses a pixel golden; narrow host asserts the shortcut icon
// (avoids fragile cross-engine golden drift on CI).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_app/features/game/flame/caches/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'golden_capture_harness.dart';
import 'province_shortcut_host_emit_fixtures.dart';

const String _kMinorId = 'minor1';

final MapTopology _goldenCombinedTopology =
    provinceShortcutHostCombinedTopology();

class _GameServicePurchaseLandGolden extends GameService {
  _GameServicePurchaseLandGolden(super.box, super.adapter);

  static final Map<String, MapTopology> _topologyByRegion =
      provinceShortcutHostTopologyByRegion();

  static final Map<String, TileMapResult> _tileMapByRegion =
      provinceShortcutHostTileMapByRegion();

  @override
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String gameId) {
    if (gameId != 'g_pl_golden') return null;
    return (
      combinedTopology: _goldenCombinedTopology,
      tileMapByRegion: _tileMapByRegion,
      topologyByRegion: _topologyByRegion,
      warpLinks: null,
    );
  }
}

Game goldenPurchaseLandGame() {
  const humanPlayerId = 'gp1';
  const provinceId = 'oldWorld|p1';
  const tileKey = 'oldWorld|p1|0|0';
  return Game(
    id: 'g_pl_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: 'oldWorld', ownerId: _kMinorId),
        ],
        units: [
          Unit(
            id: 'u_merchant',
            type: kUnitTypeMerchant,
            ownerId: humanPlayerId,
            locationProvinceId: provinceId,
            tileKey: tileKey,
            status: UnitStatus.idle,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {tileKey: 'grain'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          provinceId: [tileKey],
        },
      },
      playerVisibilityByTile: {
        humanPlayerId: {tileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: humanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: 'oldWorld|home',
        treasury: 500,
        techUnlocked: const {kTechIdMerchantCompanies: true},
      ),
    ],
    minorNations: const [MinorNation(id: _kMinorId, displayName: 'Minor 1')],
    tribes: const [],
    overtureStates: const [
      OvertureState(
        gpId: humanPlayerId,
        targetId: _kMinorId,
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
}

RegionMapViewData goldenPurchaseLandRegion() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 16,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainType: TerrainType.plains,
        resourceId: 'grain',
        ownerFactionId: _kMinorId,
        provinceDisplayName: 'Minor Province',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: {'gp1'},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      'oldWorld|p1': _kMinorId,
    },
  );
}

PerPlayerWorkTargetSelectionCache _buildSelectionCache({
  required Game game,
  required String playerId,
  required PlayerView playerView,
}) {
  final cache = PerPlayerWorkTargetSelectionCache();
  cache.refresh(
    WorkTargetSelectionSnapshot(
      game: game,
      playerId: playerId,
      playerView: playerView,
      topology: _goldenCombinedTopology,
      currentOrders: const Orders(),
      tileMapByRegion: _GameServicePurchaseLandGolden._tileMapByRegion,
    ),
  );
  return cache;
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_pl_golden');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Future<void> pumpWideHost(WidgetTester tester) async {
    final game = goldenPurchaseLandGame();
    final region = goldenPurchaseLandRegion();
    final playerId = game.players.first.id;
    final playerView = buildPlayerView(game, _goldenCombinedTopology, playerId);
    const tileKey = 'oldWorld|p1|0|0';
    const boundaryKey = ValueKey('province_pl_shortcut_wide_golden');

    await configureGoldenSurface(tester, size: const Size(360, 720));
    await tester.pumpWidget(
      wrapGoldenBoundary(
        boundaryKey: boundaryKey,
        wrapInProviderScope: true,
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) =>
                _GameServicePurchaseLandGolden(gamesBox, GameSaveAdapter()),
          ),
          appEventBusProvider.overrideWith((ref) => AppEventBus.create()),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
        ],
        child: SizedBox(
          width: 320,
          child: GameMapProvinceDetailSidePanel(
            game: game,
            region: region,
            humanPlayerId: playerId,
            playerView: playerView,
            workTargetSelectionCache: _buildSelectionCache(
              game: game,
              playerId: playerId,
              playerView: playerView,
            ),
          ),
        ),
      ),
    );
    final ctx = tester.element(find.byType(GameMapProvinceDetailSidePanel));
    final container = ProviderScope.containerOf(ctx);
    container
        .read(mapProvincePanelProvider.notifier)
        .reportMapTileTapped(tileKey);
    await pumpForGolden(tester);
  }

  Future<void> pumpNarrowHost(WidgetTester tester) async {
    final game = goldenPurchaseLandGame();
    final region = goldenPurchaseLandRegion();
    final playerId = game.players.first.id;
    final playerView = buildPlayerView(game, _goldenCombinedTopology, playerId);
    final workTargetSelectionCache = _buildSelectionCache(
      game: game,
      playerId: playerId,
      playerView: playerView,
    );
    const tileKey = 'oldWorld|p1|0|0';
    const boundaryKey = ValueKey('province_pl_shortcut_narrow_golden');

    await configureGoldenSurface(tester, size: const Size(400, 600));
    await tester.pumpWidget(
      wrapGoldenBoundary(
        boundaryKey: boundaryKey,
        center: false,
        alignment: Alignment.bottomCenter,
        wrapInProviderScope: true,
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) =>
                _GameServicePurchaseLandGolden(gamesBox, GameSaveAdapter()),
          ),
          appEventBusProvider.overrideWith((ref) => AppEventBus.create()),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
        ],
        child: GameMapNarrowDetailOverlaySlot(
          game: game,
          region: region,
          humanPlayerId: playerId,
          playerView: playerView,
          workTargetSelectionCache: workTargetSelectionCache,
        ),
      ),
    );
    final ctx = tester.element(find.byType(GameMapNarrowDetailOverlaySlot));
    final container = ProviderScope.containerOf(ctx);
    container
        .read(mapProvincePanelProvider.notifier)
        .reportMapTileTapped(tileKey);
    await pumpForGolden(tester);
    final tileTab = find.text('Tile');
    if (tileTab.evaluate().isNotEmpty) {
      await tester.tap(tileTab);
      await pumpForGolden(tester);
    }
  }

  testWidgets(
    'golden: wide province side panel shows enabled Purchase land shortcut (Refs #4274)',
    (WidgetTester tester) async {
      await pumpWideHost(tester);
      await expectLater(
        find.byKey(const ValueKey('province_pl_shortcut_wide_golden')),
        matchesGoldenFile('goldens/province_purchase_land_wide_panel.png'),
      );
    },
  );

  testWidgets(
    'narrow detail overlay shows enabled Purchase land shortcut (Refs #4274)',
    (WidgetTester tester) async {
      await pumpNarrowHost(tester);
      final purchaseLandShortcut = find.byWidgetPredicate(
        (Widget w) =>
            w is CtIconAction &&
            w.onPressed != null &&
            w.icon == Icons.payments,
      );
      expect(purchaseLandShortcut, findsOneWidget);
    },
  );
}
