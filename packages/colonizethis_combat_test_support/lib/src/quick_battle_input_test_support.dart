// Shared Quick Battle input builders for table-driven scenarios (Refs #3865).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Center-front lane deployment used across resolver and siege scenario suites.
QuickBattleDeployment centerFrontQuickBattleDeployment({
  required List<String> unitIds,
  int cohesion = 3,
  QuickBattleLaneTerrain laneTerrain = QuickBattleLaneTerrain.open,
}) {
  return QuickBattleDeployment(
    groups: [
      QuickBattleGroup(
        lane: QuickBattleLane.center,
        line: QuickBattleLine.front,
        unitIds: unitIds,
        cohesion: cohesion,
      ),
    ],
    laneTerrain: {'center_front': laneTerrain},
  );
}

/// Standard center-front [QuickBattleInput] with tunable regiment counts or ids.
QuickBattleInput centerFrontQuickBattleInput({
  required List<String> attackerUnitIds,
  required List<String> defenderUnitIds,
  required int seed,
  int attackerCohesion = 3,
  int defenderCohesion = 3,
  QuickBattleLaneTerrain attackerLaneTerrain = QuickBattleLaneTerrain.open,
  QuickBattleLaneTerrain defenderLaneTerrain = QuickBattleLaneTerrain.open,
  String attackerFactionId = 'att',
  String defenderFactionId = 'def',
  String provinceId = 'p1',
  String regionId = 'oldWorld',
  int maxRounds = 3,
  int fortLevel = 0,
  String provinceTerrain = 'plains',
  double attackerCavalryShare = 0.0,
  double defenderCavalryShare = 0.0,
  QuickBattleDeployment? attackerDeployment,
  QuickBattleDeployment? defenderDeployment,
  List<QuickBattleEmplacedGun> emplacedGuns = const [],
}) {
  return QuickBattleInput(
    attackerFactionId: attackerFactionId,
    defenderFactionId: defenderFactionId,
    provinceId: provinceId,
    regionId: regionId,
    fortLevel: fortLevel,
    provinceTerrain: provinceTerrain,
    attackerCavalryShare: attackerCavalryShare,
    defenderCavalryShare: defenderCavalryShare,
    attackerDeployment: attackerDeployment ??
        centerFrontQuickBattleDeployment(
          unitIds: attackerUnitIds,
          cohesion: attackerCohesion,
          laneTerrain: attackerLaneTerrain,
        ),
    defenderDeployment: defenderDeployment ??
        centerFrontQuickBattleDeployment(
          unitIds: defenderUnitIds,
          cohesion: defenderCohesion,
          laneTerrain: defenderLaneTerrain,
        ),
    emplacedGuns: emplacedGuns,
    seed: seed,
    maxRounds: maxRounds,
  );
}

/// Immutable emplaced gun with siege-scenario defaults (rng 11, att/def 2.0).
QuickBattleEmplacedGun siegeEmplacedGun(String id, {required int hp}) {
  return QuickBattleEmplacedGun(
    id: id,
    maxHp: hp,
    hp: hp,
    attackStrength: 2.0,
    defenseStrength: 2.0,
    rng: 11,
  );
}

/// Generates sequential unit ids (`prefix0`, `prefix1`, …).
List<String> quickBattleUnitIds(String prefix, int count) =>
    List.generate(count, (i) => '$prefix$i');

/// Siege input for perf-invariant scenarios (Refs #2316 P1 #8 / #9).
QuickBattleInput perfSiegeQuickBattleInput({
  required int seed,
  required int fortLevel,
  required List<QuickBattleEmplacedGun> guns,
  required int attackerRegiments,
  required int defenderRegiments,
  int maxRounds = 3,
  String provinceId = 'p-perf',
  String regionId = kRegionOldWorld,
}) {
  return centerFrontQuickBattleInput(
    attackerUnitIds: quickBattleUnitIds('att-', attackerRegiments),
    defenderUnitIds: quickBattleUnitIds('def-', defenderRegiments),
    seed: seed,
    maxRounds: maxRounds,
    fortLevel: fortLevel,
    provinceId: provinceId,
    regionId: regionId,
    emplacedGuns: guns,
  );
}

const _qbInputProvinceId = 'P1';
const _qbInputRegionId = 'oldWorld';

/// Flexible [Game] for [buildQuickBattleInput] unit tests.
Game quickBattleInputBuilderGame({
  String id = 'g1',
  int turnNumber = 1,
  required List<Unit> oldWorldUnits,
  List<Province> oldWorldProvinces = const [
    Province(id: 'P1', regionId: 'oldWorld', ownerId: 'def'),
  ],
  RegionData? newWorld,
  List<Player> players = const [
    Player(id: 'att', displayName: 'Attacker', isHuman: true),
    Player(id: 'def', displayName: 'Defender', isHuman: true),
  ],
  List<General> generals = const [],
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: oldWorldProvinces,
        units: oldWorldUnits,
      ),
      newWorld: newWorld ?? const RegionData(),
    ),
    players: players,
    generals: generals,
  );
}

/// New World variant for [buildQuickBattleInput] region routing tests.
Game quickBattleInputBuilderNewWorldGame({
  required String provinceId,
  required List<Unit> units,
  List<Player> players = const [
    Player(id: 'att', displayName: 'Attacker', isHuman: true),
    Player(id: 'def', displayName: 'Defender', isHuman: true),
  ],
}) {
  const nw = 'newWorld';
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: nw, ownerId: 'def'),
        ],
        units: units,
      ),
    ),
    players: players,
  );
}

/// Standard Old World [BattleContext] for QB input builder tests.
BattleContext quickBattleInputBuilderContext({
  String provinceId = _qbInputProvinceId,
  String regionId = _qbInputRegionId,
  List<String> defenderUnitIds = const ['u2'],
  List<String> attackerUnitIds = const ['u1'],
  int fortLevel = 0,
  String terrain = 'plains',
}) {
  return BattleContext(
    provinceId: provinceId,
    regionId: regionId,
    defenderFactionId: 'def',
    defenderUnitIds: defenderUnitIds,
    attackers: [
      AttackingSide(factionId: 'att', unitIds: attackerUnitIds),
    ],
    fortLevel: fortLevel,
    terrain: terrain,
  );
}
