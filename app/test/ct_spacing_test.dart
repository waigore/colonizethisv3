import 'dart:io';

import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

/// Pinning tests for `CtSpacing` (Refs #2914 S5).
///
/// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens* —
/// authoritative table for the canonical
/// `xs` / `s` / `m` / `ml` / `l` / `xl` / `xxl` scale.
void main() {
  suppressLogsForTests();

  group('CtSpacing constants match SPEC § Spacing tokens table', () {
    test('xs is 2 (hairline gaps)', () {
      expect(CtSpacing.xs, 2);
    });

    test('s is 6 (resource-cell horizontal padding)', () {
      expect(CtSpacing.s, 6);
    });

    test('m is 8 (default screen-shell / compact panel inner padding)', () {
      expect(CtSpacing.m, 8);
    });

    test('ml is 12 (mid-density panel insets / button row gaps)', () {
      expect(CtSpacing.ml, 12);
    });

    test('l is 16 (default-density card / dialog block padding)', () {
      expect(CtSpacing.l, 16);
    });

    test('xl is 20 (full-screen dialogue shell inner padding)', () {
      expect(CtSpacing.xl, 20);
    });

    test('xxl is 24 (low-density block padding)', () {
      expect(CtSpacing.xxl, 24);
    });

    test('scale is strictly monotonically increasing xs<s<m<ml<l<xl<xxl', () {
      const ordered = <double>[
        CtSpacing.xs,
        CtSpacing.s,
        CtSpacing.m,
        CtSpacing.ml,
        CtSpacing.l,
        CtSpacing.xl,
        CtSpacing.xxl,
      ];
      for (var i = 1; i < ordered.length; i++) {
        expect(
          ordered[i],
          greaterThan(ordered[i - 1]),
          reason:
              'Token at index $i (${ordered[i]}) is not strictly greater '
              'than the previous token (${ordered[i - 1]}); the spacing '
              'scale must remain strictly monotonic so callsites can pick '
              'a token by relative density.',
        );
      }
    });

    test('scale skips values 4, 10, and 14 per SPEC prose', () {
      final values = <double>{
        CtSpacing.xs,
        CtSpacing.s,
        CtSpacing.m,
        CtSpacing.ml,
        CtSpacing.l,
        CtSpacing.xl,
        CtSpacing.xxl,
      };
      expect(values.contains(4), isFalse);
      expect(values.contains(10), isFalse);
      expect(values.contains(14), isFalse);
    });
  });

  group('CtSpacing API surface is the SPEC-pinned 7-token set only', () {
    // SPEC § Spacing tokens AC #3:
    //   "every Dart constant name and value matches a row in the
    //    corresponding token table and no extra named constants exist
    //    that are not present in the SPEC table."
    //
    // Enumerating class members at runtime needs `dart:mirrors`, which
    // is not available in widget tests. Instead, parse the source file
    // directly and assert the `static const` declarations match the
    // SPEC table exactly. The file path is stable per SPEC §
    // *Spacing tokens* ("lands as `CtSpacing` constants in
    // `app/lib/widgets/ct_spacing.dart`").
    test('source declares exactly the 7 SPEC-pinned static const fields', () {
      final file = File('lib/widgets/ct_spacing.dart');
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'CtSpacing must live at the SPEC-pinned path '
            'app/lib/widgets/ct_spacing.dart; the test was launched from '
            '${Directory.current.path}, expected file '
            '${file.absolute.path}.',
      );
      final lines = file.readAsLinesSync();
      final declarations = <String>[];
      final declRegex = RegExp(r'^\s*static\s+const\s+double\s+(\w+)\s*=');
      for (final line in lines) {
        final m = declRegex.firstMatch(line);
        if (m != null) declarations.add(m.group(1)!);
      }
      expect(
        declarations,
        equals(const <String>['xs', 's', 'm', 'ml', 'l', 'xl', 'xxl']),
        reason:
            'CtSpacing static const fields must exactly match the SPEC '
            '§ Spacing tokens table in the SPEC-pinned order. Adding '
            'or renaming a token requires a SPEC update first.',
      );
    });
  });
}
