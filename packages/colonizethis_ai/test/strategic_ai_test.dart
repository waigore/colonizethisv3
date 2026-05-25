import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('generateStrategicOrders', () {
    test('returns empty orders (stub)', () {
      // Minimal game and view; stub returns empty orders.
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
        players: [
          const Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, 'gp1');
      final config = const AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(999);
      const api = DefaultOrderSuggestionAPI();

      final result = generateStrategicOrders(
        game: game,
        topology: topology,
        nationId: 'gp1',
        view: view,
        config: config,
        seeds: seeds,
        suggestionAPI: api,
      );

      expect(result.orders.moveOrdersByPlayerId.isEmpty, isTrue);
      expect(result.orders.buildUnitOrdersByPlayerId.isEmpty, isTrue);
      expect(result.economyPlan.productionAssignments, isEmpty);
      expect(
        result.economyPlan.cargoPreference,
        isIn([
          CargoPreference.none,
          CargoPreference.preferCargo,
          CargoPreference.strongCargo,
        ]),
      );
    });

    test('invokes onDialogue at configured dialogue cadence', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
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
      final view = buildPlayerView(game, topology, 'gp1');
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final base = AISeedBundle.fromTurnSeed(0);
      final seeds = AISeedBundle(
        perceptionSeed: base.perceptionSeed,
        goalSeed: base.goalSeed,
        economySeed: base.economySeed,
        militarySeed: base.militarySeed,
        diplomacySeed: base.diplomacySeed,
        researchSeed: base.researchSeed,
        tacticalSeed: base.tacticalSeed,
        dialogueSeed: kDialogueTurnsBetweenComments,
        agendaSeed: base.agendaSeed,
      );
      const api = DefaultOrderSuggestionAPI();
      DialogueEvent? captured;
      final result = generateStrategicOrders(
        game: game,
        topology: topology,
        nationId: 'gp1',
        view: view,
        config: config,
        seeds: seeds,
        suggestionAPI: api,
        onDialogue: (e) => captured = e,
      );
      expect(result.orders, isNotNull);
      expect(captured, isNotNull);
      expect(captured!.leaderId, 'victoria');
      expect(captured!.category, 'agenda');
    });

    test('invokes onMood at configured dialogue cadence', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
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
      final view = buildPlayerView(game, topology, 'gp1');
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final base = AISeedBundle.fromTurnSeed(0);
      final seeds = AISeedBundle(
        perceptionSeed: base.perceptionSeed,
        goalSeed: base.goalSeed,
        economySeed: base.economySeed,
        militarySeed: base.militarySeed,
        diplomacySeed: base.diplomacySeed,
        researchSeed: base.researchSeed,
        tacticalSeed: base.tacticalSeed,
        dialogueSeed: kDialogueTurnsBetweenComments,
        agendaSeed: base.agendaSeed,
      );
      const api = DefaultOrderSuggestionAPI();
      PortraitMoodEvent? captured;
      final result = generateStrategicOrders(
        game: game,
        topology: topology,
        nationId: 'gp1',
        view: view,
        config: config,
        seeds: seeds,
        suggestionAPI: api,
        onMood: (e) => captured = e,
      );
      expect(result.orders, isNotNull);
      expect(captured, isNotNull);
      expect(captured!.leaderId, 'victoria');
      expect(captured!.fromMood, 'considering');
      expect(captured!.toMood, 'considering');
    });
  });
}
