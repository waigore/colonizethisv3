import 'package:test/test.dart';

import '../tool/check_orders_scenario_table_runner.dart';

void main() {
  group('ordersScenarioTableRunnerViolationReason', () {
    test('baseline allow-all suppresses violations', () {
      expect(
        ordersScenarioTableRunnerViolationReason(
          'packages/colonizethis_orders/test/orders/new_test.dart',
          "void main() {\n  test('x', () {\n    expect(1, 1);\n  });\n}\n",
          baselineAllowAll: true,
        ),
        isNull,
      );
    });

    test('flags long imperative body when allow-all is off', () {
      expect(
        ordersScenarioTableRunnerViolationReason(
          'packages/colonizethis_orders/test/orders/new_test.dart',
          "void main() {\n  test('x', () {\n    expect(1, 1);\n  });\n}\n",
          baselineAllowAll: false,
        ),
        isNotNull,
      );
    });

    test('allows surrounding scenario loop when allow-all is off', () {
      expect(
        ordersScenarioTableRunnerViolationReason(
          'packages/colonizethis_orders/test/orders/new_test.dart',
          '''
void main() {
  for (final scenario in rows) {
    test('x', () {
      expect(scenario, isNotNull);
    });
  }
}
''',
          baselineAllowAll: false,
        ),
        isNull,
      );
    });

    test('honours explicit allowlist when allow-all is off', () {
      expect(
        ordersScenarioTableRunnerViolationReason(
          'packages/colonizethis_orders/test/orders/legacy_test.dart',
          "void main() {\n  test('x', () {\n    expect(1, 1);\n  });\n}\n",
          baselineAllowAll: false,
          allowlist: {
            'packages/colonizethis_orders/test/orders/legacy_test.dart',
          },
        ),
        isNull,
      );
    });

    test('default gate uses explicit allowlist (baseline allow-all off)', () {
      expect(ordersPreferScenarioTablesBaselineAllowAll, isFalse);
      expect(ordersPreferScenarioTablesAllowlist, isA<Set<String>>());
      expect(
        ordersScenarioTableRunnerViolationReason(
          'packages/colonizethis_orders/test/orders/brand_new_imperative_test.dart',
          "void main() {\n  test('x', () {\n    expect(1, 1);\n  });\n}\n",
        ),
        isNotNull,
      );
    });
  });
}
