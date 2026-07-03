// Pins the `Main Menu` Widgetbook folder inventory and the editorial-monocle
// pump contract for every desktop use case (Refs #2860 S6).
//
// Mobile-viewport stories (`Default (mobile)`, `Pixel art (mobile)`) are
// covered separately by `widgetbook_main_menu_mobile_viewport_test.dart`
// (Refs #2870 R22 / S9).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_compass_rose.dart';
import 'package:colonizethis_app/widgets/ct_fleur_de_lis_ornament.dart';
import 'package:colonizethis_app/widgets/ct_main_menu_collage.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';

import 'support/widget_test_assets.dart';
import 'support/widgetbook_test_harness.dart';

/// Normative inventory for issue #2860 S6 — renaming or removing a story
/// must fail this list before reviewers lose a state × variant combination.
const List<String> kMainMenuWidgetbookUseCaseNames = <String>[
  'Default',
  'With resume game',
  'After victory',
  'No saves',
  'Default (pixel)',
  'After victory (pixel)',
  'No saves (pixel)',
  'Resume game visible (pixel)',
  'Default (mobile)',
  'Pixel art (mobile)',
];

/// Desktop stories pumped under `AppThemes.editorialMonocle` (S6 AC).
const List<String> kMainMenuEditorialMonocleDesktopUseCaseNames = <String>[
  'Default',
  'With resume game',
  'After victory',
  'No saves',
  'Default (pixel)',
  'After victory (pixel)',
  'No saves (pixel)',
  'Resume game visible (pixel)',
];

WidgetbookFolder _mainMenuFolder() {
  return mainMenuDirectories.whereType<WidgetbookFolder>().firstWhere(
    (folder) => folder.name == 'Main Menu',
    orElse: () => fail('Missing Widgetbook folder: Main Menu'),
  );
}

bool _isPixelArtStory(String useCaseName) => useCaseName.contains('(pixel)');

Future<void> _pumpEditorialMonocleStory(
  WidgetTester tester,
  WidgetbookUseCase useCase,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.editorialMonocle,
      home: Builder(builder: useCase.builder),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(preloadNinePatchImage);

  group(
    'Main Menu Widgetbook editorial-monocle stories (Refs #2860 S6)',
    () {
      test(
        'mainMenuDirectories exposes the normative 10-story inventory',
        () {
          final names = (_mainMenuFolder().children ?? const <WidgetbookNode>[])
              .whereType<WidgetbookUseCase>()
              .map((uc) => uc.name)
              .toList();
          expect(names, kMainMenuWidgetbookUseCaseNames);
        },
      );

      for (final useCaseName in kMainMenuEditorialMonocleDesktopUseCaseNames) {
        testWidgets(
          '$useCaseName pumps under editorialMonocle without exceptions',
          (WidgetTester tester) async {
            await _pumpEditorialMonocleStory(tester, findWidgetbookUseCase(mainMenuDirectories, folderName: 'Main Menu', useCaseName: useCaseName));
            expect(
              tester.takeException(),
              isNull,
              reason:
                  'Widgetbook story "$useCaseName" must mount without '
                  'overflow or asset-missing fallbacks per SPEC/ui/main-menu.md '
                  '§ Widgetbook (Refs #2860 S6).',
            );
          },
        );

        testWidgets(
          '$useCaseName renders no Material ElevatedButton / TextButton / '
          'OutlinedButton chrome',
          (WidgetTester tester) async {
            await _pumpEditorialMonocleStory(tester, findWidgetbookUseCase(mainMenuDirectories, folderName: 'Main Menu', useCaseName: useCaseName));
            expect(find.byType(ElevatedButton), findsNothing);
            expect(find.byType(TextButton), findsNothing);
            expect(find.byType(OutlinedButton), findsNothing);
          },
        );

        testWidgets(
          '$useCaseName resolves editorial-monocle scaffold tokens',
          (WidgetTester tester) async {
            await _pumpEditorialMonocleStory(tester, findWidgetbookUseCase(mainMenuDirectories, folderName: 'Main Menu', useCaseName: useCaseName));
            final ThemeData theme = Theme.of(
              tester.element(find.byType(CtMainMenu)),
            );
            expect(theme.brightness, Brightness.dark);
            expect(
              theme.scaffoldBackgroundColor,
              EditorialMonoclePalette.bg,
            );
            expect(theme.colorScheme.primary, EditorialMonoclePalette.accent);
            expect(theme.colorScheme.surface, EditorialMonoclePalette.surface);
          },
        );

        if (_isPixelArtStory(useCaseName)) {
          testWidgets(
            '$useCaseName (pixelArt) mounts collage + compass + divider chrome',
            (WidgetTester tester) async {
              await _pumpEditorialMonocleStory(tester, findWidgetbookUseCase(mainMenuDirectories, folderName: 'Main Menu', useCaseName: useCaseName));
              expect(find.byType(CtMainMenuCollage), findsOneWidget);
              expect(find.byType(CtCompassRose), findsOneWidget);
              expect(find.byType(CtFleurDeLisOrnament), findsWidgets);
              expect(find.byType(CtBrassDivider), findsOneWidget);
            },
          );
        } else {
          testWidgets(
            '$useCaseName (plain) omits pixelArt-only decorative chrome',
            (WidgetTester tester) async {
              await _pumpEditorialMonocleStory(tester, findWidgetbookUseCase(mainMenuDirectories, folderName: 'Main Menu', useCaseName: useCaseName));
              expect(find.byType(CtMainMenuCollage), findsNothing);
              expect(find.byType(CtCompassRose), findsNothing);
              expect(find.byType(CtFleurDeLisOrnament), findsNothing);
              expect(find.byType(CtBrassDivider), findsNothing);
            },
          );
        }
      }
    },
  );
}
