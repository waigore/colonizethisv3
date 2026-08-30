// Military counsel ranking Game/topology fixtures (Refs #4508 Slice D).
// dart format off
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/military_counsel_ranking.dart';
import 'package:colonizethis_orders/src/orders/military_counsel_types.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const mcOw = 'oldWorld';
const mcGp1 = 'gp1';
const mcGp2 = 'gp2';

Army mcFieldArmy([String local = 'P1']) {
  final pid = ProvinceId.full(mcOw, local);
  return Army(id: fieldArmyIdFor(mcGp1, pid), ownerId: mcGp1, regionId: mcOw, stationedProvinceId: pid, regimentUnitIds: const ['u1'], isHomeArmy: false);
}

Army mcHomeArmy() => Army(id: homeArmyIdFor(mcGp1), ownerId: mcGp1, regionId: mcOw, stationedProvinceId: '$mcOw|P1', regimentUnitIds: const ['u1'], isHomeArmy: true);

MapTopology mcTopo(List<String> locals, [List<(String, String)> edges = const []]) => MapTopology(nodes: [for (final id in locals) TopologyNode(id: id, regionId: mcOw, type: TopologyNodeType.province)], edges: [for (final e in edges) TopologyEdge(id1: e.$1, id2: e.$2)]);

List<DiplomacyRelation> mcAtWar() => const [DiplomacyRelation(factionId1: mcGp1, factionId2: mcGp2, state: RelationState.atWar)];

Game mcTrainGame() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  var stockpile = const Stockpile();
  for (final e in econ.buildInputs.entries) {stockpile = stockpile.applyDelta(e.key, e.value * 3 + 1);}
  return TestFixtures.minimalGame(id: 'g-train', turnNumber: 1, players: [Player(id: mcGp1, displayName: 'GP', isHuman: true, capitalProvinceId: '$mcOw|P1', stockpile: stockpile, workerPool: const WorkerPool(peasants: 3), treasury: econ.buildTreasuryCost * 2 + 50)], oldWorld: RegionData(provinces: [Province(id: '$mcOw|P1', regionId: mcOw, ownerId: mcGp1)]));
}

Game mcInvadeGame({List<DiplomacyRelation> diplomacy = const []}) {
  final loc = ProvinceId.full(mcOw, 'P1');
  return TestFixtures.minimalGame(id: 'g-invade', turnNumber: 1, players: const [Player(id: mcGp1, displayName: 'A', isHuman: true), Player(id: mcGp2, displayName: 'B', isHuman: true)], oldWorld: RegionData(provinces: [Province(id: '$mcOw|P1', regionId: mcOw, ownerId: mcGp1), Province(id: '$mcOw|P2', regionId: mcOw, ownerId: mcGp2, displayName: 'Enemy')], units: [Unit(id: 'u1', type: 'musketeers', ownerId: mcGp1, locationProvinceId: loc)]), armies: [mcFieldArmy()], playerVisibilityByTile: {mcGp1: {'$mcOw|P1|0|0': 'fullyVisible', '$mcOw|P2|0|0': 'fullyVisible'}}, tileKeysByRegionAndProvince: {mcOw: {'$mcOw|P1': ['$mcOw|P1|0|0'], '$mcOw|P2': ['$mcOw|P2|0|0']}}, diplomacyRelations: diplomacy);
}

Game mcEmptyGame() => TestFixtures.minimalGame(id: 'g-empty', turnNumber: 1, players: const [Player(id: mcGp1, displayName: 'GP', isHuman: true, treasury: 0, workerPool: WorkerPool(peasants: 0))]);

Game mcInvadeWithHomeArmy() {
  final base = mcInvadeGame();
  return base.copyWith(worldState: base.worldState.copyWith(armies: [mcHomeArmy(), mcFieldArmy()]));
}

List<MilitaryCounselRecommendation> mcRank(Game game, {Orders orders = const Orders(), MapTopology topology = const MapTopology()}) => rankMilitaryCounselRecommendations(game: game, playerId: mcGp1, currentOrders: orders, topology: topology);
