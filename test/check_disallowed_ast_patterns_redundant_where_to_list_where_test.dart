import 'package:test/test.dart';

import '../tool/check_disallowed_ast_patterns.dart';
import 'disallowed_ast_patterns_test_yaml_fixture.dart';

void main() {
  late List<DisallowedPatternRule> rules;

  setUp(() {
    rules = loadDisallowedAstRulesForTest(disallowedAstPatternsTestYaml);
  });

  group('redundant_where_to_list_where_chain', () {
    test('flags direct .where(...).toList().where(...) chain', () {
      const src = r'''
List<int> bad(List<int> xs) {
  return xs
      .where((x) => x.isEven)
      .toList()
      .where((x) => x > 10)
      .toList();
}
''';
      final violations = findDisallowedAstViolations(
        'app/lib/features/game/widgets/civilian_units_panel.dart',
        src,
        rules,
      );
      expect(
        violations
            .where((e) => e.ruleId == 'redundant_where_to_list_where_chain'),
        isNotEmpty,
        reason: '`.where(...).toList().where(...)` chains are an anti-pattern.',
      );
    });

    test('flags chain on nested receiver expression', () {
      const src = r'''
List<int> bad(Map<String, List<int>> m, String key) {
  return m[key]!.where((x) => x.isEven).toList().where((x) => x > 0).toList();
}
''';
      final violations = findDisallowedAstViolations(
        'app/lib/widgets/x.dart',
        src,
        rules,
      );
      expect(
        violations
            .where((e) => e.ruleId == 'redundant_where_to_list_where_chain'),
        isNotEmpty,
      );
    });

    test('ignores a single .where(...).toList() with no follow-up .where', () {
      const src = r'''
List<int> ok(List<int> xs) {
  return xs.where((x) => x.isEven).toList();
}
''';
      expect(
        findDisallowedAstViolations(
          'app/lib/features/game/widgets/civilian_units_panel.dart',
          src,
          rules,
        ).where((e) => e.ruleId == 'redundant_where_to_list_where_chain'),
        isEmpty,
        reason: 'Single .where(...).toList() is allowed.',
      );
    });

    test('ignores a chained .where(...).where(...) without intervening .toList', () {
      const src = r'''
List<int> ok(List<int> xs) {
  return xs.where((x) => x.isEven).where((x) => x > 10).toList();
}
''';
      expect(
        findDisallowedAstViolations(
          'app/lib/widgets/x.dart',
          src,
          rules,
        ).where((e) => e.ruleId == 'redundant_where_to_list_where_chain'),
        isEmpty,
        reason: 'Lazy Iterable .where chains do not allocate intermediates.',
      );
    });

    test('ignores sequential reassignment across statements', () {
      const src = r'''
List<int> ok(List<int> xs) {
  var ys = xs.where((x) => x.isEven).toList();
  ys = ys.where((x) => x > 10).toList();
  return ys;
}
''';
      expect(
        findDisallowedAstViolations(
          'app/lib/widgets/x.dart',
          src,
          rules,
        ).where((e) => e.ruleId == 'redundant_where_to_list_where_chain'),
        isEmpty,
        reason: 'Statement-level reassignment is not the direct-chain pattern.',
      );
    });

    test(
      'respects same-line ignore for redundant_where_to_list_where_chain',
      () {
        const src = r'''
List<int> tolerated(List<int> xs) {
  return xs.where((x) => x.isEven).toList().where((x) => x > 10).toList(); // ignore: disallowed_ast_redundant_where_to_list_where_chain
}
''';
        expect(
          findDisallowedAstViolations(
            'app/lib/widgets/x.dart',
            src,
            rules,
          ).where((e) => e.ruleId == 'redundant_where_to_list_where_chain'),
          isEmpty,
        );
      },
    );

    test('respects ignore comment on previous line', () {
      const src = r'''
List<int> tolerated(List<int> xs) {
  // ignore: disallowed_ast_redundant_where_to_list_where_chain
  return xs.where((x) => x.isEven).toList().where((x) => x > 10).toList();
}
''';
      expect(
        findDisallowedAstViolations(
          'app/lib/widgets/x.dart',
          src,
          rules,
        ).where((e) => e.ruleId == 'redundant_where_to_list_where_chain'),
        isEmpty,
      );
    });

    test('respects file-level ignore_for_file marker', () {
      const src = r'''
// ignore_for_file: disallowed_ast_redundant_where_to_list_where_chain
List<int> tolerated(List<int> xs) {
  return xs.where((x) => x.isEven).toList().where((x) => x > 10).toList();
}
''';
      expect(
        findDisallowedAstViolations(
          'app/lib/widgets/x.dart',
          src,
          rules,
        ).where((e) => e.ruleId == 'redundant_where_to_list_where_chain'),
        isEmpty,
      );
    });
  });
}
