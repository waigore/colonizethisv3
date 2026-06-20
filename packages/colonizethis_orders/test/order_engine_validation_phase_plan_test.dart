import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_orders/src/orders/order_engine_validation.dart';

/// Locks the declarative per-category validation phase descriptor introduced
/// for Refs #3543 AC2. The plan is static and input-independent, so the phase
/// ordering + bundle-refresh contract (Refs #2391 AC7;
/// SPEC/program/order-engine.md § Validation pipeline) can be asserted directly
/// without constructing an engine pass.
void main() {
  group('orderValidationPhasePlan (Refs #3543 AC2)', () {
    test('declares the canonical per-category phase order', () {
      expect(orderValidationPhasePlan.map((p) => p.name).toList(), <String>[
        'move',
        'army-move',
        'recruit-worker',
        'build',
        'work',
        'diplomatic',
        'naval',
        'trade',
      ]);
    });

    test('phase names are unique (no category runs twice)', () {
      final names = orderValidationPhasePlan.map((p) => p.name).toList();
      expect(
        names.toSet().length,
        names.length,
        reason: 'duplicate phase name in $names',
      );
    });

    test('move + army-move share the initial bundle; resource/diplomatic/naval '
        'phases refresh; trade reuses the advanced bundle', () {
      final refreshByName = <String, bool>{
        for (final p in orderValidationPhasePlan) p.name: p.refreshBundleBefore,
      };

      // move + army-move run against the first validator bundle (no refresh).
      expect(refreshByName['move'], isFalse);
      expect(refreshByName['army-move'], isFalse);

      // recruit / build / work / diplomatic / naval rebuild the bundle so
      // incremental stockpile / treasury / diplomatic state is reflected.
      for (final name in const [
        'recruit-worker',
        'build',
        'work',
        'diplomatic',
        'naval',
      ]) {
        expect(
          refreshByName[name],
          isTrue,
          reason: '$name must refresh the validator bundle',
        );
      }

      // trade runs last against the already-advanced bundle (no refresh).
      expect(refreshByName['trade'], isFalse);
    });
  });
}
