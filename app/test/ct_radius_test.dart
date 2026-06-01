import 'dart:io';

import 'package:colonizethis_app/widgets/ct_radius.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

/// Pinning tests for `CtRadius` (Refs #2914 S6).
///
/// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § *Radius tokens* —
/// authoritative table for the canonical
/// `small` / `medium` / `large` / `xl` scale.
void main() {
  suppressLogsForTests();

  group('CtRadius constants match SPEC § Radius tokens table', () {
    test('small is 2 (chip/tab corners)', () {
      expect(CtRadius.small, 2);
    });

    test('medium is 4 (default rounded chrome on rows/cells/compact panels)',
        () {
      expect(CtRadius.medium, 4);
    });

    test('large is 8 (dialog/panel outer frame rounding)', () {
      expect(CtRadius.large, 8);
    });

    test('xl is 12 (roomy dialog frames / full-screen overlays)', () {
      expect(CtRadius.xl, 12);
    });

    test('scale is strictly monotonic small<medium<large<xl', () {
      const ordered = <double>[
        CtRadius.small,
        CtRadius.medium,
        CtRadius.large,
        CtRadius.xl,
      ];
      for (var i = 1; i < ordered.length; i++) {
        expect(
          ordered[i],
          greaterThan(ordered[i - 1]),
          reason:
              'Token at index $i (${ordered[i]}) is not strictly greater '
              'than the previous token (${ordered[i - 1]}); the radius '
              'scale must remain strictly monotonic.',
        );
      }
    });

    test('scale stops at 12 — out-of-scale 24/1/6 are intentional overrides',
        () {
      final values = <double>{
        CtRadius.small,
        CtRadius.medium,
        CtRadius.large,
        CtRadius.xl,
      };
      expect(values.contains(24), isFalse);
      expect(values.contains(1), isFalse);
      expect(values.contains(6), isFalse);
    });
  });

  group('CtRadius API surface is the SPEC-pinned 4-token set only', () {
    // SPEC § Radius tokens AC #3 (shared with CtSpacing):
    //   "every Dart constant name and value matches a row in the
    //    corresponding token table and no extra named constants exist
    //    that are not present in the SPEC table."
    //
    // See `ct_spacing_test.dart` for the rationale on parsing the
    // source instead of enumerating members via `dart:mirrors`.
    test('source declares exactly the 4 SPEC-pinned static const fields', () {
      final file = File('lib/widgets/ct_radius.dart');
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'CtRadius must live at the SPEC-pinned path '
            'app/lib/widgets/ct_radius.dart; the test was launched from '
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
        equals(const <String>['small', 'medium', 'large', 'xl']),
        reason:
            'CtRadius static const fields must exactly match the SPEC '
            '§ Radius tokens table in the SPEC-pinned order. Adding '
            'or renaming a token requires a SPEC update first.',
      );
    });
  });
}
