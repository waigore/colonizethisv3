import 'package:test/test.dart';

import '../tool/check_diplomacy_no_duplicate_overture_clear.dart';

void main() {
  group('findOvertureClearViolations', () {
    test('flags a negated directional pair-clear .where', () {
      const src = r'''
final next = game.overtureStates
    .where((o) => !(o.gpId == gpId && o.targetId == targetId))
    .toList();
''';
      final violations = findOvertureClearViolations(
        relativePath:
            'packages/colonizethis_diplomacy/lib/src/diplomacy/intervention_resolver_apply.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test('flags a negated bidirectional pair-clear .where', () {
      const src = r'''
overtures = overtures
    .where(
      (o) => !((o.gpId == id1 && o.targetId == id2) ||
          (o.gpId == id2 && o.targetId == id1)),
    )
    .toList();
''';
      final violations = findOvertureClearViolations(
        relativePath:
            'packages/colonizethis_diplomacy/lib/src/diplomacy/some_resolver.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test('does not flag positive overture lookups', () {
      const src = r'''
final match = overtures.where((o) => o.gpId == gpId && o.targetId == targetId);
final idx = overtures.indexWhere((o) => o.gpId == gpId && o.targetId == targetId);
''';
      final violations = findOvertureClearViolations(
        relativePath:
            'packages/colonizethis_diplomacy/lib/src/diplomacy/overture_resolver.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag single-faction teardown (!= on one id)', () {
      const src = r'''
final overtures = next.overtureStates
    .where((o) => o.gpId != absorbedFactionId && o.targetId != absorbedFactionId)
    .toList();
''';
      final violations = findOvertureClearViolations(
        relativePath:
            'packages/colonizethis_diplomacy/lib/src/diplomacy/faction_absorption_engine.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag pair-key set-membership diffs', () {
      const src = r'''
final keptKeys = {for (final n in overtures) '${n.gpId}|${n.targetId}'};
final removed = before
    .where((o) => !keptKeys.contains('${o.gpId}|${o.targetId}'))
    .toList();
''';
      final violations = findOvertureClearViolations(
        relativePath:
            'packages/colonizethis_diplomacy/lib/src/diplomacy/diplomacy_subsidies_relations_resolver.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });

  group('runCheckDiplomacyNoDuplicateOvertureClear', () {
    test('passes on current repo tree', () {
      expect(runCheckDiplomacyNoDuplicateOvertureClear('.'), 0);
    });
  });
}
