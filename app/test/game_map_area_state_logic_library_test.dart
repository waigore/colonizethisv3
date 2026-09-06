// Static library pins for game_map_area_state_logic (#4018, #4734 Slice J).
import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  suppressLogsForTests();

  group('GameMapAreaStateLogic explicit-import library (#4018, #4117)', () {
    test('positive: state-logic library has no part directives or Api* hops', () {
      final mapStateDir = Directory(
        '${Directory.current.path}/lib/features/game/flame/map_state',
      );
      final names = mapStateDir
          .listSync()
          .whereType<File>()
          .map((f) => p.basename(f.path))
          .toList();
      expect(names, contains('game_map_area_state_logic.dart'));
      expect(names, isNot(contains('game_map_area_state_logic_forwarders.dart')));
      expect(names.where((n) => n.contains('forwarders_')).toList(), isEmpty);
      final library = File(
        '${mapStateDir.path}/game_map_area_state_logic.dart',
      ).readAsStringSync();
      expect(library.contains('_GameMapAreaStateLogicApi'), isFalse);
      expect(
        library.contains("export 'game_map_area_state_logic_shell.dart';"),
        isTrue,
      );
      expect(
        library.contains("export 'game_map_area_state_logic_work_targets.dart';"),
        isTrue,
      );
      expect(
        library.contains(
          "export 'game_map_area_state_logic_draft_projection.dart';",
        ),
        isTrue,
      );
      expect(
        library.contains(
          "export 'game_map_area_state_logic_province_actions.dart';",
        ),
        isTrue,
      );
    });

    test('negative: state-logic library does not declare part directives', () {
      final library = File(
        '${Directory.current.path}/lib/features/game/flame/map_state/'
        'game_map_area_state_logic.dart',
      ).readAsStringSync();
      expect(
        library.contains("part 'game_map_area_state_logic_forwarders_"),
        isFalse,
      );
      expect(
        RegExp(r'^\s*part\s+', multiLine: true).hasMatch(library),
        isFalse,
      );
      expect(
        RegExp(r'^\s*part\s+of\s+', multiLine: true).hasMatch(library),
        isFalse,
      );
    });
  });
}
