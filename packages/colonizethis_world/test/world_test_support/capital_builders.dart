import 'package:colonizethis_models/colonizethis_models.dart';

/// Capital-loss / terminal-fall scenario factories for world tests (Refs #3968).
///
/// Keeps province/unit/fleet ownership knobs parameterized so capital_* part
/// suites stop re-inlining identical `Game(` + `WorldState(` scaffolding.

/// Capital tile at ([x], [y]) for [provinceId] (region derived from prefix).
CapitalTile capitalTileFor(String provinceId, {int x = 0, int y = 0}) =>
    CapitalTile(
      regionId: ProvinceId.regionIdFrom(provinceId),
      provinceId: provinceId,
      x: x,
      y: y,
    );

/// Orders-phase [Game] for capital / GP / faction terminal-fall scenarios.
Game capitalLossGame({
  required String id,
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  List<Unit> units = const [],
  List<Fleet> fleets = const [],
  List<Player> players = const [],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  Map<String, String> portsByProvinceSeaboard = const {},
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: oldWorldProvinces, units: units),
      newWorld: RegionData(provinces: newWorldProvinces),
      fleets: fleets,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// GP capital-reassignment scenario: player [playerId] with capital at
/// [capitalProvinceId] and OW [provinces] (optionally NW provinces).
Game gpCapitalReassignmentGame({
  required List<Province> provinces,
  String id = 'g-gp-reassign',
  String playerId = 'p1',
  String capitalProvinceId = 'oldWorld|cap',
  List<Province> newWorldProvinces = const [],
}) {
  return capitalLossGame(
    id: id,
    oldWorldProvinces: provinces,
    newWorldProvinces: newWorldProvinces,
    players: [
      Player(
        id: playerId,
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: capitalProvinceId,
        capitalTile: capitalTileFor(capitalProvinceId),
      ),
    ],
  );
}

/// Minor/tribe capital-reassignment scenario (orders-phase world + factions).
Game factionCapitalReassignmentGame({
  required String id,
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  List<Player> players = const [],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
}) {
  return capitalLossGame(
    id: id,
    oldWorldProvinces: oldWorldProvinces,
    newWorldProvinces: newWorldProvinces,
    players: players,
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// Minor-nation capital-loss scenario with a single conqueror GP [conquerorId].
Game minorCapitalLossGame({
  required String id,
  required String minorId,
  required String capitalProvinceId,
  required String capitalOwnerId,
  String conquerorId = 'p2',
  List<Province> extraOldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  List<Unit> units = const [],
  List<Fleet> fleets = const [],
  bool includeMinor = true,
}) {
  final capitalRegion = ProvinceId.regionIdFrom(capitalProvinceId);
  final capitalProvince = Province(
    id: capitalProvinceId,
    regionId: capitalRegion,
    ownerId: capitalOwnerId,
  );
  final oldWorld = capitalRegion == 'oldWorld'
      ? [capitalProvince, ...extraOldWorldProvinces]
      : extraOldWorldProvinces;
  final newWorld = capitalRegion == 'newWorld'
      ? [capitalProvince, ...newWorldProvinces]
      : newWorldProvinces;
  return capitalLossGame(
    id: id,
    oldWorldProvinces: oldWorld,
    newWorldProvinces: newWorld,
    units: units,
    fleets: fleets,
    players: [
      Player(id: conquerorId, displayName: 'P2', isHuman: true),
    ],
    minorNations: includeMinor ? [MinorNation(id: minorId)] : const [],
  );
}

/// Great-Power capital-loss scenario with fallen GP [fallenId] and conqueror.
Game gpCapitalLossGame({
  required String id,
  required String fallenId,
  required String conquerorId,
  required String capitalProvinceId,
  required String capitalOwnerId,
  List<Province> extraOldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  List<Unit> units = const [],
  List<Fleet> fleets = const [],
  Map<String, String> portsByProvinceSeaboard = const {},
  bool includeFallenPlayer = true,
}) {
  final capitalRegion = ProvinceId.regionIdFrom(capitalProvinceId);
  final capitalProvince = Province(
    id: capitalProvinceId,
    regionId: capitalRegion,
    ownerId: capitalOwnerId,
  );
  final oldWorld = capitalRegion == 'oldWorld'
      ? [capitalProvince, ...extraOldWorldProvinces]
      : extraOldWorldProvinces;
  final newWorld = capitalRegion == 'newWorld'
      ? [capitalProvince, ...newWorldProvinces]
      : newWorldProvinces;
  return capitalLossGame(
    id: id,
    oldWorldProvinces: oldWorld,
    newWorldProvinces: newWorld,
    units: units,
    fleets: fleets,
    portsByProvinceSeaboard: portsByProvinceSeaboard,
    players: [
      if (includeFallenPlayer)
        Player(id: fallenId, displayName: 'P1', isHuman: true),
      Player(id: conquerorId, displayName: 'P2', isHuman: false),
    ],
  );
}
