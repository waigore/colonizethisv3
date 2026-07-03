// Widget test pin for the `Diplomacy Detail Screen` Widgetbook folder (Refs
// #3753 S17). Pins the SPEC contract from `SPEC/ui/diplomacy-detail-screen.md`
// § Widgetbook for the colony-Tribe and subsidized-Minor use cases added in
// #3818:
//
//  1. The two S17 use cases are wired into `diplomacyDetailScreenDirectories`
//     under the canonical folder + names.
//  2. Each builder mounts without exceptions under the editorial-monocle theme;
//     the colony story shows standing chips + a RelationMeter; the subsidized
//     Minor story shows the overseas chip + RelationMeter and no dossier.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/relation_meter.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'support/widget_test_assets.dart';
import 'support/widgetbook_test_harness.dart';

const String _kFolder = 'Diplomacy Detail Screen';

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

  group('Diplomacy Detail Screen Widgetbook stories (Refs #3753 S17)', () {
    const colonyName = 'Colony Tribe — standing chips + relation meter';
    const subsidizedName = 'Subsidized Minor — overseas chip + relation meter';

    testWidgets('S17 use cases are wired under the canonical folder + names', (
      WidgetTester tester,
    ) async {
      expect(
        findWidgetbookUseCase(
          diplomacyDetailScreenDirectories,
          folderName: _kFolder,
          useCaseName: colonyName,
        ).builder,
        isNotNull,
      );
      expect(
        findWidgetbookUseCase(
          diplomacyDetailScreenDirectories,
          folderName: _kFolder,
          useCaseName: subsidizedName,
        ).builder,
        isNotNull,
      );
    });

    testWidgets('colony story pumps and shows standing chips + relation meter', (
      WidgetTester tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(600, 900));

      await _pumpUseCase(
        tester,
        findWidgetbookUseCase(
          diplomacyDetailScreenDirectories,
          folderName: _kFolder,
          useCaseName: colonyName,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.text(kDiplomacyChipColony), findsOneWidget);
      expect(find.text(kDiplomacyChipEmbassy), findsWidgets);
      expect(
        find.text('${kDiplomacyChipBoycottVsPrefix}Castile'),
        findsOneWidget,
      );
      expect(find.byType(RelationMeter), findsOneWidget);
      expect(find.text('Outgoing subsidy:'), findsNothing);
    });

    testWidgets(
      'subsidized Minor story pumps overseas chip + meter, no dossier',
      (WidgetTester tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(600, 900));

        await _pumpUseCase(
          tester,
          findWidgetbookUseCase(
            diplomacyDetailScreenDirectories,
            folderName: _kFolder,
            useCaseName: subsidizedName,
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('CURRENT RELATION'), findsOneWidget);
        expect(find.text(kDiplomacyChipEmbassy), findsWidgets);
        expect(
          find.text('${kDiplomacyChipOverseasPrefix}2 \u00b7 80%'),
          findsOneWidget,
        );
        expect(find.byType(RelationMeter), findsOneWidget);
        expect(find.text('DOSSIER'), findsNothing);
        expect(find.text('Outgoing subsidy:'), findsNothing);
      },
    );
  });
}
