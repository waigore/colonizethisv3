// Table-driven matrix consolidation of the EXPAND below-quota peace
// function-unit predicate pins (Refs #3749 branch-pin consolidation).
//
// This single file replaces three former per-predicate `*_branches_test.dart`
// suites that each pinned a pure predicate from `expand_phase_planner.dart`
// with one `test(...)` per row:
//
//   - `expand_phase_planner_below_quota_peace_insufficient_regiments_branches_test.dart`
//   - `expand_phase_planner_below_quota_peace_treasury_recovery_branches_test.dart`
//   - `expand_phase_planner_mutual_below_quota_plateau_peer_branches_test.dart`
//
// All three pinned **pure** predicates (scalar inputs, no `Game` fixture), so
// each former branch case becomes one matrix row here with byte-equivalent
// inputs and expectations. Coverage is preserved 1:1 — every former assertion
// has a corresponding row — while the per-file boilerplate collapses into three
// table-driven loops. See the original suites' history for the full per-branch
// rationale; the `reason` text on each row carries the regression it guards.
//
// SPEC/ai/ai-architecture.md § Observer goal phases (Full AI) — EXPAND
// below-quota peace insufficient-regiments / treasury-recovery trap and the
// mutual below-quota plateau-peer pivot (Refs #2509).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Stockpile holding [qty] units of riches commodity [commodityId]; empty when
/// [qty] is non-positive. Replaces the per-file `_goldStockpile` /
/// `_spicesStockpile` builders with one helper.
Stockpile _riches(String commodityId, int qty) => qty <= 0
    ? const Stockpile()
    : Stockpile().applyDelta(commodityId, qty);

void main() {
  // Quota / band constants the truth tables are built on. `cheapest` and the
  // riches base prices come from the production helpers so the boundary rows
  // track any constant tuning automatically.
  const quota = kObserverConquestMinOwProvincesPerGp; // 10
  const floor = kBelowQuotaPeaceMinRegimentsBeforeDeclareWar;
  final cheapest = cheapestRegimentBuildTreasuryCost();
  final goldPrice = richesBasePrice(CommodityCatalog.gold.id);
  final silverPrice = richesBasePrice(CommodityCatalog.silver.id);
  final spicesPrice = richesBasePrice(CommodityCatalog.spices.id);

  group('isBelowQuotaPeaceInsufficientRegiments (truth table)', () {
    final cases = <({
      String name,
      int ow,
      int regiments,
      bool atWar,
      bool hasInvadable,
      bool expected,
      String reason,
    })>[
      (
        name: 'false at or above the observer OW quota',
        ow: quota,
        regiments: 3,
        atWar: false,
        hasInvadable: true,
        expected: false,
        reason: 'GPs at or above the observer OW quota have left EXPAND.',
      ),
      (
        name: 'false when at war with any Great Power',
        ow: 8,
        regiments: 3,
        atWar: true,
        hasInvadable: true,
        expected: false,
        reason: 'The trap targets at-peace GPs only.',
      ),
      (
        name: 'false when no invadable provinces remain',
        ow: 8,
        regiments: 3,
        atWar: false,
        hasInvadable: false,
        expected: false,
        reason: 'No invadable frontier means no upcoming declare-war pass.',
      ),
      (
        name: 'false when regimentCount is zero (broke-at-peace trigger owns it)',
        ow: 8,
        regiments: 0,
        atWar: false,
        hasInvadable: true,
        expected: false,
        reason: 'Zero regiments is handled by the broke-at-peace trigger.',
      ),
      (
        name: 'false when regimentCount meets the at-peace declare-war floor',
        ow: 8,
        regiments: floor,
        atWar: false,
        hasInvadable: true,
        expected: false,
        reason: 'At the floor the GP can already open a frontier this turn.',
      ),
      (
        name: 'true seed-42 gp3 trap: 8 OW, 3 regiments, peace, invadable',
        ow: 8,
        regiments: 3,
        atWar: false,
        hasInvadable: true,
        expected: true,
        reason: 'The canonical EXPAND regiment-rebuild trap shape.',
      ),
      (
        name: 'true lower band (1 regiment) while below quota and at peace',
        ow: quota - 1,
        regiments: 1,
        atWar: false,
        hasInvadable: true,
        expected: true,
        reason: '1 regiment, 9 OW, peace, invadable stays in the trap band.',
      ),
      (
        name: 'true just below the at-peace declare-war floor',
        ow: 9,
        regiments: floor - 1,
        atWar: false,
        hasInvadable: true,
        expected: true,
        reason: 'One below the floor keeps the GP in the trap band.',
      ),
    ];

    for (final c in cases) {
      test(c.name, () {
        expect(
          isBelowQuotaPeaceInsufficientRegiments(
            oldWorldProvincesOwned: c.ow,
            regimentCount: c.regiments,
            atWarWithAnyGreatPower: c.atWar,
            hasInvadableProvinces: c.hasInvadable,
          ),
          c.expected ? isTrue : isFalse,
          reason: c.reason,
        );
      });
    }
  });

  group('isBelowQuotaPeaceTreasuryRecovery (truth table)', () {
    test('spices base price is exactly 50 (boundary-row anchor)', () {
      // Boundary rows below depend on one spice contributing exactly 50 to the
      // effective treasury; lock the constant so a base-price change surfaces.
      expect(spicesPrice, 50);
    });

    final cases = <({
      String name,
      int ow,
      int regiments,
      bool atWar,
      bool hasInvadable,
      int treasury,
      Stockpile stockpile,
      bool expected,
      String reason,
    })>[
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
        reason: 'Above-quota GPs are out of EXPAND, no cargo-recovery path.',
      ),
      (
        name: 'false when at war with any Great Power (predicate guard wins)',
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
        name: 'false when no invadable provinces remain (predicate guard wins)',
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
        reason: 'Zero-regiment below-quota GPs need cargo to fund a rebuild.',
      ),
      (
        name: 'false at the at-peace declare-war regiment floor (upper exit)',
        ow: 8,
        regiments: floor,
        atWar: false,
        hasInvadable: true,
        treasury: 0,
        stockpile: const Stockpile(),
        expected: false,
        reason: 'At the floor the GP should open a minor frontier, not recover.',
      ),
      // Effective-treasury boundary: `< cheapest` (strict) stays in recovery.
      (
        name: 'false when treasury alone equals cheapest cost (== boundary)',
        ow: 8,
        regiments: 3,
        atWar: false,
        hasInvadable: true,
        treasury: cheapest,
        stockpile: const Stockpile(),
        expected: false,
        reason: 'effectiveTreasury == cheapest can afford the build (strict <).',
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
        stockpile: _riches(CommodityCatalog.spices.id, 1),
        expected: false,
        reason: 'Mixed cash + riches compose to exactly cheapest -> exit.',
      ),
      (
        name: 'true when cash + 1 spice is still one short of cheapest cost',
        ow: 8,
        regiments: 3,
        atWar: false,
        hasInvadable: true,
        treasury: cheapest - 50 - 1,
        stockpile: _riches(CommodityCatalog.spices.id, 1),
        expected: true,
        reason: 'cash + riches == cheapest - 1 stays strictly below the cost.',
      ),
      (
        name: 'true when gold-only stockpile is one full gold unit short',
        ow: 8,
        regiments: 3,
        atWar: false,
        hasInvadable: true,
        treasury: 0,
        stockpile: _riches(
          CommodityCatalog.gold.id,
          (cheapest / goldPrice).ceil() - 1,
        ),
        expected: true,
        reason: 'Stockpile-only riches truncation leaves the GP strictly short.',
      ),
      (
        name: 'false when pending gold riches exactly cover cheapest build',
        ow: 8,
        regiments: 3,
        atWar: false,
        hasInvadable: true,
        treasury: 0,
        stockpile: _riches(
          CommodityCatalog.gold.id,
          (cheapest / goldPrice).ceil(),
        ),
        expected: false,
        reason: 'Pending riches that cover the cheapest build exit recovery.',
      ),
      // Composition sanity.
      (
        name: 'true when treasury and stockpile both contribute zero (low band)',
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
        name: 'false when multi-commodity riches (gold + silver) clear cost',
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
        reason: 'Effective treasury sums every riches commodity in the loop.',
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

  group('isMutualBelowQuotaPlateauPeer (truth table)', () {
    // True iff both ownOw and partnerOw are in [1, 9] and |gap| <= 1.
    final cases = <({String name, int ownOw, int partnerOw, bool expected})>[
      // Canonical mutual plateau.
      (name: 'both at quota minus 2 (8/8)', ownOw: 8, partnerOw: 8, expected: true),
      (name: 'quota minus 2 vs minus 1 (8/9)', ownOw: 8, partnerOw: 9, expected: true),
      (name: 'symmetry 9/8 mirrors 8/9', ownOw: 9, partnerOw: 8, expected: true),
      (name: 'both at upper stall edge (9/9)', ownOw: 9, partnerOw: 9, expected: true),
      // Stalled-band lower boundary.
      (name: 'ownOw 0 below band (0/8)', ownOw: 0, partnerOw: 8, expected: false),
      (name: 'partnerOw 0 below band (8/0)', ownOw: 8, partnerOw: 0, expected: false),
      (name: 'lowest in-band (1/1)', ownOw: 1, partnerOw: 1, expected: true),
      (name: 'lowest in-band edge (1/2)', ownOw: 1, partnerOw: 2, expected: true),
      // Stalled-band upper boundary / quota guard.
      (name: 'ownOw at quota (10/9)', ownOw: 10, partnerOw: 9, expected: false),
      (name: 'partnerOw at quota (9/10)', ownOw: 9, partnerOw: 10, expected: false),
      (name: 'both above quota (12/12)', ownOw: 12, partnerOw: 12, expected: false),
      (name: 'ownOw quota+1 vs quota (11/10)', ownOw: 11, partnerOw: 10, expected: false),
      // Peer-gap window.
      (name: 'gap 0 mid-band (5/5)', ownOw: 5, partnerOw: 5, expected: true),
      (name: 'gap 1 ascending (5/6)', ownOw: 5, partnerOw: 6, expected: true),
      (name: 'gap 1 descending (6/5)', ownOw: 6, partnerOw: 5, expected: true),
      (name: 'gap 2 ascending (5/7)', ownOw: 5, partnerOw: 7, expected: false),
      (name: 'gap 2 descending (7/5)', ownOw: 7, partnerOw: 5, expected: false),
      (name: 'gap 8 across full band (1/9)', ownOw: 1, partnerOw: 9, expected: false),
    ];

    for (final c in cases) {
      test('${c.name} -> ${c.expected}', () {
        expect(
          isMutualBelowQuotaPlateauPeer(ownOw: c.ownOw, partnerOw: c.partnerOw),
          c.expected ? isTrue : isFalse,
        );
      });
    }

    test('repeated invocation on same inputs is bit-identical', () {
      const samples = <List<int>>[
        [8, 9],
        [9, 8],
        [10, 9],
        [0, 8],
        [5, 5],
        [5, 7],
      ];
      for (final pair in samples) {
        final first =
            isMutualBelowQuotaPlateauPeer(ownOw: pair[0], partnerOw: pair[1]);
        final second =
            isMutualBelowQuotaPlateauPeer(ownOw: pair[0], partnerOw: pair[1]);
        expect(
          first,
          second,
          reason: 'pure-int predicate must be stable for ${pair[0]}/${pair[1]}.',
        );
      }
    });

    test('pairwise symmetry holds across the full pin set', () {
      for (final c in cases) {
        final forward = isMutualBelowQuotaPlateauPeer(
          ownOw: c.ownOw,
          partnerOw: c.partnerOw,
        );
        final reverse = isMutualBelowQuotaPlateauPeer(
          ownOw: c.partnerOw,
          partnerOw: c.ownOw,
        );
        expect(
          forward,
          reverse,
          reason:
              'predicate must be invariant under (ownOw, partnerOw) swap for '
              '${c.ownOw}/${c.partnerOw}; |a - b| and both band guards are '
              'symmetric.',
        );
      }
    });

    test('constants ground the upper boundary (defensive sanity)', () {
      expect(
        kStalledOldWorldProvinceThreshold,
        9,
        reason: 'the inclusive upper stall boundary the truth table relies on.',
      );
      expect(
        kObserverConquestMinOwProvincesPerGp,
        10,
        reason: 'the per-GP quota bound gating the below-quota guard.',
      );
    });
  });
}
