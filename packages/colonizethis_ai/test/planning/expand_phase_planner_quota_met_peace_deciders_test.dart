// Pins the canonical `quotaMetBelowQuotaAtWarPeaceTargets` and
// `quotaMetFutileBelowQuotaGpPeaceTargets` peace deciders in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both deciders were relocated from `colonial_pressure.dart` so they
// survive the now-completed S1 deletion of that file. The canonical
// implementations live in `expand_phase_planner.dart`.
//
// Live consumers (post-relocation):
//   * `quotaMetBelowQuotaAtWarPeaceTargets` is the broad quota-met
//     futile-war exit. Once the active player has crossed the
//     observer OW quota, every below-quota Great Power still at war
//     surfaces in the result so the planner stops dragging on mop-up
//     wars after the OW frontier is cleared. The decider is composed
//     directly via `diplomacy_planner_peace_targets.dart` and the
//     offer-peace scoring layer
//     `diplomatic_candidate_scoring_offer_peace.dart` for the
//     futile-bullying signal.
//   * `quotaMetFutileBelowQuotaGpPeaceTargets` is the narrower
//     quota-met companion. It additionally requires the active
//     player to still hold an invadable OW frontier and excludes any
//     below-quota enemy GP that owns one of those invadable OW
//     provinces (peace there would forfeit the residual OW
//     acquisition path) plus the primary invadable OW blocker
//     (`primaryInvadableOldWorldGpBlocker`; defensive backstop).
//     `diplomatic_candidate_scoring_offer_peace.dart` applies a
//     stronger offer-peace score bonus to this narrower set.
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
//   1. `quotaMetBelowQuotaAtWarPeaceTargets` short-circuits to
//      `const []` when `isBelowObserverConquestQuota` is `true` for the
//      active player. Both boundaries are pinned at the
//      `kObserverConquestMinOwProvincesPerGp` seam (own == quota - 1
//      empty; own == quota fires).
//   2. `quotaMetBelowQuotaAtWarPeaceTargets` filters non-Great-Power
//      factions (minors / tribes) and Great Power enemies at or above
//      the observer quota. The remaining below-quota Great Powers
//      are returned sorted ascending so the offer-peace consumer sees
//      a stable order.
//   3. `quotaMetFutileBelowQuotaGpPeaceTargets` short-circuits to
//      `const []` for two outer guards: (a) `isBelowObserverConquestQuota`
//      is `true` for the active player; (b)
//      `invadableProvinceIdsSorted` is empty.
//   4. `quotaMetFutileBelowQuotaGpPeaceTargets` filters non-Great-Power
//      factions (minors / tribes), Great Power enemies at or above the
//      observer quota, Great Power enemies that own one of the active
//      player's invadable OW provinces, and the primary invadable OW
//      blocker (defensive backstop). The remaining below-quota
//      non-blocker non-invadable-owner Great Powers are returned
//      sorted ascending.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gpOwn = 'gp_own';
const String _gpPartner = 'gp_partner';
const String _gpThird = 'gp_third';
const String _gpFourth = 'gp_fourth';
const String _minor1 = 'minor1';

/// Builds a minimal `Game` whose OW region contains per-faction province
/// rows matching [provincesByOwner]. Each entry becomes that many
/// `oldWorld|<owner>_<i>` provinces; ownership is the only signal the
/// helpers read via `provinceCountOwnedBy`.
///
/// The optional [extraInvadableMinorOwnerId] adds a single
/// `oldWorld|invadable_minor` row owned by that minor so the
/// `quotaMetFutileBelowQuotaGpPeaceTargets` blocker check can resolve to a
/// non-GP owner if needed.
Game _buildGame({
  required Map<String, int> provincesByOwner,
  required List<Player> players,
  List<MinorNation> minorNations = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  String? extraInvadableMinorOwnerId,
}) {
  final provinces = <Province>[];
  provincesByOwner.forEach((owner, count) {
    for (var i = 0; i < count; i++) {
      provinces.add(
        Province(
          id: 'oldWorld|${owner}_$i',
          regionId: 'oldWorld',
          ownerId: owner,
        ),
      );
    }
  });
  if (extraInvadableMinorOwnerId != null) {
    provinces.add(
      Province(
        id: 'oldWorld|invadable_minor',
        regionId: 'oldWorld',
        ownerId: extraInvadableMinorOwnerId,
      ),
    );
  }
  return Game(
    id: 'g-2509-quota-met-peace-deciders-canonical',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
      oldWorld: RegionData(provinces: provinces, units: const []),
      newWorld: const RegionData(provinces: [], units: []),
    ),
    players: players,
    minorNations: minorNations,
    diplomacyRelations: diplomacyRelations,
  );
}

AIWorldSnapshot _focusSnapshot({
  required int focusOw,
  required List<String> atWarWith,
  List<String> invadableProvinceIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: _gpOwn,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: focusOw,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('quotaMetBelowQuotaAtWarPeaceTargets — own-OW below-quota guard', () {
    test('returns const [] at own == quota - 1 even with two below-quota '
        'GP enemies at war', () {
      // `isBelowObserverConquestQuota` is true at own == quota - 1 so the
      // outer guard must short-circuit before the at-war filter runs.
      final game = _buildGame(
        provincesByOwner: {
          _gpOwn: kObserverConquestMinOwProvincesPerGp - 1,
          _gpPartner: 5,
          _gpThird: 6,
        },
        players: const [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: _gpPartner, displayName: 'P', isHuman: false),
          Player(id: _gpThird, displayName: 'T', isHuman: false),
        ],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp - 1,
        atWarWith: const [_gpPartner, _gpThird],
      );
      expect(
        quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Below the observer quota the canonical helper must short-'
            'circuit before evaluating targets. A regression that '
            'flipped `<` to `<=` would silently re-engage quota-met '
            'peace one province early and weaken the observer-gate '
            'sequencing the SPEC requires.',
      );
    });
  });

  group('quotaMetBelowQuotaAtWarPeaceTargets — at-quota fire path', () {
    test('returns the sole below-quota GP enemy at own == quota boundary', () {
      // own = quota → `isBelowObserverConquestQuota` is false; the lone
      // below-quota GP enemy surfaces.
      final game = _buildGame(
        provincesByOwner: {
          _gpOwn: kObserverConquestMinOwProvincesPerGp,
          _gpPartner: 5,
        },
        players: const [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: _gpPartner, displayName: 'P', isHuman: false),
        ],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [_gpPartner],
      );
      expect(
        quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
        [_gpPartner],
        reason:
            'Exactly at kObserverConquestMinOwProvincesPerGp (10 OW today) '
            'the canonical helper must fire toward a below-quota GP enemy. '
            'A regression that pushed the threshold to `> quota` would '
            'silently delay the futile-bullying-war exit by one province.',
      );
    });
  });

  group('quotaMetBelowQuotaAtWarPeaceTargets — at-war faction filters', () {
    test(
      'filters out at-war minors (only Great Power targets are returned)',
      () {
        // A minor in `atWarWith` must not surface; the helper is GP-vs-GP
        // peace only. A regression that dropped the
        // `game.playerById(...) != null` guard would surface "minor1".
        final game = _buildGame(
          provincesByOwner: {
            _gpOwn: kObserverConquestMinOwProvincesPerGp + 2,
            _minor1: 3,
          },
          players: const [
            Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
          ],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M')],
        );
        final snapshot = _focusSnapshot(
          focusOw: kObserverConquestMinOwProvincesPerGp + 2,
          atWarWith: const [_minor1],
        );
        expect(
          quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Minors and tribes are not in the GP-vs-GP futile-bullying war '
              'family this canonical helper exits. A regression that '
              'dropped the playerById guard would silently sweep a minor '
              'war into the GP peace list.',
        );
      },
    );

    test(
      'filters out a GP target whose own holdings are at observer quota',
      () {
        // Two enemies: one at quota (filtered) and one below quota (kept).
        final game = _buildGame(
          provincesByOwner: {
            _gpOwn: kObserverConquestMinOwProvincesPerGp + 2,
            _gpPartner: kObserverConquestMinOwProvincesPerGp,
            _gpThird: kObserverConquestMinOwProvincesPerGp - 1,
          },
          players: const [
            Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
            Player(id: _gpPartner, displayName: 'Q', isHuman: false),
            Player(id: _gpThird, displayName: 'L', isHuman: false),
          ],
        );
        final snapshot = _focusSnapshot(
          focusOw: kObserverConquestMinOwProvincesPerGp + 2,
          atWarWith: const [_gpPartner, _gpThird],
        );
        expect(
          quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
          [_gpThird],
          reason:
              'A GP exactly at kObserverConquestMinOwProvincesPerGp is no '
              'longer below the quota and must not appear in the futile-'
              'bullying peace list. A regression that flipped `<` to `<=` '
              'on the per-target check would silently sweep in peers who '
              'already completed their own observer quota.',
        );
      },
    );
  });

  group('quotaMetBelowQuotaAtWarPeaceTargets — sort determinism', () {
    test(
      'returns ascending factionId order regardless of at-war list order',
      () {
        // Intentionally pass the at-war list in reverse sort order so a
        // regression that dropped `..sort()` would surface as a flipped
        // result.
        final game = _buildGame(
          provincesByOwner: {
            _gpOwn: kObserverConquestMinOwProvincesPerGp + 1,
            _gpPartner: 4,
            _gpThird: 5,
          },
          players: const [
            Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
            Player(id: _gpPartner, displayName: 'A', isHuman: false),
            Player(id: _gpThird, displayName: 'B', isHuman: false),
          ],
        );
        final snapshot = _focusSnapshot(
          focusOw: kObserverConquestMinOwProvincesPerGp + 1,
          atWarWith: const [_gpThird, _gpPartner],
        );
        expect(
          quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
          [_gpPartner, _gpThird],
          reason:
              'Multi-target results must be sorted ascending so '
              'downstream offer-peace scoring and trace logs are '
              'independent of the iteration order of '
              'snapshot.threats.atWarWith. Dropping the sort would '
              'surface as the reverse order.',
        );
      },
    );

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = _buildGame(
        provincesByOwner: {
          _gpOwn: kObserverConquestMinOwProvincesPerGp + 1,
          _gpPartner: 4,
          _gpThird: 5,
        },
        players: const [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: _gpPartner, displayName: 'A', isHuman: false),
          Player(id: _gpThird, displayName: 'B', isHuman: false),
        ],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 1,
        atWarWith: const [_gpThird, _gpPartner],
      );
      final first = quotaMetBelowQuotaAtWarPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = quotaMetBelowQuotaAtWarPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final third = quotaMetBelowQuotaAtWarPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(first, [_gpPartner, _gpThird]);
      expect(second, first);
      expect(third, first);
    });
  });

  group('quotaMetFutileBelowQuotaGpPeaceTargets — outer guards', () {
    test('returns const [] when own OW is one below the observer quota '
        '(below-quota outer guard)', () {
      // Even with a fully eligible below-quota enemy on the invadable
      // frontier, the below-quota outer guard must short-circuit before
      // the per-enemy filter loop runs.
      final game = _buildGame(
        provincesByOwner: {
          _gpOwn: kObserverConquestMinOwProvincesPerGp - 1,
          _gpPartner: 5,
        },
        players: const [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: _gpPartner, displayName: 'P', isHuman: false),
        ],
        extraInvadableMinorOwnerId: _minor1,
        minorNations: const [MinorNation(id: _minor1, displayName: 'M')],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp - 1,
        atWarWith: const [_gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Below the observer quota the canonical helper must '
            'short-circuit before evaluating the invadable frontier. '
            'A regression that flipped `<` to `<=` would silently '
            'peace allies the same turn the GP crossed the quota '
            'boundary.',
      );
    });

    test('returns const [] when no invadable OW provinces remain '
        '(invadable-empty outer guard)', () {
      // With no invadable OW the frontier-ownership filter is
      // meaningless; the canonical helper defers to the broader
      // `quotaMetBelowQuotaAtWarPeaceTargets` / consolidate deciders.
      final game = _buildGame(
        provincesByOwner: {
          _gpOwn: kObserverConquestMinOwProvincesPerGp + 2,
          _gpPartner: 5,
        },
        players: const [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: _gpPartner, displayName: 'P', isHuman: false),
        ],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_gpPartner],
        invadableProvinceIdsSorted: const [],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'With no remaining invadable OW provinces the canonical '
            'narrower decider must defer to the broader quota-met '
            'family rather than emit peace toward every below-quota '
            'GP. A regression that dropped the invadable-empty guard '
            'would collapse the narrower decider onto the broader one.',
      );
    });

    test(
      'enters the main pass at own OW == observer quota (strict `<` boundary)',
      () {
        // own == quota → `isBelowObserverConquestQuota` is false; a
        // below-quota non-blocker non-invadable-owner enemy surfaces.
        final game = _buildGame(
          provincesByOwner: {
            _gpOwn: kObserverConquestMinOwProvincesPerGp,
            _gpPartner: 5,
          },
          players: const [
            Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
            Player(id: _gpPartner, displayName: 'P', isHuman: false),
          ],
          extraInvadableMinorOwnerId: _minor1,
          minorNations: const [MinorNation(id: _minor1, displayName: 'M')],
        );
        final snapshot = _focusSnapshot(
          focusOw: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const [_gpPartner],
          invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
        );
        expect(
          quotaMetFutileBelowQuotaGpPeaceTargets(
            game: game,
            snapshot: snapshot,
          ),
          [_gpPartner],
          reason:
              'Exactly at kObserverConquestMinOwProvincesPerGp the canonical '
              'helper must enter the main pass. A below-quota non-blocker '
              'non-invadable-owner GP must surface so the futile-bullying '
              'exit fires at the SPEC-authorized quota boundary.',
        );
      },
    );
  });

  group('quotaMetFutileBelowQuotaGpPeaceTargets — per-enemy filters', () {
    test('filters out non-GP factions in atWarWith (minors / tribes)', () {
      // A minor in `atWarWith` (here `minor1` owning the invadable
      // frontier itself) must not surface; the helper is GP-vs-GP only.
      final game = _buildGame(
        provincesByOwner: {_gpOwn: kObserverConquestMinOwProvincesPerGp + 2},
        players: const [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
        ],
        extraInvadableMinorOwnerId: _minor1,
        minorNations: const [MinorNation(id: _minor1, displayName: 'M')],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_minor1],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Minors and tribes belong to the defaultStartFutileMinorPeaceTargets '
            'family. A regression that dropped the playerById guard '
            'would surface "minor1" as a futile-bullying GP target.',
      );
    });

    test('skips at-war Great Powers at or above the observer quota', () {
      // Two GP enemies: one at-quota (filtered), one below-quota (kept).
      final game = _buildGame(
        provincesByOwner: {
          _gpOwn: kObserverConquestMinOwProvincesPerGp + 2,
          _gpPartner: kObserverConquestMinOwProvincesPerGp,
          _gpThird: kObserverConquestMinOwProvincesPerGp - 1,
        },
        players: const [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: _gpPartner, displayName: 'Q', isHuman: false),
          Player(id: _gpThird, displayName: 'L', isHuman: false),
        ],
        extraInvadableMinorOwnerId: _minor1,
        minorNations: const [MinorNation(id: _minor1, displayName: 'M')],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_gpPartner, _gpThird],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpThird],
        reason:
            'Quota-met enemies belong to consolidateGainsSoleGpPeaceTarget '
            'and the broader quota-met family, not this narrower '
            'futile-bullying decider. A regression that dropped the '
            'per-enemy quota check would silently leak quota-met '
            'enemies into the futile result set.',
      );
    });

    test('skips at-war Great Powers that own one of the invadable OW '
        'provinces (frontier-owner skip)', () {
      // gp_partner owns the sole invadable OW province → frontier-
      // owner skip fires; gp_third (off-frontier below-quota enemy)
      // is the only survivor.
      final game = _buildGame(
        provincesByOwner: {
          _gpOwn: kObserverConquestMinOwProvincesPerGp + 2,
          _gpPartner: 4,
          _gpThird: 5,
        },
        players: const [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: _gpPartner, displayName: 'F', isHuman: false),
          Player(id: _gpThird, displayName: 'O', isHuman: false),
        ],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_gpPartner, _gpThird],
        invadableProvinceIdsSorted: const ['oldWorld|${_gpPartner}_0'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpThird],
        reason:
            'Peace toward a GP that still owns one of the active '
            'player\'s invadable OW provinces would forfeit the '
            'remaining OW acquisition path. The frontier-owner skip '
            'must keep that war open while the off-frontier '
            'below-quota enemy surfaces for peace.',
      );
    });

    test('skips the primary invadable OW blocker even when it owns no '
        'invadable here (defensive backstop)', () {
      // gp_partner is the sole invadable-OW owner → also the blocker
      // by construction; gp_third is the off-frontier below-quota
      // survivor. The blocker-equality skip backstops the
      // frontier-owner skip; pinning a fixture where the blocker
      // also owns the invadable keeps the result identical with or
      // without the defensive backstop, documenting the contract.
      final game = _buildGame(
        provincesByOwner: {
          _gpOwn: kObserverConquestMinOwProvincesPerGp + 2,
          _gpPartner: 4,
          _gpThird: 5,
        },
        players: const [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: _gpPartner, displayName: 'B', isHuman: false),
          Player(id: _gpThird, displayName: 'O', isHuman: false),
        ],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_gpPartner, _gpThird],
        invadableProvinceIdsSorted: const ['oldWorld|${_gpPartner}_0'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpThird],
        reason:
            'The primary invadable OW blocker must never appear in '
            'the futile-bullying peace list. A future refactor that '
            'decoupled the blocker identity from per-province '
            'invadable ownership must still respect the equality '
            'skip pinned here.',
      );
    });
  });

  group('quotaMetFutileBelowQuotaGpPeaceTargets — multi-target ordering', () {
    test('returns multiple below-quota non-blocker off-frontier enemies '
        'sorted by factionId', () {
      // Two below-quota off-frontier enemies (gp_third, gp_fourth) +
      // one frontier owner (gp_partner) intentionally passed in
      // reverse-sort order. A regression that dropped `..sort()` on
      // the local list would surface as the reverse order.
      final game = _buildGame(
        provincesByOwner: {
          _gpOwn: kObserverConquestMinOwProvincesPerGp + 2,
          _gpPartner: 4,
          _gpThird: 5,
          _gpFourth: 5,
        },
        players: const [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: _gpPartner, displayName: 'F', isHuman: false),
          Player(id: _gpThird, displayName: 'T', isHuman: false),
          Player(id: _gpFourth, displayName: 'U', isHuman: false),
        ],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_gpFourth, _gpThird, _gpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${_gpPartner}_0'],
      );
      expect(
        quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot),
        [_gpFourth, _gpThird],
        reason:
            'Multi-target results must be sorted ascending so '
            'downstream offer-peace scoring sees a stable order. The '
            'frontier-owning gp_partner is filtered; the two '
            'off-frontier below-quota enemies surface in ascending '
            'factionId order regardless of input order.',
      );
    });

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = _buildGame(
        provincesByOwner: {
          _gpOwn: kObserverConquestMinOwProvincesPerGp + 2,
          _gpThird: 5,
          _gpFourth: 5,
        },
        players: const [
          Player(id: _gpOwn, displayName: 'GP_OWN', isHuman: false),
          Player(id: _gpThird, displayName: 'T', isHuman: false),
          Player(id: _gpFourth, displayName: 'U', isHuman: false),
        ],
        extraInvadableMinorOwnerId: _minor1,
        minorNations: const [MinorNation(id: _minor1, displayName: 'M')],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_gpFourth, _gpThird],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      final first = quotaMetFutileBelowQuotaGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = quotaMetFutileBelowQuotaGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final third = quotaMetFutileBelowQuotaGpPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(first, [_gpFourth, _gpThird]);
      expect(second, first);
      expect(third, first);
    });
  });
}
