import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_orders_lib_source_file_size.dart';

void _writeFile(Directory root, String relative, String source) {
  final file = File(p.join(root.path, relative));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
}

void main() {
  group('runCheckOrdersLibSourceFileSize', () {
    test('passes on current repo tree under wave-9 ceiling', () {
      expect(runCheckOrdersLibSourceFileSize('.'), 0);
    });

    test('wave-9 ceiling is 300 with an empty grandfather', () {
      expect(ordersLibSourceFileSizeCeiling, 300);
      expect(ordersLibSourceFileSizeGrandfathered, isEmpty);
    });

    test('wave-9 split entry files stay ≥30 lines under 300', () {
      const files = <String>[
        'packages/colonizethis_orders/lib/src/orders/order_suggestion_work_explorer.dart',
        'packages/colonizethis_orders/lib/src/orders/order_suggestion_diplomatic_candidates.dart',
        'packages/colonizethis_orders/lib/src/orders/order_suggestion_army_move_picker.dart',
        'packages/colonizethis_orders/lib/src/orders/orders_application_completed_work_handlers.dart',
        'packages/colonizethis_orders/lib/src/orders/incremental_candidate_validator.dart',
        'packages/colonizethis_orders/lib/src/orders/orders_application_context.dart',
      ];
      for (final relative in files) {
        final lines = File(relative).readAsLinesSync().length;
        expect(
          lines,
          lessThanOrEqualTo(270),
          reason: '$relative is $lines physical lines (need ≤270)',
        );
      }
    });

    test('fails when an orders lib file exceeds the ceiling', () {
      final root = Directory.systemTemp.createTempSync('orders_src_size_bad');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_orders/lib/src/orders/fat.dart',
        List.generate(12, (i) => '// line $i').join('\n'),
      );

      final errors = <String>[];
      final code = runCheckOrdersLibSourceFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [],
        info: (_) {},
        err: errors.add,
      );
      expect(code, 1);
      expect(errors.join('\n'), contains('fat.dart'));
    });

    test('ignores generated files and shrink-only grandfather entries', () {
      final root = Directory.systemTemp.createTempSync('orders_src_size_gen');
      addTearDown(() => root.deleteSync(recursive: true));
      _writeFile(
        root,
        'packages/colonizethis_orders/lib/src/orders/models.g.dart',
        List.generate(12, (i) => '// generated $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_orders/lib/src/orders/grandfathered.dart',
        List.generate(12, (i) => '// grandfathered $i').join('\n'),
      );
      _writeFile(
        root,
        'packages/colonizethis_orders/lib/src/orders/ok.dart',
        '// small\n',
      );

      final logs = <String>[];
      final code = runCheckOrdersLibSourceFileSize(
        root.path,
        ceiling: 10,
        grandfatheredPaths: const [
          'packages/colonizethis_orders/lib/src/orders/grandfathered.dart',
        ],
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
