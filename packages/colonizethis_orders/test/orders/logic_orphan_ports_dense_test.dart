// Dense ports from colonizethis_logic orphans (Refs #4090 Slice D/E).
// Keeps unique asserts under repo.orders_test_support_loc package ceiling.
// dart format off
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'support/scenario_runner.dart';

const _ow = 'oldWorld'; const _nw = 'newWorld'; const _gp1 = 'gp1'; const _gp2 = 'gp2';
Army _field(String local) {final pid = ProvinceId.full(_ow, local); return Army(id: fieldArmyIdFor(_gp1, pid), ownerId: _gp1, regionId: _ow, stationedProvinceId: pid, regimentUnitIds: const ['u1'], isHomeArmy: false);}
MapTopology _topo(List<String> locals, List<(String, String)> edges) => MapTopology(nodes: [for (final id in locals) TopologyNode(id: id, regionId: _ow, type: TopologyNodeType.province)], edges: [for (final e in edges) TopologyEdge(id1: e.$1, id2: e.$2)]);
Game _pickerGame({required Map<String, String> owners, List<DiplomacyRelation> diplomacy = const [], RegionData newWorld = const RegionData(), Map<String, Map<String, String>>? vis, Map<String, Map<String, List<String>>>? tiles}) {
  final loc = ProvinceId.full(_ow, 'P1');
  final provinces = [for (final e in owners.entries) Province(id: ProvinceId.full(_ow, e.key), regionId: _ow, ownerId: e.value)];
  return TestFixtures.minimalGame(id: 'g', turnNumber: 1, players: const [Player(id: _gp1, displayName: 'A', isHuman: true), Player(id: _gp2, displayName: 'B', isHuman: true)],
    oldWorld: RegionData(provinces: provinces, units: [Unit(id: 'u1', type: 'musketeers', ownerId: _gp1, locationProvinceId: loc)]), newWorld: newWorld, armies: [_field('P1')],
    playerVisibilityByTile: vis ?? {_gp1: {for (final e in owners.entries) '$_ow|${e.key}|0|0': 'fullyVisible'}},
    tileKeysByRegionAndProvince: tiles ?? {_ow: {for (final e in owners.entries) ProvinceId.full(_ow, e.key): ['$_ow|${e.key}|0|0']}}, diplomacyRelations: diplomacy);
}
List<ArmyMovePickerDestination> _dests(Game g, MapTopology t) => armyMovePickerDestinations(game: g, topology: t, playerId: _gp1, army: _field('P1'), currentOrders: const Orders());

void main() {
  suppressLogsForTests();
  runLabeledScenarioGroup('logicOrphanPortsDense', [
    rs('picker includes adjacent own-province move (no declare war)', () {final list = _dests(_pickerGame(owners: {'P1': _gp1, 'P2': _gp1}), _topo(['P1', 'P2'], [('P1', 'P2')])); expect(list.map((e) => e.fullProvinceId), contains('$_ow|P2')); expect(list.every((e) => !e.requiresDeclareWarOnConfirm), isTrue);}),
    rs('picker includes cross-region own province (different landmass)', () {
      final g = _pickerGame(owners: {'P1': _gp1}, newWorld: RegionData(provinces: [Province(id: '$_nw|N1', regionId: _nw, ownerId: _gp1, displayName: 'Colony')]),
        vis: {_gp1: {'$_ow|P1|0|0': 'fullyVisible', '$_nw|N1|0|0': 'fullyVisible'}}, tiles: {_ow: {'$_ow|P1': ['$_ow|P1|0|0']}, _nw: {'$_nw|N1': ['$_nw|N1|0|0']}});
      final nw = _dests(g, const MapTopology()).firstWhere((e) => e.fullProvinceId == '$_nw|N1'); expect(nw.isPlayerOwned, isTrue); expect(nw.requiresDeclareWarOnConfirm, isFalse);
    }),
    rs('adjacent enemy province requires declare war on confirm when at peace', () {final inv = _dests(_pickerGame(owners: {'P1': _gp1, 'P2': _gp2}), _topo(['P1', 'P2'], [('P1', 'P2')])).firstWhere((e) => e.fullProvinceId == '$_ow|P2'); expect(inv.requiresDeclareWarOnConfirm, isTrue); expect(inv.ownerFactionId, _gp2);}),
    rs('two reachable enemy provinces of same owner both require declare war (Refs #2394 trial-validator cache keyed by defender)', () {
      final invasions = _dests(_pickerGame(owners: {'P1': _gp1, 'P2': _gp2, 'P3': _gp2}), _topo(['P1', 'P2', 'P3'], [('P1', 'P2'), ('P1', 'P3')])).where((e) => e.fullProvinceId == '$_ow|P2' || e.fullProvinceId == '$_ow|P3').toList();
      expect(invasions, hasLength(2)); expect(invasions.every((e) => e.requiresDeclareWarOnConfirm && e.ownerFactionId == _gp2), isTrue);
    }),
    rs('at war with enemy: invasion confirm not required', () {final inv = _dests(_pickerGame(owners: {'P1': _gp1, 'P2': _gp2}, diplomacy: const [DiplomacyRelation(factionId1: _gp1, factionId2: _gp2, state: RelationState.atWar)]), _topo(['P1', 'P2'], [('P1', 'P2')])).firstWhere((e) => e.fullProvinceId == '$_ow|P2'); expect(inv.requiresDeclareWarOnConfirm, isFalse);}),
    rs('player-owned destinations sort before other factions', () {
      final list = _dests(_pickerGame(owners: {'P1': _gp1, 'P2': _gp2, 'P3': _gp1}, diplomacy: const [DiplomacyRelation(factionId1: _gp1, factionId2: _gp2, state: RelationState.atWar)]), _topo(['P1', 'P2', 'P3'], [('P1', 'P2'), ('P1', 'P3')]));
      expect(list.lastIndexWhere((e) => e.isPlayerOwned) < list.indexWhere((e) => e.ownerFactionId == _gp2), isTrue);
    }),
    rs('applyArmyMoveOrderForPlayer last order per armyId wins', () {var o = const Orders(); o = applyArmyMoveOrderForPlayer(o, _gp1, const ArmyMoveOrder(armyId: 'army_field', destinationProvinceId: 'oldWorld|p1')); o = applyArmyMoveOrderForPlayer(o, _gp1, const ArmyMoveOrder(armyId: 'army_field', destinationProvinceId: 'oldWorld|p2')); expect(o.armyMoveOrdersByPlayerId[_gp1]!.single.destinationProvinceId, 'oldWorld|p2');}),
    rs('applyNavalMoveOrderForPlayer replaces prior naval move for same fleet', () {final after = applyNavalMoveOrderForPlayer(Orders(navalMoveOrdersByPlayerId: {_gp1: [const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1')]}), _gp1, const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2')); expect(after.navalMoveOrdersByPlayerId[_gp1], equals([const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2')]));}),
    rs('applyNavalMoveOrderForPlayer removes naval mission orders for same fleet', () {
      final after = applyNavalMoveOrderForPlayer(Orders(navalMoveOrdersByPlayerId: {_gp1: [const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2')]}, navalMissionOrdersByPlayerId: {_gp1: [NavalMissionOrder(fleetId: 'f1', mission: 'patrol'), NavalMissionOrder(fleetId: 'f2', mission: 'patrol')]}), _gp1, const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea3'));
      expect(after.navalMissionOrdersByPlayerId[_gp1]?.map((e) => e.fleetId).toList(), equals(['f2']));
    }),
    rs('navalMissionOrdersRespectingNavalMoves drops mission for fleet that has a move order', () {expect(navalMissionOrdersRespectingNavalMoves({_gp1: [NavalMissionOrder(fleetId: 'f1', mission: 'patrol')]}, {_gp1: [const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'z')]}).isEmpty, isTrue);}),
    rs('devExclusiveReservedTileKeysForPlayer includes in-progress and pending; ignorePending omits unit', () {
      const tk = 'oldWorld|p1|0|0'; final players = const [Player(id: _gp1, displayName: 'GP', isHuman: true)];
      final working = TestFixtures.minimalGame(id: 'g1', turnNumber: 1, players: players, oldWorld: RegionData(units: [Unit(id: 'b1', type: kUnitTypeBuilder, ownerId: _gp1, locationProvinceId: 'oldWorld|p1', status: UnitStatus.working, currentWork: CurrentWork(workTarget: kWorkTargetBuildImprovement, tileKey: tk, totalTurns: 2, remainingTurns: 1))]));
      expect(devExclusiveReservedTileKeysForPlayer(working, const Orders(), _gp1), contains(tk));
      final empty = TestFixtures.minimalGame(id: 'g1', turnNumber: 1, players: players); final orders = Orders(workOrdersByPlayerId: {_gp1: [WorkOrder(unitId: 'b1', target: kWorkTargetBuildImprovement, targetTileKey: tk)]});
      expect(devExclusiveReservedTileKeysForPlayer(empty, orders, _gp1), contains(tk)); expect(devExclusiveReservedTileKeysForPlayer(empty, orders, _gp1, ignorePendingWorkOrderUnitId: 'b1'), isNot(contains(tk))); expect(devExclusiveReservedTileKeysForPlayer(empty, orders, _gp1, ignorePendingWorkOrderUnitId: 'b2'), contains(tk));
    }),
    rs('terrain prospectability classification matches canonical mineral rules', () {expect(kProspectableByTerrainType.keys.toSet(), TerrainType.values.toSet()); expect(kProspectableByTerrainType[TerrainType.plains], isFalse); expect(kProspectableByTerrainType[TerrainType.hardwoodForest], isFalse); expect(kProspectableByTerrainType[TerrainType.scrubForest], isFalse); expect(kProspectableByTerrainType[TerrainType.hills], isTrue); expect(kProspectableByTerrainType[TerrainType.mountain], isTrue); expect(kProspectableByTerrainType[TerrainType.swamp], isTrue); expect(kProspectableByTerrainType[TerrainType.desert], isTrue);}),
    rs('civilian work draft commit validation accepts merged explorer explore work order', () {
      final p1 = Province(id: '$_ow|p1', regionId: _ow, ownerId: _gp1);
      final game = TestFixtures.minimalGame(id: 'g1', turnNumber: 1, players: const [Player(id: _gp1, displayName: 'Human', isHuman: true, treasury: 5000)], oldWorld: RegionData(provinces: [p1], units: [Unit(id: 'E1', type: kUnitTypeExplorer, ownerId: _gp1, locationProvinceId: p1.id, tileKey: '$_ow|p1|0|0', status: UnitStatus.idle)]), playerVisibilityByTile: {_gp1: {'$_ow|p1|0|0': 'fullyVisible', '$_ow|p1|0|1': 'unknown'}}, tileKeysByRegionAndProvince: {_ow: {p1.id: ['$_ow|p1|0|0', '$_ow|p1|0|1']}});
      final results = OrderEngine(initialOrders: const Orders().copyWith(workOrdersByPlayerId: {_gp1: [WorkOrder(unitId: 'E1', target: kWorkTargetExplore, targetTileKey: '$_ow|p1|0|0')]})).validatePlayerOrdersWithContext(game, const MapTopology(nodes: [TopologyNode(id: 'p1', regionId: _ow, type: TopologyNodeType.province)]), _gp1);
      expect(results, isNotEmpty); expect(results.every((r) => r.isAccepted), isTrue);
    }),
    rs('explore retains currentWork after Build/Work tick in foreign-owned partially-revealed province', () {
      const p1 = '$_ow|P1'; const p2 = '$_ow|P2'; const tP1 = '$_ow|P1|0|0'; const tP2a = '$_ow|P2|0|0'; const tP2b = '$_ow|P2|1|0';
      final next = applyBuildAndWorkOrders(TestFixtures.minimalGame(turnNumber: 0, players: const [Player(id: 'p1', displayName: 'P1', isHuman: true), Player(id: 'p2', displayName: 'P2', isHuman: true)], oldWorld: RegionData(provinces: const [Province(id: p1, regionId: _ow, ownerId: 'p1'), Province(id: p2, regionId: _ow, ownerId: 'p2')], units: [Unit(id: 'u1', type: kUnitTypeExplorer, ownerId: 'p1', locationProvinceId: p1, tileKey: tP1)]), playerVisibilityByTile: const {'p1': {tP1: 'fullyVisible', tP2a: 'fogged', tP2b: 'unknown'}}, tileKeysByRegionAndProvince: const {_ow: {p1: [tP1], p2: [tP2a, tP2b]}}), Orders(workOrdersByPlayerId: {'p1': [WorkOrder(unitId: 'u1', target: kWorkTargetExplore, targetTileKey: tP2a)]}));
      final u = next.worldState.oldWorld.units.single; expect(u.currentWork, isNotNull); expect(u.currentWork!.workTarget, kWorkTargetExplore); expect(u.currentWork!.remainingTurns, greaterThanOrEqualTo(1));
    }),
  ], runRunnableScenario);
}
