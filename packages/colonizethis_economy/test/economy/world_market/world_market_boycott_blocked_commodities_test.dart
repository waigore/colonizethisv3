// SPEC-AC tests for `boycottedColonySellableCommodityIds`
// (Refs #3758 S7/R12; SPEC/ai/treasury-planner.md § Boycott-aware bid
// suppression). Confirms the commodity set a boycotted buyer cannot source
// from a colony Tribe it is boycotted from, and the cheap-gating no-ops.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  late final Map<String, TileMapResult> tileMaps;
  late final MapTopology topology;

  setUpAll(() {
    tileMaps = tileMapsForBoycottColonyTribeTest();
    topology = topologyForBoycottColonyTribeTest();
  });

  group('boycottedColonySellableCommodityIds (Refs #3758 S7/R12)', () {
    test(
      'returns the colony Tribe sellable commodities for the boycotted buyer',
      () {
        final game = gameWithColonyTribeBoycottTest(
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
          tileMapByRegion: tileMaps,
          topology: topology,
        );

        expect(blocked, equals(<CommodityId>{'furs'}));
      },
    );

    test(
      'honors precomputed auto-offers without recomputing connectivity',
      () {
        final game = gameWithColonyTribeBoycottTest(
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
          tileMapByRegion: tileMaps,
          topology: topology,
          connectivityByFactionId: const {},
          autoOffersByFactionId: {
            't1': [testOffer('furs', 1)],
          },
        );

        expect(blocked, equals(<CommodityId>{'furs'}));
      },
    );

    test('empty for a buyer that is not the boycott target', () {
      final game = gameWithColonyTribeBoycottTest(
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
        tileMapByRegion: tileMaps,
        topology: topology,
      );

      expect(blocked, isEmpty);
    });

    test('empty when no boycott is active', () {
      final game = gameWithColonyTribeBoycottTest(
        colonyStates: const [
          ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
        ],
      );

      final blocked = boycottedColonySellableCommodityIds(
        game: game,
        buyerPlayerId: 'gpC',
        tileMapByRegion: tileMaps,
        topology: topology,
      );

      expect(blocked, isEmpty);
    });

    test('empty when the boycotting GP holds no colony', () {
      final game = gameWithColonyTribeBoycottTest(
        boycottStates: const [
          BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
        ],
      );

      final blocked = boycottedColonySellableCommodityIds(
        game: game,
        buyerPlayerId: 'gpC',
        tileMapByRegion: tileMaps,
        topology: topology,
      );

      expect(blocked, isEmpty);
    });

    test('empty when tile maps are omitted (unit-test path unaffected)', () {
      final game = gameWithColonyTribeBoycottTest(
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
        topology: topology,
      );

      expect(blocked, isEmpty);
    });

    test('empty when topology is absent', () {
      final game = gameWithColonyTribeBoycottTest(
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
        tileMapByRegion: tileMaps,
        topology: null,
      );

      expect(blocked, isEmpty);
    });
  });
}
