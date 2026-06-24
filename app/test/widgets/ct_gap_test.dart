import 'dart:io';

import 'package:colonizethis_app/widgets/ct_gap.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pinning + adoption tests for `CtGap` (Refs #3594, item 1).
///
/// `CtGap` provides named single-dimension [SizedBox] gaps sourced **only**
/// from the SPEC-pinned [CtSpacing] tokens — it introduces no new spacing
/// values, so adopting it across `app/lib/features/game/widgets/` is a
/// behavior-preserving, zero-golden-diff refactor.
///
/// SPEC: `SPEC/ui/pixel-art-ui-catalog.md` § *Spacing tokens* (the
/// `xs`/`s`/`m`/`ml`/`l`/`xl`/`xxl` scale that backs every `CtGap`).
void main() {
  suppressLogsForTests();

  group('CtGap maps each gap to the matching CtSpacing token', () {
    test('vertical CtGap.m is SizedBox(height: CtSpacing.m) == 8', () {
      expect(CtGap.m.height, CtSpacing.m);
      expect(CtGap.m.height, 8);
      expect(CtGap.m.width, isNull);
    });

    test('vertical CtGap.ml is SizedBox(height: CtSpacing.ml) == 12', () {
      expect(CtGap.ml.height, CtSpacing.ml);
      expect(CtGap.ml.height, 12);
      expect(CtGap.ml.width, isNull);
    });

    test('vertical CtGap.l is SizedBox(height: CtSpacing.l) == 16', () {
      expect(CtGap.l.height, CtSpacing.l);
      expect(CtGap.l.height, 16);
      expect(CtGap.l.width, isNull);
    });

    test('horizontal CtGap.wm is SizedBox(width: CtSpacing.m) == 8', () {
      expect(CtGap.wm.width, CtSpacing.m);
      expect(CtGap.wm.width, 8);
      expect(CtGap.wm.height, isNull);
    });
  });

  group('CtGap introduces no spacing values outside the CtSpacing scale', () {
    test('every CtGap dimension is a member of the CtSpacing token set', () {
      final tokenValues = <double>{
        CtSpacing.xs,
        CtSpacing.s,
        CtSpacing.m,
        CtSpacing.ml,
        CtSpacing.l,
        CtSpacing.xl,
        CtSpacing.xxl,
      };
      final gapDimensions = <double>[
        CtGap.m.height!,
        CtGap.ml.height!,
        CtGap.l.height!,
        CtGap.wm.width!,
      ];
      for (final dimension in gapDimensions) {
        expect(
          tokenValues.contains(dimension),
          isTrue,
          reason:
              'CtGap dimension $dimension is not a CtSpacing token; CtGap '
              'must forward existing tokens only (no new spacing values).',
        );
      }
    });

    test('source declares exactly the four SPEC-sourced gap fields', () {
      final file = File('lib/widgets/ct_gap.dart');
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'CtGap must live at app/lib/widgets/ct_gap.dart; test launched '
            'from ${Directory.current.path}.',
      );
      final declRegex = RegExp(r'^\s*static\s+const\s+SizedBox\s+(\w+)\s*=');
      final declarations = <String>[
        for (final line in file.readAsLinesSync())
          if (declRegex.firstMatch(line) case final m?) m.group(1)!,
      ];
      expect(
        declarations,
        equals(const <String>['m', 'ml', 'l', 'wm']),
        reason:
            'CtGap fields must match the Refs #3594 set (vertical m/ml/l '
            'plus horizontal wm). Adding a gap whose dimension is not a '
            'CtSpacing token requires a SPEC update first.',
      );
    });
  });

  group('CtGap renders the expected physical gap', () {
    testWidgets('CtGap.l lays out a 16px-tall box', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: CtGap.l),
        ),
      );
      final size = tester.getSize(find.byType(SizedBox));
      expect(size.height, 16);
    });

    testWidgets('CtGap.wm lays out an 8px-wide box', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: CtGap.wm),
        ),
      );
      final size = tester.getSize(find.byType(SizedBox));
      expect(size.width, 8);
    });
  });

  group('CtGap adoption: no raw token-gap SizedBox in features/game/widgets', () {
    // Negative/regression guard mapped to Refs #3594 AC #1: the migrated raw
    // forms must not creep back in. `SizedBox(width: 12)` and the off-scale
    // `4` gaps are intentionally NOT banned (no matching CtGap; `4` is absent
    // from CtSpacing and `width: 12` has no horizontal CtGap variant yet).
    final bannedGap = RegExp(
      r'SizedBox\(\s*(?:'
      r'height:\s*(?:8|12|16)'
      r'|width:\s*8'
      r')(?:\.0)?\s*\)',
    );

    test('the banned-gap detector matches migrated forms only', () {
      expect(bannedGap.hasMatch('const SizedBox(height: 8)'), isTrue);
      expect(bannedGap.hasMatch('const SizedBox(height: 12)'), isTrue);
      expect(bannedGap.hasMatch('SizedBox(height: 16.0)'), isTrue);
      expect(bannedGap.hasMatch('const SizedBox(width: 8)'), isTrue);
      // Out of scope: kept raw on purpose.
      expect(bannedGap.hasMatch('const SizedBox(width: 12)'), isFalse);
      expect(bannedGap.hasMatch('const SizedBox(width: 4)'), isFalse);
      expect(bannedGap.hasMatch('const SizedBox(height: 4)'), isFalse);
      // Migrated references are not flagged.
      expect(bannedGap.hasMatch('CtGap.m'), isFalse);
    });

    test('no migrated raw token gap remains under features/game/widgets', () {
      final dir = Directory('lib/features/game/widgets');
      expect(
        dir.existsSync(),
        isTrue,
        reason:
            'Expected lib/features/game/widgets to exist; test launched '
            'from ${Directory.current.path}.',
      );
      final offenders = <String>[];
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          if (bannedGap.hasMatch(line)) {
            offenders.add('  ${entity.path}:${i + 1}: ${line.trim()}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'Found raw token-gap SizedBox literals that must use CtGap '
            '(height: 8 → CtGap.m, height: 12 → CtGap.ml, '
            'height: 16 → CtGap.l, width: 8 → CtGap.wm):\n'
            '${offenders.join('\n')}',
      );
    });
  });
}
