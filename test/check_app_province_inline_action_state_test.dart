import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_province_inline_action_state.dart';

void main() {
  group('repo.app_province_inline_action_state', () {
    test('passes on real repo workspace', () {
      final logs = <String>[];
      final code = runCheckAppProvinceInlineActionState(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });

    test('fails on forbidden hasEngineerUnits record field', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_province_inline_action_state_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeOverlayHostStubs(temp.path);
      final lib = Directory(
        p.join(temp.path, 'app', 'lib', 'features', 'game', 'sample'),
      )..createSync(recursive: true);
      File(p.join(lib.path, 'bad.dart')).writeAsStringSync('''
({bool hasEngineerUnits}) kBad = (hasEngineerUnits: false);
''');
      final err = <String>[];
      final code = runCheckAppProvinceInlineActionState(
        temp.path,
        info: (_) {},
        err: err.add,
      );
      expect(code, 1);
      expect(err.join('\n'), contains('bad.dart'));
    });

    test('fails on 3-field hasBuilderUnits civilian remap', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_province_inline_builder_remap_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeOverlayHostStubs(temp.path);
      final lib = Directory(
        p.join(temp.path, 'app', 'lib', 'features', 'game', 'sample'),
      )..createSync(recursive: true);
      File(p.join(lib.path, 'bad.dart')).writeAsStringSync('''
({bool showIcon, bool enabled, bool hasBuilderUnits}) kBad = (
  showIcon: false,
  enabled: false,
  hasBuilderUnits: false,
);
''');
      final err = <String>[];
      final code = runCheckAppProvinceInlineActionState(
        temp.path,
        info: (_) {},
        err: err.add,
      );
      expect(code, 1);
      expect(err.join('\n'), contains('3-field record uses hasBuilderUnits'));
    });

    test('allows 4-field upgrade-town record with hasBuilderUnits', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_province_inline_upgrade_town_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeOverlayHostStubs(temp.path);
      final lib = Directory(
        p.join(
          temp.path,
          'app',
          'lib',
          'features',
          'game',
          'map_state',
        ),
      )..createSync(recursive: true);
      File(
        p.join(
          lib.path,
          'game_map_area_province_action_states_upgrade_town.dart',
        ),
      ).writeAsStringSync('''
const kHidden = (
  showControl: false,
  enabled: false,
  hasBuilderUnits: false,
  townTileKey: null,
);
''');
      final logs = <String>[];
      final code = runCheckAppProvinceInlineActionState(
        temp.path,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}

const _overlayHostPaths = {
  'app/lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_widget.dart':
      280,
  'app/lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_province_content.dart':
      280,
};

void _writeOverlayHostStubs(String tempRoot) {
  for (final entry in _overlayHostPaths.entries) {
    final file = File(p.join(tempRoot, entry.key));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('// line budget pin\n');
  }
}
