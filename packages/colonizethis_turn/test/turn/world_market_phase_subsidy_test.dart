import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';
import 'world_market_phase_first_right_credit_test_support.dart';

/// Phase-handler integration for the subsidy price adjustment (Refs #3753
/// R3.4): a Great Power that subsidises a Minor pays a surcharge when buying
/// that Minor's goods on the world market.
///
/// SPEC anchors:
///
/// - `SPEC/game/world-market.md` § Subsidy price adjustment (Minor/Tribe deals).
/// - `SPEC/program/world-market-resolution.md` § Step D — Subsidy price
///   adjustment.
void main() {
  Game subsidyGame({required int subsidyPercent}) {
    return TestFixtures.minimalGame(
          players: const [
            Player(
              id: 'gpA',
              displayName: 'GP A',
              isHuman: true,
              treasury: 1000,
              stockpile: Stockpile.empty,
            ),
          ],
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: frrCreditTestMinorProvinceId,
                regionId: frrCreditTestOw,
                ownerId: 'M1',
              ),
            ],
          ),
          tileKeysByRegionAndProvince: const {
            frrCreditTestOw: {
              frrCreditTestMinorProvinceId: [frrCreditTestTileKey],
            },
          },
          minorNations: const [MinorNation(id: 'M1', displayName: 'Minor 1')],
        )
        .copyWith(
          worldMarketState: WorldMarketState.empty.copyWith(
            prices: const {'timber': 20},
          ),
          subsidyStates: [
            SubsidyState(payerId: 'gpA', targetId: 'M1', percent: subsidyPercent),
          ],
        );
  }

  group('worldMarketTurnPhaseHandler subsidy surcharge (Refs #3753 R3.4b)', () {
    test('GP buyer pays a 10% surcharge buying its subsidised Minor\'s goods',
        () {
      final next = runWorldMarketFrrCreditPhase(
        game: subsidyGame(subsidyPercent: 10),
        tradeOrdersByPlayerId: {
          'M1': minorTimberOffer(quantity: 10),
          'gpA': gpTimberBid(quantity: 10),
        },
      );

      // base 10*20 = 200, +10% surcharge = 220 debited; Minor is a sink.
      expect(next.players.firstWhere((p) => p.id == 'gpA').treasury, 1000 - 220);
      expect(
        next.players.firstWhere((p) => p.id == 'gpA').stockpile.quantityOf(
          'timber',
        ),
        10,
      );
    });

    test('GP buyer pays the unadjusted price when no subsidy is active', () {
      final game = subsidyGame(subsidyPercent: 10).copyWith(
        subsidyStates: const <SubsidyState>[],
      );
      final next = runWorldMarketFrrCreditPhase(
        game: game,
        tradeOrdersByPlayerId: {
          'M1': minorTimberOffer(quantity: 10),
          'gpA': gpTimberBid(quantity: 10),
        },
      );

      expect(next.players.firstWhere((p) => p.id == 'gpA').treasury, 1000 - 200);
    });
  });
}
