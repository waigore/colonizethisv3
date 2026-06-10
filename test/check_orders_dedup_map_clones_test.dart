import 'package:test/test.dart';

import '../tool/check_orders_dedup_map_clones.dart';

void main() {
  group('findOrdersDedupMapCloneViolations', () {
    test('flags raw Map<String, int>.from(...quantities) clone', () {
      const src = r'''
Stockpile snapshot(EconomySnap snap) {
  return Stockpile(
    quantities: Map<String, int>.from(snap.stockpile.quantities),
  );
}
''';
      final violations = findOrdersDedupMapCloneViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/incremental_candidate_validator_projection.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      final lines = src.split('\n');
      expect(lines[violations.single.line - 1], contains('Map<String, int>.from'));
    });

    test('flags clone regardless of stockpile receiver name', () {
      const src = r'''
final q = Map<String , int>.from(workValidator.stockpile.quantities);
''';
      final violations = findOrdersDedupMapCloneViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/incremental_candidate_validator_prefix_replay.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test('accepts canonical Stockpile.copyQuantities() delegation', () {
      const src = r'''
Stockpile snapshot(EconomySnap snap) {
  return Stockpile(quantities: snap.stockpile.copyQuantities());
}
''';
      final violations = findOrdersDedupMapCloneViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/incremental_candidate_validator_projection.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag unrelated Map<String, int>.from clones', () {
      const src = r'''
final copy = Map<String, int>.from(someOtherMap);
''';
      final violations = findOrdersDedupMapCloneViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/orders_application.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
