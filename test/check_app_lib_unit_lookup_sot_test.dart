import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_lib_unit_lookup_sot.dart';

void main() {
  group('repo.app_lib_unit_lookup_sot', () {
    test('passes on real repo workspace', () {
      final logs = <String>[];
      final code = runCheckAppLibUnitLookupSot(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
    test('fails on dual-region unit concatenation', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_lib_unit_lookup_concat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      final lib = Directory(p.join(temp.path, 'app', 'lib'))
        ..createSync(recursive: true);
      File(p.join(lib.path, 'sample.dart')).writeAsStringSync('''
class RegionData { List<Unit> get units => const []; }
class WorldState {
  RegionData get oldWorld => RegionData();
  RegionData get newWorld => RegionData();
}
class Game { WorldState get worldState => WorldState(); }
class Unit { String get id => ''; }
List<Unit> all(Game game) => [
  ...game.worldState.oldWorld.units,
  ...game.worldState.newWorld.units,
];
''');
      final err = <String>[];
      final code = runCheckAppLibUnitLookupSot(
        temp.path,
        info: (_) {},
        err: err.add,
      );
      expect(code, 1);
      expect(err.join('\n'), contains('sample.dart'));
    });

    test('fails on dual-region unit.id walks', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_lib_unit_lookup_id_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      final lib = Directory(p.join(temp.path, 'app', 'lib'))
        ..createSync(recursive: true);
      File(p.join(lib.path, 'sample.dart')).writeAsStringSync('''
class RegionData { List<Unit> get units => const []; }
class WorldState {
  RegionData get oldWorld => RegionData();
  RegionData get newWorld => RegionData();
}
class Game { WorldState get worldState => WorldState(); }
class Unit { String get id => ''; }
Unit? find(Game game, String unitId) {
  for (final unit in game.worldState.oldWorld.units) {
    if (unit.id == unitId) return unit;
  }
  for (final unit in game.worldState.newWorld.units) {
    if (unit.id == unitId) return unit;
  }
  return null;
}
''');
      final err = <String>[];
      final code = runCheckAppLibUnitLookupSot(
        temp.path,
        info: (_) {},
        err: err.add,
      );
      expect(code, 1);
      expect(err.join('\n'), contains('sample.dart'));
    });

    test('passes single-region named-function argument', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_lib_unit_lookup_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      final lib = Directory(p.join(temp.path, 'app', 'lib'))
        ..createSync(recursive: true);
      File(p.join(lib.path, 'sample.dart')).writeAsStringSync('''
class RegionData { List<Unit> get units => const []; }
class WorldState {
  RegionData get oldWorld => RegionData();
  RegionData get newWorld => RegionData();
}
class Game { WorldState get worldState => WorldState(); }
class Unit {}
List<Unit> civilianUnitsInRegionForOwners(List<Unit> units, Object a, Object b, Object c) => units;
void build(Game game) {
  civilianUnitsInRegionForOwners(game.worldState.oldWorld.units, {}, {}, {});
  civilianUnitsInRegionForOwners(game.worldState.newWorld.units, {}, {}, {});
}
''');
      final logs = <String>[];
      final code = runCheckAppLibUnitLookupSot(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
