import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_grain_bonus_shared_helper.dart';

const _helperRelative =
    'packages/colonizethis_economy/lib/src/economy/capital_tile_grain_bonus.dart';
const _extractor =
    'packages/colonizethis_economy/lib/src/economy/resource_extractor.dart';
const _scopes =
    'packages/colonizethis_economy/lib/src/economy/'
    'development_panel_read_model_scopes.dart';
const _snapshot =
    'packages/colonizethis_economy/lib/src/economy/'
    'province_extraction_snapshot_builder.dart';

const _helperSource = r'''
int? capitalTileGrainBonusForPlayer({required Game game, required Player player}) {
  return game.capitalTileGrainBonusPerTurn;
}
''';

const _ok = 'void f() { capitalTileGrainBonusForPlayer(); }\n';

const _inline =
    'void f() { addUnits(m, grain, game.capitalTileGrainBonusPerTurn); }\n';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckEconomyGrainBonusSharedHelper', () {
    test('passes when three consumers call the helper', () {
      final root = Directory.systemTemp.createTempSync('grain_ok');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _extractor, _ok);
      _writeFile(root, _scopes, _ok);
      _writeFile(root, _snapshot, _ok);

      final logs = <String>[];
      expect(
        runCheckEconomyGrainBonusSharedHelper(
          root.path,
          info: logs.add,
          err: logs.add,
        ),
        0,
        reason: logs.join('\n'),
      );
    });

    test('fails when a consumer inlines capitalTileGrainBonusPerTurn', () {
      final root = Directory.systemTemp.createTempSync('grain_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(root, _helperRelative, _helperSource);
      _writeFile(root, _extractor, _ok);
      _writeFile(root, _scopes, _ok);
      _writeFile(root, _snapshot, _inline);

      final logs = <String>[];
      final code = runCheckEconomyGrainBonusSharedHelper(
        root.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 1);
      expect(
        logs.join('\n'),
        contains('province_extraction_snapshot_builder.dart'),
      );
    });
  });
}
