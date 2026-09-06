import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show TileVisibility;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'map_view_provider_test_support.dart';
import 'app_test_hive_harness.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/config/constants.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'map_view_provider');
  });

  test('mapViewDataProvider reveals all tiles in global observe mode', () {
    const unrevealedTile = 'oldWorld|p1|0|0';
    final game = Game(
      id: 'g_map',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              displayName: 'OW P1',
              ownerId: 'gp1',
            ),
          ],
          units: const [],
        ),
        newWorld: const RegionData(),
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p1': [unrevealedTile],
          },
        },
        playerVisibilityByTile: const {
          'gp1': {unrevealedTile: 'unknown'},
        },
      ),
      players: const [
        Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        Player(id: 'gp2', displayName: 'France', isHuman: false),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => mapViewProviderShortcutHostMapService(gamesBox),
        ),
      ],
    );
    addTearDown(container.dispose);

    final constrained = container.read(mapViewDataProvider);
    expect(constrained, isNotNull);
    expect(
      constrained!.oldWorld.cellAt(0, 0).visibility,
      TileVisibility.unrevealed,
    );

    final observe = container.read(observeSessionProvider.notifier);
    final handedOff = observe.applyObserveHandoffIfNeeded(game);
    container.read(currentGameProvider.notifier).setGame(handedOff);
    observe.setModeGlobal();

    final globalObserve = container.read(mapViewDataProvider);
    expect(globalObserve, isNotNull);
    for (final cell in globalObserve!.oldWorld.cells) {
      expect(cell.visibility, TileVisibility.visible);
    }
    for (final cell in globalObserve.newWorld.cells) {
      expect(cell.visibility, TileVisibility.visible);
    }
  });

  test(
    'mapViewDataProvider includes non-human civilian markers in global observe',
    () {
      final game = Game(
        id: 'g_map',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
            ],
            units: [
              Unit(
                id: 'u_gp2',
                type: kUnitTypeBuilder,
                ownerId: 'gp2',
                locationProvinceId: 'oldWorld|p2',
                tileKey: 'oldWorld|p2|1|0',
                status: UnitStatus.idle,
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          currentGameProvider.overrideWith(CurrentGameNotifier.new),
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => mapViewProviderShortcutHostMapService(gamesBox),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(currentGameProvider.notifier).setGame(game);

      expect(
        container.read(mapViewDataProvider)!.oldWorld.civilianTileMarkers,
        isEmpty,
      );

      final observe = container.read(observeSessionProvider.notifier);
      final handedOff = observe.applyObserveHandoffIfNeeded(game);
      container.read(currentGameProvider.notifier).setGame(handedOff);
      observe.setModeGlobal();

      final markers = container
          .read(mapViewDataProvider)!
          .oldWorld
          .civilianTileMarkers;
      expect(markers, hasLength(1));
      expect(markers.single.tileKey, 'oldWorld|p2|1|0');
    },
  );
}
