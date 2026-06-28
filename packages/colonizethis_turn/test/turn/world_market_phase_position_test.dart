import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_turn/src/turn/phases/world_market_phase.dart';
import 'package:colonizethis_turn/src/turn/turn_phase_handler_registry.dart';
import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_turn/src/turn/turn_resolution_sequence.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('World Market phase position (Refs #2990 B0+B1+B4)', () {
    test('worldMarket sits between buildWork and endOfTurn in canonical '
        'sequence', () {
      final buildWorkIndex = turnResolutionSequence.indexOf(
        TurnPhase.buildWork,
      );
      final worldMarketIndex = turnResolutionSequence.indexOf(
        TurnPhase.worldMarket,
      );
      final endOfTurnIndex = turnResolutionSequence.indexOf(
        TurnPhase.endOfTurn,
      );
      expect(buildWorkIndex, greaterThanOrEqualTo(0));
      expect(worldMarketIndex, greaterThan(buildWorkIndex));
      expect(endOfTurnIndex, greaterThan(worldMarketIndex));
      expect(
        worldMarketIndex,
        buildWorkIndex + 1,
        reason:
            'World Market (phase 13) must run immediately after Build/Work '
            '(phase 12) per SPEC/program/turn-resolution-phases.md.',
      );
      expect(
        endOfTurnIndex,
        worldMarketIndex + 1,
        reason:
            'End-of-turn (phase 14) must run immediately after World Market '
            '(phase 13) per SPEC/program/turn-resolution-phases.md.',
      );
    });

    test('TurnPhaseHandlerRegistry has a handler registered for worldMarket', () {
      expect(
        TurnPhaseHandlerRegistry.handlerFor(TurnPhase.worldMarket),
        isNotNull,
        reason:
            'Every phase in turnResolutionSequence must have a registered '
            'handler per turn-resolution-phases.md § Phase dispatch.',
      );
    });

    test('canonical sequence length is 14 phases', () {
      expect(
        turnResolutionSequence.length,
        14,
        reason:
            'Inserting World Market renumbers End-of-turn 13 → 14; the '
            'canonical sequence should have 14 entries.',
      );
    });
  });

  group('worldMarketTurnPhaseHandler empty-turn no-op (Refs #2990 B3)', () {
    test('returns TurnPhaseStepContinue with semantically unchanged Game '
        'when no trade orders or carry-forwards exist', () {
      final game = Game(
        id: 'g1',
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
        worldState: WorldState(
          turnState: const TurnState(
            phase: TurnPhase.worldMarket,
            turnNumber: 3,
          ),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
      );
      final acc = TurnPipelineState(game: game);
      final config = TurnResolverConfig(
        topology: const MapTopology(nodes: [], edges: []),
        orders: const Orders(),
      );

      final outcome = worldMarketTurnPhaseHandler(acc, config, 3);

      expect(outcome, isA<TurnPhaseStepContinue>());
      final next = (outcome as TurnPhaseStepContinue).pipeline;
      expect(
        next.game,
        equals(game),
        reason:
            'Empty-turn no-op: no commodity transfers, no treasury changes, '
            'no carry-forward orders, no price updates per '
            'SPEC/program/world-market-resolution.md § Phase resolution.',
      );
    });
  });
}
