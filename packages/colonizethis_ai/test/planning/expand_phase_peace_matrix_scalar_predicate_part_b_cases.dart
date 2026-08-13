// EXPAND peace matrix case module (Refs #3749 / #3941).
// Registered from `expand_phase_peace_matrix_test.dart` — the single contract
// file for all four former `expand_phase_planner_*_peace_*_matrix_test.dart`
// shards. Row coverage is preserved 1:1.

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

void registerExpandPeaceScalarPredicateCasesPartB() {
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
