// Refs #4028 — guards `repo.diplomacy_relation_upsert_commit`.

import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_diplomacy_relation_upsert_commit.dart';

void main() {
  group('repo.diplomacy_relation_upsert_commit', () {
    test('passes on real repo workspace', () {
      final exitCode = runCheckDiplomacyRelationUpsertCommit(
        Directory.current.path,
        info: (_) {},
      );
      expect(exitCode, 0);
    });

    test('allows the helper module itself', () {
      expect(
        findDiplomacyRelationUpsertCommitViolations(
          relativePath:
              'packages/colonizethis_diplomacy/lib/src/diplomacy/diplomacy_relation_upsert.dart',
          source:
              'game.copyWith(diplomacyRelations: relationsIndex.toList());',
        ),
        isEmpty,
      );
    });

    test('fails on raw relationsIndex.toList commit outside helper', () {
      final violations = findDiplomacyRelationUpsertCommitViolations(
        relativePath:
            'packages/colonizethis_diplomacy/lib/src/diplomacy/war_resolver.dart',
        source: '''
Game f(Game game, RelationUpsertIndex relationsIndex) {
  return game.copyWith(
    diplomacyRelations: relationsIndex.toList(),
  );
}
''',
      );
      expect(violations, isNotEmpty);
      expect(violations.first, contains('committedRelations'));
    });

    test('fails when commit is split across lines', () {
      expect(
        findDiplomacyRelationUpsertCommitViolations(
          relativePath:
              'packages/colonizethis_diplomacy/lib/src/diplomacy/alliance_resolver.dart',
          source: '''
game = game.copyWith(
  diplomacyRelations:
      relationsIndex
          .toList(),
);
''',
        ),
        isNotEmpty,
      );
    });
  });
}
