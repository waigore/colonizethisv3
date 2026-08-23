// Diplomacy wide-row action-cluster fixtures (Refs #4606 Slice D).
// SPEC/ui/diplomacy-panel.md § Action button styling / Responsive layout.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';

import 'app_shell_harness.dart';

const MapTopology diplomacyActionClusterEmptyTopology = MapTopology(
  nodes: [],
  edges: [],
);

Game diplomacyActionClusterGreatPowerRowGame() {
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
    id: 'diplo-action-cluster',
    worldState: world,
    players: const [
      Player(id: 'gp1', displayName: 'Albion', isHuman: true),
      Player(id: 'gp2', displayName: 'Castile', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
    ],
  );
}

Widget diplomacyActionClusterPanelHost({required Size viewportSize}) {
  return buildAppShell(
    viewport: viewportSize,
    child: Scaffold(
      body: DiplomacyPanel(
        game: diplomacyActionClusterGreatPowerRowGame(),
        humanPlayerId: 'gp1',
        topology: diplomacyActionClusterEmptyTopology,
        currentOrders: const Orders(),
        bus: AppEventBus.create(),
      ),
    ),
  );
}

Map<double, List<Rect>> diplomacyActionClusterRunsByTop(
  List<Rect> rects, {
  double tol = 0.5,
}) {
  double quantize(double v) => (v / tol).roundToDouble() * tol;
  final Map<double, List<Rect>> byTop = <double, List<Rect>>{};
  for (final Rect r in rects) {
    byTop.putIfAbsent(quantize(r.top), () => <Rect>[]).add(r);
  }
  for (final List<Rect> run in byTop.values) {
    run.sort((Rect a, Rect b) => a.left.compareTo(b.left));
  }
  return byTop;
}
