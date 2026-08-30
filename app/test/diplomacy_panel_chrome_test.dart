// DiplomacyPanel editorial-monocle chrome pins (Refs #4352).
// SPEC: SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<void> pumpDefault(WidgetTester tester) =>
      pumpDiplomacyPanelOnTallSurface(
        tester,
        game: fixture.gameWithFactions,
        humanPlayerId: fixture.humanPlayerId,
        topology: fixture.topology,
      );

  group('DiplomacyPanel section headings (editorial-monocle)', () {
    testWidgets('AC: Section heading text resolves to --accent color', (
      WidgetTester tester,
    ) async {
      await pumpDefault(tester);
      final heading = tester.widget<Text>(find.text('Great Powers'));
      expect(heading.style?.color, EditorialMonoclePalette.accent);
      expect(heading.style?.fontFamily, 'Cinzel');
    });

    testWidgets(
      'AC: Section heading container exposes a 2 px --accent-dim bottom border',
      (WidgetTester tester) async {
        await pumpDefault(tester);
        final decorated = find.ancestor(
          of: find.text('Great Powers'),
          matching: find.byType(DecoratedBox),
        );
        expect(decorated, findsAtLeastNWidgets(1));
        final box = tester.widget<DecoratedBox>(decorated.first);
        final decoration = box.decoration as BoxDecoration;
        expect(
          decoration.border!.bottom.color,
          EditorialMonoclePalette.accentDim,
        );
        expect(decoration.border!.bottom.width, 2);
      },
    );
  });

  group('DiplomacyPanel faction kind badges (editorial-monocle)', () {
    Future<List<DiplomacyRowData>> rows(WidgetTester tester) async {
      await pumpDefault(tester);
      return buildDiplomacyRows(
        fixture.gameWithFactions,
        fixture.topology,
        fixture.humanPlayerId,
        const Orders(),
      );
    }

    testWidgets(
      'AC: GP badge background --accent-dim and foreground --bg-deep',
      (WidgetTester tester) async {
        final panelRows = await rows(tester);
        if (!panelRows.any((r) => r.kind == FactionKind.greatPower)) return;
        final gpText = find.text('GP').first;
        final container = tester.widget<Container>(
          find.ancestor(of: gpText, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, EditorialMonoclePalette.accentDim);
        expect(decoration.border, isNull);
        expect(
          tester.widget<Text>(gpText).style?.color,
          EditorialMonoclePalette.bgDeep,
        );
      },
    );

    testWidgets('AC: Minor badge background --muted and foreground --bg-deep', (
      WidgetTester tester,
    ) async {
      final panelRows = await rows(tester);
      if (!panelRows.any((r) => r.kind == FactionKind.minor)) return;
      final minorText = find.text('Minor').first;
      final container = tester.widget<Container>(
        find.ancestor(of: minorText, matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, EditorialMonoclePalette.muted);
      expect(decoration.border, isNull);
      expect(
        tester.widget<Text>(minorText).style?.color,
        EditorialMonoclePalette.bgDeep,
      );
    });

    testWidgets(
      'AC: Tribe badge outlined with --muted border, transparent background',
      (WidgetTester tester) async {
        final panelRows = await rows(tester);
        final tribeRows = panelRows
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
        expect(decoration.color, isNull);
        expect(decoration.border!.top.color, EditorialMonoclePalette.muted);
        expect(
          tester.widget<Text>(tribeText).style?.color,
          EditorialMonoclePalette.muted,
        );
      },
    );

    testWidgets(
      'AC: No badge uses raw Material chrome (Colors.blue/grey/orange)',
      (WidgetTester tester) async {
        await pumpDefault(tester);
        for (final label in ['GP', 'Minor', 'Tribe']) {
          final finder = find.text(label);
          if (finder.evaluate().isEmpty) continue;
          final color = tester.widget<Text>(finder.first).style?.color;
          expect(color, isNot(equals(Colors.blue)));
          expect(color, isNot(equals(Colors.grey)));
          expect(color, isNot(equals(Colors.orange)));
        }
      },
    );
  });
}
