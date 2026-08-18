// Military counsel ranking (Refs #4307 Slice A). Dense for repo.orders_test_support_loc.
// dart format off
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/military_counsel_ranking.dart';
import 'package:colonizethis_orders/src/orders/military_counsel_scoring.dart';
import 'package:colonizethis_orders/src/orders/military_counsel_types.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_probe_validator.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'support/scenario_runner.dart';

const _ow = 'oldWorld';
const _gp1 = 'gp1';
const _gp2 = 'gp2';

Army _mcFieldArmy(String local) {
  final pid = ProvinceId.full(_ow, local);
  return Army(
    id: fieldArmyIdFor(_gp1, pid),
    ownerId: _gp1,
    regionId: _ow,
    stationedProvinceId: pid,
    regimentUnitIds: const ['u1'],
    isHomeArmy: false,
  );
}

MapTopology _mcTopo(List<String> locals, List<(String, String)> edges) =>
    MapTopology(
      nodes: [
        for (final id in locals)
          TopologyNode(id: id, regionId: _ow, type: TopologyNodeType.province),
      ],
      edges: [
        for (final e in edges) TopologyEdge(id1: e.$1, id2: e.$2),
      ],
    );

Game _mcTrainGame() {
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  var stockpile = const Stockpile();
  for (final e in econ.buildInputs.entries) {
    stockpile = stockpile.applyDelta(e.key, e.value * 3 + 1);
  }
  return TestFixtures.minimalGame(
    id: 'g-train',
    turnNumber: 1,
    players: [
      Player(
        id: _gp1,
        displayName: 'GP',
        isHuman: true,
        capitalProvinceId: '$_ow|P1',
        stockpile: stockpile,
        workerPool: const WorkerPool(peasants: 3),
        treasury: econ.buildTreasuryCost * 2 + 50,
      ),
    ],
    oldWorld: RegionData(
      provinces: [
        Province(id: '$_ow|P1', regionId: _ow, ownerId: _gp1),
      ],
    ),
  );
}

Game _mcInvadeGame({
  List<DiplomacyRelation> diplomacy = const [],
}) {
  final loc = ProvinceId.full(_ow, 'P1');
  return TestFixtures.minimalGame(
    id: 'g-invade',
    turnNumber: 1,
    players: const [
      Player(id: _gp1, displayName: 'A', isHuman: true),
      Player(id: _gp2, displayName: 'B', isHuman: true),
    ],
    oldWorld: RegionData(
      provinces: [
        Province(id: '$_ow|P1', regionId: _ow, ownerId: _gp1),
        Province(
          id: '$_ow|P2',
          regionId: _ow,
          ownerId: _gp2,
          displayName: 'Enemy',
        ),
      ],
      units: [
        Unit(
          id: 'u1',
          type: 'musketeers',
          ownerId: _gp1,
          locationProvinceId: loc,
        ),
      ],
    ),
    armies: [_mcFieldArmy('P1')],
    playerVisibilityByTile: {
      _gp1: {
        '$_ow|P1|0|0': 'fullyVisible',
        '$_ow|P2|0|0': 'fullyVisible',
      },
    },
    tileKeysByRegionAndProvince: {
      _ow: {
        '$_ow|P1': ['$_ow|P1|0|0'],
        '$_ow|P2': ['$_ow|P2|0|0'],
      },
    },
    diplomacyRelations: diplomacy,
  );
}

List<MilitaryCounselRecommendation> _mcRank(
  Game game, {
  Orders orders = const Orders(),
  MapTopology topology = const MapTopology(),
}) =>
    rankMilitaryCounselRecommendations(
      game: game,
      playerId: _gp1,
      currentOrders: orders,
      topology: topology,
    );

void main() {
  runLabeledScenarioGroup('rankMilitaryCounselRecommendations', [
    rs('builds one pass-level validator without fallback rebuild (Refs #4508)', () {
      resetIncrementalCandidateValidatorBuildCountForTests();
      _mcRank(_mcTrainGame(), topology: _mcTopo(['P1'], []));
      expect(incrementalCandidateValidatorBuildCountForTests, 1);
    }),
    rs('returns at most three stable recommendations', () {
      final game = _mcTrainGame();
      final topo = _mcTopo(['P1'], []);
      final first = _mcRank(game, topology: topo);
      final second = _mcRank(game, topology: topo);
      expect(first.length, lessThanOrEqualTo(3));
      expect(
        second.map((r) => r.recommendationId).toList(),
        equals(first.map((r) => r.recommendationId).toList()),
      );
    }),
    rs('emits train recommendation with positive count and cost snapshot', () {
      final ranked = _mcRank(_mcTrainGame(), topology: _mcTopo(['P1'], []));
      final trains = ranked
          .where((r) => r.kind == MilitaryCounselRecommendationKind.trainUnit)
          .toList();
      expect(trains, isNotEmpty);
      final train = trains.first;
      expect(train.count, greaterThan(0));
      expect(train.unitType, isNotNull);
      expect(train.recommendationId, 'train:${train.unitType}');
      expect(train.costSnapshot?.treasuryCost, greaterThan(0));
      expect(train.briefReasonKey, MilitaryCounselReasonKey.affordableTrain);
      expect(train.isHighlight, isTrue);
    }),
    rs('returns empty when no affordable builds and no invasions', () {
      final game = TestFixtures.minimalGame(
        id: 'g-empty',
        turnNumber: 1,
        players: const [
          Player(
            id: _gp1,
            displayName: 'GP',
            isHuman: true,
            treasury: 0,
            workerPool: WorkerPool(peasants: 0),
          ),
        ],
      );
      expect(_mcRank(game), isEmpty);
    }),
    rs('never recommends Home Army for invade', () {
      final homeArmy = Army(
        id: homeArmyIdFor(_gp1),
        ownerId: _gp1,
        regionId: _ow,
        stationedProvinceId: '$_ow|P1',
        regimentUnitIds: const ['u1'],
        isHomeArmy: true,
      );
      final game = _mcInvadeGame().copyWith(
        worldState: _mcInvadeGame().worldState.copyWith(
          armies: [homeArmy, _mcFieldArmy('P1')],
        ),
      );
      final ranked = _mcRank(
        game,
        topology: _mcTopo(['P1', 'P2'], [('P1', 'P2')]),
      );
      final invades = ranked
          .where((r) => r.kind == MilitaryCounselRecommendationKind.invade)
          .toList();
      expect(invades, isNotEmpty);
      expect(invades.every((r) => r.armyId != homeArmy.id), isTrue);
    }),
    rs('invade at war scores higher than declare-war peace target', () {
      final atWarScore = militaryCounselScoreInvade(
        game: _mcInvadeGame(
          diplomacy: const [
            DiplomacyRelation(
              factionId1: _gp1,
              factionId2: _gp2,
              state: RelationState.atWar,
            ),
          ],
        ),
        playerId: _gp1,
        ownerFactionId: _gp2,
      );
      final peaceScore = militaryCounselScoreInvade(
        game: _mcInvadeGame(),
        playerId: _gp1,
        ownerFactionId: _gp2,
      );
      expect(atWarScore, greaterThan(peaceScore));
    }),
    rs('emits invade recommendation with intel and stable id', () {
      final ranked = _mcRank(
        _mcInvadeGame(),
        topology: _mcTopo(['P1', 'P2'], [('P1', 'P2')]),
      );
      final invade = ranked.singleWhere(
        (r) => r.kind == MilitaryCounselRecommendationKind.invade,
      );
      expect(invade.recommendationId, 'invade:${invade.armyId}:${invade.destinationProvinceId}');
      expect(invade.requiresDeclareWar, isTrue);
      expect(invade.ownerFactionId, _gp2);
      expect(invade.invasionIntel, isNotNull);
      expect(
        invade.briefReasonKey,
        MilitaryCounselReasonKey.declareWarInvasion,
      );
    }),
    rs('at war invade recommendation omits declare-war flag', () {
      final ranked = _mcRank(
        _mcInvadeGame(
          diplomacy: const [
            DiplomacyRelation(
              factionId1: _gp1,
              factionId2: _gp2,
              state: RelationState.atWar,
            ),
          ],
        ),
        topology: _mcTopo(['P1', 'P2'], [('P1', 'P2')]),
      );
      final invade = ranked.singleWhere(
        (r) => r.kind == MilitaryCounselRecommendationKind.invade,
      );
      expect(invade.requiresDeclareWar, isFalse);
      expect(
        invade.briefReasonKey,
        MilitaryCounselReasonKey.atWarInvasion,
      );
    }),
    rs('sorts by descending rankScore then kind precedence', () {
      final ranked = _mcRank(
        _mcInvadeGame(
          diplomacy: const [
            DiplomacyRelation(
              factionId1: _gp1,
              factionId2: _gp2,
              state: RelationState.atWar,
            ),
          ],
        ),
        topology: _mcTopo(['P1', 'P2'], [('P1', 'P2')]),
      );
      for (var i = 0; i < ranked.length - 1; i++) {
        expect(
          ranked[i].rankScore,
          greaterThanOrEqualTo(ranked[i + 1].rankScore),
        );
      }
    }),
  ], runRunnableScenario);
}
