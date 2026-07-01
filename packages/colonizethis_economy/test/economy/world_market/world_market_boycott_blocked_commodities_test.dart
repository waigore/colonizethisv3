// SPEC-AC tests for `boycottedColonySellableCommodityIds`
// (Refs #3758 S7/R12; SPEC/ai/treasury-planner.md § Boycott-aware bid
// suppression). Confirms the commodity set a boycotted buyer cannot source
// from a colony Tribe it is boycotted from, and the cheap-gating no-ops.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

const _nw = 'newWorld';
const _tribeProvinceId = 'newWorld|t1';

Game _gameWithColonyTribe({
  List<ColonyState> colonyStates = const [],
  List<BoycottState> boycottStates = const [],
}) {
  // A one-tile New-World tribe `t1` whose single developed tile produces furs,
  // so `computeNonGreatPowerAutoOffers` emits a furs offer for it.
  final tileState = TileMapState()
      .setImprovement('newWorld|t1|0|0', 1)
      .setRoadLevel('newWorld|t1|0|0', 1);
  return Game(
    id: 'g_boycott_test',
    worldState: WorldState(
      turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(
            id: _tribeProvinceId,
            regionId: _nw,
            ownerId: 't1',
            townDevelopmentLevel: 1,
          ),
        ],
      ),
      tileState: tileState,
    ),
    players: [
      Player(id: 'gpA', displayName: 'Aragon', isHuman: false),
      Player(id: 'gpC', displayName: 'Castile', isHuman: false),
    ],
    tribes: [testTribe()],
    colonyStates: colonyStates,
    boycottStates: boycottStates,
  );
}

Map<String, TileMapResult> _tileMaps() => {
  _nw: tileMapAllInProvinceForNonGpExtractionTest(
    provinceId: _tribeProvinceId,
    width: 1,
    height: 1,
    resources: const [
      [Resource.furs],
    ],
  ),
};

MapTopology _topology() => const MapTopology(
  nodes: [
    TopologyNode(id: 't1', regionId: _nw, type: TopologyNodeType.province),
  ],
  edges: [],
);

void main() {
  group('boycottedColonySellableCommodityIds (Refs #3758 S7/R12)', () {
    test(
      'returns the colony Tribe sellable commodities for the boycotted buyer',
      () {
        final game = _gameWithColonyTribe(
          colonyStates: const [
            ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
          ],
          boycottStates: const [
            BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
          ],
        );

        final blocked = boycottedColonySellableCommodityIds(
          game: game,
          buyerPlayerId: 'gpC',
          tileMapByRegion: _tileMaps(),
          topology: _topology(),
        );

        expect(blocked, equals(<CommodityId>{'furs'}));
      },
    );

    test('empty for a buyer that is not the boycott target', () {
      final game = _gameWithColonyTribe(
        colonyStates: const [
          ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
        ],
        boycottStates: const [
          BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
        ],
      );

      // The colony-holding GP itself is never the boycott target.
      final blocked = boycottedColonySellableCommodityIds(
        game: game,
        buyerPlayerId: 'gpA',
        tileMapByRegion: _tileMaps(),
        topology: _topology(),
      );

      expect(blocked, isEmpty);
    });

    test('empty when no boycott is active', () {
      final game = _gameWithColonyTribe(
        colonyStates: const [
          ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
        ],
      );

      final blocked = boycottedColonySellableCommodityIds(
        game: game,
        buyerPlayerId: 'gpC',
        tileMapByRegion: _tileMaps(),
        topology: _topology(),
      );

      expect(blocked, isEmpty);
    });

    test('empty when the boycotting GP holds no colony', () {
      final game = _gameWithColonyTribe(
        boycottStates: const [
          BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
        ],
      );

      final blocked = boycottedColonySellableCommodityIds(
        game: game,
        buyerPlayerId: 'gpC',
        tileMapByRegion: _tileMaps(),
        topology: _topology(),
      );

      expect(blocked, isEmpty);
    });

    test('empty when tile maps are omitted (unit-test path unaffected)', () {
      final game = _gameWithColonyTribe(
        colonyStates: const [
          ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
        ],
        boycottStates: const [
          BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
        ],
      );

      final blocked = boycottedColonySellableCommodityIds(
        game: game,
        buyerPlayerId: 'gpC',
        tileMapByRegion: const {},
        topology: _topology(),
      );

      expect(blocked, isEmpty);
    });

    test('empty when topology is absent', () {
      final game = _gameWithColonyTribe(
        colonyStates: const [
          ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
        ],
        boycottStates: const [
          BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
        ],
      );

      final blocked = boycottedColonySellableCommodityIds(
        game: game,
        buyerPlayerId: 'gpC',
        tileMapByRegion: _tileMaps(),
        topology: null,
      );

      expect(blocked, isEmpty);
    });
  });
}
