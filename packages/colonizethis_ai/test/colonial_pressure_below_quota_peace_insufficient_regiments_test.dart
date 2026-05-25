import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/planning/colonial_pressure.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

// Pins observer-EXPAND below-quota peace insufficient-regiments predicate
// (seed-42 gp3 turn-100 trap; Refs #2509 § Observer goal phases (Full AI)
// "EXPAND regiment-rebuild trap").
void main() {
  group('isBelowQuotaPeaceInsufficientRegiments', () {
    test('false when at or above the observer OW quota', () {
      expect(
        isBelowQuotaPeaceInsufficientRegiments(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
        ),
        isFalse,
      );
    });

    test('false when at war with any Great Power', () {
      expect(
        isBelowQuotaPeaceInsufficientRegiments(
          oldWorldProvincesOwned: 8,
          regimentCount: 3,
          atWarWithAnyGreatPower: true,
          hasInvadableProvinces: true,
        ),
        isFalse,
      );
    });

    test('false when no invadable provinces remain', () {
      expect(
        isBelowQuotaPeaceInsufficientRegiments(
          oldWorldProvincesOwned: 8,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: false,
        ),
        isFalse,
      );
    });

    test(
      'false when regimentCount is zero (handled by broke-at-peace trigger)',
      () {
        expect(
          isBelowQuotaPeaceInsufficientRegiments(
            oldWorldProvincesOwned: 8,
            regimentCount: 0,
            atWarWithAnyGreatPower: false,
            hasInvadableProvinces: true,
          ),
          isFalse,
        );
      },
    );

    test('false when regimentCount meets the at-peace declare-war floor', () {
      expect(
        isBelowQuotaPeaceInsufficientRegiments(
          oldWorldProvincesOwned: 8,
          regimentCount: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
        ),
        isFalse,
      );
    });

    test(
      'true for the seed-42 gp3 trap: 8 OW, 3 regiments, peace, invadable GP frontier',
      () {
        expect(
          isBelowQuotaPeaceInsufficientRegiments(
            oldWorldProvincesOwned: 8,
            regimentCount: 3,
            atWarWithAnyGreatPower: false,
            hasInvadableProvinces: true,
          ),
          isTrue,
        );
      },
    );

    test(
      'true at the lower band (1 regiment) while below quota and at peace',
      () {
        expect(
          isBelowQuotaPeaceInsufficientRegiments(
            oldWorldProvincesOwned:
                kObserverConquestMinOwProvincesPerGp - 1, // 9
            regimentCount: 1,
            atWarWithAnyGreatPower: false,
            hasInvadableProvinces: true,
          ),
          isTrue,
        );
      },
    );

    test('true just below the at-peace declare-war floor', () {
      expect(
        isBelowQuotaPeaceInsufficientRegiments(
          oldWorldProvincesOwned: 9,
          regimentCount: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar - 1,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
        ),
        isTrue,
      );
    });
  });

  group('isBelowQuotaPeaceTreasuryRecovery', () {
    test('false when pending riches cover cheapest regiment build', () {
      final stockpile = Stockpile().applyDelta(
        CommodityCatalog.gold.id,
        (cheapestRegimentBuildTreasuryCost() /
                richesBasePrice(CommodityCatalog.gold.id))
            .ceil(),
      );
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: 8,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
          treasury: 0,
          stockpile: stockpile,
        ),
        isFalse,
      );
    });

    test(
      'true for seed-42 trap shape with zero treasury and empty stockpile',
      () {
        expect(
          isBelowQuotaPeaceTreasuryRecovery(
            oldWorldProvincesOwned: 8,
            regimentCount: 3,
            atWarWithAnyGreatPower: false,
            hasInvadableProvinces: true,
            treasury: 0,
            stockpile: const Stockpile(),
          ),
          isTrue,
        );
      },
    );
  });
}
