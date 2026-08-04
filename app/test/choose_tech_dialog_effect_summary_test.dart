// Choose-tech effect summary + Details ACs (Refs #4222).
// SPEC/ui/technology-panel.md § Choose-tech dialog.

import 'package:colonizethis_app/features/game/widgets/technology/tech_definition_detail_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_effect_summary.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel_orders.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  final game = buildTechnologyPanelTestGame();
  final player = game.players.first;

  TechDefinition requireTech(String id) {
    final tech = techById(id);
    expect(tech, isNotNull, reason: 'fixture tech $id must exist');
    return tech!;
  }

  Future<void> pumpChooseTechDialog(
    WidgetTester tester, {
    required List<TechDefinition> techs,
    void Function(TechDefinition tech)? onSelect,
  }) async {
    await pumpDialogs320At(
      tester,
      Builder(
        builder: (context) => ChooseTechDialog(
          game: game,
          contextPlayerId: player.id,
          slotIndex: 0,
          availableTechs: techs,
          onSelect: (tech) {
            (onSelect ?? (_) {})(tech);
            Navigator.of(context).pop();
          },
        ),
      ),
      size: kDialogs320WideRegressionViewport,
    );
  }

  group('Choose-tech effect summary rows (Refs #4222)', () {
    testWidgets(
      'positive: default row shows up to two effect lines for multi-effect tech',
      (WidgetTester tester) async {
        final hussars = requireTech(kTechIdHussars);
        final lines = buildTechEffectSummaryLines(
          AppLocalizationsEn(),
          hussars,
        );
        expect(lines.length, greaterThan(2));

        await pumpChooseTechDialog(tester, techs: [hussars]);

        expect(find.text(lines[0]), findsOneWidget);
        expect(find.text(lines[1]), findsOneWidget);
        expect(find.text(lines[2]), findsNothing);
        expect(find.text('Details'), findsOneWidget);
      },
    );

    testWidgets(
      'positive: category fallback line renders when no unlocks or authored lines',
      (WidgetTester tester) async {
        final fallbackTech = TechDefinition(
          id: 'choose_tech_fallback_fixture',
          era: 1,
          category: 'military',
          cost: 100,
          displayName: 'Fallback Fixture',
        );
        final fallbackLine = buildTechEffectSummaryLines(
          AppLocalizationsEn(),
          fallbackTech,
        );
        expect(fallbackLine, hasLength(1));
        expect(fallbackLine.single, contains('Military'));

        await pumpChooseTechDialog(tester, techs: [fallbackTech]);
        expect(find.text(fallbackLine.single), findsOneWidget);
      },
    );

    testWidgets(
      'positive: Details opens nested dialog without assigning or closing Choose-tech',
      (WidgetTester tester) async {
        var assigned = false;
        final hussars = requireTech(kTechIdHussars);

        await pumpChooseTechDialog(
          tester,
          techs: [hussars],
          onSelect: (_) => assigned = true,
        );

        await tester.tap(find.text('Details'));
        await tester.pumpAndSettle();

        expect(find.byType(ChooseTechDialog), findsOneWidget);
        expect(find.byType(CtDialogShell), findsNWidgets(2));
        expect(find.text('Hussars'), findsWidgets);
        expect(assigned, isFalse);

        await tester.tap(find.text('Close').last);
        await tester.pumpAndSettle();

        expect(find.byType(ChooseTechDialog), findsOneWidget);
        expect(assigned, isFalse);
      },
    );

    testWidgets(
      'positive: row body tap assigns tech and closes Choose-tech',
      (WidgetTester tester) async {
        TechDefinition? assignedTech;
        final hussars = requireTech(kTechIdHussars);

        await pumpChooseTechDialog(
          tester,
          techs: [hussars],
          onSelect: (tech) => assignedTech = tech,
        );

        await tester.tap(find.textContaining('Era '));
        await tester.pumpAndSettle();

        expect(find.byType(ChooseTechDialog), findsNothing);
        expect(assignedTech?.id, kTechIdHussars);
      },
    );

    testWidgets(
      'positive: shared helper matches Tree dialog effect strings',
      (WidgetTester tester) async {
        final hussars = requireTech(kTechIdHussars);
        final l10n = AppLocalizationsEn();
        final sharedLines = buildTechEffectSummaryLines(l10n, hussars);

        await pumpDialogs320At(
          tester,
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showTechDefinitionDetailDialog(
                  context,
                  game: game,
                  player: player,
                  tech: hussars,
                ),
                child: const Text('open'),
              );
            },
          ),
          size: kDialogs320WideRegressionViewport,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        for (final line in sharedLines) {
          expect(find.textContaining(line), findsOneWidget);
        }
      },
    );

    testWidgets(
      'positive: empty choosable list shows no effect or Details chrome',
      (WidgetTester tester) async {
        await pumpChooseTechDialog(tester, techs: const []);

        expect(find.text('No techs available to research'), findsOneWidget);
        expect(find.text('Details'), findsNothing);
      },
    );

    testWidgets(
      'positive: populated dialog with effect lines fits 320 dp without overflow',
      (WidgetTester tester) async {
        final hussars = requireTech(kTechIdHussars);
        await pumpDialogs320At(
          tester,
          ChooseTechDialog(
            game: game,
            contextPlayerId: player.id,
            slotIndex: 0,
            availableTechs: [hussars],
            onSelect: (_) {},
          ),
          size: kDialogs320MinViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Details'), findsOneWidget);
      },
    );
  });
}
