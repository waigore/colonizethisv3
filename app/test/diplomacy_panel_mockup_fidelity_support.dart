// Diplomacy panel mockup-fidelity game fixtures (Refs #3621, #4680).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_constants.dart'
    show diplomacyRelationWordColor;
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';

import 'app_shell_harness.dart';
import 'diplomacy_panel_test_support.dart';

const MapTopology kDiplomacyMockupEmptyTopology = MapTopology(
  nodes: [],
  edges: [],
);

Game diplomacyMockupEmptyStateGame() {
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

Game diplomacyMockupGpRelationGame(int score) {
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

Game diplomacyMockupSubsidyGame() {
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

Widget diplomacyMockupPanelHost(Game game) {
  return buildAppShell(
    child: Scaffold(
      body: SizedBox(
        width: 460,
        height: 1000,
        child: DiplomacyPanel(
          game: game,
          humanPlayerId: 'gp1',
          topology: kDiplomacyMockupEmptyTopology,
          currentOrders: const Orders(),
          bus: AppEventBus.create(),
        ),
      ),
    ),
  );
}

BoxDecoration diplomacyMockupChipDecoration(WidgetTester tester, String label) {
  final Finder container = find
      .ancestor(of: find.text(label), matching: find.byType(Container))
      .first;
  final Container c = tester.widget<Container>(container);
  return c.decoration! as BoxDecoration;
}

TextSpan diplomacyMockupRelationWordSpan(WidgetTester tester, String word) {
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

Future<void> pumpDiplomacyMockupRelation(
  WidgetTester tester,
  int score,
) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(600, 1100));
  await tester.pumpWidget(diplomacyMockupPanelHost(diplomacyMockupGpRelationGame(score)));
  await pumpDiplomacyPanelBuilt(tester);
}

EdgeInsets diplomacyMockupHeadingOuterPadding(
  WidgetTester tester,
  String title,
) {
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
