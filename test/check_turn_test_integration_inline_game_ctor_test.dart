import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_turn_test_integration_inline_game_ctor.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('repo.turn_test_integration_inline_game_ctor', () {
    test('passes when integration scenarios use harness builders', () {
      final root = Directory.systemTemp.createTempSync('turn_integ_game_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_turn/test/support/integration/'
        'resolve_turn_combat_movement_scenarios.dart',
        "final game = adjacentOwP1P2Game();\n",
      );

      final logs = <String>[];
      final code = runCheckTurnTestIntegrationInlineGameCtor(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails when a new integration file inlines Game(', () {
      final root = Directory.systemTemp.createTempSync('turn_integ_game_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_turn/test/support/integration/'
        'resolve_turn_new_scenarios.dart',
        'final game = Game(id: "g1");\n',
      );

      final logs = <String>[];
      final code = runCheckTurnTestIntegrationInlineGameCtor(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('resolve_turn_new_scenarios.dart'),
      );
    });

    test('grandfathers allowlisted integration files with inline Game(', () {
      final root =
          Directory.systemTemp.createTempSync('turn_integ_game_grandfather');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_turn/test/support/integration/'
        'resolve_turn_economy_continued_scenarios.dart',
        'final game = Game(id: "g1");\n',
      );

      final logs = <String>[];
      final code = runCheckTurnTestIntegrationInlineGameCtor(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
