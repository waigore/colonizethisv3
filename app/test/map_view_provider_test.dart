import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class _FakeGameService extends GameService {
  _FakeGameService(Box<dynamic> box, GameSaveAdapter adapter) : super(box, adapter);

  @override
  getMapData(String gameId) {
    return null;
  }
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_map_view_provider');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  test('mapViewDataProvider returns null when there is no current game', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final mapView = container.read(mapViewDataProvider);
    expect(mapView, isNull);
  });

  test('mapViewDataProvider returns null when GameService has no map data', () {
    final game = Game(
      id: 'g1',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(
          id: 'gp1',
          displayName: 'Human',
          isHuman: true,
          treasury: 0,
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        currentGameProvider.overrideWith((ref) => game),
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => _FakeGameService(gamesBox, GameSaveAdapter()),
        ),
      ],
    );
    addTearDown(container.dispose);

    final mapView = container.read(mapViewDataProvider);
    expect(mapView, isNull);
  });
}

