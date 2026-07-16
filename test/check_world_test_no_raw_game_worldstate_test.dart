import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_world_test_no_raw_game_worldstate.dart';

void main() {
  group('runCheckWorldTestNoRawGameWorldState', () {
    test('fails when an in-scope fog test inlines Game(', () {
      final temp = Directory.systemTemp.createTempSync('world-raw-game-');
      try {
        final testDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_world', 'test', 'world'),
        )..createSync(recursive: true);
        File(
          p.join(testDir.path, 'fog_resolution_spy_decay_test.dart'),
        ).writeAsStringSync(
          "void main() {\n"
          "  final g = Game(id: 'g');\n"
          "}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckWorldTestNoRawGameWorldState(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(
          errors.join('\n'),
          contains('fog_resolution_spy_decay_test.dart'),
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when fog tests use builders only', () {
      final temp = Directory.systemTemp.createTempSync('world-raw-game-ok-');
      try {
        final testDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_world', 'test', 'world'),
        )..createSync(recursive: true);
        File(
          p.join(testDir.path, 'fog_resolution_spy_decay_test.dart'),
        ).writeAsStringSync(
          'void main() {\n'
          '  final g = fogDecayVisibilityGame(players: const []);\n'
          '}\n',
        );
        final supportDir = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_world',
            'test',
            'world_test_support',
          ),
        )..createSync(recursive: true);
        File(p.join(supportDir.path, 'fog_builders.dart')).writeAsStringSync(
          "Game fogDecayVisibilityGame({required List players}) =>\n"
          "    Game(id: 'g');\n",
        );

        final exitCode = runCheckWorldTestNoRawGameWorldState(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('worldTestNoRawGameWorldStatePathInScope', () {
    test('includes fog/capital/connectivity/ownership/player_view basenames', () {
      expect(
        worldTestNoRawGameWorldStatePathInScope(
          'packages/colonizethis_world/test/world/'
          'connectivity_resolver_non_gp_test.dart',
        ),
        isTrue,
      );
      expect(
        worldTestNoRawGameWorldStatePathInScope(
          'packages/colonizethis_world/test/world/'
          'province_ownership_transfer_test.dart',
        ),
        isTrue,
      );
      expect(
        worldTestNoRawGameWorldStatePathInScope(
          'packages/colonizethis_world/test/world/player_view_build_test.dart',
        ),
        isTrue,
      );
      expect(
        worldTestNoRawGameWorldStatePathInScope(
          'packages/colonizethis_world/test/world_test_support/fog_builders.dart',
        ),
        isFalse,
      );
      expect(
        worldTestNoRawGameWorldStatePathInScope(
          'packages/colonizethis_world/test/world/army_commands_test.dart',
        ),
        isFalse,
      );
    });

    test('fails when an in-scope ownership test inlines Game(', () {
      final temp = Directory.systemTemp.createTempSync('world-raw-own-');
      try {
        final testDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_world', 'test', 'world'),
        )..createSync(recursive: true);
        File(
          p.join(testDir.path, 'province_ownership_transfer_test.dart'),
        ).writeAsStringSync(
          "void main() {\n"
          "  final g = Game(id: 'g');\n"
          "}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckWorldTestNoRawGameWorldState(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(
          errors.join('\n'),
          contains('province_ownership_transfer_test.dart'),
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
