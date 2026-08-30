// Scalar predicate matrix pins (Refs #4602 Slice B).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'expand_phase_peace_matrix_scalar_predicate_support.dart';

void registerExpandPeaceScalarPredicateTreasuryRecoveryCases() {
  final c = expandPeaceScalarPredicateConstants();
  final quota = c.quota;
  final floor = c.floor;
  final cheapest = c.cheapest;
  final goldPrice = c.goldPrice;
  final silverPrice = c.silverPrice;
  final spicesPrice = c.spicesPrice;

  group('isBelowQuotaPeaceTreasuryRecovery (truth table)', () {
    test('spices base price is exactly 50 (boundary-row anchor)', () {
      // Boundary rows below depend on one spice contributing exactly 50 to the
      // effective treasury; lock the constant so a base-price change surfaces.
      expect(spicesPrice, 50);
    });

    final cases =
        <
          ({
            String name,
            int ow,
            int regiments,
            bool atWar,
            bool hasInvadable,
            int treasury,
            Stockpile stockpile,
            bool expected,
            String reason,
          })
        >[
          // Predicate fall-through: each precondition false branch must
          // short-circuit regardless of treasury / stockpile inputs.
          (
            name: 'false at or above the observer OW quota',
            ow: quota,
            regiments: 3,
            atWar: false,
            hasInvadable: true,
            treasury: 0,
            stockpile: const Stockpile(),
            expected: false,
            reason:
                'Above-quota GPs are out of EXPAND, no cargo-recovery path.',
          ),
          (
            name:
                'false when at war with any Great Power (predicate guard wins)',
            ow: 8,
            regiments: 3,
            atWar: true,
            hasInvadable: true,
            treasury: 0,
            stockpile: const Stockpile(),
            expected: false,
            reason: 'A GP at war is not diverted onto cargo preference.',
          ),
          (
            name:
                'false when no invadable provinces remain (predicate guard wins)',
            ow: 8,
            regiments: 3,
            atWar: false,
            hasInvadable: false,
            treasury: 0,
            stockpile: const Stockpile(),
            expected: false,
            reason: 'Short-circuits before the cash/riches sum.',
          ),
          (
            name: 'true when regimentCount is zero and invadable OW remains',
            ow: 8,
            regiments: 0,
            atWar: false,
            hasInvadable: true,
            treasury: 0,
            stockpile: const Stockpile(),
            expected: true,
            reason:
                'Zero-regiment below-quota GPs need cargo to fund a rebuild.',
          ),
          (
            name:
                'false at the at-peace declare-war regiment floor (upper exit)',
            ow: 8,
            regiments: floor,
            atWar: false,
            hasInvadable: true,
            treasury: 0,
            stockpile: const Stockpile(),
            expected: false,
            reason:
                'At the floor the GP should open a minor frontier, not recover.',
          ),
          // Effective-treasury boundary: `< cheapest` (strict) stays in recovery.
          (
            name:
                'false when treasury alone equals cheapest cost (== boundary)',
            ow: 8,
            regiments: 3,
            atWar: false,
            hasInvadable: true,
            treasury: cheapest,
            stockpile: const Stockpile(),
            expected: false,
            reason:
                'effectiveTreasury == cheapest can afford the build (strict <).',
          ),
          (
            name: 'true when treasury alone is one short of cheapest cost',
            ow: 8,
            regiments: 3,
            atWar: false,
            hasInvadable: true,
            treasury: cheapest - 1,
            stockpile: const Stockpile(),
            expected: true,
            reason: 'cheapest - 1 stays in recovery for one more cargo unit.',
          ),
          (
            name: 'false when cash + 1 spice (=50) just clears cheapest cost',
            ow: 8,
            regiments: 3,
            atWar: false,
            hasInvadable: true,
            treasury: cheapest - 50,
            stockpile: expandPeaceMatrixRichesStockpile(
              CommodityCatalog.spices.id,
              1,
            ),
            expected: false,
            reason: 'Mixed cash + riches compose to exactly cheapest -> exit.',
          ),
          (
            name:
                'true when cash + 1 spice is still one short of cheapest cost',
            ow: 8,
            regiments: 3,
            atWar: false,
            hasInvadable: true,
            treasury: cheapest - 50 - 1,
            stockpile: expandPeaceMatrixRichesStockpile(
              CommodityCatalog.spices.id,
              1,
            ),
            expected: true,
            reason:
                'cash + riches == cheapest - 1 stays strictly below the cost.',
          ),
          (
            name: 'true when gold-only stockpile is one full gold unit short',
            ow: 8,
            regiments: 3,
            atWar: false,
            hasInvadable: true,
            treasury: 0,
            stockpile: expandPeaceMatrixRichesStockpile(
              CommodityCatalog.gold.id,
              (cheapest / goldPrice).ceil() - 1,
            ),
            expected: true,
            reason:
                'Stockpile-only riches truncation leaves the GP strictly short.',
          ),
          (
            name: 'false when pending gold riches exactly cover cheapest build',
            ow: 8,
            regiments: 3,
            atWar: false,
            hasInvadable: true,
            treasury: 0,
            stockpile: expandPeaceMatrixRichesStockpile(
              CommodityCatalog.gold.id,
              (cheapest / goldPrice).ceil(),
            ),
            expected: false,
            reason:
                'Pending riches that cover the cheapest build exit recovery.',
          ),
          // Composition sanity.
          (
            name:
                'true when treasury and stockpile both contribute zero (low band)',
            ow: quota - 1,
            regiments: 1,
            atWar: false,
            hasInvadable: true,
            treasury: 0,
            stockpile: const Stockpile(),
            expected: true,
            reason: 'Lower-band canonical seed-42 trap: effective treasury 0.',
          ),
          (
            name:
                'false when multi-commodity riches (gold + silver) clear cost',
            ow: 8,
            regiments: 3,
            atWar: false,
            hasInvadable: true,
            treasury: 0,
            stockpile: Stockpile()
                .applyDelta(CommodityCatalog.gold.id, 1)
                .applyDelta(
                  CommodityCatalog.silver.id,
                  ((cheapest - goldPrice) / silverPrice).ceil(),
                ),
            expected: false,
            reason:
                'Effective treasury sums every riches commodity in the loop.',
          ),
        ];

    for (final c in cases) {
      test(c.name, () {
        expect(
          isBelowQuotaPeaceTreasuryRecovery(
            oldWorldProvincesOwned: c.ow,
            regimentCount: c.regiments,
            atWarWithAnyGreatPower: c.atWar,
            hasInvadableProvinces: c.hasInvadable,
            treasury: c.treasury,
            stockpile: c.stockpile,
          ),
          c.expected ? isTrue : isFalse,
          reason: c.reason,
        );
      });
    }
  });
}
