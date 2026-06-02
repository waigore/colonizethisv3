import 'dart:io';

import 'package:colonizethis_logic/src/turn/turn_phase_handler_registry.dart';
import 'package:colonizethis_logic/src/turn/turn_resolution_sequence.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TurnPhaseHandlerRegistry', () {
    test(
      'defaults registers a handler for every turnResolutionSequence phase',
      () {
        assertTurnPhaseHandlerRegistryComplete();
        for (final phase in turnResolutionSequence) {
          expect(
            TurnPhaseHandlerRegistry.handlerFor(phase),
            isNotNull,
            reason: 'missing handler for ${phase.name}',
          );
        }
      },
    );

    test('defaults map keys match turnResolutionSequence exactly', () {
      expect(
        TurnPhaseHandlerRegistry.defaults.keys.toList(),
        turnResolutionSequence,
      );
    });

    test(
      'registry module contains no inline TurnPhaseHandler implementations',
      () {
        // Locks AC4 of #2560: every `TurnPhaseHandler` body lives in
        // `turn/phases/*.dart`. The registry module must remain a thin
        // `(TurnPhase, handler)` lookup with no inline handler functions
        // beyond `assertTurnPhaseHandlerRegistryComplete`.
        final source = File(
          'lib/src/turn/turn_phase_handler_registry.dart',
        ).readAsStringSync();
        final inlineHandlerDecl = RegExp(
          r'^TurnPhaseStepOutcome\s+\w+TurnPhaseHandler\s*\(',
          multiLine: true,
        );
        expect(
          inlineHandlerDecl.hasMatch(source),
          isFalse,
          reason:
              'turn_phase_handler_registry.dart must not define '
              '*TurnPhaseHandler functions inline; move them under '
              'lib/src/turn/phases/*.dart (Refs #2560).',
        );
      },
    );
  });
}
