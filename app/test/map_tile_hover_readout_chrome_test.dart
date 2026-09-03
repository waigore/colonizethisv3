// Pins MAP10001 owner/sight hover chrome (Refs #4406).
import 'package:colonizethis_app/features/game/flame/controls/map_tile_hover_readout.dart';
import 'package:colonizethis_app/features/game/flame/controls/map_tile_hover_readout_copy.dart';
import 'package:colonizethis_app/features/game/flame/map_area/game_map_canvas_stack_hover.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Game _hoverGame() {
  return const Game(
    id: 'hover_readout',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'France', isHuman: false, treasury: 0),
    ],
  );
}

RegionMapViewData _hoverRegion({
  required CellViewData cell,
  List<WarpMarkerView> warpMarkers = const [],
  Map<String, String> seaNames = const {},
}) {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 16,
    cells: [cell],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {'gp1', 'gp2'},
    terrainColors: const {},
    warpMarkers: warpMarkers,
    seaZoneDisplayNameByPrefixedId: seaNames,
  );
}

void main() {
  suppressLogsForTests();
  final game = _hoverGame();

  group('MapTileHoverReadout chrome', () {
    testWidgets('renders place owner and sight', (tester) async {
      await tester.pumpWidget(
        buildAppShell(
          child: const MapTileHoverReadout(
            copy: MapTileHoverReadoutCopy(
              placeLine: 'Place: Wessex',
              identityLine: 'Owner: England',
              sightLine: 'Sight: Fully visible',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(kMapTileHoverReadoutKey), findsOneWidget);
      expect(find.text('Place: Wessex'), findsOneWidget);
      expect(find.text('Owner: England'), findsOneWidget);
      expect(find.text('Sight: Fully visible'), findsOneWidget);
    });

    testWidgets('320 dp viewport does not overflow', (tester) async {
      await tester.pumpWidget(
        buildAppShell(
          viewport: const Size(320, 640),
          child: const SizedBox(
            width: 320,
            child: MapTileHoverReadout(
              copy: MapTileHoverReadoutCopy(
                placeLine: 'Place: Wessex',
                identityLine: 'Owner: England',
                sightLine: 'Sight: Fully visible',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(kMapTileHoverReadoutKey), findsOneWidget);
    });
  });

  group('GameMapCanvasStackHoverHost', () {
    testWidgets('shows readout on hover and hides in work-target mode', (
      tester,
    ) async {
      var selectionMode = false;
      late void Function(void Function()) setHostState;
      await tester.pumpWidget(
        buildAppShell(
          child: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return GameMapCanvasStackHoverHost(
                inWorkTargetSelectionMode: selectionMode,
                game: game,
                region: _hoverRegion(
                  cell: const CellViewData(
                    x: 0,
                    y: 0,
                    regionCellId: 'p1',
                    isSea: false,
                    ownerFactionId: 'gp1',
                    provinceDisplayName: 'Wessex',
                    visibility: TileVisibility.visible,
                  ),
                ),
                mapBuilder: (onTileHovered) {
                  return TextButton(
                    key: const Key('fake_map_hover'),
                    onPressed: () => onTileHovered('oldWorld|p1|0|0'),
                    child: const Text('hover'),
                  );
                },
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(kMapTileHoverReadoutKey), findsNothing);

      await tester.tap(find.byKey(const Key('fake_map_hover')));
      await tester.pump();
      expect(find.byKey(kMapTileHoverReadoutKey), findsOneWidget);
      expect(find.text('Place: Wessex'), findsOneWidget);

      setHostState(() => selectionMode = true);
      await tester.pump();
      expect(find.byKey(kMapTileHoverReadoutKey), findsNothing);
    });
  });
}
