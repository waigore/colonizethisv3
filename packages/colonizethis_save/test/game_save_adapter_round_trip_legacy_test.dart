import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart';

import 'support/game_save_adapter_test_harness.dart';

/// Legacy / optional-field envelope pins split from the field suite (Refs #4664).
void main() {
  final harness = GameSaveAdapterHiveHarness(
    hivePath: './.dart_tool/test_hive_save_fields_legacy',
    boxName: 'games_fields_legacy',
  );

  setUpAll(harness.open);
  tearDownAll(harness.close);
  setUp(harness.reset);

  Map<String, dynamic> minimalGameJson(String id) => {
    'id': id,
    'worldState': {
      'turnState': {'phase': 'orders', 'turnNumber': 1},
      'oldWorld': {'provinces': []},
      'newWorld': {'provinces': []},
    },
    'players': [
      {'id': 'pl1', 'displayName': 'Spain', 'isHuman': true},
    ],
  };

  void putEnvelope(String id, Map<String, dynamic> gameJson) {
    harness.box.put(id, {
      'saveFormatVersion': kSaveFormatVersion,
      'game': gameJson,
    });
  }

  group('GameSaveAdapter legacy / optional field round-trips', () {
    test('save/load round-trip includes turnTimeMapping', () {
      final game =
          minimalSaveGame(
            id: 'turnTime',
            turnNumber: 1,
            players: const [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            ],
          ).copyWith(
            turnTimeMapping: const TurnTimeMapping(
              startYear: 1600,
              cutoffYear: 1750,
              yearsPerTurnBeforeCutoff: 3,
              yearsPerTurnAfterCutoff: 2,
            ),
          );
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'turnTime')!;
      expect(loaded.turnTimeMapping!.startYear, 1600);
      expect(loaded.turnTimeMapping!.cutoffYear, 1750);
      expect(loaded.turnTimeMapping!.yearsPerTurnBeforeCutoff, 3);
      expect(loaded.turnTimeMapping!.yearsPerTurnAfterCutoff, 2);
    });

    test('save/load round-trip includes mapViewState and legacy default', () {
      final game =
          minimalSaveGame(
            id: 'mapViewStateSave',
            turnNumber: 1,
            players: const [
              Player(id: 'pl1', displayName: 'Spain', isHuman: true),
            ],
          ).copyWith(
            mapViewState: const MapViewState(
              zoomMultiplier: 3.5,
              showProvinceOverlay: false,
              showProvinceOwnershipTint: true,
              showProvinceNamesLayer: false,
              showCapitalLinkDisconnectedHighlight: false,
              showPlayerTurnEventsFeed: true,
              showMapResources: false,
              showMapImprovements: true,
              showMapRoads: false,
            ),
          );
      harness.adapter.save(harness.box, game);
      final loaded = harness.adapter.load(harness.box, 'mapViewStateSave')!;
      expect(loaded.mapViewState.zoomMultiplier, 3.5);
      expect(loaded.mapViewState.showProvinceOverlay, isFalse);
      expect(loaded.mapViewState.showProvinceOwnershipTint, isTrue);
      expect(loaded.mapViewState.showProvinceNamesLayer, isFalse);
      expect(loaded.mapViewState.showCapitalLinkDisconnectedHighlight, isFalse);
      expect(loaded.mapViewState.showPlayerTurnEventsFeed, isTrue);
      expect(loaded.mapViewState.showPlayersBar, isTrue);
      expect(loaded.mapViewState.showMapResources, isFalse);
      expect(loaded.mapViewState.showMapImprovements, isTrue);
      expect(loaded.mapViewState.showMapRoads, isFalse);

      final legacyGameJson = Map<String, dynamic>.from(game.toJson())
        ..remove('mapViewState');
      putEnvelope('legacyMapViewStateSave', legacyGameJson);
      final legacyLoaded = harness.adapter.load(
        harness.box,
        'legacyMapViewStateSave',
      )!;
      expect(legacyLoaded.mapViewState, MapViewState.defaults);
      expect(legacyLoaded.mapViewState.showPlayerTurnEventsFeed, isFalse);
      expect(legacyLoaded.mapViewState.showPlayersBar, isTrue);
      expect(
        legacyLoaded.mapViewState.showCapitalLinkDisconnectedHighlight,
        isTrue,
      );

      const rematerializeId = 'legacyMapViewStateRematerialize';
      harness.adapter.save(
        harness.box,
        legacyLoaded.copyWith(id: rematerializeId),
      );
      final rematerialized =
          harness.box.get(rematerializeId) as Map<dynamic, dynamic>;
      final rematerializedGame =
          rematerialized['game'] as Map<dynamic, dynamic>;
      expect(rematerializedGame.containsKey('mapViewState'), isTrue);
      expect(
        (rematerializedGame['mapViewState']
            as Map<dynamic, dynamic>)['showPlayersBar'],
        isTrue,
      );
    });

    test('load succeeds when turnTimeMapping is Map<dynamic,dynamic>', () {
      final gameJson = minimalGameJson('hiveTurnMap')
        ..['turnTimeMapping'] = <dynamic, dynamic>{
          'startYear': 1600,
          'cutoffYear': 1750,
          'yearsPerTurnBeforeCutoff': 3,
          'yearsPerTurnAfterCutoff': 2,
        };
      putEnvelope('hiveTurnMap', gameJson);
      final loaded = harness.adapter.load(harness.box, 'hiveTurnMap')!;
      expect(loaded.turnTimeMapping!.startYear, 1600);
      expect(loaded.turnTimeMapping!.cutoffYear, 1750);
      expect(loaded.turnTimeMapping!.yearsPerTurnBeforeCutoff, 3);
      expect(loaded.turnTimeMapping!.yearsPerTurnAfterCutoff, 2);
    });

    test('load supports missing greatPowerColorOverride', () {
      putEnvelope('legacyGame', minimalGameJson('legacyGame'));
      final loaded = harness.adapter.load(harness.box, 'legacyGame')!;
      expect(loaded.greatPowerColorOverride, isNull);
    });

    test('load supports missing turnTimeMapping', () {
      putEnvelope('legacyGame2', minimalGameJson('legacyGame2'));
      final loaded = harness.adapter.load(harness.box, 'legacyGame2')!;
      expect(loaded.turnTimeMapping, isNull);
    });
  });
}
