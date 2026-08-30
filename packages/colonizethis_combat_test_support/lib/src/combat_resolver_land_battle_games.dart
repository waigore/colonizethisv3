import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combat_resolver_player_constants.dart';

Game landResolverBattleGame({
  String id = 'g1',
  int turnNumber = 1,
  TurnPhase phase = TurnPhase.orders,
  String provinceId = 'p',
  String regionId = 'oldWorld',
  String defenderOwnerId = 'def',
  required List<Unit> units,
  List<Province>? provinces,
  RegionData? newWorld,
  List<Player>? players,
  List<General> generals = const [],
  int? globalGameSeed,
}) {
  final provinceList =
      provinces ??
      [Province(id: provinceId, regionId: regionId, ownerId: defenderOwnerId)];
  return Game(
    id: id,
    globalGameSeed: globalGameSeed,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: provinceList, units: units),
      newWorld: newWorld ?? const RegionData(),
    ),
    players: players ?? landResolverAttDefPlayers,
    generals: generals,
  );
}

Game landResolverNewWorldBattleGame({
  String id = 'g1',
  int turnNumber = 1,
  required String provinceId,
  required List<Unit> units,
  List<Player>? players,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: 'newWorld', ownerId: 'def'),
        ],
        units: units,
      ),
    ),
    players: players ?? landResolverHumanPlayers,
  );
}

Game landResolverSeededEmptyGame({
  String id = 'g',
  int? globalGameSeed,
  int turnNumber = 1,
  List<Player> players = const [],
}) {
  return Game(
    id: id,
    globalGameSeed: globalGameSeed,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
  );
}

Game landResolverMultiProvinceGame({
  String id = 'g1',
  int turnNumber = 4,
  required List<Province> provinces,
  List<General> generals = const [],
  List<Player> players = landResolverHumanPlayers,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: provinces, units: const []),
      newWorld: const RegionData(),
    ),
    players: players,
    generals: generals,
  );
}

Game landResolverTieBreakGame() {
  return Game(
    id: 'g1',
    globalGameSeed: 1234,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 8),
      oldWorld: RegionData(
        provinces: const [
          Province(id: 'p', regionId: 'oldWorld', ownerId: 'def'),
        ],
        units: [
          Unit(
            id: 'a1',
            type: 'pikemen',
            ownerId: 'attA',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'a2',
            type: 'pikemen',
            ownerId: 'attB',
            locationProvinceId: 'p',
          ),
          Unit(
            id: 'd1',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: 'p',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'attA', displayName: 'A', isHuman: true),
      Player(id: 'attB', displayName: 'B', isHuman: true),
      Player(id: 'def', displayName: 'D', isHuman: true),
    ],
  );
}

Game landResolverMutualAnnihilationGame({
  required String provinceId,
  required String defenderOwnerId,
  required List<Unit> units,
  required List<Player> players,
  int turnNumber = 1,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
}) {
  return Game(
    id: 'g1',
    minorNations: minorNations,
    tribes: tribes,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: 'oldWorld',
            ownerId: defenderOwnerId,
          ),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
    ),
    players: players,
  );
}
