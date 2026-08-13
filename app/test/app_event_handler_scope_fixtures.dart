// Shared Game fixtures for AppEventHandlerScope debug-apply tests (Refs #4352).

import 'package:colonizethis_app_debug/colonizethis_app_debug.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Game scopeGameWithCombatMode(CombatMode mode) {
  return Game(
    id: 'g1',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: false),
    ],
    defaultCombatMode: mode,
  );
}

Game scopeCivilianCapitalGame({
  required String id,
  List<Unit> existingUnits = const [],
  List<Player> extraPlayers = const [],
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        units: existingUnits,
      ),
      newWorld: const RegionData(),
    ),
    players: [
      const Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: 'oldWorld|1',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|1',
          x: 2,
          y: 3,
        ),
      ),
      ...extraPlayers,
    ],
  );
}

Game scopeCapitalProvinceOnlyGame({required String id}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|1', regionId: 'oldWorld', ownerId: 'p1'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: 'oldWorld|1',
      ),
    ],
  );
}

Game scopeEmptyWorldGame({
  required String id,
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 1,
  required List<Player> players,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
  );
}

const scopeFlipHuman = Player(
  id: 'human_1',
  displayName: 'Human',
  isHuman: true,
);

const scopeFlipAi = Player(id: 'ai_1', displayName: 'AI', isHuman: false);

Game scopeFlipBaseGame({
  required TurnPhase phase,
  required String ownerId,
  required String humanVisibility,
}) {
  return Game(
    id: 'g-flip',
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: 2),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: 'oldWorld|P1',
            regionId: 'oldWorld',
            ownerId: ownerId,
            displayName: 'New Bordeaux',
          ),
        ],
        units: [
          Unit(
            id: 'r1',
            type: 'musketeers',
            ownerId: ownerId,
            locationProvinceId: 'oldWorld|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          'oldWorld|P1': ['oldWorld|P1|0|0'],
        },
      },
      playerVisibilityByTile: {
        'human_1': {'oldWorld|P1|0|0': humanVisibility},
      },
    ),
    players: const [scopeFlipHuman, scopeFlipAi],
  );
}

FlipDebugProvinceOwnershipEvent scopeFlipNameEvent([
  String displayName = 'New Bordeaux',
]) {
  return FlipDebugProvinceOwnershipEvent(
    humanPlayerId: 'human_1',
    regionId: 'oldWorld',
    provinceDisplayName: displayName,
  );
}

({Game? game, String message}) scopeApplyFlip(
  Game game,
  FlipDebugProvinceOwnershipEvent event,
) {
  return applyDebugFlipProvinceOwnership(
    currentGame: game,
    event: event,
    combinedTopology: const MapTopology(),
  );
}
