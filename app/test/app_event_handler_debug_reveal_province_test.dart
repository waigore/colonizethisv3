import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/core/services/debug/app_event_handler_debug_reveal_province.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/debug_handler_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyDebugRevealProvince', () {
    test('reveals province by full id for unknown target', () {
      final game = buildDebugHandlerRevealProvinceGame();
      const event = RevealDebugProvinceEvent(
        humanPlayerId: 'human_1',
        target: 'oldWorld|P1',
        targetIsFullProvinceId: true,
      );
      final result = applyDebugRevealProvince(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );
      expect(result.game, isNotNull);
      final vis = result.game!.worldState.playerVisibilityByTile['human_1']!;
      expect(vis['oldWorld|P1|0|0'], 'fullyVisible');
    });

    test('reveal by display name returns disambiguation candidates', () {
      final base = buildDebugHandlerRevealProvinceGame();
      final game = base.copyWith(
        worldState: base.worldState.copyWith(
          newWorld: const RegionData(
            provinces: [
              Province(
                id: 'newWorld|P7',
                regionId: 'newWorld',
                ownerId: 'ai_1',
                displayName: 'New Bordeaux',
              ),
            ],
          ),
        ),
      );
      const event = RevealDebugProvinceEvent(
        humanPlayerId: 'human_1',
        target: 'New Bordeaux',
        targetIsFullProvinceId: false,
      );
      final result = applyDebugRevealProvince(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );
      expect(result.game, isNull);
      expect(result.message, contains('Candidates: newWorld|P7, oldWorld|P1'));
      expect(result.message, contains('/reveal_province <regionId|localId>'));
    });

    test('reveals adjacent sea-zone tiles for coastal province', () {
      final game = buildDebugHandlerRevealProvinceGame();
      const event = RevealDebugProvinceEvent(
        humanPlayerId: 'human_1',
        target: 'oldWorld|P1',
        targetIsFullProvinceId: true,
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'P1', id2: 's1')],
      );
      final result = applyDebugRevealProvince(
        currentGame: game,
        event: event,
        combinedTopology: topology,
      );
      final vis = result.game!.worldState.playerVisibilityByTile['human_1']!;
      expect(vis['oldWorld|s1|0|0'], 'fullyVisible');
    });

    test('returns deterministic no-op when already fully revealed', () {
      final game = buildDebugHandlerRevealProvinceGame(
        playerVisibilityByTile: {
          'human_1': {
            'oldWorld|P1|0|0': 'fullyVisible',
            'oldWorld|s1|0|0': 'fullyVisible',
          },
        },
      );
      const event = RevealDebugProvinceEvent(
        humanPlayerId: 'human_1',
        target: 'oldWorld|P1',
        targetIsFullProvinceId: true,
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'P1', id2: 's1')],
      );
      final result = applyDebugRevealProvince(
        currentGame: game,
        event: event,
        combinedTopology: topology,
      );
      expect(result.message, contains('no-op'));
    });

    test('rejects reveal outside human Orders phase without mutating state', () {
      final game = buildDebugHandlerRevealProvinceGame(
        phase: TurnPhase.buildWork,
      );
      const event = RevealDebugProvinceEvent(
        humanPlayerId: 'human_1',
        target: 'oldWorld|P1',
        targetIsFullProvinceId: true,
      );
      final result = applyDebugRevealProvince(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );
      expect(result.game, isNull);
      expect(
        result.message,
        contains('allowed only during human Orders phase'),
      );
      expect(
        game.worldState.playerVisibilityByTile['human_1']!['oldWorld|P1|0|0'],
        'unknown',
      );
    });

    test('reveals province by global display name when exactly one match', () {
      final game = buildDebugHandlerRevealProvinceGame();
      const event = RevealDebugProvinceEvent(
        humanPlayerId: 'human_1',
        target: 'New Bordeaux',
        targetIsFullProvinceId: false,
      );
      final result = applyDebugRevealProvince(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );
      expect(result.game, isNotNull);
      final vis = result.game!.worldState.playerVisibilityByTile['human_1']!;
      expect(vis['oldWorld|P1|0|0'], 'fullyVisible');
    });

    test('not-found full province id leaves visibility unchanged', () {
      final game = buildDebugHandlerRevealProvinceGame();
      const event = RevealDebugProvinceEvent(
        humanPlayerId: 'human_1',
        target: 'oldWorld|MissingProvince',
        targetIsFullProvinceId: true,
      );
      final result = applyDebugRevealProvince(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );
      expect(result.game, isNull);
      expect(result.message, contains('not found'));
      expect(
        game.worldState.playerVisibilityByTile['human_1']!['oldWorld|P1|0|0'],
        'unknown',
      );
    });

    test('not-found display name leaves visibility unchanged', () {
      final game = buildDebugHandlerRevealProvinceGame();
      const event = RevealDebugProvinceEvent(
        humanPlayerId: 'human_1',
        target: 'No Such Display Name Xyz',
        targetIsFullProvinceId: false,
      );
      final result = applyDebugRevealProvince(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );
      expect(result.game, isNull);
      expect(result.message, contains('not found'));
      expect(
        game.worldState.playerVisibilityByTile['human_1']!['oldWorld|P1|0|0'],
        'unknown',
      );
    });

    test('JSON round-trip preserves reveal visibility (persistence parity)', () {
      final game = buildDebugHandlerRevealProvinceGame();
      const event = RevealDebugProvinceEvent(
        humanPlayerId: 'human_1',
        target: 'oldWorld|P1',
        targetIsFullProvinceId: true,
      );
      final result = applyDebugRevealProvince(
        currentGame: game,
        event: event,
        combinedTopology: const MapTopology(),
      );
      expect(result.game, isNotNull);
      final restored = Game.fromJson(result.game!.toJson());
      expect(
        restored.worldState.playerVisibilityByTile['human_1']!['oldWorld|P1|0|0'],
        'fullyVisible',
      );
    });
  });
}
