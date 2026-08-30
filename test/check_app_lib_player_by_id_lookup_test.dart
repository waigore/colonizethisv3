import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_lib_player_by_id_lookup.dart';

void main() {
  group('repo.app_lib_player_by_id_lookup', () {
    test('passes on real repo workspace', () {
      final logs = <String>[];
      final code = runCheckAppLibPlayerByIdLookup(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
    test('fails on for-loop p.id lookup', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_lib_player_by_id_fail_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      final lib = Directory(p.join(temp.path, 'app', 'lib'))
        ..createSync(recursive: true);
      File(p.join(lib.path, 'sample.dart')).writeAsStringSync('''
class Game { List<Player> get players => const []; }
class Player { String get id => ''; }
Player? lookup(Game game, String x) {
  for (final p in game.players) {
    if (p.id == x) return p;
  }
  return null;
}
''');
      final err = <String>[];
      final code = runCheckAppLibPlayerByIdLookup(
        temp.path,
        info: (_) {},
        err: err.add,
      );
      expect(code, 1);
      expect(err.join('\n'), contains('sample.dart'));
    });

    test('fails on players.where id lookup', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_lib_player_by_id_where_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      final lib = Directory(p.join(temp.path, 'app', 'lib'))
        ..createSync(recursive: true);
      File(p.join(lib.path, 'sample.dart')).writeAsStringSync('''
class Game { List<Player> get players => const []; }
class Player { String get id => ''; }
Player? lookup(Game game, String x) {
  return game.players.where((p) => p.id == x).firstOrNull;
}
''');
      final err = <String>[];
      final code = runCheckAppLibPlayerByIdLookup(
        temp.path,
        info: (_) {},
        err: err.add,
      );
      expect(code, 1);
      expect(err.join('\n'), contains('sample.dart'));
    });

    test('passes capital-predicate and full-list map transform', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_lib_player_by_id_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      final lib = Directory(p.join(temp.path, 'app', 'lib'))
        ..createSync(recursive: true);
      File(p.join(lib.path, 'sample.dart')).writeAsStringSync('''
class Game { List<Player> get players => const []; }
class Player {
  String get id => '';
  String? get capitalProvinceId => null;
  bool get isHuman => false;
}
bool isCapital(Game game, String provinceId) {
  for (final p in game.players) {
    if (p.capitalProvinceId == provinceId) return true;
  }
  return false;
}
Map<String, bool> humans(Game game) =>
    {for (final p in game.players) p.id: p.isHuman};
''');
      final logs = <String>[];
      final code = runCheckAppLibPlayerByIdLookup(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
