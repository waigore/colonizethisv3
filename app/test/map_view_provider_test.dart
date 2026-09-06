import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'map_view_provider_test_support.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'map_view_provider');
  });

  test('mapViewDataProvider returns null when there is no current game', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final mapView = container.read(mapViewDataProvider);
    expect(mapView, isNull);
  });

  test('mapViewDataProvider throws when GameService has no map data', () {
    final game = Game(
      id: 'g1',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => MapViewProviderFakeGameService(gamesBox, GameSaveAdapter()),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      () => container.read(mapViewDataProvider),
      throwsA(
        predicate(
          (e) =>
              e.toString().contains('Missing required map data for gameId=g1'),
        ),
      ),
    );
  });

  test(
    'mapViewDataProvider applies Game.greatPowerColorOverride (player id keys) to faction colors',
    () {
      const portugalRgb = (90, 160, 90);
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
          newWorld: RegionData(
            provinces: const [
              Province(
                id: 'newWorld|p1',
                regionId: 'newWorld',
                displayName: 'NW P1',
              ),
            ],
            units: const [],
          ),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
        ],
        minorNations: const [],
        tribes: const [],
        greatPowerColorOverride: {
          'gp1': [portugalRgb.$1, portugalRgb.$2, portugalRgb.$3],
        },
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

      final mapView = container.read(mapViewDataProvider);
      expect(mapView, isNotNull);
      expect(mapView!.oldWorld.factionColors['gp1'], portugalRgb);
      expect(mapView.newWorld.factionColors['gp1'], portugalRgb);
    },
  );
}
