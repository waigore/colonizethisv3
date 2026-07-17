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
          Province(id: capitalLocalId, regionId: 'oldWorld', ownerId: playerId),
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

/// Prefixed province tile key.
String debugHandlerTileKey(String provinceFullId, [int x = 0, int y = 0]) =>
    '$provinceFullId|$x|$y';

/// Capital tile for flip/reveal suites.
CapitalTile debugHandlerCapitalTile(
  String provinceFullId, [
  int x = 0,
  int y = 0,
]) => CapitalTile(
  regionId: provinceFullId.split('|').first,
  provinceId: provinceFullId,
  x: x,
  y: y,
);

/// Province with matching town tile key.
Province debugHandlerTownProvince(
  String provinceFullId,
  String ownerId,
  String displayName, [
  int x = 0,
  int y = 0,
]) => Province(
  id: provinceFullId,
  regionId: provinceFullId.split('|').first,
  ownerId: ownerId,
  displayName: displayName,
  townTileKey: debugHandlerTileKey(provinceFullId, x, y),
);

/// Visibility + tile-key Game used by flip/reveal province debug suites.
Game buildDebugHandlerVisibilityGame({
  required String id,
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {},
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  Map<String, String> portsByProvinceSeaboard = const {},
  List<Player> players = const [
    Player(id: 'human_1', displayName: 'Human', isHuman: true),
  ],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 2,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: RegionData(provinces: newWorldProvinces),
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
      playerVisibilityByTile: playerVisibilityByTile,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// Reveal-province baseline: unknown OW province + adjacent sea tile keys.
Game buildDebugHandlerRevealProvinceGame({
  String id = 'g-reveal',
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 2,
  Map<String, Map<String, String>>? playerVisibilityByTile,
}) {
  return buildDebugHandlerVisibilityGame(
    id: id,
    phase: phase,
    turnNumber: turnNumber,
    oldWorldProvinces: const [
      Province(
        id: 'oldWorld|P1',
        regionId: 'oldWorld',
        ownerId: 'ai_1',
        displayName: 'New Bordeaux',
      ),
    ],
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        'oldWorld|P1': ['oldWorld|P1|0|0'],
        'oldWorld|s1': ['oldWorld|s1|0|0'],
      },
    },
    playerVisibilityByTile:
        playerVisibilityByTile ??
        const {
          'human_1': {
            'oldWorld|P1|0|0': 'unknown',
            'oldWorld|s1|0|0': 'unknown',
          },
        },
    players: const [
      Player(id: 'human_1', displayName: 'Human', isHuman: true),
      Player(id: 'ai_1', displayName: 'AI', isHuman: false),
    ],
  );
}

/// Flip-province capital cast: human + optional AI / minor / tribe capital.
Game buildDebugHandlerFlipCapitalGame({
  required String id,
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  required Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince,
  required Map<String, Map<String, String>> playerVisibilityByTile,
  Map<String, String> portsByProvinceSeaboard = const {},
  String? aiCapitalProvinceId,
  String? minorCapitalProvinceId,
  String? tribeCapitalProvinceId,
}) {
  return buildDebugHandlerVisibilityGame(
    id: id,
    oldWorldProvinces: oldWorldProvinces,
    newWorldProvinces: newWorldProvinces,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    playerVisibilityByTile: playerVisibilityByTile,
    portsByProvinceSeaboard: portsByProvinceSeaboard,
    players: [
      const Player(id: 'human_1', displayName: 'Human', isHuman: true),
      if (aiCapitalProvinceId != null)
        Player(
          id: 'ai_1',
          displayName: 'AI',
          isHuman: false,
          capitalProvinceId: aiCapitalProvinceId,
          capitalTile: debugHandlerCapitalTile(aiCapitalProvinceId),
        ),
    ],
    minorNations: [
      if (minorCapitalProvinceId != null)
        MinorNation(
          id: 'minor_1',
          displayName: 'Minor',
          capitalProvinceId: minorCapitalProvinceId,
          capitalTile: debugHandlerCapitalTile(minorCapitalProvinceId),
        ),
    ],
    tribes: [
      if (tribeCapitalProvinceId != null)
        Tribe(
          id: 'tribe_1',
          displayName: 'Tribe',
          capitalProvinceId: tribeCapitalProvinceId,
          capitalTile: debugHandlerCapitalTile(tribeCapitalProvinceId),
        ),
    ],
  );
}
