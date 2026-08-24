// Widget goldens for GP nation-color tech pennant visual ACs (Refs #3862).
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_gp_pennant_row.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel_choose_tech_dialog.dart';
import 'package:colonizethis_app/widgets/gp_nation_color_pennant.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'golden_capture_harness.dart';
import 'min_viewport_harness.dart';
import 'tech_gp_pennant_goldens_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'AC1 golden: context gp1 highlights first pennant on crop_rotation row',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('tech_gp_pennant_ac1_highlighted');
      final game = cropRotationResearchersGame(contextPlayerId: 'gp1');

      await tester.pumpWidget(
        pennantGoldenHost(
          boundaryKey: boundaryKey,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TechGpPennantRow(
              game: game,
              techId: kTechIdCropRotation,
              contextPlayerId: 'gp1',
            ),
          ),
        ),
      );
      await pumpForGolden(tester, settle: false);

      expect(find.byType(GpNationColorPennant), findsNWidgets(2));
      final gp1Pennant = tester.widget<GpNationColorPennant>(
        find.byKey(const ValueKey<String>('tech_gp_pennant_crop_rotation_gp1')),
      );
      final gp3Pennant = tester.widget<GpNationColorPennant>(
        find.byKey(const ValueKey<String>('tech_gp_pennant_crop_rotation_gp3')),
      );
      expect(gp1Pennant.highlighted, isTrue);
      expect(gp3Pennant.highlighted, isFalse);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/tech_gp_pennant_row_context_highlighted.png',
        ),
      );
    },
  );

  testWidgets(
    'AC2 golden: non-researcher context gp2 uses standard chrome only',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('tech_gp_pennant_ac2_no_highlight');
      final game = cropRotationResearchersGame(contextPlayerId: 'gp2');

      await tester.pumpWidget(
        pennantGoldenHost(
          boundaryKey: boundaryKey,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TechGpPennantRow(
              game: game,
              techId: kTechIdCropRotation,
              contextPlayerId: 'gp2',
            ),
          ),
        ),
      );
      await pumpForGolden(tester, settle: false);

      expect(find.byType(GpNationColorPennant), findsNWidgets(2));
      for (final id in ['gp1', 'gp3']) {
        final pennant = tester.widget<GpNationColorPennant>(
          find.byKey(ValueKey<String>('tech_gp_pennant_crop_rotation_$id')),
        );
        expect(pennant.highlighted, isFalse);
      }

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/tech_gp_pennant_row_context_absent.png'),
      );
    },
  );

  testWidgets('AC3 golden: choose-tech row shows inline pennants at 320 dp', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const boundaryKey = ValueKey<String>('choose_tech_pennants_320dp');
    final game = sawMillChooseTechGame();
    final tech = techById(kTechIdSawMill)!;

    await pumpAtMinViewport(
      tester,
      size: const Size(kMinViewportWidth, 640),
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      child: RepaintBoundary(
        key: boundaryKey,
        child: ChooseTechDialog(
          game: game,
          contextPlayerId: 'gp1',
          slotIndex: 0,
          availableTechs: [tech],
          onSelect: (_) {},
        ),
      ),
    );
    await pumpForGolden(tester, settle: false);

    expect(tester.takeException(), isNull);
    expect(find.byType(GpNationColorPennant), findsNWidgets(2));
    expect(find.text('Saw Mill'), findsOneWidget);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/choose_tech_pennants_320dp.png'),
    );
  });
}
