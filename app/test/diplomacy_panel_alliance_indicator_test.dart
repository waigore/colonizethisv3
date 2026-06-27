// Structural tests for the formal-alliance (treaty) indicator on the
// diplomacy panel (Refs #3625, AC4). The badge reconciles GAME30001 against
// SPEC/ui/diplomacy-panel.md § Formal alliance indicator:
//
//  - shown only when DiplomacyRelation.formalAlliance is true, in --accent;
//  - absent when the relation is in the informal RelationLevel.allied band
//    (score 76-100) but formalAlliance is false;
//  - a separate widget from the one-word relation label so the treaty marker
//    never reuses the informal relation band word.
//
// SPEC: SPEC/ui/diplomacy-panel.md § Formal alliance indicator (Refs #3625).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';

import 'support/app_shell_harness.dart';

const MapTopology _emptyTopology = MapTopology(nodes: [], edges: []);

/// Human GP `gp1` discovered GP `gp2` whose relation [score] drives the
/// one-word relation label; [formalAlliance] toggles the persisted treaty flag
/// surfaced by the alliance badge.
Game _gpRelationGame({required int score, required bool formalAlliance}) {
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
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
    oldWorld: RegionData(provinces: [home, rival], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  return Game(
    id: 'diplo-alliance-$score-$formalAlliance',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: score,
        formalAlliance: formalAlliance,
      ),
    ],
  );
}

Widget _panelHost(Game game) {
  return buildAppShell(
    child: Scaffold(
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

void main() {
  suppressLogsForTests();

  setUp(AppEventBus.reset);

  Future<void> bindSurface(WidgetTester tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(600, 1100));
  }

  group('Diplomacy formal-alliance indicator (AC4, Refs #3625)', () {
    testWidgets('badge shown in --accent for a formal alliance', (
      WidgetTester tester,
    ) async {
      await bindSurface(tester);
      // Friendly band (score 90) AND a persisted formal alliance.
      await tester.pumpWidget(
        _panelHost(_gpRelationGame(score: 90, formalAlliance: true)),
      );
      await _pumpBuilt(tester);

      final Finder badge = find.text(kDiplomacyAllianceBadgeLabel);
      expect(badge, findsOneWidget);
      final Text text = tester.widget<Text>(badge);
      expect(text.style?.color, EditorialMonoclePalette.accent);
    });

    testWidgets(
      'badge absent for informal Allied band without a formal alliance',
      (WidgetTester tester) async {
        await bindSurface(tester);
        // Score 90 is the informal RelationLevel.allied band, but no treaty.
        await tester.pumpWidget(
          _panelHost(_gpRelationGame(score: 90, formalAlliance: false)),
        );
        await _pumpBuilt(tester);

        expect(find.text(kDiplomacyAllianceBadgeLabel), findsNothing);
        // The informal high-relation row still shows the one-word label.
        expect(find.textContaining('Friendly'), findsWidgets);
      },
    );

    testWidgets('badge is a separate widget from the relation word', (
      WidgetTester tester,
    ) async {
      await bindSurface(tester);
      await tester.pumpWidget(
        _panelHost(_gpRelationGame(score: 90, formalAlliance: true)),
      );
      await _pumpBuilt(tester);

      // The treaty marker never reuses the informal relation band word.
      expect(find.text(kDiplomacyAllianceBadgeLabel), findsOneWidget);
      expect(kDiplomacyAllianceBadgeLabel, isNot('Friendly'));
      expect(find.textContaining('Friendly'), findsWidgets);
    });
  });
}
