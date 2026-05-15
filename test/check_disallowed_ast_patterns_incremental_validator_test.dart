import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../tool/check_disallowed_ast_patterns.dart';

const _incrementalValidatorRuleYaml = r'''
rules:
  - id: prohibited_incremental_validator_per_item
    message: no per-loop validator
    match:
      kind: incremental_validator_for_player_in_loop
      relative_path_prefix: packages/colonizethis_logic/lib/src/
''';

void main() {
  late List<DisallowedPatternRule> rules;

  setUp(() {
    rules = parseDisallowedAstRulesFromYaml(loadYaml(_incrementalValidatorRuleYaml));
  });

  group('prohibited_incremental_validator_per_item', () {
    test('flags IncrementalCandidateValidator.forPlayer inside for', () {
      const src = r'''
void f() {
  for (var i = 0; i < 3; i++) {
    IncrementalCandidateValidator.forPlayer(
      game: g,
      topology: t,
      playerId: 'p1',
      basePrefix: o,
    );
  }
}
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_logic/lib/src/orders/x.dart',
        src,
        rules,
      );
      expect(violations, hasLength(1));
      expect(violations.first.ruleId, 'prohibited_incremental_validator_per_item');
    });

    test('flags buildIncrementalCandidateValidator inside for-in', () {
      const src = r'''
void f(List<String> ids) {
  for (final id in ids) {
    buildIncrementalCandidateValidator(
      game: g,
      topology: t,
      playerId: id,
      baseOrders: o,
    );
  }
}
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_logic/lib/src/orders/x.dart',
        src,
        rules,
      );
      expect(violations, hasLength(1));
    });

    test('allows forPlayer outside loops', () {
      const src = r'''
void f() {
  IncrementalCandidateValidator.forPlayer(
    game: g,
    topology: t,
    playerId: 'p1',
    basePrefix: o,
  );
}
''';
      expect(
        findDisallowedAstViolations(
          'packages/colonizethis_logic/lib/src/orders/x.dart',
          src,
          rules,
        ),
        isEmpty,
      );
    });

    test('allows forBasePrefix inside loops', () {
      const src = r'''
void f(IncrementalCandidateValidator v, Orders o) {
  for (var i = 0; i < 3; i++) {
    v.forBasePrefix(o);
  }
}
''';
      expect(
        findDisallowedAstViolations(
          'packages/colonizethis_logic/lib/src/orders/x.dart',
          src,
          rules,
        ),
        isEmpty,
      );
    });

    test('ignores paths outside colonizethis_logic lib/src', () {
      const src = r'''
void f() {
  for (var i = 0; i < 3; i++) {
    IncrementalCandidateValidator.forPlayer(
      game: g,
      topology: t,
      playerId: 'p1',
      basePrefix: o,
    );
  }
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });
  });
}
