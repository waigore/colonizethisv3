// Integration tests for productionDesiredOutputProvider + mapping helpers.
// SPEC/ui/production-panel.md.

import 'dart:convert';
import 'dart:typed_data';

import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _SeededProductionDesiredOutputNotifier
    extends ProductionDesiredOutputNotifier {
  _SeededProductionDesiredOutputNotifier(this._initial);

  final Map<String, int> _initial;

  @override
  Map<String, int> build() => _initial;
}

class _MapBackedGameService extends GameService {
  _MapBackedGameService(
    super.box,
    super.adapter, {
    required this.expectedGameId,
    required this.mapData,
  });

  final String expectedGameId;
  final ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })
  mapData;
  int getMapDataCallCount = 0;

  @override
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String gameId) {
    getMapDataCallCount += 1;
    if (gameId != expectedGameId) return null;
    return mapData;
  }
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> gamesBox;

  group('production desired output provider integration', () {
    test('preseeded provider state is reflected', () {
      final container = ProviderContainer(
        overrides: [
          productionDesiredOutputProvider.overrideWith(
            () => _SeededProductionDesiredOutputNotifier(const {
              'lumber_from_timber': 5,
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(productionDesiredOutputProvider);
      expect(state, const {'lumber_from_timber': 5});
      expect(desiredOutputToAssignments(state), isNotEmpty);
    });

    test('updating provider rebuilds derived assignment list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(productionDesiredOutputProvider), isEmpty);
      expect(
        desiredOutputToAssignments(
          container.read(productionDesiredOutputProvider),
        ),
        isEmpty,
      );

      container.read(productionDesiredOutputProvider.notifier).replaceAll(
        const {'lumber_from_timber': 2},
      );

      final next = container.read(productionDesiredOutputProvider);
      final assignments = desiredOutputToAssignments(next);
      expect(next['lumber_from_timber'], 2);
      expect(assignments, hasLength(1));
      expect(assignments.first.recipeId, 'lumber_from_timber');
      expect(assignments.first.assignedLabour, 4);
    });
  });

  setUpAll(() async {
    final onePxPng = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ioAAAAASUVORK5CYII=',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = const StringCodec().decodeMessage(message);
          if (key != null && key.startsWith('assets/') && key.endsWith('.png')) {
            return ByteData.view(Uint8List.fromList(onePxPng).buffer);
          }
          return null;
        });

    Hive.init('./.dart_tool/test_hive_production_screen_integration');
    gamesBox = await Hive.openBox<dynamic>('games_production_screen_integration');
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    await gamesBox.close();
  });

  test(
    'map-backed preview parity through GameService provider wiring',
    () {
      final game = Game(
        id: 'g-prod-screen',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'Human',
            isHuman: true,
            stockpile: Stockpile(quantities: {'grain': 2, 'timber': 2}),
            workerPool: WorkerPool(peasants: 2),
          ),
        ],
      );
      final player = game.players.first;
      final mapData = (
        combinedTopology: const MapTopology(),
        tileMapByRegion: <String, TileMapResult>{},
        topologyByRegion: <String, MapTopology>{},
        warpLinks: null,
      );
      final service = _MapBackedGameService(
        gamesBox,
        GameSaveAdapter(),
        expectedGameId: game.id,
        mapData: mapData,
      );
      final expected = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        playerId: player.id,
        topology: mapData.combinedTopology,
        tileMapByRegion: mapData.tileMapByRegion,
      );
      final container = ProviderContainer(
        overrides: [gameServiceProvider.overrideWith((ref) => service)],
      );
      addTearDown(container.dispose);
      final wiredService = container.read(gameServiceProvider);
      final loaded = wiredService.getMapData(game.id);
      final actual = previewStockpileNetDeltaByCommodityForPlayer(
        game: game,
        playerId: player.id,
        topology: loaded?.combinedTopology ?? const MapTopology(),
        tileMapByRegion: loaded?.tileMapByRegion ?? const {},
      );

      expect(actual, expected);
      expect(service.getMapDataCallCount, greaterThan(0));
    },
  );
}
