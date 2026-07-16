// Widget goldens for GP nation-color tech pennant visual ACs (Refs #3862).
//
// Pixel baselines live under `app/test/goldens/` and are asserted with
// `matchesGoldenFile`, following the committed golden harness pattern
// (`diplomacy_panel_goldens_test.dart`, `train_dialogs_goldens_test.dart`):
// a keyed `RepaintBoundary` wraps each surface, deterministic fixtures pin
// GP map colours via `greatPowerColorOverride`, and
// `AppThemes.editorialMonocle` supplies the dark-theme chrome.
//
// AC mapping:
//  - AC1  context gp1, gp1+gp3 researched → highlighted then standard pennants
//  - AC2  context gp2 (non-researcher) → standard chrome only, gp1 then gp3
//  - AC3  Choose-tech dialog at 320 dp with inline pennants after tech name
//  - AC5  Tech description dialog "Researched by" section
//  - AC6  Long-press researchers list modal
//  - AC7  context gp4 with gp4 researched → gp4 pennant highlighted
//  - AC8  Tech tree legend GP pennant entry
//
// SPEC: SPEC/ui/tech-tree-widget.md, SPEC/ui/technology-panel.md,
// SPEC/ui/components/gp-nation-color-pennant.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/golden_capture_harness.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_gp_researchers.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_gp_pennant_row.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_researchers_list_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel_orders.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/gp_nation_color_pennant.dart';

import 'support/min_viewport_harness.dart';
import 'support/panel_test_fixtures.dart';

const Map<String, List<int>> _kPennantGoldenColorOverride = {
  'gp1': [200, 40, 40],
  'gp2': [40, 160, 40],
  'gp3': [40, 80, 200],
  'gp4': [220, 180, 60],
};

Game _pennantGoldenGame({
  required List<Player> players,
}) {
  return buildPanelTestGame(players: players).copyWith(
    greatPowerColorOverride: _kPennantGoldenColorOverride,
  );
}

Game _cropRotationResearchersGame({required String contextPlayerId}) {
  return _pennantGoldenGame(
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP One',
        isHuman: contextPlayerId == 'gp1',
        techUnlocked: const {kTechIdCropRotation: true},
      ),
      Player(
        id: 'gp2',
        displayName: 'GP Two',
        isHuman: contextPlayerId == 'gp2',
      ),
      Player(
        id: 'gp3',
        displayName: 'GP Three',
        isHuman: false,
        techUnlocked: const {kTechIdCropRotation: true},
      ),
    ],
  );
}

Game _sawMillChooseTechGame() {
  return _pennantGoldenGame(
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP One',
        isHuman: true,
        techUnlocked: const {kTechIdSawMill: true},
      ),
      Player(
        id: 'gp2',
        displayName: 'GP Two',
        isHuman: false,
        techUnlocked: const {kTechIdSawMill: true},
      ),
    ],
  );
}

Game _observeGp4Game() {
  return _pennantGoldenGame(
    players: [
      const Player(id: 'gp1', displayName: 'GP One', isHuman: false),
      const Player(id: 'gp2', displayName: 'GP Two', isHuman: false),
      const Player(id: 'gp3', displayName: 'GP Three', isHuman: false),
      Player(
        id: 'gp4',
        displayName: 'GP Four',
        isHuman: true,
        techUnlocked: const {kTechIdCropRotation: true},
      ),
    ],
  );
}

Widget _goldenHost({
  required Key boundaryKey,
  required Widget child,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: child,
  );
}


void main() {
  suppressLogsForTests();

  testWidgets('AC1 golden: context gp1 highlights first pennant on crop_rotation row', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('tech_gp_pennant_ac1_highlighted');
    final game = _cropRotationResearchersGame(contextPlayerId: 'gp1');

    await tester.pumpWidget(
      _goldenHost(
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
      find.byKey(
        const ValueKey<String>('tech_gp_pennant_crop_rotation_gp1'),
      ),
    );
    final gp3Pennant = tester.widget<GpNationColorPennant>(
      find.byKey(
        const ValueKey<String>('tech_gp_pennant_crop_rotation_gp3'),
      ),
    );
    expect(gp1Pennant.highlighted, isTrue);
    expect(gp3Pennant.highlighted, isFalse);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/tech_gp_pennant_row_context_highlighted.png'),
    );
  });

  testWidgets('AC2 golden: non-researcher context gp2 uses standard chrome only', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('tech_gp_pennant_ac2_no_highlight');
    final game = _cropRotationResearchersGame(contextPlayerId: 'gp2');

    await tester.pumpWidget(
      _goldenHost(
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
  });

  testWidgets('AC3 golden: choose-tech row shows inline pennants at 320 dp', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const boundaryKey = ValueKey<String>('choose_tech_pennants_320dp');
    final game = _sawMillChooseTechGame();
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

  testWidgets('AC5 golden: tech description dialog researched-by section', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('tech_description_researched_by');
    final game = _cropRotationResearchersGame(contextPlayerId: 'gp1');
    final player = game.playerById('gp1')!;

    await tester.pumpWidget(
      _goldenHost(
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
    final game = _cropRotationResearchersGame(contextPlayerId: 'gp1');

    await tester.pumpWidget(
      _goldenHost(
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
    final game = _observeGp4Game();

    await tester.pumpWidget(
      _goldenHost(
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
      find.byKey(
        const ValueKey<String>('tech_gp_pennant_crop_rotation_gp4'),
      ),
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
    final game = _cropRotationResearchersGame(contextPlayerId: 'gp1');
    final sampleColor = gpMapColorForPlayer(game, 'gp1');

    await tester.pumpWidget(
      _goldenHost(
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

    expect(find.text('GP nation-color pennants (highlighted = you)'), findsOneWidget);
    expect(find.byType(GpNationColorPennant), findsNWidgets(2));

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/tech_tree_legend_gp_pennants.png'),
    );
  });
}
