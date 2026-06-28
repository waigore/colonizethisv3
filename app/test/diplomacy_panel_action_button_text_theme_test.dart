// Regression test for Refs #2914 S7 — diplomacy-panel action button must
// resolve its caption text style through the M3 dark `bodySmall` slot on
// `AppThemes.editorialMonocle.textTheme` rather than a hard-coded
// `const TextStyle(fontSize: 12)` literal.
//
// `_ActionButton` lives in `diplomacy_panel_row.dart` (extracted from
// `diplomacy_panel.dart`).
//
// SPEC:
//  * `SPEC/ui/pixel-art-ui-catalog.md` § *Editorial-monocle palette* —
//    canonical TextTheme contract (M3 dark slot table).
//  * Issue #2914 § "3. Hardcoded `fontSize:` values bypassing the theme
//    TextTheme" pins the slot → size mapping; `bodySmall == 12`.
//
// Source-scan style (no `WidgetTester`) is sufficient because the action
// button's text style is constructed inline and the regression vector is
// a `style: const TextStyle(fontSize: 12)` literal reappearing on the
// `_ActionButton` build path. Pumping the widget would add Flame /
// Riverpod boot scaffolding without exercising more of the contract this
// slice closes.

import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group(
    'diplomacy_panel_row.dart _ActionButton routes caption through TextTheme '
    '(Refs #2914 S7 regression guard)',
    () {
      late final String diplomacyPanelRowSource;

      setUpAll(() {
        // `flutter test` runs from the package root (`app/`); the source
        // path is therefore relative to that working directory.
        final File source =
            File('lib/features/game/widgets/diplomacy_panel_row.dart');
        expect(
          source.existsSync(),
          isTrue,
          reason:
              'Expected `app/lib/features/game/widgets/diplomacy_panel_row.dart` '
              'to exist; running directory is `${Directory.current.path}`.',
        );
        diplomacyPanelRowSource = source.readAsStringSync();
      });

      test(
          'imports `Theme.of(context).textTheme.bodySmall` fallback for the '
          'action-button caption', () {
        // The fallback must use the canonical M3 dark `bodySmall` slot
        // (12 dp per the SPEC slot→size table); the regex pins the slot
        // *and* the fallback size together so a slot rename or size
        // change is caught even if the literal `12` is left intact.
        final RegExp slotFallback = RegExp(
          r'textTheme\.bodySmall\s*\?\?\s*const\s+TextStyle\s*\(\s*'
          r'fontSize:\s*12\s*\)',
        );
        expect(
          slotFallback.hasMatch(diplomacyPanelRowSource),
          isTrue,
          reason:
              'Expected `_ActionButton.build` in `diplomacy_panel_row.dart` to '
              'resolve its caption text style via '
              '`theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)` '
              '(Refs #2914 S7). If the slot was intentionally changed, '
              'update both this test and the SPEC/ui/pixel-art-ui-catalog.md '
              'slot→size table first.',
        );
      });

      test(
          'does not declare any inline `style: const TextStyle(fontSize: ...)` '
          'literal on a child', () {
        // Negative regression vector: removing the slot fallback and
        // going back to `style: const TextStyle(fontSize: N)` reintroduces
        // the exact hard-coded literal this slice removed.
        final RegExp inlineHardCoded = RegExp(
          r'style:\s*const\s+TextStyle\s*\(\s*fontSize:\s*\d+',
        );
        final Iterable<RegExpMatch> matches =
            inlineHardCoded.allMatches(diplomacyPanelRowSource);
        expect(
          matches,
          isEmpty,
          reason:
              'Found ${matches.length} `style: const TextStyle(fontSize: N)` '
              'literal(s) in `diplomacy_panel_row.dart`. Each must route through '
              '`Theme.of(context).textTheme.<slot> ?? const TextStyle(...)` '
              'per Refs #2914 S7 so font, weight, and colour flow from '
              '`AppThemes.editorialMonocle`. Offending occurrences: '
              '${matches.map((m) => m.group(0)).join(' | ')}.',
        );
      });
    },
  );
}
