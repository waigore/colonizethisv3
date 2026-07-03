// Widget test pin for the `Diplomatic Standing Chips` Widgetbook folder added
// by Refs #3753 R12 (diplomatic standing chip cluster, S13/S17).
//
// Pins the SPEC contract from `SPEC/ui/diplomacy-panel.md` § Widgetbook
// (Diplomatic Standing Chips) and the AC "Standing-chips Widgetbook stories
// render (Refs #3753 R12)":
//
//  1. The three use cases are wired into the public `diplomacyPanelDirectories`
//     getter under the canonical folder + names (so renaming or removing one
//     surfaces here in CI before reviewers lose the isolated chip stories).
//  2. Each builder mounts without exceptions under the editorial-monocle theme;
//     the colony story shows the Colony / Embassy / Boycott vs chips, the
//     overseas story shows the `Overseas: 2 · 80%` chip, and the empty story
//     renders no `Wrap` (zero layout footprint).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';

import 'support/widget_test_assets.dart';
import 'support/widgetbook_test_harness.dart';

const String _kFolder = 'Diplomatic Standing Chips';

Future<void> _pumpUseCase(WidgetTester tester, WidgetbookUseCase useCase) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.editorialMonocle,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (BuildContext ctx) => useCase.builder(ctx)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(preloadNinePatchImage);

  group('Diplomatic Standing Chips Widgetbook stories (Refs #3753 R12)', () {
    const colonyName = 'Colony Tribe (treaty + Colony + Boycott vs)';
    const overseasName = 'Minor overseas holdings (Overseas chip)';
    const emptyName = 'Empty standing (no chips, zero footprint)';

    testWidgets('three use cases are wired under the canonical folder + names', (
      WidgetTester tester,
    ) async {
      expect(
        findWidgetbookUseCase(
          diplomacyPanelDirectories,
          folderName: _kFolder,
          useCaseName: colonyName,
        ).builder,
        isNotNull,
      );
      expect(
        findWidgetbookUseCase(
          diplomacyPanelDirectories,
          folderName: _kFolder,
          useCaseName: overseasName,
        ).builder,
        isNotNull,
      );
      expect(
        findWidgetbookUseCase(
          diplomacyPanelDirectories,
          folderName: _kFolder,
          useCaseName: emptyName,
        ).builder,
        isNotNull,
      );
    });

    testWidgets('colony story pumps and shows Colony/Embassy/Boycott chips', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(600, 400));

      await _pumpUseCase(
        tester,
        findWidgetbookUseCase(
          diplomacyPanelDirectories,
          folderName: _kFolder,
          useCaseName: colonyName,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(kDiplomacyChipColony), findsOneWidget);
      expect(find.text(kDiplomacyChipEmbassy), findsOneWidget);
      expect(
        find.text('${kDiplomacyChipBoycottVsPrefix}Castile'),
        findsOneWidget,
      );
    });

    testWidgets('overseas story pumps and shows the Overseas chip', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(600, 400));

      await _pumpUseCase(
        tester,
        findWidgetbookUseCase(
          diplomacyPanelDirectories,
          folderName: _kFolder,
          useCaseName: overseasName,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text('${kDiplomacyChipOverseasPrefix}2 \u00b7 80%'),
        findsOneWidget,
      );
    });

    testWidgets('empty story pumps and renders no Wrap (zero footprint)', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(600, 400));

      await _pumpUseCase(
        tester,
        findWidgetbookUseCase(
          diplomacyPanelDirectories,
          folderName: _kFolder,
          useCaseName: emptyName,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Wrap), findsNothing);
      expect(find.text(kDiplomacyChipColony), findsNothing);
    });
  });
}
