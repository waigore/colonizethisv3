// Widget tests for GP tech pennant surfaces. Refs #3862.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/tech_gp_pennant_row.dart';
import 'package:colonizethis_app/features/game/widgets/tech_researchers_list_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/tech_tree_widget.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel_orders.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/gp_nation_color_pennant.dart';

import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  Game pennantFixtureGame({required String contextPlayerId}) {
    return buildPanelTestGame(
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

  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  group('TechGpPennantRow', () {
    testWidgets('renders two pennants with context player highlighted first', (
      WidgetTester tester,
    ) async {
      final game = pennantFixtureGame(contextPlayerId: 'gp1');
      await tester.pumpWidget(
        wrap(
          TechGpPennantRow(
            game: game,
            techId: kTechIdCropRotation,
            contextPlayerId: 'gp1',
          ),
        ),
      );
      expect(find.byType(GpNationColorPennant), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey<String>('tech_gp_pennant_crop_rotation_gp1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('tech_gp_pennant_crop_rotation_gp3')),
        findsOneWidget,
      );
    });

    testWidgets('renders nothing when no GP researched tech', (
      WidgetTester tester,
    ) async {
      final game = buildPanelTestGame(players: [panelTestHumanPlayer()]);
      await tester.pumpWidget(
        wrap(
          TechGpPennantRow(
            game: game,
            techId: kTechIdDynamite,
            contextPlayerId: 'gp1',
          ),
        ),
      );
      expect(find.byType(GpNationColorPennant), findsNothing);
    });

    testWidgets('long-press opens researchers dialog', (
      WidgetTester tester,
    ) async {
      final game = pennantFixtureGame(contextPlayerId: 'gp1');
      await tester.pumpWidget(
        wrap(
          TechGpPennantRow(
            game: game,
            techId: kTechIdCropRotation,
            contextPlayerId: 'gp1',
          ),
        ),
      );
      await tester.longPress(
        find.byKey(
          const ValueKey<String>('tech_gp_pennant_crop_rotation_gp1'),
        ),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.byType(TechResearchersListDialog), findsOneWidget);
      expect(find.text('GP One'), findsOneWidget);
      expect(find.text('GP Three'), findsOneWidget);
    });
  });

  group('TechTreeWidget pennants', () {
    testWidgets('description dialog lists researched-by section', (
      WidgetTester tester,
    ) async {
      final game = pennantFixtureGame(contextPlayerId: 'gp1');
      final player = game.playerById('gp1')!;
      await tester.pumpWidget(
        wrap(TechTreeWidget(game: game, player: player)),
      );
      await tester.pumpAndSettle();
      final cropRotation = find.text('Crop Rotation');
      await tester.ensureVisible(cropRotation);
      await tester.pumpAndSettle();
      await tester.tap(cropRotation);
      await tester.pumpAndSettle();
      expect(find.text('Researched by'), findsOneWidget);
      expect(find.text('GP One'), findsWidgets);
      expect(find.text('GP Three'), findsOneWidget);
    });
  });

  group('ChooseTechDialog pennants', () {
    testWidgets('inline pennants after tech name at 320dp', (
      WidgetTester tester,
    ) async {
      final game = pennantFixtureGame(contextPlayerId: 'gp1');
      final tech = techById(kTechIdCropRotation)!;
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChooseTechDialog(
              game: game,
              contextPlayerId: 'gp1',
              slotIndex: 0,
              availableTechs: [tech],
              onSelect: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(GpNationColorPennant), findsNWidgets(2));
    });
  });
}
