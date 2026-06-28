// Widget test pin for the `Main Menu` → `Default (mobile)` and
// `Pixel art (mobile)` Widgetbook use cases under
// `app/lib/widgetbook/catalog.dart`.
//
// Pins three SPEC contracts (Refs #2870 R22 / S9):
//
//  1. Both mobile use cases are wired into the public
//     `mainMenuDirectories` getter (so renaming or removing them surfaces
//     here in CI before reviewers lose the mobile-viewport story for the
//     Main Menu surface).
//  2. The `Default (mobile)` builder pumps without exceptions inside the
//     shared `mobileViewport` (360 × 640 dp `MediaQuery.size`) frame.
//  3. The `Pixel art (mobile)` builder pumps without exceptions inside
//     the same frame, so the `≤ 430 dp` letter-spacing override and the
//     compact menu-container padding rules in
//     `SPEC/ui/main-menu.md` § Variant rendering are reviewable in
//     Widgetbook without resizing the host window.
//
// Together these pins enforce that the player-app exposes a reviewable
// `< 600 dp` Main Menu story for both `plain` and `pixelArt` variants
// per `SPEC/ui/mobile-adaptation.md` § 6 and the Widgetbook AC under
// the cross-cutting `Refs #2870` mobile-adaptation issue.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/widgetbook/catalog.dart';

import 'support/widget_test_assets.dart';

WidgetbookUseCase _useCase(
  List<WidgetbookNode> directories, {
  required String folderName,
  required String useCaseName,
}) {
  final folder = directories.whereType<WidgetbookFolder>().firstWhere(
    (folder) => folder.name == folderName,
    orElse: () =>
        fail('Missing Widgetbook folder: $folderName (got: $directories)'),
  );
  final children = folder.children ?? const <WidgetbookNode>[];
  final useCase = children.whereType<WidgetbookUseCase>().firstWhere(
    (uc) => uc.name == useCaseName,
    orElse: () => fail(
      'Missing use case "$useCaseName" in folder "$folderName" '
      '(got: ${children.map((c) => c.name).toList()})',
    ),
  );
  return useCase;
}

Future<void> _pumpMobileViewport(
  WidgetTester tester,
  WidgetbookUseCase useCase,
) async {
  // Match the surface bound by the production `mobileViewport` helper
  // (`SizedBox(width: 360, height: 640)`) so the explicit MediaQuery the
  // helper overlays maps to the surface bounds.
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(360, 640));

  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: Size(360, 640)),
      child: MaterialApp(
        home: Builder(builder: (BuildContext ctx) => useCase.builder(ctx)),
      ),
    ),
  );
  // Drive past the post-mount frame so async font / image dependencies
  // settle before the test ends.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(preloadNinePatchImage);

  group(
    'Main Menu Widgetbook mobile-viewport stories (Refs #2870 R22 / S9)',
    () {
      testWidgets(
        'Default (mobile) is wired into mainMenuDirectories under the '
        'canonical folder + name',
        (WidgetTester tester) async {
          final useCase = _useCase(
            mainMenuDirectories,
            folderName: 'Main Menu',
            useCaseName: 'Default (mobile)',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Pixel art (mobile) is wired into mainMenuDirectories under the '
        'canonical folder + name',
        (WidgetTester tester) async {
          final useCase = _useCase(
            mainMenuDirectories,
            folderName: 'Main Menu',
            useCaseName: 'Pixel art (mobile)',
          );
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'Default (mobile) builder pumps at 360 × 640 dp without exceptions',
        (WidgetTester tester) async {
          final useCase = _useCase(
            mainMenuDirectories,
            folderName: 'Main Menu',
            useCaseName: 'Default (mobile)',
          );
          await _pumpMobileViewport(tester, useCase);
          expect(
            tester.takeException(),
            isNull,
            reason:
                'Mobile-viewport story must pump without exceptions per '
                'SPEC/ui/mobile-adaptation.md § 6 and the Widgetbook AC in '
                'SPEC/ui/main-menu.md.',
          );
        },
      );

      testWidgets(
        'Pixel art (mobile) builder pumps at 360 × 640 dp without exceptions '
        '(exercises ≤ 430 dp letter-spacing + compact padding rules)',
        (WidgetTester tester) async {
          final useCase = _useCase(
            mainMenuDirectories,
            folderName: 'Main Menu',
            useCaseName: 'Pixel art (mobile)',
          );
          await _pumpMobileViewport(tester, useCase);
          expect(
            tester.takeException(),
            isNull,
            reason:
                'Mobile-viewport story must pump without exceptions per '
                'SPEC/ui/mobile-adaptation.md § 6 and the Widgetbook AC in '
                'SPEC/ui/main-menu.md (the pixelArt variant exercises the '
                '≤ 430 dp narrow override at the 360 dp story width).',
          );
        },
      );
    },
  );
}
