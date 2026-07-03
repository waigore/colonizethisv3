// Structural mockup-fidelity tests for the diplomacy panel chrome slices that
// reconcile GAME30001 against SPEC/ui/mockups/GAME30001-diplomacy-panel.html
// (Refs #3621):
//
//  - AC4 (§ Mode-bar chip chrome): each filter chip paints
//    `CtGradients.actionButtonGradient` with a 1 px border — `--border`
//    inactive, `--accent-dim` active.
//  - AC7 (§ Outgoing economic diplomacy styling): economic lines render mono,
//    `--accent-dim`, non-italic per mockup `.f-subsidy`.
//  - AC8 (§ Section headings first-heading top rhythm): the first rendered
//    section heading drops its top gap to 0; subsequent headings keep the
//    `CtSpacing.l` leading gap.
//
// SPEC: SPEC/ui/diplomacy-panel.md § Mode bar (filter), § Per-faction row,
// § Section headings, and § Acceptance criteria (Refs #3621).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show relationScoreToMeterStep;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/relation_meter.dart';

const MapTopology _emptyTopology = MapTopology(nodes: [], edges: []);

/// Solo human Great Power with no other discovered factions, so every section
/// heading and the mode bar render against an otherwise empty list.
Game _emptyStateGame() {
  const ow = 'oldWorld';
  final p1 = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'P1',
    ownerId: 'gp1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: [p1], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  const player = Player(id: 'gp1', displayName: 'Solo', isHuman: true);
  return Game(
    id: 'diplo-fidelity-empty',
    worldState: world,
    players: const [player],
    diplomacyRelations: const [],
  );
}

/// Human GP `gp1` with a single discovered GP `gp2` whose relation [score]
/// drives the one-word relation label and its level color.
Game _gpRelationGame(int score) {
  const ow = 'oldWorld';
  final home = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final rival = Province(
    id: '$ow|p2',
    regionId: ow,
    displayName: 'Rival',
    ownerId: 'gp2',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
    oldWorld: RegionData(provinces: [home, rival], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  return Game(
    id: 'diplo-fidelity-relation-$score',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    diplomacyRelations: [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', score: score),
    ],
  );
}

/// Human GP `gp1` pays an ongoing subsidy to GP `gp2`, so the `gp2` row
/// renders the outgoing-subsidy economic line.
Game _subsidyGame() {
  const ow = 'oldWorld';
  final home = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final rival = Province(
    id: '$ow|p2',
    regionId: ow,
    displayName: 'Rival',
    ownerId: 'gp2',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 4),
    oldWorld: RegionData(provinces: [home, rival], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  return Game(
    id: 'diplo-fidelity-subsidy',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
    ],
    subsidyStates: const [
      SubsidyState(payerId: 'gp1', targetId: 'gp2', percent: 15),
    ],
  );
}

Widget _panelHost(Game game) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: SizedBox(
        width: 460,
        height: 1000,
        child: DiplomacyPanel(
          game: game,
          humanPlayerId: 'gp1',
          topology: _emptyTopology,
          currentOrders: const Orders(),
          bus: AppEventBus.create(),
        ),
      ),
    ),
  );
}

Future<void> _pumpBuilt(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// The chip [Container] painted by `_DiplomacyModeButton` is the immediate
/// [Container] ancestor of the chip label.
BoxDecoration _chipDecoration(WidgetTester tester, String label) {
  final Finder container = find
      .ancestor(of: find.text(label), matching: find.byType(Container))
      .first;
  final Container c = tester.widget<Container>(container);
  return c.decoration! as BoxDecoration;
}

void main() {
  suppressLogsForTests();

  setUp(AppEventBus.reset);

  Future<void> bindSurface(WidgetTester tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(600, 1100));
  }

  group('Diplomacy mode-bar chip chrome (AC4, Refs #3621)', () {
    testWidgets('inactive chip paints action gradient + --border outline', (
      WidgetTester tester,
    ) async {
      await bindSurface(tester);
      await tester.pumpWidget(_panelHost(_emptyStateGame()));
      await _pumpBuilt(tester);

      // "Great Powers only" is inactive by default (default mode is `all`).
      final BoxDecoration deco = _chipDecoration(tester, 'Great Powers only');
      expect(deco.gradient, CtGradients.actionButtonGradient);
      final Border border = deco.border! as Border;
      expect(border.top.width, 1);
      expect(
        border.top.color,
        EditorialMonoclePalette.border,
        reason: 'Inactive mode-bar chip outline must resolve to --border.',
      );
    });

    testWidgets('active chip paints action gradient + --accent-dim outline', (
      WidgetTester tester,
    ) async {
      await bindSurface(tester);
      await tester.pumpWidget(_panelHost(_emptyStateGame()));
      await _pumpBuilt(tester);

      // "All" is the active mode by default.
      final BoxDecoration deco = _chipDecoration(tester, 'All');
      expect(deco.gradient, CtGradients.actionButtonGradient);
      final Border border = deco.border! as Border;
      expect(border.top.width, 1);
      expect(
        border.top.color,
        EditorialMonoclePalette.accentDim,
        reason: 'Active mode-bar chip outline must resolve to --accent-dim.',
      );
    });
  });

  group('Diplomacy economic lines styling (AC7, Refs #3621)', () {
    testWidgets('outgoing subsidy line is mono, --accent-dim, non-italic', (
      WidgetTester tester,
    ) async {
      await bindSurface(tester);
      await tester.pumpWidget(_panelHost(_subsidyGame()));
      await _pumpBuilt(tester);

      final Finder subsidyLine = find.textContaining('Outgoing subsidy');
      expect(subsidyLine, findsOneWidget);
      final Text text = tester.widget<Text>(subsidyLine);
      expect(text.style?.fontFamily, 'monospace');
      expect(text.style?.color, EditorialMonoclePalette.accentDim);
      expect(text.style?.fontStyle, isNot(FontStyle.italic));
    });
  });

  group('Diplomacy relation word styling (AC5, Refs #3621)', () {
    /// Locates the relation-word [TextSpan] (the colored italic word, e.g.
    /// "Cordial") inside the relation-row `Text.rich` for the single GP row.
    TextSpan relationWordSpan(WidgetTester tester, String word) {
      for (final Text t in tester.widgetList<Text>(find.byType(Text))) {
        final InlineSpan? span = t.textSpan;
        if (span is! TextSpan) continue;
        final List<InlineSpan>? children = span.children;
        if (children == null) continue;
        for (final InlineSpan child in children) {
          if (child is TextSpan && child.text == word) {
            return child;
          }
        }
      }
      fail('relation word span "$word" was not found in the panel');
    }

    Future<void> pumpRelation(WidgetTester tester, int score) async {
      await bindSurface(tester);
      await tester.pumpWidget(_panelHost(_gpRelationGame(score)));
      await _pumpBuilt(tester);
    }

    testWidgets('relation word renders italic in its meter-step color', (
      WidgetTester tester,
    ) async {
      await pumpRelation(tester, 60); // step 7 → Cordial
      final TextSpan word = relationWordSpan(tester, 'Cordial');
      expect(word.style?.fontStyle, FontStyle.italic);
      expect(word.style?.color, relationMeterStepColor(7));
    });

    testWidgets('Hostile word (step 1) resolves to --danger', (
      WidgetTester tester,
    ) async {
      await pumpRelation(tester, 5); // step 1 → Hostile
      final TextSpan word = relationWordSpan(tester, 'Hostile');
      expect(word.style?.color, EditorialMonoclePalette.danger);
      expect(word.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('interior word (step 5) resolves to its gradient color', (
      WidgetTester tester,
    ) async {
      await pumpRelation(tester, 40); // step 5 → Wary
      final TextSpan word = relationWordSpan(tester, 'Wary');
      expect(word.style?.color, relationMeterStepColor(5));
    });

    testWidgets('Devoted word (step 10) resolves to --success', (
      WidgetTester tester,
    ) async {
      await pumpRelation(tester, 95); // step 10 → Devoted
      final TextSpan word = relationWordSpan(tester, 'Devoted');
      expect(word.style?.color, EditorialMonoclePalette.success);
    });

    test('diplomacyRelationWordColor follows the meter-step gradient', () {
      // Endpoints reuse the canonical danger/success tokens.
      expect(diplomacyRelationWordColor(0), EditorialMonoclePalette.danger);
      expect(diplomacyRelationWordColor(9.9), EditorialMonoclePalette.danger);
      expect(diplomacyRelationWordColor(100), EditorialMonoclePalette.success);
      expect(diplomacyRelationWordColor(90), EditorialMonoclePalette.success);
      // Interior scores resolve to the gradient color for their step.
      for (final num score in <num>[15, 25, 35, 45, 55, 65, 75, 85]) {
        expect(
          diplomacyRelationWordColor(score),
          relationMeterStepColor(relationScoreToMeterStep(score)),
        );
      }
    });
  });

  group('Diplomacy section heading rhythm (AC8, Refs #3621)', () {
    /// The outer [Padding] in `_DiplomacySectionHeader` is the ancestor whose
    /// bottom inset equals `CtSpacing.m` (the inner heading Padding uses
    /// `CtSpacing.s`).
    EdgeInsets headingOuterPadding(WidgetTester tester, String title) {
      final Finder padding = find.ancestor(
        of: find.text(title),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Padding &&
              w.padding is EdgeInsets &&
              (w.padding as EdgeInsets).bottom == CtSpacing.m,
        ),
      );
      return tester.widget<Padding>(padding.first).padding as EdgeInsets;
    }

    testWidgets('first heading has zero top gap; later headings keep --l gap', (
      WidgetTester tester,
    ) async {
      await bindSurface(tester);
      await tester.pumpWidget(_panelHost(_emptyStateGame()));
      await _pumpBuilt(tester);

      // Default mode `all` renders Great Powers first, then Minor Nations.
      expect(
        headingOuterPadding(tester, 'Great Powers').top,
        0,
        reason: 'First section heading must drop its top gap to 0.',
      );
      expect(
        headingOuterPadding(tester, 'Minor Nations').top,
        CtSpacing.l,
        reason: 'Subsequent section headings keep the CtSpacing.l top gap.',
      );
    });
  });
}
