import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_combat_dedup_precombat_indexes.dart';

const _conflictRelative =
    'packages/colonizethis_combat/lib/src/combat/conflict_detection.dart';
const _unopposedRelative =
    'packages/colonizethis_combat/lib/src/combat/unopposed_province_capture.dart';

const _delegatingSource = r'''
import 'pre_combat_index.dart';

void run(Game game, Orders orders) {
  final index = PreCombatMovementIndex.build(game, orders);
  for (final move in index.greatPowerArmyMoves) {
    process(move);
  }
}
''';

const _reInlinedSource = r'''
void run(Game game, Orders orders) {
  // Re-introduced a private scan instead of delegating to the shared index.
  final moves = <ResolvedArmyMove>[];
  for (final order in orders.armyMoves) {
    moves.add(order);
  }
}
''';

void _writeConsumer(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckCombatDedupPrecombatIndexes', () {
    test('passes when both consumers delegate to PreCombatMovementIndex', () {
      final root = Directory.systemTemp.createTempSync('combat_dedup_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeConsumer(root, _conflictRelative, _delegatingSource);
      _writeConsumer(root, _unopposedRelative, _delegatingSource);

      final logs = <String>[];
      final code = runCheckCombatDedupPrecombatIndexes(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when a consumer drops the shared-index references', () {
      final root = Directory.systemTemp.createTempSync('combat_dedup_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeConsumer(root, _conflictRelative, _delegatingSource);
      _writeConsumer(root, _unopposedRelative, _reInlinedSource);

      final logs = <String>[];
      final code = runCheckCombatDedupPrecombatIndexes(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('PreCombatMovementIndex.build'));
    });

    test('fails when a consumer file is missing', () {
      final root = Directory.systemTemp.createTempSync('combat_dedup_missing');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeConsumer(root, _conflictRelative, _delegatingSource);

      final logs = <String>[];
      final code = runCheckCombatDedupPrecombatIndexes(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(logs.join('\n'), contains('Missing pre-combat index consumer'));
    });
  });
}
