import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_dedup_advanced_start_selection.dart';

void main() {
  group('findSetupDedupAdvancedStartSelectionViolations', () {
    const canonicalPath =
        'packages/colonizethis_setup/lib/src/setup/advanced_start_selection.dart';
    const prospectingPath =
        'packages/colonizethis_setup/lib/src/setup/advanced_start_bootstrap_prospecting.dart';
    const developmentPath =
        'packages/colonizethis_setup/lib/src/setup/advanced_start_bootstrap_development.dart';

    test('flags minor-buyer round-robin modulo', () {
      const src = '''
final buyerId = game.players[i % game.players.length].id;
''';
      final violations = findSetupDedupAdvancedStartSelectionViolations(
        sourcesByPath: const {prospectingPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('minorBuyerIdRoundRobin'));
    });

    test('flags fraction ceil+take selection', () {
      const src = '''
final target = (candidates.length * fraction).ceil();
final selected = candidates.take(target).toList();
''';
      final violations = findSetupDedupAdvancedStartSelectionViolations(
        sourcesByPath: const {developmentPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('selectByFractionCeil'));
    });

    test('accepts shared helpers', () {
      const src = '''
final buyerId = minorBuyerIdRoundRobin(game, i);
final selected = selectByFractionCeil(candidates, fraction);
''';
      final violations = findSetupDedupAdvancedStartSelectionViolations(
        sourcesByPath: const {prospectingPath: src},
      );
      expect(violations, isEmpty);
    });

    test('exempts the canonical selection module', () {
      const src = '''
return players[index % players.length].id;
final target = (sortedCandidates.length * fraction).ceil();
return sortedCandidates.take(target).toList();
''';
      final violations = findSetupDedupAdvancedStartSelectionViolations(
        sourcesByPath: const {canonicalPath: src},
      );
      expect(violations, isEmpty);
    });

    test('ignores comment lines', () {
      const src = '''
// final buyerId = game.players[i % game.players.length].id;
/// Avoid (n * fraction).ceil() then .take(target).
''';
      final violations = findSetupDedupAdvancedStartSelectionViolations(
        sourcesByPath: const {developmentPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup source tree', () {
      final repoRoot = _repoRoot();
      final code = runCheckSetupDedupAdvancedStartSelection(
        repoRoot,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final manifest = File(
      p.join(dir.path, 'tool', 'ct_repo_lint_manifest.yaml'),
    );
    if (manifest.existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
