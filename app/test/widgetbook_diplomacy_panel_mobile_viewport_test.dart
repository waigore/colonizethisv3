// Widget test pin for the `Diplomacy Panel` → `Mobile viewport — narrow
// rows (≤ 500 dp)` Widgetbook use case added by Refs #2870 R22 / S9.
//
// Pins two SPEC contracts:
//
//  1. The use case is wired into the public `diplomacyPanelDirectories`
//     getter (so renaming or removing it surfaces here in CI before
//     reviewers lose the mobile-viewport story for the diplomacy
//     surface).
//  2. The builder mounts without exceptions inside the shared
//     `mobileViewport` (360 × 640 dp `MediaQuery.size`) frame and
//     selects the narrow `_DiplomacyRow` body — a `Column` — for at
//     least one rendered faction row, per
//     `SPEC/ui/diplomacy-panel.md` § Responsive layout and the issue's
//     AC "Mobile-viewport Widgetbook story renders narrow rows".
//
// The narrow body is the deterministic signal that the responsive
// variant is reviewable in Widgetbook without resizing — at 360 dp
// (< `kDiplomacyRowNarrowMaxWidth` = 500 dp) the diplomacy faction-row
// body builder selects the `Column` arrangement.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widget_test_assets.dart';
import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(preloadNinePatchImage);

  group(
    'Diplomacy Panel Widgetbook mobile-viewport story (Refs #2870 R22 / S9)',
    () {
      testWidgets(
        'use case is wired into diplomacyPanelDirectories under the '
        'canonical folder + name',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            diplomacyPanelDirectories,
            folderName: 'Diplomacy Panel',
            useCaseName: 'Mobile viewport — narrow rows (≤ 500 dp)',
          );
          // Smoke: the getter returns a builder closure (the constructor
          // contract for `WidgetbookUseCase`). The deeper pump assertion
          // lives in the second test below so this one fails fast on
          // wiring regressions even if the panel itself becomes
          // expensive to mount.
          expect(useCase.builder, isNotNull);
        },
      );

      testWidgets(
        'builder pumps at 360 × 640 dp without exceptions and selects the '
        'narrow Column body for at least one faction row',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            diplomacyPanelDirectories,
            folderName: 'Diplomacy Panel',
            useCaseName: 'Mobile viewport — narrow rows (≤ 500 dp)',
          );

          // Editorial shell + 360 × 640 viewport via shared harness
          // (Refs #4035); `mobileViewport` inside the story then copyWiths
          // MediaQuery from that ancestor.
          await pumpWidgetbookUseCaseAtSize(tester, useCase);

          expect(
            tester.takeException(),
            isNull,
            reason:
                'Mobile-viewport story must pump without exceptions per '
                'SPEC/ui/mobile-adaptation.md § 6 and the new AC in '
                'SPEC/ui/diplomacy-panel.md.',
          );

          // Locate at least one faction-row body keyed by the public
          // `kDiplomacyRowBodyKeyPrefix` prefix and confirm it is a
          // `Column` (narrow variant per
          // `SPEC/ui/diplomacy-panel.md` § Responsive layout).
          final Finder bodyFinder = find.byWidgetPredicate(
            (Widget w) {
              final Key? key = w.key;
              if (key is! ValueKey<String>) return false;
              return key.value.startsWith(kDiplomacyRowBodyKeyPrefix);
            },
            description:
                'faction-row body keyed by kDiplomacyRowBodyKeyPrefix',
          );
          expect(
            bodyFinder,
            findsWidgets,
            reason:
                'Debug-init-game must seed at least one discovered '
                'faction so the diplomacy panel surfaces a row body.',
          );
          final Widget firstBody = tester.widget(bodyFinder.first);
          expect(
            firstBody,
            isA<Column>(),
            reason:
                'At the mobileViewport (360 dp ≤ kDiplomacyRowNarrowMaxWidth = '
                '500 dp), SPEC/ui/diplomacy-panel.md § Responsive layout '
                'requires the narrow Column body so action buttons drop '
                'below the info column.',
          );
        },
      );
    },
  );
}
