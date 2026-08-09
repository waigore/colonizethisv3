import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import '../support/extraction_auto_transport_test_fixtures.dart';
import '../support/extraction_town_manufacturing_bonus_fixtures.dart';

/// End-to-end extraction-phase tests for town manufacturing bonus AC matrix
/// (Refs #3872).
void main() {
  group('runExtractionPhase — town manufacturing bonus AC matrix (Refs #3872)', () {
    test(
      'capital-connected but not town-connected: timber reaches stockpile, '
      'no lumber bonus',
      () {
        final (:game, :tileMapByRegion) =
            capitalConnectedNotTownConnectedFixture();
        final topology = twoProvinceOldWorldTopology();
        final priorTimber = _stockpileQty(game, CommodityCatalog.timber.id);
        final priorLumber = _stockpileQty(game, CommodityCatalog.lumber.id);

        final next = runExtractionPhase(
          game,
          topology,
          tileMapByRegion,
          <String, Map<CommodityId, int>>{},
        );
        final player = next.players.firstWhere((p) => p.id == 'pl1');

        expect(
          player.stockpile.quantityOf(CommodityCatalog.timber.id),
          greaterThan(priorTimber),
          reason: 'timber tile is capital-connected and should extract',
        );
        expect(
          player.stockpile.quantityOf(CommodityCatalog.lumber.id),
          priorLumber,
          reason: 'timber is not town-connected so no manufacturing bonus',
        );
      },
    );

    test(
      'town-connected but not capital-connected: zero timber and zero lumber',
      () {
        final (:game, :tileMapByRegion) =
            townConnectedNotCapitalConnectedFixture();
        final topology = twoProvinceOldWorldTopology();
        final priorTimber = _stockpileQty(game, CommodityCatalog.timber.id);
        final priorLumber = _stockpileQty(game, CommodityCatalog.lumber.id);

        final next = runExtractionPhase(
          game,
          topology,
          tileMapByRegion,
          <String, Map<CommodityId, int>>{},
        );
        final player = next.players.firstWhere((p) => p.id == 'pl1');

        expect(player.stockpile.quantityOf(CommodityCatalog.timber.id), priorTimber);
        expect(player.stockpile.quantityOf(CommodityCatalog.lumber.id), priorLumber);
      },
    );

    test(
      'both capital- and town-connected: timber extracts and lumber bonus '
      'credits',
      () {
        final (:game, :tileMapByRegion) = bothConnectedFixture();
        final topology = twoProvinceOldWorldTopology();
        final priorLumber = _stockpileQty(game, CommodityCatalog.lumber.id);

        final next = runExtractionPhase(
          game,
          topology,
          tileMapByRegion,
          <String, Map<CommodityId, int>>{},
        );
        final player = next.players.firstWhere((p) => p.id == 'pl1');

        expect(
          player.stockpile.quantityOf(CommodityCatalog.timber.id),
          greaterThan(0),
        );
        expect(
          player.stockpile.quantityOf(CommodityCatalog.lumber.id),
          greaterThan(priorLumber),
          reason: 'level-4 town with ≥4 town-connected timber → +2 lumber',
        );
      },
    );

    test('neither connected: zero timber extraction and zero lumber bonus', () {
      final (:game, :tileMapByRegion) = neitherConnectedFixture();
      final topology = twoProvinceOldWorldTopology();
      final priorTimber = _stockpileQty(game, CommodityCatalog.timber.id);
      final priorLumber = _stockpileQty(game, CommodityCatalog.lumber.id);

      final next = runExtractionPhase(
        game,
        topology,
        tileMapByRegion,
        <String, Map<CommodityId, int>>{},
      );
      final player = next.players.firstWhere((p) => p.id == 'pl1');

      expect(player.stockpile.quantityOf(CommodityCatalog.timber.id), priorTimber);
      expect(player.stockpile.quantityOf(CommodityCatalog.lumber.id), priorLumber);
    });

    test(
      'overseas: only cargo-delivered cotton counts for bonus input',
      () {
        final (:game, :tileMapByRegion) = extractionAutoTransportFixture(
          nwResourceGrid: const [
            [Resource.cotton, Resource.cotton],
            [Resource.cotton, Resource.cotton],
          ],
          nwImprovementLevel: 4,
          techUnlocked: {kTechIdCottonWeaving: true},
        );
        final topology = crossRegionSeaTopologyForExtractionTests();
        final priorCotton = _stockpileQty(game, CommodityCatalog.cotton.id);
        final priorFabric = _stockpileQty(game, CommodityCatalog.fabric.id);

        final next = runExtractionPhase(
          game,
          topology,
          tileMapByRegion,
          <String, Map<CommodityId, int>>{},
        );
        final player = next.players.firstWhere((p) => p.id == 'pl1');
        final cottonDelta =
            player.stockpile.quantityOf(CommodityCatalog.cotton.id) - priorCotton;
        final fabricDelta =
            player.stockpile.quantityOf(CommodityCatalog.fabric.id) - priorFabric;

        expect(cottonDelta, lessThanOrEqualTo(NavalStatsCatalog.carrack.cargoHold));
        expect(cottonDelta, greaterThan(0));
        expect(
          fabricDelta,
          (cottonDelta ~/ 4) * 2,
          reason: 'level-4 bonus uses floor(delivered/4)×2 from cargo-delivered '
              'town-connected cotton only',
        );
      },
    );

    test(
      'overseas: bonus fabric credits without consuming cargo holds',
      () {
        final (:game, :tileMapByRegion) = extractionAutoTransportFixture(
          nwResourceGrid: const [
            [Resource.cotton, Resource.cotton],
            [Resource.cotton, Resource.cotton],
          ],
          nwImprovementLevel: 4,
          techUnlocked: {kTechIdCottonWeaving: true},
        );
        final expandedFleets = game.worldState.fleets
            .map(
              (fleet) => fleet.id == 'fleet_pl1'
                  ? fleet.copyWith(
                      ships: const [
                        ShipInstance(id: 'ship_1', typeId: 'carrack'),
                        ShipInstance(id: 'ship_2', typeId: 'carrack'),
                      ],
                    )
                  : fleet,
            )
            .toList();
        final gameWithCargo = game.copyWith(
          worldState: game.worldState.copyWith(fleets: expandedFleets),
        );
        final topology = crossRegionSeaTopologyForExtractionTests();
        final priorCotton = _stockpileQty(gameWithCargo, CommodityCatalog.cotton.id);
        final priorFabric = _stockpileQty(gameWithCargo, CommodityCatalog.fabric.id);

        final next = runExtractionPhase(
          gameWithCargo,
          topology,
          tileMapByRegion,
          <String, Map<CommodityId, int>>{},
        );
        final player = next.players.firstWhere((p) => p.id == 'pl1');
        final cottonDelta =
            player.stockpile.quantityOf(CommodityCatalog.cotton.id) - priorCotton;
        final fabricDelta =
            player.stockpile.quantityOf(CommodityCatalog.fabric.id) - priorFabric;

        expect(cottonDelta, 4);
        expect(fabricDelta, 2);
        expect(
          player.stockpile.quantityOf(CommodityCatalog.cotton.id) +
              player.stockpile.quantityOf(CommodityCatalog.fabric.id),
          greaterThan(cottonDelta),
          reason: 'manufactured fabric bonus is credited in addition to raw '
              'cargo-limited delivery',
        );
      },
    );
  });
}

int _stockpileQty(Game game, CommodityId id) {
  return game.players.first.stockpile.quantityOf(id);
}
