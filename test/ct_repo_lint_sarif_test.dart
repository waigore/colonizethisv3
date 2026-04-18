import 'dart:convert';

import 'package:test/test.dart';

import '../tool/ct_repo_lint_lib.dart';

RepoLintRule _dartRule(String id, {String spec = 'SPEC/x.md'}) {
  return RepoLintRule(
    ruleId: id,
    group: 'g',
    title: 'Title $id',
    spec: spec,
    runner: 'dart',
    argv: const [],
    script: 'tool/x.dart',
    prIncremental: false,
    includeOnlyWhenEnvName: null,
    includeOnlyWhenEnvValue: null,
  );
}

RepoLintRule _shellRule() {
  return RepoLintRule(
    ruleId: 'repo.shell',
    group: 'g',
    title: 'Shell gate',
    spec: '',
    runner: 'shell',
    argv: const ['tool/check_test_imports.sh'],
    script: null,
    prIncremental: false,
    includeOnlyWhenEnvName: null,
    includeOnlyWhenEnvValue: null,
  );
}

void main() {
  group('buildCtRepoLintSarifObject', () {
    test('empty failures yields empty results', () {
      final r = _dartRule('repo.ok');
      final obj = buildCtRepoLintSarifObject(
        executedRules: [r],
        failures: const [],
      );
      expect(obj['version'], '2.1.0');
      final runs = obj['runs']! as List<Object?>;
      final run = runs.single! as Map<String, Object?>;
      final results = run['results']! as List<Object?>;
      expect(results, isEmpty);
      final tool = run['tool']! as Map<String, Object?>;
      final driver = tool['driver']! as Map<String, Object?>;
      final rules = driver['rules']! as List<Object?>;
      expect(rules.length, 1);
    });

    test('failure references ruleIndex and script or argv', () {
      final a = _dartRule('repo.a', spec: 'SPEC/program/a.md');
      final b = _shellRule();
      final obj = buildCtRepoLintSarifObject(
        executedRules: [a, b],
        failures: [(rule: a, exitCode: 2), (rule: b, exitCode: 1)],
      );
      final runs = obj['runs']! as List<Object?>;
      final run = runs.single! as Map<String, Object?>;
      final results = run['results']! as List<Object?>;
      expect(results.length, 2);

      final first = results[0]! as Map<String, Object?>;
      expect(first['ruleId'], 'repo.a');
      expect(first['ruleIndex'], 0);
      final loc0 =
          (first['locations']! as List<Object?>).single!
              as Map<String, Object?>;
      final phys0 = loc0['physicalLocation']! as Map<String, Object?>;
      final art0 = phys0['artifactLocation']! as Map<String, Object?>;
      expect(art0['uri'], 'tool/x.dart');

      final second = results[1]! as Map<String, Object?>;
      expect(second['ruleId'], 'repo.shell');
      expect(second['ruleIndex'], 1);
      final loc1 =
          (second['locations']! as List<Object?>).single!
              as Map<String, Object?>;
      final phys1 = loc1['physicalLocation']! as Map<String, Object?>;
      final art1 = phys1['artifactLocation']! as Map<String, Object?>;
      expect(art1['uri'], 'tool/check_test_imports.sh');
    });
  });

  group('encodeCtRepoLintSarif', () {
    test('produces decodable JSON', () {
      final r = _dartRule('repo.z');
      final text = encodeCtRepoLintSarif(
        executedRules: [r],
        failures: const [],
      );
      final decoded = jsonDecode(text) as Map<String, Object?>;
      expect(decoded['version'], '2.1.0');
    });
  });
}
