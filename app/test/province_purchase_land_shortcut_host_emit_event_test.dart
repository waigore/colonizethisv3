// Pins the host-level Purchase land *shortcut-assignment* tap flow for
// both province detail hosts (`GameMapProvinceDetailSidePanel` wide,
// `GameMapNarrowDetailOverlaySlot` narrow).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Tile inline actions — Purchase land icon behavior:
//   On tap, open Civilian Units panel in merchant-only shortcut mode targeting
//   purchase_land for the exact selected tile key.
// SPEC/ui/civilian-units-panel.md — explicit shortcut contract:
//   `purchaseLandShortcutTargetTileKey` opens direct-assign `purchase_land`.
//
// Coverage gap closed here (Refs #4274):
//   - `province_overlay_tile_inline_action_non_clickable_test.dart` pins the
//     *overlay-level* callback contract (enabled fires / disabled does not).
//   - This file pins the *host wiring*: that tapping the enabled inline action
//     emits `OpenCivilianUnitsPanelEvent(merchantOnly: true,
//     purchaseLandShortcutTargetTileKey: <exact tile key>)` on the app event
//     bus, plus the no-Merchant negative.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'province_shortcut_host_emit_test_support.dart';

const String _kGameId = 'g_pl_shortcut_emit';
const String _kHumanPlayerId = 'gp1';
const String _kMinorId = 'minor1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';

final MapTopology _combinedTopology = provinceShortcutHostCombinedTopology();
final Map<String, MapTopology> _topologyByRegion =
    provinceShortcutHostTopologyByRegion();

final Map<String, TileMapResult> _tileMapByRegion =
    provinceShortcutHostTileMapByRegion();

Game _buildGame({required bool withMerchant}) {
  return Game(
    id: _kGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: _kProvinceId, regionId: 'oldWorld', ownerId: _kMinorId),
        ],
        units: [
          if (withMerchant)
            Unit(
              id: 'u_merchant',
              type: kUnitTypeMerchant,
              ownerId: _kHumanPlayerId,
              locationProvinceId: _kProvinceId,
              tileKey: _kTileKey,
              status: UnitStatus.idle,
            ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {_kTileKey: 'grain'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          _kProvinceId: [_kTileKey],
        },
      },
      playerVisibilityByTile: {
        _kHumanPlayerId: {_kTileKey: 'fullyVisible'},
      },
    ),
    players: [
      Player(
        id: _kHumanPlayerId,
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
        gpId: _kHumanPlayerId,
        targetId: _kMinorId,
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
}

RegionMapViewData _region() {
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
    greatPowerFactionIds: {_kHumanPlayerId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      'oldWorld|p1': _kMinorId,
    },
  );
}

Finder _purchaseLandAction({required bool enabledOnly}) {
  return find.byWidgetPredicate(
    (Widget w) =>
        w is CtIconAction &&
        w.icon == Icons.payments &&
        (!enabledOnly || w.onPressed != null),
  );
}

void main() {
  suppressLogsForTests();

  test('purchase land action state fixture is enabled for host wiring', () {
    final game = _buildGame(withMerchant: true);
    final playerView = buildPlayerView(
      game,
      _combinedTopology,
      _kHumanPlayerId,
    );
    final state =
        GameMapAreaStateLogicProvinceActions.provincePurchaseLandActionState(
          game: game,
          humanPlayerId: _kHumanPlayerId,
          selectedTileKey: _kTileKey,
          playerView: playerView,
          topology: _combinedTopology,
          currentOrders: const Orders(),
          tileMapByRegion: _tileMapByRegion,
        );
    expect(state.showIcon, isTrue);
    expect(state.enabled, isTrue);
  });

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_pl_shortcut_emit');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Future<List<OpenCivilianUnitsPanelEvent>> pumpHostAndSelect(
    WidgetTester tester, {
    required Game game,
    required ProvinceShortcutHostCase host,
  }) => pumpProvinceShortcutHostAndSelect(
    tester,
    gamesBox: gamesBox,
    gameService: provinceShortcutHostEmitGameService(
      gamesBox: gamesBox,
      gameId: _kGameId,
      combinedTopology: _combinedTopology,
      tileMapByRegion: _tileMapByRegion,
      topologyByRegion: _topologyByRegion,
    ),
    game: game,
    humanPlayerId: _kHumanPlayerId,
    host: host,
    region: _region(),
    combinedTopology: _combinedTopology,
    workTargetSelectionCache: refreshedProvinceShortcutWorkTargetCache(
      game: game,
      humanPlayerId: _kHumanPlayerId,
      combinedTopology: _combinedTopology,
      tileMapByRegion: _tileMapByRegion,
    ),
    selectedTileKey: _kTileKey,
  );

  Future<void> expectPurchaseLandShortcutEmits(
    WidgetTester tester, {
    required List<OpenCivilianUnitsPanelEvent> opened,
    required String hostLabel,
  }) async {
    final shortcut = _purchaseLandAction(enabledOnly: true);
    expect(
      shortcut,
      findsOneWidget,
      reason:
          '$hostLabel must render an enabled Purchase land inline action for a '
          'valid Merchant + embassy Minor resource tile.',
    );
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(
      opened,
      hasLength(1),
      reason:
          'Tapping the enabled Purchase land shortcut must open the Civilian '
          'Units panel exactly once via OpenCivilianUnitsPanelEvent.',
    );
    final event = opened.single;
    expect(event.merchantOnly, isTrue);
    expect(event.explorerOnly, isFalse);
    expect(event.builderOnly, isFalse);
    expect(event.engineerOnly, isFalse);
    expect(event.purchaseLandShortcutTargetTileKey, _kTileKey);
    expect(event.exploreShortcutTargetTileKey, isNull);
    expect(event.prospectShortcutTargetTileKey, isNull);
    expect(event.buildImprovementShortcutTargetTileKey, isNull);
    expect(event.buildRoadShortcutTargetTileKey, isNull);
  }

  for (final host in provinceShortcutHostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: tapping the enabled Purchase '
      'land shortcut emits a merchant-only OpenCivilianUnitsPanelEvent '
      'targeting the exact selected tile key (SPEC § Tile inline actions — '
      'Purchase land shortcut assignment)',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withMerchant: true),
          host: host,
        );
        await expectPurchaseLandShortcutEmits(
          tester,
          opened: opened,
          hostLabel: host.label,
        );
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host with no Merchant unit '
      'does not enable Purchase land and emits no '
      'OpenCivilianUnitsPanelEvent',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withMerchant: false),
          host: host.wide ? host : provinceShortcutHostCaseWithoutTileTab(host),
        );
        expect(_purchaseLandAction(enabledOnly: true), findsNothing);
        if (host.wide) {
          final anyShortcut = _purchaseLandAction(enabledOnly: false);
          if (anyShortcut.evaluate().isNotEmpty) {
            await tester.tap(anyShortcut.first, warnIfMissed: false);
            await tester.pump();
          }
        }
        expect(opened, isEmpty);
      },
    );
  }
}
