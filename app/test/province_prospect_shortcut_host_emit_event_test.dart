// Pins the host-level Prospect-with-explorer *shortcut-assignment* tap flow for
// both province detail hosts (`GameMapProvinceDetailSidePanel` wide,
// `GameMapNarrowDetailOverlaySlot` narrow).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Tile inline actions — Prospect icon behavior:
//   "On tap, open Civilian Units panel in explorer-only shortcut mode targeting
//    prospect for the exact selected tile key."
// SPEC/ui/civilian-units-panel.md — explicit shortcut contract:
//   `prospectShortcutTargetTileKey` opens direct-assign `prospect`.
//
// Coverage gap closed here (Refs #2865):
//   - `province_overlay_tile_inline_action_non_clickable_test.dart` pins the
//     *overlay-level* callback contract (enabled fires / disabled does not).
//   - Neither asserts the *host wiring*: that tapping the enabled inline action
//     emits `OpenCivilianUnitsPanelEvent(explorerOnly: true,
//     prospectShortcutTargetTileKey: <exact tile key>)` on the app event bus.
//   - This file pins the positive path and the no-explorer negative.

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

const String _kGameId = 'g_prospect_shortcut_emit';
const String _kHumanPlayerId = 'gp1';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';

final MapTopology _combinedTopology = provinceShortcutHostCombinedTopology();
final Map<String, MapTopology> _topologyByRegion =
    provinceShortcutHostTopologyByRegion();

final Map<String, TileMapResult> _tileMapByRegion =
    provinceShortcutHostTileMapByRegion(
      terrainGrid: const [
        [TerrainType.hills],
      ],
      resourceGrid: const [
        [Resource.iron],
      ],
    );

Game _buildGame({required bool withExplorer}) {
  return Game(
    id: _kGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _kProvinceId,
            regionId: 'oldWorld',
            ownerId: _kHumanPlayerId,
          ),
        ],
        units: [
          if (withExplorer)
            Unit(
              id: 'u_explorer',
              type: kUnitTypeExplorer,
              ownerId: _kHumanPlayerId,
              locationProvinceId: _kProvinceId,
              tileKey: _kTileKey,
              status: UnitStatus.idle,
            ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {_kTileKey: 'iron'},
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
        capitalProvinceId: _kProvinceId,
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData _fullyVisibleRegion() {
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
        terrainType: TerrainType.hills,
        resourceId: 'iron',
        ownerFactionId: _kHumanPlayerId,
        provinceDisplayName: 'Test Province',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: {_kHumanPlayerId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      'oldWorld|p1': _kHumanPlayerId,
    },
  );
}

Finder _prospectAction({required bool enabledOnly}) {
  return find.byWidgetPredicate(
    (Widget w) =>
        w is CtIconAction &&
        w.icon == Icons.travel_explore &&
        (!enabledOnly || w.onPressed != null),
  );
}

void main() {
  suppressLogsForTests();

  test('prospect action state fixture is enabled for host wiring', () {
    final game = _buildGame(withExplorer: true);
    final playerView = buildPlayerView(
      game,
      _combinedTopology,
      _kHumanPlayerId,
    );
    final state =
        GameMapAreaStateLogicProvinceActions.provinceProspectActionState(
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
    Hive.init('./.dart_tool/test_hive_province_prospect_shortcut_emit');
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
    region: _fullyVisibleRegion(),
    combinedTopology: _combinedTopology,
    workTargetSelectionCache: refreshedProvinceShortcutWorkTargetCache(
      game: game,
      humanPlayerId: _kHumanPlayerId,
      combinedTopology: _combinedTopology,
      tileMapByRegion: _tileMapByRegion,
    ),
    selectedTileKey: _kTileKey,
  );

  Future<void> expectProspectShortcutEmits(
    WidgetTester tester, {
    required List<OpenCivilianUnitsPanelEvent> opened,
    required String hostLabel,
  }) async {
    final shortcut = _prospectAction(enabledOnly: true);
    expect(
      shortcut,
      findsOneWidget,
      reason:
          '$hostLabel must render an enabled Prospect inline action for a '
          'fully visible mineral tile with an Explorer unit.',
    );
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(opened, hasLength(1));
    final event = opened.single;
    expect(event.explorerOnly, isTrue);
    expect(event.builderOnly, isFalse);
    expect(event.prospectShortcutTargetTileKey, _kTileKey);
    expect(event.exploreShortcutTargetTileKey, isNull);
    expect(event.buildImprovementShortcutTargetTileKey, isNull);
  }

  for (final host in provinceShortcutHostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: tapping the enabled Prospect '
      'shortcut emits an explorer-only OpenCivilianUnitsPanelEvent targeting '
      'the exact selected tile key '
      '(SPEC § Tile inline actions — Prospect shortcut assignment)',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withExplorer: true),
          host: host,
        );
        await expectProspectShortcutEmits(
          tester,
          opened: opened,
          hostLabel: host.label,
        );
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host with no Explorer unit '
      'does not enable Prospect and emits no OpenCivilianUnitsPanelEvent',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withExplorer: false),
          // Narrow negative originally omitted selectTileTab; keep that when the
          // shortcut stays off so the assert does not depend on Tile-tab chrome.
          host: host.wide ? host : provinceShortcutHostCaseWithoutTileTab(host),
        );
        expect(_prospectAction(enabledOnly: true), findsNothing);
        if (host.wide) {
          final anyShortcut = _prospectAction(enabledOnly: false);
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
