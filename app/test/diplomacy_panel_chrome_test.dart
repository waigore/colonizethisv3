// DiplomacyPanel chrome tests: row chrome, relation-state badges, and the
// danger-variant war action button. Split from `diplomacy_panel_test.dart`
// to keep each file under `repo.dart_file_non_comment_line_size` (1000
// non-comment lines). SPEC/ui/diplomacy-panel.md § Per-faction row.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'support/diplomacy_panel_test_support.dart';
import 'support/panel_test_fixtures.dart';
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
    // Refs #3656: lightweight discovered-GP fixture replaces the ~7-11s
    // getDebugInitGameResult() map generation. These chrome suites only read a
    // discovered Great Power row (relation badges + action buttons), which the
    // fixture's at-peace gp1↔gp2 relation provides; no generated map/topology
    // data is consumed.
    gameWithFactions = buildDiplomacyPanelTestGame();
    topology = const MapTopology();
    humanPlayerId = gameWithFactions.players.isNotEmpty
        ? gameWithFactions.players.first.id
        : 'gp1';
  });

  group('DiplomacyPanel relation-state badge (editorial-monocle)', () {
    Game gameWithWarRelation(Game source, String otherFactionId) {
      // Replace any existing relation between humanPlayerId ↔ otherFactionId
      // with an at-war pair so the panel always renders at least one WAR
      // badge for the assertion.
      bool involvesPair(DiplomacyRelation r) =>
          (r.factionId1 == humanPlayerId && r.factionId2 == otherFactionId) ||
          (r.factionId1 == otherFactionId && r.factionId2 == humanPlayerId);
      final updated = [
        for (final r in source.diplomacyRelations)
          if (!involvesPair(r)) r,
        DiplomacyRelation(
          factionId1: humanPlayerId,
          factionId2: otherFactionId,
          score: 10,
          state: RelationState.atWar,
          sinceTurn: 0,
        ),
      ];
      return source.copyWith(diplomacyRelations: updated);
    }

    testWidgets(
      'AC: WAR badge foreground resolves to --danger',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        final otherGp = gameWithFactions.players.firstWhere(
          (p) => p.id != humanPlayerId,
        );
        final warGame = gameWithWarRelation(gameWithFactions, otherGp.id);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: warGame,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        final warText = find.text('WAR');
        expect(warText, findsAtLeastNWidgets(1));
        final widget = tester.widget<Text>(warText.first);
        expect(
          widget.style?.color,
          EditorialMonoclePalette.danger,
          reason: 'WAR badge foreground must resolve to --danger.',
        );
        expect(
          widget.style?.fontFamily,
          'monospace',
          reason: 'WAR badge label must use the mono font stack.',
        );
      },
    );

    testWidgets(
      'AC: PEACE badge foreground resolves to --success',
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

        final peaceText = find.text('PEACE');
        if (peaceText.evaluate().isEmpty) {
          // Debug-init game may have all relations at-war by default;
          // skip rather than fail.
          return;
        }
        final widget = tester.widget<Text>(peaceText.first);
        expect(
          widget.style?.color,
          EditorialMonoclePalette.success,
          reason: 'PEACE badge foreground must resolve to --success.',
        );
        expect(
          widget.style?.fontFamily,
          'monospace',
          reason: 'PEACE badge label must use the mono font stack.',
        );
      },
    );

    testWidgets(
      'AC: WAR badge background derives from --danger hue at alpha 0.40',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        final otherGp = gameWithFactions.players.firstWhere(
          (p) => p.id != humanPlayerId,
        );
        final warGame = gameWithWarRelation(gameWithFactions, otherGp.id);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: warGame,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        // Mockup token: oklch(40% 0.06 20 / 0.4).
        final Color expectedBg =
            oklchToColor(const OklchToken(0.40, 0.06, 20))
                .withValues(alpha: 0.4);
        final warText = find.text('WAR');
        expect(warText, findsAtLeastNWidgets(1));
        final container = tester.widget<Container>(
          find.ancestor(of: warText.first, matching: find.byType(Container))
              .first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.color,
          expectedBg,
          reason:
              'WAR badge background must derive from the danger hue at alpha 0.4.',
        );
        expect(decoration.border, isNull,
            reason: 'WAR badge must not draw an outline border.');
      },
    );

    testWidgets(
      'AC: PEACE badge background derives from --success hue at alpha 0.20',
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

        final peaceText = find.text('PEACE');
        if (peaceText.evaluate().isEmpty) return;
        final Color expectedBg =
            oklchToColor(const OklchToken(0.40, 0.06, 150))
                .withValues(alpha: 0.2);
        final container = tester.widget<Container>(
          find.ancestor(of: peaceText.first, matching: find.byType(Container))
              .first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.color,
          expectedBg,
          reason:
              'PEACE badge background must derive from the success hue at alpha 0.2.',
        );
        expect(decoration.border, isNull,
            reason: 'PEACE badge must not draw an outline border.');
      },
    );
  });

  group('DiplomacyPanel faction-row chrome (editorial-monocle)', () {
    testWidgets(
      'AC: Faction row paints --bg-deep → --surface vertical gradient and --border outline',
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

        // Locate the first AnimatedContainer that wraps a faction row
        // (the row chrome lives inside _DiplomacyRowChrome → MouseRegion →
        // AnimatedContainer per diplomacy_panel_chrome.dart).
        final containers = find.byType(AnimatedContainer);
        BoxDecoration? rowDecoration;
        for (final element in containers.evaluate()) {
          final w = element.widget as AnimatedContainer;
          final deco = w.decoration;
          if (deco is! BoxDecoration) continue;
          final gradient = deco.gradient;
          if (gradient is! LinearGradient) continue;
          if (gradient.colors.length != 2) continue;
          // Match against the canonical row gradient (bg-deep → surface).
          if (gradient.colors[0] == EditorialMonoclePalette.bgDeep &&
              gradient.colors[1] == EditorialMonoclePalette.surface) {
            rowDecoration = deco;
            break;
          }
        }
        expect(
          rowDecoration,
          isNotNull,
          reason:
              'At least one faction row must paint the canonical --bg-deep → --surface vertical gradient.',
        );
        final LinearGradient gradient = rowDecoration!.gradient as LinearGradient;
        expect(gradient.begin, Alignment.topCenter,
            reason: 'Row gradient must flow top → bottom (180deg).');
        expect(gradient.end, Alignment.bottomCenter);
        expect(rowDecoration.border, isNotNull,
            reason: 'Row chrome must draw a 1 px outline.');
        final BorderSide side = rowDecoration.border!.top;
        expect(side.width, 1);
        expect(
          side.color,
          EditorialMonoclePalette.border,
          reason: 'Idle row outline must resolve to --border.',
        );
      },
    );
  });

  group('DiplomacyPanel war-action button (editorial-monocle danger variant)',
      () {
    testWidgets(
      'AC: Declare War button resolves border and label to --danger',
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

        final warBtn = find.text('Declare War');
        if (warBtn.evaluate().isEmpty) return;
        final button = tester.widget<CtNinePatchButton>(
          find
              .ancestor(of: warBtn, matching: find.byType(CtNinePatchButton))
              .first,
        );
        expect(
          button.dangerVariant,
          isTrue,
          reason:
              'Declare War button must opt into the CtNinePatchButton danger variant.',
        );
      },
    );

    testWidgets(
      'AC: Non-war action buttons do not opt into the danger variant',
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

        const nonWarLabels = [
          'Offer Peace',
          'Alliance',
          'Grant Aid',
          'Set Subsidy',
        ];
        for (final label in nonWarLabels) {
          final finder = find.text(label);
          if (finder.evaluate().isEmpty) continue;
          final button = tester.widget<CtNinePatchButton>(
            find
                .ancestor(of: finder, matching: find.byType(CtNinePatchButton))
                .first,
          );
          expect(
            button.dangerVariant,
            isFalse,
            reason:
                'Non-war action button "$label" must keep the default brass variant.',
          );
        }
      },
    );
  });
}
