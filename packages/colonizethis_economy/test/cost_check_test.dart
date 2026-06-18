import 'package:colonizethis_economy/src/economy/cost_check.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('checkPreconditionsInOrder (Refs #3517 Cluster 2)', () {
    test('returns null when every check passes', () {
      final reason = checkPreconditionsInOrder([
        (failReason: 'a', check: () => true),
        (failReason: 'b', check: () => true),
        (failReason: 'c', check: () => true),
      ]);
      expect(reason, isNull);
    });

    test('returns the first failing reason in list order', () {
      final reason = checkPreconditionsInOrder([
        (failReason: 'tech', check: () => true),
        (failReason: 'workers', check: () => false),
        (failReason: 'treasury', check: () => false),
      ]);
      expect(reason, 'workers');
    });

    test('honours canonical priority: earlier failure wins over later', () {
      final reason = checkPreconditionsInOrder([
        (failReason: 'tech', check: () => false),
        (failReason: 'materials', check: () => false),
      ]);
      expect(reason, 'tech');
    });

    test('short-circuits: no later check runs once one fails', () {
      final evaluated = <String>[];
      final reason = checkPreconditionsInOrder([
        (
          failReason: 'first',
          check: () {
            evaluated.add('first');
            return true;
          },
        ),
        (
          failReason: 'second',
          check: () {
            evaluated.add('second');
            return false;
          },
        ),
        (
          failReason: 'third',
          check: () {
            evaluated.add('third');
            return true;
          },
        ),
      ]);
      expect(reason, 'second');
      expect(evaluated, ['first', 'second']);
    });

    test('empty precondition list passes (returns null)', () {
      expect(checkPreconditionsInOrder(const []), isNull);
    });
  });
}
