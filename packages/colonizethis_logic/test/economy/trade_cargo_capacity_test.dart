import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/src/economy/trade_cargo_capacity.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('overseasShippedTonnageFromExtractionTotals', () {
    test('sums units committed by allocateOverseasToStockpile', () {
      expect(
        overseasShippedTonnageFromExtractionTotals(
          const {'grain': 20},
          homeFleetCargoHolds: 12,
        ),
        12,
      );
    });

    test('returns 0 when no overseas totals or zero holds', () {
      expect(
        overseasShippedTonnageFromExtractionTotals(
          const {},
          homeFleetCargoHolds: 3,
        ),
        0,
      );
      expect(
        overseasShippedTonnageFromExtractionTotals(
          const {'grain': 5},
          homeFleetCargoHolds: 0,
        ),
        0,
      );
    });
  });

  group('tradeCargoCapacityForGreatPower', () {
    test('returns full home fleet when tile maps are empty', () {
      final game = Game(
        id: 'g1',
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: false,
            stockpile: Stockpile.empty,
            treasury: 0,
          ),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
      );
      expect(
        tradeCargoCapacityForGreatPower(
          game: game,
          playerId: 'gp1',
          tileMapByRegion: const {},
          topology: const MapTopology(nodes: [], edges: []),
        ),
        cargoHoldsForHomeFleet(game, 'gp1'),
      );
    });
  });
}
