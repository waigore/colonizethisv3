// Widget tests for Victory political minimap inspect. SPEC/ui/victory-panel.md.

import 'package:colonizethis_app/features/game/screens/victory/victory_political_minimap.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_keys.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_fixtures/core.dart';
import 'widget_test_pumps.dart';

RegionMapViewData _sampleRegion() {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 2,
    height: 2,
    cellSize: 8,
    cells: [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        ownerFactionId: 'gp1',
      ),
      CellViewData(
        x: 1,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        ownerFactionId: 'gp1',
      ),
      CellViewData(x: 0, y: 1, regionCellId: 'sea1', isSea: true),
      CellViewData(
        x: 1,
        y: 1,
        regionCellId: 'p2',
        isSea: false,
        ownerFactionId: 'gp2',
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: {
      'gp1': (180, 80, 80),
      'gp2': (80, 80, 180),
    },
    greatPowerFactionIds: {'gp1', 'gp2'},
    terrainColors: const {},
    unitMarkers: const [],
    civilianTileMarkers: const [],
    fleetTileMarkers: const [],
    warpMarkers: const [],
    townMarkers: const [],
    provinceUnitPresenceByProvinceId: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {},
    seaZoneDisplayNameByPrefixedId: const {},
  );
}

void main() {
  suppressLogsForTests();

  testWidgets('tap on land province shows origin inspect line', (tester) async {
    final game = buildPanelTestGame(
      players: [
        panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
        const Player(id: 'gp2', displayName: 'France', isHuman: false),
      ],
      oldWorldProvinces: const [
        Province(
          id: 'oldWorld|p2',
          regionId: 'oldWorld',
          ownerId: 'gp2',
          originalOwnerId: 'gp1',
          displayName: 'Yorkshire',
        ),
      ],
    );
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: SizedBox(
            width: 120,
            height: 280,
            child: VictoryPoliticalMinimap(
              game: game,
              region: _sampleRegion(),
            ),
          ),
        ),
      ),
    );
    await pumpSettleCapped(tester);

    final gesture = find.byKey(VictoryScreenKeys.politicalMinimapGestureKey);
    final topLeft = tester.getTopLeft(gesture);
    final size = tester.getSize(gesture);
    await tester.tapAt(
      topLeft + Offset(size.width * 0.75, size.height * 0.75),
    );
    await pumpSyncFrames(tester);

    expect(
      find.byKey(VictoryScreenKeys.politicalMinimapInspectKey),
      findsOneWidget,
    );
    expect(find.textContaining('captured from England'), findsOneWidget);
  });

  testWidgets('tap GP-owned province selects owning Great Power', (tester) async {
    String? selectedId;
    final game = buildPanelTestGame(
      players: [
        panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
        const Player(id: 'gp2', displayName: 'France', isHuman: false),
      ],
      oldWorldProvinces: const [
        Province(
          id: 'oldWorld|p2',
          regionId: 'oldWorld',
          ownerId: 'gp2',
          originalOwnerId: 'gp1',
          displayName: 'Yorkshire',
        ),
      ],
    );
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: SizedBox(
            width: 120,
            height: 280,
            child: VictoryPoliticalMinimap(
              game: game,
              region: _sampleRegion(),
              selectedPlayerId: 'gp1',
              onGreatPowerOwnerSelected: (id) => selectedId = id,
            ),
          ),
        ),
      ),
    );
    await pumpSettleCapped(tester);

    final gesture = find.byKey(VictoryScreenKeys.politicalMinimapGestureKey);
    final topLeft = tester.getTopLeft(gesture);
    final size = tester.getSize(gesture);
    await tester.tapAt(
      topLeft + Offset(size.width * 0.75, size.height * 0.75),
    );
    await pumpSyncFrames(tester);

    expect(selectedId, 'gp2');
  });
}
