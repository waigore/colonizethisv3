// Shared Game factories for `app_event_handler_debug_*` pure suites (Refs #4048).
// SPEC: SPEC/program/repo-lint.md (approved app/test/support harness list).

import 'package:colonizethis_models/colonizethis_models.dart';

/// Empty regions + one human (treasury / stockpile / workers).
Game buildDebugHandlerPlayerGame({
  String id = 'g-debug',
  String playerId = 'p1',
  String displayName = 'P1',
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 1,
  int treasury = 0,
  WorkerPool workerPool = const WorkerPool(),
  Stockpile? stockpile,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: playerId,
        displayName: displayName,
        isHuman: true,
        treasury: treasury,
        workerPool: workerPool,
        stockpile: stockpile ?? const Stockpile(),
      ),
    ],
  );
}

/// OW capital owned by [playerId] (spawn civilian / regiment / ship).
Game buildDebugHandlerCapitalGame({
  String id = 'g-debug-capital',
  String playerId = 'p1',
  String displayName = 'P1',
  bool isHuman = true,
  String? capitalProvinceId = 'oldWorld|1',
  String capitalLocalId = 'oldWorld|1',
  int capitalX = 5,
  int capitalY = 5,
  bool includeCapitalTile = true,
  List<Fleet> fleets = const [],
  int nextShipInstanceSeq = 1,
}) {
  final tileId = capitalProvinceId;
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: capitalLocalId,
            regionId: 'oldWorld',
            ownerId: playerId,
          ),
        ],
      ),
      newWorld: const RegionData(),
      fleets: fleets,
      nextShipInstanceSeq: nextShipInstanceSeq,
    ),
    players: [
      Player(
        id: playerId,
        displayName: displayName,
        isHuman: isHuman,
        capitalProvinceId: capitalProvinceId,
        capitalTile: includeCapitalTile && tileId != null
            ? CapitalTile(
                regionId: 'oldWorld',
                provinceId: tileId,
                x: capitalX,
                y: capitalY,
              )
            : null,
      ),
    ],
  );
}

/// Diplomacy cast: England + France + Ireland + Zulu.
Game buildDebugHandlerDiplomacyGame({
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 1,
  List<DiplomacyRelation> relations = const [],
  List<OvertureState> overtures = const [],
  Set<String> ftpKeys = const {},
  Set<String> usedPairKeys = const {},
}) {
  return Game(
    id: 'g-set-diplomacy',
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'england', displayName: 'England', isHuman: true),
      Player(id: 'france', displayName: 'France', isHuman: false),
    ],
    minorNations: const [MinorNation(id: 'ireland', displayName: 'Ireland')],
    tribes: const [Tribe(id: 'zulu', displayName: 'Zulu Kingdom')],
    diplomacyRelations: relations,
    overtureStates: overtures,
    ftpPartnershipKeys: ftpKeys,
    debugDiplomacyUsedPairKeys: usedPairKeys,
  );
}
