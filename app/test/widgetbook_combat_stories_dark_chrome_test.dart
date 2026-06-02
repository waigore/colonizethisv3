// Pins SPEC/ui/quick-battle-screen.md § Widgetbook S6 contract (Refs #2869 S6 /
// AC: "Given Widgetbook is launched with the dark theme active, when each of
// the 11 existing combat stories renders, then none throws, all chrome
// resolves from dark-theme tokens, and no Material `ElevatedButton`,
// `TextButton`, or `OutlinedButton` appears in any of the rendered widget
// trees").
//
// The Widgetbook directory `combatUiDirectories.Quick Battle` enumerates the
// 11 stories that issue #2869 declares in scope (S6: "Update the 11 existing
// Widgetbook stories listed under 'Tests / Widgetbook' to render against the
// dark theme (no new stories)"). This test pins all three sub-claims of that
// acceptance criterion:
//
//   1. Every story builder mounts without throwing.
//   2. The Material-design ban from `SPEC/ui/pixel-art-ui-catalog.md`
//      (`ElevatedButton`, `TextButton`, `OutlinedButton`) holds in every
//      rendered tree.
//   3. The ambient theme resolves to `AppThemes.editorialMonocle` so the
//      story chrome inherits the dark-theme scaffold background
//      (`EditorialMonoclePalette.bg`) and dark `colorScheme`.

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

/// Stable ordered list of every use-case name that appears under the
/// `Quick Battle` folder in `combatUiDirectories`. The order mirrors
/// `app/lib/widgetbook/catalog_part3.dart`. The 11 names match issue
/// #2869's "Tests / Widgetbook" inventory exactly; a future addition or
/// rename will fail this list before the dark-chrome assertions run, which
/// is the desired regression guard for the S6 scope ("no new stories").
const List<String> _combatStoryUseCaseNames = <String>[
  'Quick Battle Screen — non-interactive',
  'Quick Battle Screen — interactive',
  'Deployment view',
  'Action selector — full CP',
  'Action selector — 1 CP (assault disabled)',
  'Action selector — spent (0 CP)',
  'Combat mode choice — regular province',
  'Combat mode choice — capital siege',
  'Quick Battle result — attacker wins, province flips',
  'Quick Battle result — defender holds',
  'Quick Battle result — mutual exhaustion',
];

WidgetbookUseCase _quickBattleUseCase(String useCaseName) {
  final folder = combatUiDirectories
      .whereType<WidgetbookFolder>()
      .firstWhere(
        (f) => f.name == 'Quick Battle',
        orElse: () => fail(
          'Missing Widgetbook folder "Quick Battle" in combatUiDirectories '
          '(got: ${combatUiDirectories.map((d) => d.name).toList()}).',
        ),
      );
  final children = folder.children ?? const <WidgetbookNode>[];
  return children.whereType<WidgetbookUseCase>().firstWhere(
        (uc) => uc.name == useCaseName,
        orElse: () => fail(
          'Missing Quick Battle use case "$useCaseName" '
          '(got: ${children.map((c) => c.name).toList()}).',
        ),
      );
}

void main() {
  suppressLogsForTests();

  group(
    'Combat Widgetbook stories (Refs #2869 S6 — '
    'SPEC/ui/quick-battle-screen.md § Widgetbook)',
    () {
      testWidgets(
        'Quick Battle folder exposes exactly the 11 in-scope use cases',
        (WidgetTester tester) async {
          final folder = combatUiDirectories
              .whereType<WidgetbookFolder>()
              .firstWhere(
                (f) => f.name == 'Quick Battle',
                orElse: () => fail(
                  'Missing Widgetbook folder "Quick Battle" in '
                  'combatUiDirectories.',
                ),
              );
          final renderedNames = (folder.children ?? const <WidgetbookNode>[])
              .whereType<WidgetbookUseCase>()
              .map((uc) => uc.name)
              .toList();
          expect(
            renderedNames,
            _combatStoryUseCaseNames,
            reason:
                'Issue #2869 S6 scope is "no new stories"; any add/remove/'
                'rename in `combatUiDirectories` must be reflected in this '
                'pinned list and the related SPEC inventory.',
          );
        },
      );

      for (final useCaseName in _combatStoryUseCaseNames) {
        testWidgets(
          '"$useCaseName" mounts without Material ElevatedButton / '
          'TextButton / OutlinedButton',
          (WidgetTester tester) async {
            final story = _quickBattleUseCase(useCaseName);
            await tester.pumpWidget(
              story.builder(tester.element(find.byType(View))),
            );
            await tester.pump();

            expect(
              tester.takeException(),
              isNull,
              reason: 'Story "$useCaseName" threw during build/pump.',
            );

            expect(
              find.byType(ElevatedButton),
              findsNothing,
              reason:
                  'Story "$useCaseName" rendered a Material ElevatedButton '
                  '(banned by SPEC/ui/pixel-art-ui-catalog.md '
                  '§ Material design ban).',
            );
            expect(
              find.byType(TextButton),
              findsNothing,
              reason:
                  'Story "$useCaseName" rendered a Material TextButton '
                  '(banned by SPEC/ui/pixel-art-ui-catalog.md '
                  '§ Material design ban).',
            );
            expect(
              find.byType(OutlinedButton),
              findsNothing,
              reason:
                  'Story "$useCaseName" rendered a Material OutlinedButton '
                  '(banned by SPEC/ui/pixel-art-ui-catalog.md '
                  '§ Material design ban).',
            );
          },
        );

        testWidgets(
          '"$useCaseName" inherits AppThemes.editorialMonocle scaffold + '
          'dark colorScheme',
          (WidgetTester tester) async {
            final story = _quickBattleUseCase(useCaseName);
            await tester.pumpWidget(
              story.builder(tester.element(find.byType(View))),
            );
            await tester.pump();

            final BuildContext scaffoldContext = tester.element(
              find.byType(Scaffold).first,
            );
            final ThemeData theme = Theme.of(scaffoldContext);

            expect(
              theme.brightness,
              Brightness.dark,
              reason:
                  'Story "$useCaseName" must render under the dark '
                  'editorial-monocle theme (Refs #2869 S6 / R1).',
            );
            expect(
              theme.scaffoldBackgroundColor,
              EditorialMonoclePalette.bg,
              reason:
                  'Story "$useCaseName" scaffold background must resolve to '
                  'EditorialMonoclePalette.bg from AppThemes.editorialMonocle '
                  '(no light-theme parchment regression).',
            );
            expect(
              theme.colorScheme.primary,
              EditorialMonoclePalette.accent,
              reason:
                  'Story "$useCaseName" colorScheme.primary must resolve to '
                  'the --accent token (no Material default purple regression).',
            );
            expect(
              theme.colorScheme.surface,
              EditorialMonoclePalette.surface,
              reason:
                  'Story "$useCaseName" colorScheme.surface must resolve to '
                  'the --surface token.',
            );
          },
        );
      }
    },
  );
}
