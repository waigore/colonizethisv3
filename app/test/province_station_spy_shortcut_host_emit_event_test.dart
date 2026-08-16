// Pins host-level MAP20001 Station spy tap → OpenCivilianUnitsPanelEvent.
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md (Refs #4439).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/map_state/province_station_spy_action_state.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'province_shortcut_host_emit_test_support.dart';

const String _kGameId = 'g_station_spy_emit';
const String _kHumanPlayerId = 'gp1';
const String _kProvinceId = 'oldWorld|p1';
const String _kSpyTile = 'oldWorld|p1|0|0';
const String _kTargetTile = 'oldWorld|p1|1|0';

final MapTopology _combinedTopology = provinceShortcutHostCombinedTopology(
  includeSea: false,
);
final Map<String, MapTopology> _topologyByRegion =
    provinceShortcutHostTopologyByRegion(includeSea: false);

final Map<String, TileMapResult> _tileMapByRegion =
    provinceShortcutHostTileMapByRegion(
      width: 2,
      height: 1,
      grid: const [
        ['p1', 'p1'],
      ],
      terrainGrid: const [
        [TerrainType.plains, TerrainType.plains],
      ],
      resourceGrid: const [
        [Resource.grain, Resource.grain],
      ],
    );

Game _buildGame({required bool withSpy}) {
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
          if (withSpy)
            Unit(
              id: 'u_spy',
              type: kUnitTypeSpy,
              ownerId: _kHumanPlayerId,
              locationProvinceId: _kProvinceId,
              tileKey: _kSpyTile,
              status: UnitStatus.idle,
            ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {_kSpyTile: 'grain', _kTargetTile: 'grain'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          _kProvinceId: [_kSpyTile, _kTargetTile],
        },
      },
      playerVisibilityByTile: {
        _kHumanPlayerId: {
          _kSpyTile: 'fullyVisible',
          _kTargetTile: 'fullyVisible',
        },
      },
    ),
    players: [Player(id: _kHumanPlayerId, displayName: 'Human', isHuman: true)],
  );
}

RegionMapViewData _region() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 2,
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
        ownerFactionId: _kHumanPlayerId,
        provinceDisplayName: 'Home',
        visibility: TileVisibility.visible,
      ),
      CellViewData(
        x: 1,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainType: TerrainType.plains,
        resourceId: 'grain',
        ownerFactionId: _kHumanPlayerId,
        provinceDisplayName: 'Home',
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

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  test('station spy action state is enabled for host wiring', () {
    final game = _buildGame(withSpy: true);
    final resolved = computeProvinceStationSpyActionState(
      game: game,
      orders: const Orders(),
      humanPlayerId: _kHumanPlayerId,
      selectedTileKey: _kTargetTile,
      canMutateViaUi: true,
      isSeaZone: false,
      tileObfuscated: false,
      civilianSectionObfuscated: false,
    );
    expect(resolved.showControl, isTrue);
    expect(resolved.enabled, isTrue);
  });

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_station_spy_shortcut_emit');
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
    host: (
      label: host.label,
      hostType: host.hostType,
      surfaceSize: host.surfaceSize,
      selectTileTab: false,
      wide: host.wide,
    ),
    region: _region(),
    combinedTopology: _combinedTopology,
    workTargetSelectionCache: refreshedProvinceShortcutWorkTargetCache(
      game: game,
      humanPlayerId: _kHumanPlayerId,
      combinedTopology: _combinedTopology,
      tileMapByRegion: _tileMapByRegion,
    ),
    selectedTileKey: _kTargetTile,
  );

  Future<void> revealCivilianSection(
    WidgetTester tester, {
    required bool wide,
  }) async {
    if (wide) return;
    final tab = find.text('Civilian');
    await tester.scrollUntilVisible(
      tab,
      48,
      scrollable: find.descendant(
        of: find.byType(CtTabStrip),
        matching: find.byWidgetPredicate((Widget w) {
          if (w is! Scrollable) return false;
          return w.axisDirection == AxisDirection.right ||
              w.axisDirection == AxisDirection.left;
        }),
      ),
    );
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  for (final host in provinceShortcutHostCases) {
    testWidgets('${host.label} Station spy emits spyOnly Relocate shortcut', (
      tester,
    ) async {
      final opened = await pumpHostAndSelect(
        tester,
        game: _buildGame(withSpy: true),
        host: host,
      );
      await revealCivilianSection(tester, wide: host.wide);
      final button = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_stationSpyAction,
      );
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(opened, hasLength(1));
      final event = opened.single;
      expect(event.spyOnly, isTrue);
      expect(event.relocateShortcutTargetTileKey, _kTargetTile);
      expect(event.explorerOnly, isFalse);
      expect(event.merchantOnly, isFalse);
      expect(event.exploreShortcutTargetTileKey, isNull);
      expect(event.purchaseLandShortcutTargetTileKey, isNull);
    });

    testWidgets(
      '${host.label} without a Spy does not emit OpenCivilianUnitsPanelEvent',
      (tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: _buildGame(withSpy: false),
          host: host,
        );
        await revealCivilianSection(tester, wide: host.wide);
        final button = find.widgetWithText(
          CtActionTextButton,
          l10n.provinceOverlay_stationSpyAction,
        );
        expect(button, findsOneWidget);
        final action = tester.widget<CtActionTextButton>(button);
        expect(action.enabled, isFalse);
        expect(action.onPressed, isNull);
        expect(opened, isEmpty);
      },
    );
  }
}
