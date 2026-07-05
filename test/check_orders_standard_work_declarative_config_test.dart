import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_orders_standard_work_declarative_config.dart';

void main() {
  group('runCheckOrdersStandardWorkDeclarativeConfig', () {
    test('passes on current repo tree', () {
      expect(runCheckOrdersStandardWorkDeclarativeConfig('.'), 0);
    });

    test('flags legacy builder map in temp work_handlers tree', () {
      final tempRoot = Directory.systemTemp.createTempSync(
        'ct_orders_standard_work_gate_',
      );
      addTearDown(() => tempRoot.deleteSync(recursive: true));

      final handlerDir = Directory(
        p.join(
          tempRoot.path,
          'packages/colonizethis_orders/lib/src/orders/work_handlers',
        ),
      )..createSync(recursive: true);
      File(p.join(handlerDir.path, 'standard_work_handler.dart')).writeAsStringSync(
        '''
enum _StandardWorkTargetKind { fixedMaterial }
const _standardWorkTargetKinds = {};
_StandardWorkTargetConfig _buildStandardWorkTargetConfig() =>
    throw UnimplementedError();
''',
      );
      File(p.join(handlerDir.path, 'legacy_handler.dart')).writeAsStringSync(
        'const _standardWorkTargetConfigBuilders = {};',
      );

      expect(runCheckOrdersStandardWorkDeclarativeConfig(tempRoot.path), 1);
    });
  });
}
