import 'package:colonizethis_logic/src/turn/turn_phase_handler_registry.dart';
import 'package:colonizethis_logic/src/turn/turn_resolution_sequence.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TurnPhaseHandlerRegistry', () {
    test('defaults registers a handler for every turnResolutionSequence phase', () {
      assertTurnPhaseHandlerRegistryComplete();
      for (final phase in turnResolutionSequence) {
        expect(
          TurnPhaseHandlerRegistry.handlerFor(phase),
          isNotNull,
          reason: 'missing handler for ${phase.name}',
        );
      }
    });

    test('defaults map keys match turnResolutionSequence exactly', () {
      expect(
        TurnPhaseHandlerRegistry.defaults.keys.toList(),
        turnResolutionSequence,
      );
    });
  });
}
