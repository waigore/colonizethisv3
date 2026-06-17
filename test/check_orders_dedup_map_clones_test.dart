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

    test('flags raw Map<String, Unit>.from(...) clone', () {
      const src = r'''
final units = Map<String, Unit>.from(state.work.unitsById.old)..[id] = u;
''';
      final violations = findOrdersDedupMapCloneViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/orders_application.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('copyUnitsById'));
    });

    test('flags Map<String, Unit>.from regardless of receiver', () {
      const src = r'''
final q = Map<String , Unit>.from(game.worldState.allUnitsById);
''';
      final violations = findOrdersDedupMapCloneViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/order_engine.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test('accepts canonical copyUnitsById(...) delegation', () {
      const src = r'''
final units = copyUnitsById(state.work.unitsByIdForRegion(oldWorld))..[id] = u;
''';
      final violations = findOrdersDedupMapCloneViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/orders_application.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a comment mentioning Map<String, Unit>.from', () {
      const src = r'''
/// Centralises the Map<String, Unit>.from(...) clone into one call site.
Map<String, Unit> copyUnitsById(Map<String, Unit> source) =>
    <String, Unit>{...source};
''';
      final violations = findOrdersDedupMapCloneViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/orders_application_context.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });

  group('findDuplicateWithProjectedEconomyViolations', () {
    test('flags subclass constructor without super delegation', () {
      const src = r'''
class BuildOrderValidator extends StatefulValidator {
  BuildOrderValidator.withProjectedEconomy({
    required Stockpile stockpile,
    required int treasury,
    required WorkerPool workerPool,
  }) : stockpileState = stockpile,
       treasuryState = treasury,
       workerPoolState = workerPool,
       super();
}
''';
      final violations = findDuplicateWithProjectedEconomyViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/validators/build_order_validator.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test('accepts super.withProjectedEconomy delegation', () {
      const src = r'''
class BuildOrderValidator extends StatefulValidator {
  BuildOrderValidator.withProjectedEconomy({
    required Stockpile stockpile,
    required int treasury,
    required WorkerPool workerPool,
  }) : super.withProjectedEconomy(
         stockpile: stockpile,
         treasury: treasury,
         workerPool: workerPool,
       );
}
''';
      final violations = findDuplicateWithProjectedEconomyViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/validators/build_order_validator.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });

  group('findOrderAcceptedProbeDuplicateViolations', () {
    test('flags is*OrderAccepted that inlines incrementalValidatorForCandidateProbe', () {
      const src = r'''
bool isMoveOrderAccepted(Game game, MapTopology topology, String playerId,
    Orders baseOrders, MoveOrder candidate) {
  final validator = incrementalValidatorForCandidateProbe(
    game: game,
    topology: topology,
    playerId: playerId,
    baseOrders: baseOrders,
  );
  return validator.isMoveAccepted(candidate);
}
''';
      final violations = findOrderAcceptedProbeDuplicateViolations(
        relativePath: _orderSuggestionContextRelative,
        source: src,
      );
      expect(violations, hasLength(1));
    });
  });
}

const _orderSuggestionContextRelative =
    'packages/colonizethis_orders/lib/src/orders/order_suggestion_context.dart';
