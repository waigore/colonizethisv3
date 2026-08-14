import 'package:test/test.dart';

import '../tool/check_colonizethis_setup_scenario_table_runner.dart';

void main() {
  group('setupScenarioTableRunnerPathInScope', () {
    test('positive: setup test paths are in scope', () {
      expect(
        setupScenarioTableRunnerPathInScope(
          'packages/colonizethis_setup/test/setup/foo_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: other packages are out of scope', () {
      expect(
        setupScenarioTableRunnerPathInScope(
          'packages/colonizethis_orders/test/foo_test.dart',
        ),
        isFalse,
      );
    });
  });

  group('setupScenarioTableRunnerViolationReason', () {
    test('baseline allow-all suppresses long imperative bodies', () {
      final reason = setupScenarioTableRunnerViolationReason(
        'packages/colonizethis_setup/test/setup/foo_test.dart',
        "test('long body', () { expect(1, 1); });",
        baselineAllowAll: true,
      );
      expect(reason, isNull);
    });

    test('flags long imperative body when baseline is tightened', () {
      final reason = setupScenarioTableRunnerViolationReason(
        'packages/colonizethis_setup/test/setup/foo_test.dart',
        "test('long body', () { expect(1, 1); });",
        baselineAllowAll: false,
      );
      expect(reason, isNotNull);
      expect(reason, contains('scenario'));
    });

    test('allows scenario-loop wrapped bodies when baseline is tightened', () {
      final content = '''
void main() {
  for (final scenario in scenarios) {
    test(scenario.label, () { scenario.run(); });
  }
}
''';
      final reason = setupScenarioTableRunnerViolationReason(
        'packages/colonizethis_setup/test/setup/foo_test.dart',
        content,
        baselineAllowAll: false,
      );
      expect(reason, isNull);
    });
  });

  group('runCheckColonizethisSetupScenarioTableRunner', () {
    test('wave-7 slice C keeps baseline allow-all off', () {
      expect(setupPreferScenarioTablesBaselineAllowAll, isFalse);
      expect(setupPreferScenarioTablesAllowlist, isNotEmpty);
    });

    test('passes on current repo tree', () {
      expect(runCheckColonizethisSetupScenarioTableRunner('.'), 0);
    });
  });
}
