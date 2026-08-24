// Widget goldens for GP tech-pennant dialog, list, observe, and legend ACs (Refs #3862).
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_gp_pennant_row.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_gp_researchers.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_researchers_list_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel_orders.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/gp_nation_color_pennant.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'golden_capture_harness.dart';
import 'tech_gp_pennant_goldens_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('AC5 golden: tech description dialog researched-by section', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('tech_description_researched_by');
    final game = cropRotationResearchersGame(contextPlayerId: 'gp1');
    final player = game.players.firstWhere((p) => p.id == 'gp1');

    await tester.pumpWidget(
      pennantGoldenHost(
        boundaryKey: boundaryKey,
        child: TechTreeWidget(game: game, player: player),
      ),
    );
    await pumpForGolden(tester, settle: false);

    final cropRotation = find.text('Crop Rotation');
    await tester.ensureVisible(cropRotation);
    await tester.tap(cropRotation);
    await tester.pumpAndSettle();

    expect(find.text('Researched by'), findsOneWidget);
    expect(find.byType(CtDialogShell), findsOneWidget);

    await expectLater(
      find.byType(CtDialogShell),
      matchesGoldenFile('goldens/tech_description_researched_by.png'),
    );
  });

  testWidgets('AC6 golden: researchers list dialog after long-press', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('tech_researchers_list_dialog');
    final game = cropRotationResearchersGame(contextPlayerId: 'gp1');

    await tester.pumpWidget(
      pennantGoldenHost(
        boundaryKey: boundaryKey,
        child: TechResearchersListDialog(
          game: game,
          techId: kTechIdCropRotation,
          contextPlayerId: 'gp1',
        ),
      ),
    );
    await pumpForGolden(tester, settle: false);

    expect(find.text('GP One'), findsOneWidget);
    expect(find.text('GP Three'), findsOneWidget);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/tech_researchers_list_dialog.png'),
    );
  });

  testWidgets('AC7 golden: observe context gp4 highlights gp4 pennant', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('tech_gp_pennant_observe_gp4');
    final game = observeGp4Game();

    await tester.pumpWidget(
      pennantGoldenHost(
        boundaryKey: boundaryKey,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: TechGpPennantRow(
            game: game,
            techId: kTechIdCropRotation,
            contextPlayerId: 'gp4',
          ),
        ),
      ),
    );
    await pumpForGolden(tester, settle: false);

    final gp4Pennant = tester.widget<GpNationColorPennant>(
      find.byKey(const ValueKey<String>('tech_gp_pennant_crop_rotation_gp4')),
    );
    expect(gp4Pennant.highlighted, isTrue);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/tech_gp_pennant_observe_gp4_highlight.png'),
    );
  });

  testWidgets('AC8 golden: tech tree legend includes GP pennant entry', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('tech_tree_legend_gp_pennants');
    final game = cropRotationResearchersGame(contextPlayerId: 'gp1');
    final sampleColor = gpMapColorForPlayer(game, 'gp1');

    await tester.pumpWidget(
      pennantGoldenHost(
        boundaryKey: boundaryKey,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              GpNationColorPennant(color: sampleColor, highlighted: true),
              GpNationColorPennant(color: sampleColor),
              Text(
                AppLocalizationsEn().techTree_legendGpPennants,
                style: AppThemes.editorialMonocle.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
    await pumpForGolden(tester, settle: false);

    expect(
      find.text('GP nation-color pennants (highlighted = you)'),
      findsOneWidget,
    );
    expect(find.byType(GpNationColorPennant), findsNWidgets(2));

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/tech_tree_legend_gp_pennants.png'),
    );
  });
}
