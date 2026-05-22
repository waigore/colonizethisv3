// Pins the EXPAND below-quota peace **treasury-recovery** predicate branches at
// the `isBelowQuotaPeaceTreasuryRecovery` function boundary (Refs #2509 S10
// § Observer goal phases (Full AI) "EXPAND regiment-rebuild trap").
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI) — below-quota
//   peace insufficient-regiments trap with treasury recovery:
//     A below-quota GP at peace with 1..(floor-1) regiments and an invadable
//     OW frontier whose **effective** treasury (cash plus same-turn pending
//     riches conversion) is short of the cheapest regiment build cost should
//     trigger overseas cargo preference so auto-transport delivers riches to
//     the stockpile before the next build pass.
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `colonial_pressure_below_quota_peace_insufficient_regiments_test.dart`
//     groups `isBelowQuotaPeaceInsufficientRegiments` /
//     `isBelowQuotaPeaceTreasuryRecovery` — pin the **base predicate** table
//     (at-or-above quota, at-war, no invadable, regiments=0, regiments at
//     floor, valid trap shape) plus a single positive
//     `isBelowQuotaPeaceTreasuryRecovery` case (`treasury=0`, empty
//     stockpile) and a single negative case (`treasury=0`, gold riches
//     exactly cover cheapest). The other false-branch fall-throughs of the
//     `isBelowQuotaPeaceInsufficientRegiments` precondition and the
//     **boundary** between `effectiveTreasury == cheapest` (false) and
//     `effectiveTreasury == cheapest - 1` (true) are not pinned by either
//     file today.
//   - `colonial_pressure_test.dart` — pins peer-gap / quota-threshold helpers
//     consumed by `belowQuotaPeerGpPeaceTargets`, `nearQuotaHoldPeaceTargets`,
//     `defaultStartGpPeaceTargets`, etc. Does not exercise the
//     `isBelowQuotaPeaceTreasuryRecovery` predicate at all.
//
// What's not currently pinned (this file's coverage):
//
//   1. **Predicate fall-through (false-by-precondition):** Each of the five
//      false branches of `isBelowQuotaPeaceInsufficientRegiments`
//      (`oldWorldProvincesOwned >= quota`, `atWarWithAnyGreatPower`,
//      `regimentCount <= 0`, `regimentCount >= floor`,
//      `!hasInvadableProvinces`) must short-circuit
//      `isBelowQuotaPeaceTreasuryRecovery` to `false` **regardless** of the
//      treasury / stockpile inputs. A regression that re-ordered the
//      treasury check before the predicate (or duplicated the predicate with
//      a divergent guard table) could silently treat a GP that no longer
//      qualifies as a recovery candidate.
//   2. **Effective-treasury boundary `==` vs `<` cheapest:** The comparison
//      `effectiveTreasury < cheapestRegimentBuildTreasuryCost()` must hold
//      strictly. Boundary at `effectiveTreasury == cheapest` returns `false`
//      (already covered, exit recovery — afford one build); one-below
//      (`effectiveTreasury == cheapest - 1`) returns `true` (stay in
//      recovery). A regression that swapped `<` for `<=` would silently
//      keep a GP in cargo-preference recovery the same turn it could
//      already afford the build, blocking the EXPAND declare-war pass.
//   3. **Effective-treasury composition (cash vs riches):** The cash
//      contribution and the riches contribution must sum into
//      `effectiveTreasury`. Today only treasury=0 with gold riches (false)
//      and treasury=0 with empty stockpile (true) are pinned. A regression
//      that dropped the cash addend (`effectiveTreasury =
//      pendingRichesTreasuryDelta(stockpile: stockpile)`) or the stockpile
//      addend (`effectiveTreasury = treasury`) would still pass the two
//      existing tests but mishandle mixed cash + riches GP states (most
//      seed-42 turn-100 traps are non-zero cash, low riches).
//
// Coverage layers (function unit, no Game required):
//   - **Predicate fall-through:** five precondition false rows, each with
//     non-trivial treasury / stockpile inputs to guard against treasury
//     check-first regressions.
//   - **Effective-treasury boundary:** `cheapest - 1` (true) vs `cheapest`
//     (false), each via cash-only and via cash + riches composition.
//   - **Composition sanity:** treasury > 0 alone (no riches) under cheapest
//     stays in recovery; treasury = 0 with multi-riches commodities exiting
//     recovery exercises `pendingRichesTreasuryDelta`'s loop across the
//     `richesCommodityIds` order.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/planning/colonial_pressure.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Stockpile holding [qty] gold riches; chosen because gold's base price
/// (`50 * 10 / 3 == 166`) is a non-divisor of typical regiment build costs,
/// so the boundary tests below exercise the integer-truncation path through
/// `pendingRichesTreasuryDelta`.
Stockpile _goldStockpile(int qty) =>
    qty <= 0 ? const Stockpile() : Stockpile().applyDelta(
          CommodityCatalog.gold.id,
          qty,
        );

/// Stockpile holding [qty] **spices**, whose base price is exactly 50 (the
/// spices spawn weight equals the spices base-price denominator in
/// `richesBasePrice`). This makes effective-treasury composition arithmetic
/// straightforward for boundary tests that need to land on
/// `cheapest`/`cheapest - 1` exactly.
Stockpile _spicesStockpile(int qty) =>
    qty <= 0 ? const Stockpile() : Stockpile().applyDelta(
          CommodityCatalog.spices.id,
          qty,
        );

void main() {
  group('isBelowQuotaPeaceTreasuryRecovery — predicate fall-through', () {
    // Each fall-through case supplies a non-trivial treasury/stockpile that
    // *would* place the GP in recovery if the precondition predicate were
    // bypassed; the predicate must short-circuit to false regardless.

    test('false when at or above the observer OW quota', () {
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
          treasury: 0,
          stockpile: const Stockpile(),
        ),
        isFalse,
        reason:
            'GPs at or above the observer OW quota are no longer in EXPAND '
            'and must not be flagged for the treasury-recovery cargo path '
            'even when treasury=0 and the stockpile is empty.',
      );
    });

    test('false when at war with any Great Power (predicate guard wins)', () {
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: 8,
          regimentCount: 3,
          atWarWithAnyGreatPower: true,
          hasInvadableProvinces: true,
          treasury: 0,
          stockpile: const Stockpile(),
        ),
        isFalse,
        reason:
            'The trap targets at-peace GPs only. A GP at war is already in a '
            'conquest-driving path and must not be diverted onto cargo '
            'preference, regardless of how little effective treasury it has.',
      );
    });

    test('false when no invadable provinces remain (predicate guard wins)', () {
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: 8,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: false,
          treasury: 0,
          stockpile: const Stockpile(),
        ),
        isFalse,
        reason:
            'Without an invadable OW frontier there is no upcoming declare-war '
            'pass for the rebuilt regiments to feed; the treasury-recovery '
            'shortcut must short-circuit before the cash/riches sum.',
      );
    });

    test('true when regimentCount is zero and invadable OW remains', () {
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: 8,
          regimentCount: 0,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
          treasury: 0,
          stockpile: const Stockpile(),
        ),
        isTrue,
        reason:
            'Zero-regiment below-quota GPs need cargo preference to fund the '
            'first rebuild before declare-war (seed-42 gp5/gp6; Refs #2509).',
      );
    });

    test('false at the at-peace declare-war regiment floor (upper band exit)',
        () {
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: 8,
          regimentCount: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
          treasury: 0,
          stockpile: const Stockpile(),
        ),
        isFalse,
        reason:
            'At or above the at-peace declare-war regiment floor the GP is no '
            'longer in the "too few to declare war" band; treasury-recovery '
            'must not keep diverting cargo to a GP that should be opening a '
            'minor frontier this turn.',
      );
    });
  });

  group('isBelowQuotaPeaceTreasuryRecovery — effective-treasury boundary', () {
    // The cash-vs-riches composition tests below all hold the predicate
    // shape (8 OW, 3 regiments, peace, invadable) so the boundary check is
    // the single moving part.

    test('false when treasury alone equals cheapest cost (== boundary)', () {
      final cheapest = cheapestRegimentBuildTreasuryCost();
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: 8,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
          treasury: cheapest,
          stockpile: const Stockpile(),
        ),
        isFalse,
        reason:
            'effectiveTreasury == cheapest exits recovery: the GP can afford '
            'the cheapest build immediately and should not block its EXPAND '
            'declare-war pass with cargo preference. Comparison must remain '
            '`<` (strict) — a regression to `<=` would silently re-enable '
            'recovery at the affordability boundary.',
      );
    });

    test('true when treasury alone is one short of cheapest cost', () {
      final cheapest = cheapestRegimentBuildTreasuryCost();
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: 8,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
          treasury: cheapest - 1,
          stockpile: const Stockpile(),
        ),
        isTrue,
        reason:
            'effectiveTreasury == cheapest - 1 must stay in recovery so the '
            'auto-cargo path delivers one more unit of riches before the next '
            'build pass. This is the seed-42 turn-100 shape after partial '
            'cash accumulation.',
      );
    });

    test(
      'false when cash + 1 spice (=50) just clears cheapest cost',
      () {
        final cheapest = cheapestRegimentBuildTreasuryCost();
        // spices basePrice is exactly 50, so one spice contributes 50 to
        // effective treasury (verified at the constant).
        expect(richesBasePrice(CommodityCatalog.spices.id), 50);
        expect(
          isBelowQuotaPeaceTreasuryRecovery(
            oldWorldProvincesOwned: 8,
            regimentCount: 3,
            atWarWithAnyGreatPower: false,
            hasInvadableProvinces: true,
            treasury: cheapest - 50,
            stockpile: _spicesStockpile(1),
          ),
          isFalse,
          reason:
              'Mixed cash + riches must compose into `effectiveTreasury` via '
              '`pendingRichesTreasuryDelta`. (treasury=cheapest-50) + (1 '
              'spice × 50) == cheapest, so recovery exits at the boundary '
              'just like cash-only.',
        );
      },
    );

    test(
      'true when cash + 1 spice is still one short of cheapest cost',
      () {
        final cheapest = cheapestRegimentBuildTreasuryCost();
        expect(richesBasePrice(CommodityCatalog.spices.id), 50);
        expect(
          isBelowQuotaPeaceTreasuryRecovery(
            oldWorldProvincesOwned: 8,
            regimentCount: 3,
            atWarWithAnyGreatPower: false,
            hasInvadableProvinces: true,
            treasury: cheapest - 50 - 1,
            stockpile: _spicesStockpile(1),
          ),
          isTrue,
          reason:
              'Mixed cash + riches composition: (treasury=cheapest-51) + (1 '
              'spice × 50) == cheapest - 1, still strictly below the build '
              'cost so recovery stays active. Guards against a regression '
              'that drops either the cash or the riches addend.',
        );
      },
    );

    test('true when gold-only stockpile is one full gold unit short', () {
      final goldPrice = richesBasePrice(CommodityCatalog.gold.id);
      final cheapest = cheapestRegimentBuildTreasuryCost();
      // (cheapest / goldPrice).ceil() units would just cover; one fewer
      // leaves us strictly short and re-engages recovery.
      final shortQty = (cheapest / goldPrice).ceil() - 1;
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: 8,
          regimentCount: 3,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
          treasury: 0,
          stockpile: _goldStockpile(shortQty),
        ),
        isTrue,
        reason:
            'Stockpile-only path: `pendingRichesTreasuryDelta` must apply '
            'gold base price (truncating integer arithmetic) to compute '
            'effective treasury. One unit short of the ceiling keeps the GP '
            'in recovery.',
      );
    });
  });

  group('isBelowQuotaPeaceTreasuryRecovery — composition sanity', () {
    test('true when treasury and stockpile both contribute zero', () {
      // Anchors the trap-shape positive case at the lower bound of the
      // band (`oldWorldProvincesOwned == kObserverConquestMinOwProvincesPerGp
      // - 1`, regimentCount == 1) for parity with the sibling pin file's
      // 8-OW / 3-regiment shape.
      expect(
        isBelowQuotaPeaceTreasuryRecovery(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
          regimentCount: 1,
          atWarWithAnyGreatPower: false,
          hasInvadableProvinces: true,
          treasury: 0,
          stockpile: const Stockpile(),
        ),
        isTrue,
        reason:
            'Lower-band positive shape (1 regiment, 9 OW): zero cash and an '
            'empty stockpile mean effective treasury 0, strictly below the '
            'cheapest build cost. This is the canonical seed-42 trap.',
      );
    });

    test(
      'false when multi-commodity riches (gold + silver) together clear cost',
      () {
        // Iterating across two riches commodities exercises
        // `pendingRichesTreasuryDelta`'s loop over `richesCommodityIds`
        // beyond the single-commodity gold case in the sibling pin file.
        final cheapest = cheapestRegimentBuildTreasuryCost();
        final goldPrice = richesBasePrice(CommodityCatalog.gold.id);
        final silverPrice = richesBasePrice(CommodityCatalog.silver.id);
        // 1 gold + enough silver to exceed cheapest at treasury=0.
        final silverQty = ((cheapest - goldPrice) / silverPrice).ceil();
        final stockpile = Stockpile()
            .applyDelta(CommodityCatalog.gold.id, 1)
            .applyDelta(CommodityCatalog.silver.id, silverQty);
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
          reason:
              'Effective treasury must sum every riches commodity. Two riches '
              'kinds combining to cover the cheapest build must exit recovery '
              'just like a single commodity covering it alone.',
        );
      },
    );
  });
}
