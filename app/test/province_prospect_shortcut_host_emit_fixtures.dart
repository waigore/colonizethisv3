// Prospect shortcut host fixtures (Refs #4734 Slice H).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_shortcut_host_emit_test_support.dart';

const String kProspectShortcutEmitGameId = 'g_prospect_shortcut_emit';
const String kProspectShortcutEmitHumanPlayerId = 'gp1';
const String kProspectShortcutEmitProvinceId = 'oldWorld|p1';
const String kProspectShortcutEmitTileKey = 'oldWorld|p1|0|0';

final MapTopology kProspectShortcutEmitCombinedTopology =
    provinceShortcutHostCombinedTopology();
final Map<String, MapTopology> kProspectShortcutEmitTopologyByRegion =
    provinceShortcutHostTopologyByRegion();
final Map<String, TileMapResult> kProspectShortcutEmitTileMapByRegion =
    provinceShortcutHostTileMapByRegion(
      terrainGrid: const [
        [TerrainType.hills],
      ],
      resourceGrid: const [
        [Resource.iron],
      ],
    );

Game buildProspectShortcutEmitGame({required bool withExplorer}) {
  return Game(
    id: kProspectShortcutEmitGameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: kProspectShortcutEmitProvinceId,
            regionId: 'oldWorld',
            ownerId: kProspectShortcutEmitHumanPlayerId,
          ),
        ],
        units: [
          if (withExplorer)
            Unit(
              id: 'u_explorer',
              type: kUnitTypeExplorer,
              ownerId: kProspectShortcutEmitHumanPlayerId,
              locationProvinceId: kProspectShortcutEmitProvinceId,
              tileKey: kProspectShortcutEmitTileKey,
              status: UnitStatus.idle,
            ),
        ],
      ),
      newWorld: const RegionData(provinces: [], units: []),
      resourceByTileKey: const {kProspectShortcutEmitTileKey: 'iron'},
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          kProspectShortcutEmitProvinceId: [kProspectShortcutEmitTileKey],
        },
      },
      playerVisibilityByTile: {
        kProspectShortcutEmitHumanPlayerId: {
          kProspectShortcutEmitTileKey: 'fullyVisible',
        },
      },
    ),
    players: [
      Player(
        id: kProspectShortcutEmitHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: kProspectShortcutEmitProvinceId,
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData prospectShortcutEmitFullyVisibleRegion() {
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
        ownerFactionId: kProspectShortcutEmitHumanPlayerId,
        provinceDisplayName: 'Test Province',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: {kProspectShortcutEmitHumanPlayerId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {
      'oldWorld|p1': kProspectShortcutEmitHumanPlayerId,
    },
  );
}

Finder prospectShortcutActionFinder({required bool enabledOnly}) {
  return find.byWidgetPredicate(
    (Widget w) =>
        w is CtIconAction &&
        w.icon == Icons.travel_explore &&
        (!enabledOnly || w.onPressed != null),
  );
}

Future<void> expectProspectShortcutTapEmits(
  WidgetTester tester, {
  required List<OpenCivilianUnitsPanelEvent> opened,
  required String hostLabel,
}) async {
  final shortcut = prospectShortcutActionFinder(enabledOnly: true);
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
  expect(event.prospectShortcutTargetTileKey, kProspectShortcutEmitTileKey);
  expect(event.exploreShortcutTargetTileKey, isNull);
  expect(event.buildImprovementShortcutTargetTileKey, isNull);
}
