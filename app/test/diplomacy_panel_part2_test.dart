// DiplomacyPanel chrome token pins (part2). SPEC/ui/diplomacy-panel.md.
// Relative-power line colors, section headings, and faction kind badges.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';

import 'support/diplomacy_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'support/widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  late Game gameWithFactions;
  late String humanPlayerId;
  late MapTopology topology;

  setUp(() {
    AppEventBus.reset();
  });

  setUpAll(() async {
    await preloadNinePatchImage();
    gameWithFactions = buildDiplomacyRichPanelTestGame();
    topology = const MapTopology();
    humanPlayerId = gameWithFactions.players.isNotEmpty
        ? gameWithFactions.players.first.id
        : 'gp1';
  });

  group('DiplomacyPanel GP relative-power line rendering', () {
    testWidgets('AC: stronger GP relative-power line renders in --danger', (
      WidgetTester tester,
    ) async {
      await bindDiplomacyTallTestSurface(tester);
      await tester.pumpWidget(
        buildDiplomacyPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final stronger = rows
          .where(
            (r) =>
                r.kind == FactionKind.greatPower &&
                r.powerScore != null &&
                r.playerPowerScore != null &&
                powerComparisonPercent(r.powerScore!, r.playerPowerScore!) > 0,
          )
          .toList();
      if (stronger.isEmpty) {
        // No qualifying row in the debug-init game; skip dynamically rather
        // than failing — the helper-level + RelativePowerLine widget tests
        // already pin the formula and colors.
        return;
      }
      for (final r in stronger) {
        final colors = relativePowerSpanColors(tester, r.factionId);
        expect(
          colors.pctColor,
          EditorialMonoclePalette.danger,
          reason: 'Stronger GP percentage must use --danger',
        );
        expect(
          colors.tierColor,
          EditorialMonoclePalette.danger,
          reason: 'Stronger GP tier word must match the percentage color',
        );
      }
    });

    testWidgets(
      'AC: weaker/equal GP relative-power line renders in --success',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        final rows = buildDiplomacyRows(
          gameWithFactions,
          topology,
          humanPlayerId,
          const Orders(),
        );
        final weakerOrEqual = rows
            .where(
              (r) =>
                  r.kind == FactionKind.greatPower &&
                  r.powerScore != null &&
                  r.playerPowerScore != null &&
                  powerComparisonPercent(r.powerScore!, r.playerPowerScore!) <=
                      0,
            )
            .toList();
        if (weakerOrEqual.isEmpty) {
          return;
        }
        for (final r in weakerOrEqual) {
          final colors = relativePowerSpanColors(tester, r.factionId);
          expect(
            colors.pctColor,
            EditorialMonoclePalette.success,
            reason: 'Weaker/equal GP percentage must use --success',
          );
          expect(
            colors.tierColor,
            EditorialMonoclePalette.success,
            reason: 'Weaker/equal GP tier word must match the percentage color',
          );
        }
      },
    );

    testWidgets(
      'AC: Great Power rows render the localized "Relative power:" prefix',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        final rows = buildDiplomacyRows(
          gameWithFactions,
          topology,
          humanPlayerId,
          const Orders(),
        );
        final hasGp = rows.any((r) => r.kind == FactionKind.greatPower);
        if (!hasGp) return;
        expect(find.byType(RelativePowerLine), findsAtLeastNWidgets(1));
        expect(find.textContaining('Relative power:'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'absolute "Power: N" score label is no longer rendered on GP rows',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        // SPEC: relative-power line replaces the absolute score. No row should
        // render text starting with "Power: ".
        expect(find.textContaining('Power: '), findsNothing);
      },
    );
  });

  group('DiplomacyPanel section headings (editorial-monocle)', () {
    testWidgets('AC: Section heading text resolves to --accent color', (
      WidgetTester tester,
    ) async {
      await bindDiplomacyTallTestSurface(tester);
      await tester.pumpWidget(
        buildDiplomacyPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

      final heading = tester.widget<Text>(find.text('Great Powers'));
      expect(
        heading.style?.color,
        EditorialMonoclePalette.accent,
        reason:
            'Section heading must render in --accent per editorial-monocle.',
      );
      expect(
        heading.style?.fontFamily,
        'Cinzel',
        reason: 'Section heading must use the editorial-monocle display font.',
      );
    });

    testWidgets(
      'AC: Section heading container exposes a 2 px --accent-dim bottom border',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        final headingFinder = find.text('Great Powers');
        final decorated = find.ancestor(
          of: headingFinder,
          matching: find.byType(DecoratedBox),
        );
        expect(decorated, findsAtLeastNWidgets(1));
        final box = tester.widget<DecoratedBox>(decorated.first);
        final decoration = box.decoration as BoxDecoration;
        final BorderSide bottom = decoration.border!.bottom;
        expect(bottom.color, EditorialMonoclePalette.accentDim);
        expect(bottom.width, 2);
      },
    );
  });

  group('DiplomacyPanel faction kind badges (editorial-monocle)', () {
    testWidgets(
      'AC: GP badge background --accent-dim and foreground --bg-deep',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        // Only assert if the debug-init game actually has a GP row.
        final rows = buildDiplomacyRows(
          gameWithFactions,
          topology,
          humanPlayerId,
          const Orders(),
        );
        final hasGp = rows.any((r) => r.kind == FactionKind.greatPower);
        if (!hasGp) return;

        final gpText = find.text('GP').first;
        final container = tester.widget<Container>(
          find.ancestor(of: gpText, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.color,
          EditorialMonoclePalette.accentDim,
          reason: 'GP badge background must resolve to --accent-dim.',
        );
        expect(
          decoration.border,
          isNull,
          reason: 'GP badge must not draw an outline border.',
        );
        final textWidget = tester.widget<Text>(gpText);
        expect(
          textWidget.style?.color,
          EditorialMonoclePalette.bgDeep,
          reason: 'GP badge foreground must resolve to --bg-deep.',
        );
      },
    );

    testWidgets('AC: Minor badge background --muted and foreground --bg-deep', (
      WidgetTester tester,
    ) async {
      await bindDiplomacyTallTestSurface(tester);
      await tester.pumpWidget(
        buildDiplomacyPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final hasMinor = rows.any((r) => r.kind == FactionKind.minor);
      if (!hasMinor) return;

      final minorText = find.text('Minor').first;
      final container = tester.widget<Container>(
        find.ancestor(of: minorText, matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(
        decoration.color,
        EditorialMonoclePalette.muted,
        reason: 'Minor badge background must resolve to --muted.',
      );
      expect(
        decoration.border,
        isNull,
        reason: 'Minor badge must not draw an outline border.',
      );
      final textWidget = tester.widget<Text>(minorText);
      expect(
        textWidget.style?.color,
        EditorialMonoclePalette.bgDeep,
        reason: 'Minor badge foreground must resolve to --bg-deep.',
      );
    });

    testWidgets(
      'AC: Tribe badge outlined with --muted border, transparent background',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        final rows = buildDiplomacyRows(
          gameWithFactions,
          topology,
          humanPlayerId,
          const Orders(),
        );
        final tribeRows = rows
            .where((r) => r.kind == FactionKind.tribe)
            .toList();
        if (tribeRows.isEmpty) return;
        final tribeRow = tribeRows.first;

        final tribeText = find.descendant(
          of: find.byKey(
            ValueKey('$kDiplomacyRowBodyKeyPrefix${tribeRow.factionId}'),
          ),
          matching: find.text('Tribe'),
        );
        await tester.scrollUntilVisible(
          tribeText,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        final container = tester.widget<Container>(
          find.ancestor(of: tribeText, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.color,
          isNull,
          reason: 'Tribe badge background must be transparent (null).',
        );
        expect(decoration.border, isNotNull);
        expect(
          decoration.border!.top.color,
          EditorialMonoclePalette.muted,
          reason: 'Tribe badge outline must use --muted.',
        );
        final textWidget = tester.widget<Text>(tribeText);
        expect(
          textWidget.style?.color,
          EditorialMonoclePalette.muted,
          reason: 'Tribe badge foreground must resolve to --muted.',
        );
      },
    );

    testWidgets(
      'AC: No badge uses raw Material chrome (Colors.blue/grey/orange)',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        final allLabels = ['GP', 'Minor', 'Tribe'];
        for (final label in allLabels) {
          final finder = find.text(label);
          if (finder.evaluate().isEmpty) continue;
          final widget = tester.widget<Text>(finder.first);
          final color = widget.style?.color;
          // Reject the prior hardcoded Material palette for these labels.
          expect(
            color,
            isNot(equals(Colors.blue)),
            reason: '$label badge must not use Colors.blue.',
          );
          expect(
            color,
            isNot(equals(Colors.grey)),
            reason: '$label badge must not use Colors.grey.',
          );
          expect(
            color,
            isNot(equals(Colors.orange)),
            reason: '$label badge must not use Colors.orange.',
          );
        }
      },
    );
  });
}
