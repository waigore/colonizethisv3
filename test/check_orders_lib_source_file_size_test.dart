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
    test('passes on current repo tree under wave-10 ceiling', () {
      expect(runCheckOrdersLibSourceFileSize('.'), 0);
    });

    test('wave-10 ceiling is 250 with an empty grandfather', () {
      expect(ordersLibSourceFileSizeCeiling, 250);
      expect(ordersLibSourceFileSizeGrandfathered, isEmpty);
    });

    test('wave-10 split entry files stay ≥20 lines under 250', () {
      const files = <String>[
        'packages/colonizethis_orders/lib/src/orders/orders_application_build_phase.dart',
        'packages/colonizethis_orders/lib/src/orders/validators/diplomatic/diplomatic_sub_validator.dart',
        'packages/colonizethis_orders/lib/src/orders/draft_orders_mutations.dart',
        'packages/colonizethis_orders/lib/src/orders/incremental_candidate_validator.dart',
        'packages/colonizethis_orders/lib/src/orders/order_suggestion_research.dart',
        'packages/colonizethis_orders/lib/src/orders/order_suggestion_pass_context.dart',
        'packages/colonizethis_orders/lib/src/orders/validator_bundle.dart',
        'packages/colonizethis_orders/lib/src/orders/order_suggestion_naval.dart',
        'packages/colonizethis_orders/lib/src/orders/per_player_work_target_selection_cache.dart',
        'packages/colonizethis_orders/lib/src/orders/order_engine.dart',
        'packages/colonizethis_orders/lib/src/orders/work_tile_candidacy/work_tile_candidate_index_prefilters.dart',
      ];
      for (final relative in files) {
        final lines = File(relative).readAsLinesSync().length;
        expect(
          lines,
          lessThanOrEqualTo(230),
          reason: '$relative is $lines physical lines (need ≤230)',
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
