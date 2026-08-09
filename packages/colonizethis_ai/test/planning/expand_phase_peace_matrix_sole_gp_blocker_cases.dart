// Topic-split case module (Refs #3997 Phase 8).
// Pin/row coverage preserved 1:1 from the former combined cases file.

// ignore_for_file: unused_element, unused_element_parameter

// EXPAND peace matrix case module (Refs #3749 / #3941).
// Registered from `expand_phase_peace_matrix_test.dart` — the single contract
// file for all four former `expand_phase_planner_*_peace_*_matrix_test.dart`
// shards. Row coverage is preserved 1:1.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

typedef _SoleGpPeaceTargetFn = String? Function({
  required Game game,
  required AIWorldSnapshot snapshot,
});

/// Shared snapshot skeleton for the sole-GP peace-target deciders. Only the
/// `playerId`, at-war set, own OW count, and invadable OW frontier matter to
/// these deciders; every other summary stays empty.
AIWorldSnapshot _snapshot({
  required String playerId,
  required List<String> atWarWith,
  int oldWorldProvincesOwned = 0,
  List<String> invadableProvinceIdsSorted = const [],
}) => AIWorldSnapshot(
  playerId: playerId,
  threats: ThreatSummary(atWarWith: atWarWith),
  opportunities: const OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: oldWorldProvincesOwned,
    invadableProvinceIdsSorted: invadableProvinceIdsSorted,
  ),
  colonial: const ColonialSummary(),
  economy: const EconomySummary(),
  relations: const {},
);

/// One byte-equivalent branch row transcribed from a source `*_branches_test`.
/// The `game` + `snapshot` are pre-built per row by the decider-appropriate
/// helper below so the matrix runner stays decider-agnostic.
class _Case {
  _Case({
    required this.name,
    required this.game,
    required this.snapshot,
    this.expected,
    this.reason,
  });

  final String name;
  final Game game;
  final AIWorldSnapshot snapshot;

  /// Expected target id; `null` asserts `isNull` (matches the source suites'
  /// `isNull` matcher exactly).
  final String? expected;
  final String? reason;
}

void _runDecider(String label, _SoleGpPeaceTargetFn fn, List<_Case> cases) {
  group(label, () {
    for (final c in cases) {
      test(c.name, () {
        final result = fn(game: c.game, snapshot: c.snapshot);
        if (c.expected == null) {
          expect(result, isNull, reason: c.reason);
        } else {
          expect(result, c.expected, reason: c.reason);
        }
      });
    }
  });
}

// --- soleAtWarGreatPowerId fixtures (plain roster). ---

// --- consolidateGainsSoleGpPeaceTarget fixtures (two-GP OW counts). ---

/// Builds a minimal `Game` where `gp_own` holds [ownProvinces] OW provinces,
/// the at-war partner `partnerId` holds [partnerProvinces] OW provinces, and
/// the OW map optionally carries a [minorId]-owned province and/or
/// [extraInvadableMinorOwnerId]-owned invadable province.

void registerExpandPeaceSoleGpBlockerCases() {
  _runDecider(
      'unwinnableSoleGpFrontierPeaceTarget (truth table)',
      unwinnableSoleGpFrontierPeaceTarget, <_Case>[
    _Case(
      name: 'null when zero Great Powers are at war (only minor in atWarWith)',
      // `soleAtWarGreatPowerId` returns null when no entry in
      // `threats.atWarWith` matches a Great Power. Built inline (not via
      // `_ownVsPartnerGame`) because this is the only case where the at-war
      // partner is a minor, not a Great Power.
      game: Game(
        id: 'g-unwinnable-only-minor-at-war',
        worldState: WorldState(
          turnState: const TurnState(
            phase: TurnPhase.orders,
            turnNumber: 80,
          ),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 5; i++)
                Province(
                  id: 'oldWorld|gp_own_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp_own',
                ),
              for (var i = 1; i <= 12; i++)
                Province(
                  id: 'oldWorld|minor1_$i',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp_own', displayName: 'GP_OWN', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'M1'),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp_own',
            factionId2: 'minor1',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      ),
      snapshot: _snapshot(
        playerId: 'gp_own',
        oldWorldProvincesOwned: 5,
        atWarWith: const ['minor1'],
      ),
      reason:
          'Only a minor is in threats.atWarWith, so soleAtWarGreatPowerId '
          'returns null and the forced sole-GP-frontier peace path must '
          'short-circuit before any deficit comparison. A regression that '
          'broadened "sole GP at war" to "sole faction at war" would '
          'return "minor1" here.',
    ),
    _Case(
      name: 'null when two Great Powers are at war (multi-front, no single '
          'enemy)',
      game: buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 6,
        partnerProvinces: 12,
        partnerId: 'gp_partner',
        extraGpId: 'gp_third',
        extraGpProvinces: 12,
      ),
      snapshot: _snapshot(
        playerId: 'gp_own',
        oldWorldProvincesOwned: 6,
        atWarWith: const ['gp_partner', 'gp_third'],
      ),
      reason:
          'Two GP wars violate the sole-enemy contract; the forced '
          'sole-GP-frontier peace path must defer to multi-front diplomacy '
          'selection (e.g. nearQuotaHoldPeaceTargets) instead of choosing '
          'one GP unilaterally.',
    ),
    _Case(
      name: 'null at the observer OW quota even with a stronger sole GP enemy',
      game: buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverConquestMinOwProvincesPerGp,
        partnerProvinces: kObserverConquestMinOwProvincesPerGp + 5,
        partnerId: 'gp_partner',
      ),
      snapshot: _snapshot(
        playerId: 'gp_own',
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const ['gp_partner'],
      ),
      reason:
          'At-or-above the observer OW quota exits the unwinnable-sole-GP '
          'shortcut so consolidation diplomacy (`consolidateGainsSoleGp` / '
          '`quotaMetFutileBelowQuotaGp` etc.) decides when to peace.',
    ),
    _Case(
      name: 'null when no minor pivot remains '
          '(canPivotFromSoleGpWarAfterPeace=false)',
      // own < quota, no minors on the OW map, every invadable GP-owned.
      game: buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 6,
        partnerProvinces: 12,
        partnerId: 'gp_partner',
      ),
      snapshot: _snapshot(
        playerId: 'gp_own',
        oldWorldProvincesOwned: 6,
        atWarWith: const ['gp_partner'],
        // Invadable owned by the partner GP (no minor pivot via invadable).
        invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
      ),
      reason:
          'canPivotFromSoleGpWarAfterPeace=false: no OW minors remain and '
          'every invadable belongs to a GP, so peacing the sole GP war '
          'leaves the GP with no minor pivot. The forced peace shortcut '
          'must defer to other survival paths.',
    ),
    _Case(
      name: 'null at default-start when enemy ties OW count (lead 0)',
      // own=kObserverDefaultStartOldWorldProvincesPerGp, minDeficit=1 row.
      // Enemy ties exactly (lead 0). `enemyOw < own + 1` -> null.
      game: buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerId: 'gp_partner',
        minorId: 'minor_pivot',
        minorProvinces: 1,
      ),
      snapshot: _snapshot(
        playerId: 'gp_own',
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const ['gp_partner'],
      ),
      reason:
          'Default-start band requires `enemyOw >= own + 1` (lead >= 1). '
          'A tied enemy at own=7 returns null. Guards against a regression '
          'that swapped `<` for `<=` (would peace at lead 0) or that '
          'inflated the default-start deficit above 1.',
    ),
    _Case(
      name: 'null at 8 OW non-GP-only when enemy ties (lead 0)',
      // own=8 >= kObserverConquestMinOwProvincesPerGp - 2, !GP-only frontier
      // (minor on the invadable), minDeficit=1. Enemy ties -> null.
      game: buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 8,
        partnerProvinces: 8,
        partnerId: 'gp_partner',
        extraInvadableMinorOwnerId: 'minor_frontier',
      ),
      snapshot: _snapshot(
        playerId: 'gp_own',
        oldWorldProvincesOwned: 8,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      ),
      reason:
          '8 OW non-GP-only band still requires lead >= 1. A regression '
          'that promoted ties to peace would peace too eagerly when the '
          'GP is at parity with its enemy.',
    ),
    _Case(
      name: 'null at 9 OW non-GP-only when enemy ties (lead 0)',
      // Re-pin the 8-9 OW non-GP-only minDeficit=1 row at the upper boundary.
      game: buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 9,
        partnerProvinces: 9,
        partnerId: 'gp_partner',
        extraInvadableMinorOwnerId: 'minor_frontier',
      ),
      snapshot: _snapshot(
        playerId: 'gp_own',
        oldWorldProvincesOwned: 9,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      ),
      reason:
          '9 OW non-GP-only also uses minDeficit=1. Tied enemy at own=9 '
          'still returns null. A regression that narrowed the 8-9-OW '
          'non-GP-only branch to own=8 only would silently flip this row.',
    ),
    _Case(
      name: 'returns enemy at 9 OW non-GP-only with one-province lead',
      // Enemy=10 leads by 1; minDeficit=1; satisfies.
      game: buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 9,
        partnerProvinces: 10,
        partnerId: 'gp_partner',
        extraInvadableMinorOwnerId: 'minor_frontier',
      ),
      snapshot: _snapshot(
        playerId: 'gp_own',
        oldWorldProvincesOwned: 9,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      ),
      expected: 'gp_partner',
      reason:
          '9 OW non-GP-only with lead-1 enemy must peace (minDeficit=1). '
          'Mirrors the existing 8-OW pin and locks the upper boundary '
          'of the 8-9 OW non-GP-only row.',
    ),
    _Case(
      name: 'null at 8 OW GP-only frontier when enemy leads by only 1 '
          '(needs 2)',
      // own=8 on a GP-only invadable frontier triggers the
      // kUnwinnableSoleGpMinProvinceDeficit row. Enemy=9 (lead 1) -> null.
      game: buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 8,
        partnerProvinces: 9,
        partnerId: 'gp_partner',
        minorId: 'minor_pivot',
        minorProvinces: 1,
      ),
      snapshot: _snapshot(
        playerId: 'gp_own',
        oldWorldProvincesOwned: 8,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
      ),
      reason:
          '8 OW on a GP-only invadable frontier requires lead >= '
          'kUnwinnableSoleGpMinProvinceDeficit (currently 2). Lead 1 must '
          'not trigger the forced peace shortcut so the GP keeps the war '
          'open against a near-peer GP-only blocker.',
    ),
    _Case(
      name: 'returns enemy at 8 OW GP-only frontier when enemy leads by 2',
      // own=8 GP-only frontier, enemy=10 (lead 2 == minDeficit).
      game: buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 8,
        partnerProvinces: 10,
        partnerId: 'gp_partner',
        minorId: 'minor_pivot',
        minorProvinces: 1,
      ),
      snapshot: _snapshot(
        playerId: 'gp_own',
        oldWorldProvincesOwned: 8,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
      ),
      expected: 'gp_partner',
      reason:
          '8 OW GP-only with lead exactly equal to '
          'kUnwinnableSoleGpMinProvinceDeficit must peace (the inequality '
          'is `enemyOw < own + minDeficit`, so equality satisfies). '
          'Guards against a regression to a strict `>` lead requirement.',
    ),
    _Case(
      name: 'null at 9 OW GP-only frontier when enemy leads by only 1',
      // Upper boundary of the GP-only band (own=9). Lead 1 still fails.
      game: buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 9,
        partnerProvinces: 10,
        partnerId: 'gp_partner',
        minorId: 'minor_pivot',
        minorProvinces: 1,
      ),
      snapshot: _snapshot(
        playerId: 'gp_own',
        oldWorldProvincesOwned: 9,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
      ),
      reason:
          '9 OW on a GP-only invadable frontier still uses '
          'kUnwinnableSoleGpMinProvinceDeficit. Lead 1 returns null. A '
          'regression that exempted own=9 from the GP-only branch would '
          'silently peace at lead 1 and surrender the near-quota war.',
    ),
    _Case(
      name: 'returns enemy at 9 OW GP-only frontier when enemy leads by 2',
      // own=9 GP-only frontier, enemy=11 (lead 2).
      game: buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 9,
        partnerProvinces: 11,
        partnerId: 'gp_partner',
        minorId: 'minor_pivot',
        minorProvinces: 1,
      ),
      snapshot: _snapshot(
        playerId: 'gp_own',
        oldWorldProvincesOwned: 9,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
      ),
      expected: 'gp_partner',
      reason:
          '9 OW GP-only with lead exactly equal to '
          'kUnwinnableSoleGpMinProvinceDeficit must peace. Locks the '
          'upper boundary of the GP-only row.',
    ),
  ]);
}
