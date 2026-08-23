// Scalar predicate matrix pins (Refs #4602 Slice B).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'expand_phase_peace_matrix_scalar_predicate_support.dart';

void registerExpandPeaceScalarPredicateInsufficientRegimentsCases() {
  final c = expandPeaceScalarPredicateConstants();
  final quota = c.quota;
  final floor = c.floor;
  final cheapest = c.cheapest;
  final goldPrice = c.goldPrice;
  final silverPrice = c.silverPrice;
  final spicesPrice = c.spicesPrice;

  group('isBelowQuotaPeaceInsufficientRegiments (truth table)', () {
    final cases =
        <
          ({
            String name,
            int ow,
            int regiments,
            bool atWar,
            bool hasInvadable,
            bool expected,
            String reason,
          })
        >[
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
            name:
                'false when regimentCount is zero (broke-at-peace trigger owns it)',
            ow: 8,
            regiments: 0,
            atWar: false,
            hasInvadable: true,
            expected: false,
            reason: 'Zero regiments is handled by the broke-at-peace trigger.',
          ),
          (
            name:
                'false when regimentCount meets the at-peace declare-war floor',
            ow: 8,
            regiments: floor,
            atWar: false,
            hasInvadable: true,
            expected: false,
            reason:
                'At the floor the GP can already open a frontier this turn.',
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
            reason:
                '1 regiment, 9 OW, peace, invadable stays in the trap band.',
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
}
