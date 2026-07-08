// Table-driven cost-check precondition scenarios (Refs #3939 phase 3).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'scenario_runner.dart';

/// One row in [checkPreconditionsInOrderScenarios].
class CheckPreconditionsInOrderScenario implements RefsScenario {
  const CheckPreconditionsInOrderScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runCheckPreconditionsInOrderScenario(
  CheckPreconditionsInOrderScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for [checkPreconditionsInOrder].
List<CheckPreconditionsInOrderScenario> checkPreconditionsInOrderScenarios() =>
    [
      CheckPreconditionsInOrderScenario(
        label: 'returns null when every check passes',
        run: () {
          final reason = checkPreconditionsInOrder([
            (failReason: 'a', check: () => true),
            (failReason: 'b', check: () => true),
            (failReason: 'c', check: () => true),
          ]);
          expect(reason, isNull);
        },
        refs: '#3517',
      ),
      CheckPreconditionsInOrderScenario(
        label: 'returns the first failing reason in list order',
        run: () {
          final reason = checkPreconditionsInOrder([
            (failReason: 'tech', check: () => true),
            (failReason: 'workers', check: () => false),
            (failReason: 'treasury', check: () => false),
          ]);
          expect(reason, 'workers');
        },
        refs: '#3517',
      ),
      CheckPreconditionsInOrderScenario(
        label: 'honours canonical priority: earlier failure wins over later',
        run: () {
          final reason = checkPreconditionsInOrder([
            (failReason: 'tech', check: () => false),
            (failReason: 'materials', check: () => false),
          ]);
          expect(reason, 'tech');
        },
        refs: '#3517',
      ),
      CheckPreconditionsInOrderScenario(
        label: 'short-circuits: no later check runs once one fails',
        run: () {
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
        },
        refs: '#3517',
      ),
      CheckPreconditionsInOrderScenario(
        label: 'empty precondition list passes (returns null)',
        run: () {
          expect(checkPreconditionsInOrder(const []), isNull);
        },
        refs: '#3517',
      ),
    ];
