// Discovery/empty-section diplomacy fixtures (Refs #3847 / #4734 Slice F).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Solo human GP with no [DiplomacyRelation]s (Refs #4013).
Game buildDiplomacyPanelGameWithNoDiscoveredFactions() {
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
    id: 'empty-diplo',
    worldState: world,
    players: const [player],
    diplomacyRelations: const [],
  );
}

/// Tribe discovered via tile visibility without a relation (Refs #3341).
Game buildDiplomacyPanelGameWithTribeDiscoveredByVisibility() {
  const nw = 'newWorld';
  const ow = 'oldWorld';
  final tribeProvince = Province(
    id: '$nw|t1prov',
    regionId: nw,
    displayName: 'Tribe Land',
    ownerId: 't1',
  );
  final homeProvince = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
    oldWorld: RegionData(provinces: [homeProvince], units: const []),
    newWorld: RegionData(provinces: [tribeProvince], units: const []),
    playerVisibilityByTile: const {
      'gp1': {'newWorld|t1prov|0|0': 'fullyVisible'},
    },
    playerProspectedTiles: const {},
  );
  const player = Player(id: 'gp1', displayName: 'Solo', isHuman: true);
  return Game(
    id: 'tribe-visibility',
    worldState: world,
    players: const [player],
    tribes: const [Tribe(id: 't1', displayName: 'Tribe One')],
    diplomacyRelations: const [],
  );
}
