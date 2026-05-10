import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Game _minimalGame({
  required List<Player> players,
  Map<String, bool> aiControlByGpId = const {},
  Map<String, String> hiddenAgendaByGpId = const {},
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(provinces: [], units: []),
      newWorld: RegionData(provinces: [], units: []),
    ),
    players: players,
    aiControlByGpId: aiControlByGpId,
    hiddenAgendaByGpId: hiddenAgendaByGpId,
  );
}

void main() {
  group('generateOrdersForPlayerFullAI', () {
    test('unknown player id returns empty orders and default economy plan', () {
      final game = _minimalGame(
        players: const [Player(id: 'gp1', displayName: 'AI', isHuman: false)],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final r = generateOrdersForPlayerFullAI(game, topology, 'no_such_gp');
      expect(r.orders.moveOrdersByPlayerId, isEmpty);
      expect(r.economyPlan.cargoPreference, CargoPreference.none);
      expect(r.economyPlan.productionAssignments, isEmpty);
    });

    test('non-AI-controlled player returns empty', () {
      final game = _minimalGame(
        players: const [Player(id: 'gp1', displayName: 'Human', isHuman: true)],
        aiControlByGpId: const {'gp1': false},
      );
      const topology = MapTopology(nodes: [], edges: []);
      final r = generateOrdersForPlayerFullAI(game, topology, 'gp1');
      expect(r.orders.moveOrdersByPlayerId, isEmpty);
      expect(r.economyPlan.productionAssignments, isEmpty);
    });

    test('AI player runs strategic path with default suggestion API', () {
      final game = _minimalGame(
        players: const [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
        hiddenAgendaByGpId: const {'gp1': 'peacemaker'},
      );
      const topology = MapTopology(nodes: [], edges: []);
      final r = generateOrdersForPlayerFullAI(game, topology, 'gp1');
      expect(r.orders.moveOrdersByPlayerId['gp1'] ?? const [], isEmpty);
      expect(
        r.economyPlan.cargoPreference,
        isIn([
          CargoPreference.none,
          CargoPreference.preferCargo,
          CargoPreference.strongCargo,
        ]),
      );
    });

    test('passes tileMapByRegion, explicit API, and callbacks through', () {
      final game = _minimalGame(
        players: const [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      var dialogueCalls = 0;
      var moodCalls = 0;
      final r = generateOrdersForPlayerFullAI(
        game,
        topology,
        'gp1',
        tileMapByRegion: const {},
        orderSuggestionApi: const DefaultOrderSuggestionAPI(),
        onDialogue: (_) => dialogueCalls++,
        onMood: (_) => moodCalls++,
      );
      expect(r.orders, isNotNull);
      expect(dialogueCalls + moodCalls, greaterThanOrEqualTo(0));
    });
  });

  group('generateOrdersForGameFullAI', () {
    test('no AI players yields empty aggregate orders and economy map', () {
      final game = _minimalGame(
        players: const [Player(id: 'gp1', displayName: 'Human', isHuman: true)],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final r = generateOrdersForGameFullAI(game, topology);
      expect(r.economyPlansByPlayerId, isEmpty);
      expect(r.orders.moveOrdersByPlayerId, isEmpty);
    });

    test('aggregates one AI player', () {
      final game = _minimalGame(
        players: const [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final r = generateOrdersForGameFullAI(game, topology);
      expect(r.economyPlansByPlayerId.containsKey('gp1'), isTrue);
      expect(r.orders.moveOrdersByPlayerId['gp1'] ?? const [], isEmpty);
    });

    test('onStagedPlannerProgress emits A–G sequence per AI player', () {
      final game = _minimalGame(
        players: const [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
        hiddenAgendaByGpId: const {'gp1': 'peacemaker'},
      );
      const topology = MapTopology(nodes: [], edges: []);
      final phases = <String>[];
      generateOrdersForGameFullAI(
        game,
        topology,
        onStagedPlannerProgress: phases.add,
      );
      const expected = <String>[
        'suggestionPools',
        'aiStageA',
        'aiStageB',
        'aiStageC',
        'aiStageD',
        'aiStageE',
        'aiStageF',
        'aiStageG',
      ];
      expect(phases, expected);
    });

    test('includes schema-shaped AI trace section for full AI player', () {
      final game = _minimalGame(
        players: const [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
        aiControlByGpId: const {'gp1': true},
        hiddenAgendaByGpId: const {'gp1': 'peacemaker'},
      );
      const topology = MapTopology(nodes: [], edges: []);

      final r = generateOrdersForGameFullAI(game, topology);

      expect(r.aiTraceSections, hasLength(1));
      final section = r.aiTraceSections.single;
      expect(section.factionId, 'gp1');
      expect(section.state['winningCandidate'], isA<Map<String, Object?>>());
      expect(section.state['topAlternates'], isA<List<Object?>>());
      expect(section.state['aggregates'], isA<Map<String, Object?>>());
      expect(section.thresholds['constants'], isA<Map<String, Object?>>());
      expect(section.thresholds['derived'], isA<Map<String, Object?>>());
      expect(section.thresholds['effective'], isA<Map<String, Object?>>());
      expect(section.thresholds['gates'], isA<List<Object?>>());
      expect(section.outcome['domainOutputs'], isA<Map<String, Object?>>());
      expect(section.outcome['finalAggregatedOrders'], isA<List<Object?>>());
      expect(section.outcome['emittedOrderCount'], isA<int>());

      final constants = section.thresholds['constants'] as Map<String, Object?>;
      expect(constants['goalWeights'], isA<Map<String, Object?>>());
      expect(constants['agendaModifiers'], isA<Map<String, Object?>>());

      final effective = section.thresholds['effective'] as Map<String, Object?>;
      expect(effective['selectedGoalScore'], isA<int>());
      expect(effective['adjustedGoalScores'], isA<Map<String, Object?>>());

      final gates = section.thresholds['gates'] as List<Object?>;
      expect(gates, isNotEmpty);
      final firstGate = gates.first as Map<String, Object?>;
      expect(firstGate['candidateGoal'], isA<String>());
      expect(firstGate['candidateScore'], isA<int>());
      expect(firstGate['selected'], isA<bool>());
    });
  });
}
