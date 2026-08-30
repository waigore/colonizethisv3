// Game / BattleContext builders for Quick Battle input tests (Refs #3865, #4633).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const _qbInputProvinceId = 'P1';
const _qbInputRegionId = 'oldWorld';

/// Attacker musketeers + defender pikemen pair used by QB input-builder rows.
List<Unit> musketeersPikemenPair({
  String musketeerId = 'u1',
  String pikemanId = 'u2',
  String provinceId = 'P1',
}) => [
  Unit(
    id: musketeerId,
    type: 'musketeers',
    ownerId: 'att',
    locationProvinceId: provinceId,
  ),
  Unit(
    id: pikemanId,
    type: 'pikemen',
    ownerId: 'def',
    locationProvinceId: provinceId,
  ),
];

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
      oldWorld: RegionData(provinces: oldWorldProvinces, units: oldWorldUnits),
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
        provinces: [Province(id: provinceId, regionId: nw, ownerId: 'def')],
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
    attackers: [AttackingSide(factionId: 'att', unitIds: attackerUnitIds)],
    fortLevel: fortLevel,
    terrain: terrain,
  );
}
