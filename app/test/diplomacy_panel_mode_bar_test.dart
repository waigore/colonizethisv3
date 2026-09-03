// DiplomacyPanel mode bar + GP relative-power rendering (Refs #4720 Slice F).
// SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';

import 'diplomacy_panel_test_scenarios.dart';
import 'diplomacy_panel_widget_harness.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  late DiplomacyPanelRichFixture fixture;

  setUp(() => AppEventBus.reset());

  setUpAll(() async {
    await preloadNinePatchImage();
    fixture = DiplomacyPanelRichFixture.create();
  });

  Future<void> pumpDefault(WidgetTester tester, {Orders? orders}) =>
      pumpDiplomacyPanelOnTallSurface(
        tester,
        game: fixture.gameWithFactions,
        humanPlayerId: fixture.humanPlayerId,
        topology: fixture.topology,
        currentOrders: orders ?? const Orders(),
      );

  group('DiplomacyPanel mode bar', () {
    testWidgets(
      'AC: default state — All button active (--accent), others inactive (--muted)',
      (WidgetTester tester) async {
        await pumpDefault(tester);
        expect(
          tester.widget<Text>(find.text('All')).style?.color,
          EditorialMonoclePalette.accent,
        );
        for (final label in ['Great Powers only', 'Minors only']) {
          expect(
            tester.widget<Text>(find.text(label)).style?.color,
            EditorialMonoclePalette.muted,
          );
        }
      },
    );

    for (final scenario in diplomacyModeBarFilterScenarios) {
      testWidgets(
        'AC: tapping "${scenario.filterLabel}" applies section filter',
        (WidgetTester tester) async {
          await pumpDefault(tester);
          expect(find.text('Great Powers'), findsOneWidget);
          await tester.tap(find.text(scenario.filterLabel));
          await pumpDiplomacyPanelBuilt(tester);
          for (final heading in scenario.visibleSectionHeadings) {
            expect(find.text(heading), findsOneWidget);
          }
          for (final heading in scenario.hiddenSectionHeadings) {
            expect(find.text(heading), findsNothing);
          }
          expect(
            tester.widget<Text>(find.text(scenario.filterLabel)).style?.color,
            EditorialMonoclePalette.accent,
          );
        },
      );
    }

    testWidgets('AC: mode bar renders all three filter labels', (
      WidgetTester tester,
    ) async {
      await pumpDefault(tester);
      for (final label in diplomacyModeBarFilterLabels) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('DiplomacyPanel GP relative-power line rendering', () {
    Future<void> pumpAndRows(WidgetTester tester) async {
      await pumpDefault(tester);
    }

    testWidgets('AC: stronger GP relative-power line renders in --danger', (
      WidgetTester tester,
    ) async {
      await pumpAndRows(tester);
      final stronger =
          buildDiplomacyRows(
            fixture.gameWithFactions,
            fixture.topology,
            fixture.humanPlayerId,
            const Orders(),
          ).where(
            (r) =>
                r.kind == FactionKind.greatPower &&
                r.powerScore != null &&
                r.playerPowerScore != null &&
                powerComparisonPercent(r.powerScore!, r.playerPowerScore!) > 0,
          );
      if (stronger.isEmpty) return;
      for (final r in stronger) {
        final colors = relativePowerSpanColors(tester, r.factionId);
        expect(colors.pctColor, EditorialMonoclePalette.danger);
        expect(colors.tierColor, EditorialMonoclePalette.danger);
      }
    });

    testWidgets(
      'AC: weaker/equal GP relative-power line renders in --success',
      (WidgetTester tester) async {
        await pumpAndRows(tester);
        final weakerOrEqual =
            buildDiplomacyRows(
              fixture.gameWithFactions,
              fixture.topology,
              fixture.humanPlayerId,
              const Orders(),
            ).where(
              (r) =>
                  r.kind == FactionKind.greatPower &&
                  r.powerScore != null &&
                  r.playerPowerScore != null &&
                  powerComparisonPercent(r.powerScore!, r.playerPowerScore!) <=
                      0,
            );
        if (weakerOrEqual.isEmpty) return;
        for (final r in weakerOrEqual) {
          final colors = relativePowerSpanColors(tester, r.factionId);
          expect(colors.pctColor, EditorialMonoclePalette.success);
          expect(colors.tierColor, EditorialMonoclePalette.success);
        }
      },
    );

    testWidgets(
      'AC: Great Power rows render the localized "Relative power:" prefix',
      (WidgetTester tester) async {
        await pumpAndRows(tester);
        final hasGp = buildDiplomacyRows(
          fixture.gameWithFactions,
          fixture.topology,
          fixture.humanPlayerId,
          const Orders(),
        ).any((r) => r.kind == FactionKind.greatPower);
        if (!hasGp) return;
        expect(find.byType(RelativePowerLine), findsAtLeastNWidgets(1));
        expect(find.textContaining('Relative power:'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'absolute "Power: N" score label is no longer rendered on GP rows',
      (WidgetTester tester) async {
        await pumpAndRows(tester);
        expect(find.textContaining('Power: '), findsNothing);
      },
    );
  });
}
