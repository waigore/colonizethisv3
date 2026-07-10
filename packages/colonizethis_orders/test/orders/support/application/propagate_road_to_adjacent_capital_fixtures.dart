// Shared fixtures for propagate-road-to-adjacent-capital scenarios (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const pracOw = 'oldWorld';
const pracProvinceFull = 'oldWorld|P';
const pracCapitalKey = '$pracOw|P|0|0';
const pracBuildKey = '$pracOw|P|1|0';
const pracNextLevel = 3;

TileMapResult pracPlain3x3TileMap() => TileMapResult(
  width: 3,
  height: 3,
  grid: const [
    ['P', 'P', 'P'],
    ['P', 'P', 'P'],
    ['P', 'P', 'P'],
  ],
  terrainGrid: [
    [for (var i = 0; i < 3; i++) TerrainType.plains],
    [for (var i = 0; i < 3; i++) TerrainType.plains],
    [for (var i = 0; i < 3; i++) TerrainType.plains],
  ],
);

WorldState pracEmptyWorldState() => const WorldState(
  turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
  oldWorld: RegionData(),
  newWorld: RegionData(),
);

Player pracPlayerWithCapital() => const Player(
  id: 'p1',
  displayName: 'P1',
  isHuman: true,
  capitalTile: CapitalTile(
    regionId: pracOw,
    provinceId: pracProvinceFull,
    x: 0,
    y: 0,
  ),
);

const pracPlayerWithoutCapital = Player(
  id: 'p1',
  displayName: 'P1',
  isHuman: true,
);
