import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/turn/end_of_turn_resolver.dart';
import 'package:colonizethis_logic/src/turn/turn_phase_runner.dart';
import 'package:colonizethis_logic/src/turn/turn_resolution_result.dart';
import 'package:colonizethis_logic/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('runEndOfTurnPhase calendar campaign halt', () {
    MapTopology _minimalTopology() {
      const ow = 'oldWorld';
      return MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
    }

    Game _gameAtTurn(int turn, {bool explicitGdd01 = false}) {
      const ow = 'oldWorld';
      return Game(
        id: 'g-cal',
        turnTimeMapping: explicitGdd01 ? TurnTimeMapping.gdd01 : null,
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.endOfTurn, turnNumber: turn),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        ],
      );
    }

    test('turn 200 advances to 201 without halt', () {
      final after = runEndOfTurnPhase(
        _gameAtTurn(200),
        topology: _minimalTopology(),
      );
      expect(after.calendarCampaignHalted, isFalse);
      expect(after.worldState.turnState.turnNumber, 201);
    });

    test('turn 201 halts calendar without incrementing turn', () {
      final after = runEndOfTurnPhase(
        _gameAtTurn(201, explicitGdd01: true),
        topology: _minimalTopology(),
      );
      expect(after.calendarCampaignHalted, isTrue);
      expect(after.worldState.turnState.turnNumber, 201);
      expect(after.victory, isNull);
    });

    test('turn 201 advances when infiniteMode is true', () {
      final after = runEndOfTurnPhase(
        _gameAtTurn(201, explicitGdd01: true).copyWith(infiniteMode: true),
        topology: _minimalTopology(),
      );
      expect(after.calendarCampaignHalted, isFalse);
      expect(after.worldState.turnState.turnNumber, 202);
      expect(
        TurnTimeMapping.gdd01.yearAtTurn(202),
        1801,
      );
    });

    test('runTurnResolutionPipeline skips phases when calendar halted', () {
      final game = _gameAtTurn(201, explicitGdd01: true).copyWith(
        calendarCampaignHalted: true,
      );
      final result = runTurnResolutionPipeline(
        gameAtResolutionStart: game,
        config: TurnResolverConfig(
          topology: _minimalTopology(),
          orders: const Orders(),
        ),
      );
      expect(result, isA<TurnResolutionComplete>());
      final complete = result as TurnResolutionComplete;
      expect(complete.game.calendarCampaignHalted, isTrue);
      expect(complete.game.worldState.turnState.turnNumber, 201);
    });
  });
}
