// Pins the **quota-met peace below-quota Great Power** branch table at the
// `quotaMetBelowQuotaAtWarPeaceTargets` function boundary (Refs #2509 §
// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when this GP
// already meets the observer quota and a below-quota Great Power at war
// ... exit futile bullying wars; observer seed-42 gp4/gp3").
//
// The function has the following decision points:
//
//   1. **Own-OW below-quota guard.** When `oldWorldProvincesOwned <
//      kObserverConquestMinOwProvincesPerGp` (10) the helper returns
//      `const []`. Quota-met peace targets only fire after this GP
//      already crossed the observer quota; below-quota GPs are still
//      pressing war and must not appear in this family.
//   2. **At-war filter — non-Great-Power factions.** Targets that are not
//      Great Powers (`game.playerById(factionId) == null`, i.e. minors /
//      tribes) are skipped. The helper is GP-vs-GP peace only.
//   3. **At-war filter — Great Powers at or above the observer quota.**
//      GPs whose own holdings are at or above the observer quota are
//      skipped: peacing a peer GP that already met its quota is not the
//      "futile bullying" shape this helper targets.
//   4. **Sort determinism.** The returned list is sorted in ascending
//      `factionId` order so downstream offer-peace scoring (Refs
//      `SPEC/program/diplomacy-resolution.md`) is independent of the
//      iteration order of `snapshot.threats.atWarWith`.
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `diplomacy_planner_stalled_peace_test.dart` contains the sole
//     happy-path test for `quotaMetFutileBelowQuotaGpPeaceTargets`
//     (a different but related helper that additionally filters by
//     invadable-frontier ownership). There is **no** direct unit-level
//     test today for `quotaMetBelowQuotaAtWarPeaceTargets` at all — every
//     branch is currently unpinned.
//   - `colonial_pressure_test.dart` covers `belowQuotaPeerGpPeaceTargets`,
//     `nearQuotaHoldPeaceTargets`, `defaultStartGpPeaceTargets`, and
//     `criticalOwHoldPeaceTargets` — none touch the quota-met
//     below-quota peace family.
//   - `diplomatic_candidate_scoring_offer_peace*` tests cover the score
//     **bonus** layer that consumes the result; they do not pin the
//     filter/sort table at the source predicate.
//
// What this file pins:
//
//   1. **Below-quota guard (`own == quota - 1`).** Even with two below-
//      quota GP enemies at war, the helper must return `const []`. A
//      regression that flipped `<` to `<=` here would silently re-engage
//      quota-met peace one province early, weakening the observer-gate
//      sequencing the SPEC requires.
//   2. **At-quota boundary (`own == quota`).** With a single below-quota
//      GP at war the helper must fire at exactly
//      `kObserverConquestMinOwProvincesPerGp` (not one province above).
//      This is the seed-42 gp4 turn ≈100 shape after meeting the
//      observer quota.
//   3. **Non-GP at-war factions are filtered out.** A war with a minor
//      whose OW count is below quota must not surface — the helper is
//      GP-vs-GP peace only.
//   4. **GP target at observer quota is filtered out.** A GP whose own
//      holdings exactly meet `kObserverConquestMinOwProvincesPerGp` is
//      no longer "below quota" and must not be peaced under this trigger
//      (a regression to `<=` on the target check would silently sweep
//      in peer GPs whose quota already cleared).
//   5. **Sort determinism with multiple targets.** With two below-quota
//      GP enemies the returned list is sorted ascending so the offer-
//      peace consumer sees a stable order regardless of input ordering.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';

/// Builds a Game whose OW region contains the requested per-faction
/// province counts. Each entry of [provincesByOwner] becomes that many
/// `oldWorld|<owner>_<i>` provinces; ownership is the only signal the
/// helper reads via `provinceCountOwnedBy`.
Game _buildGame({
  required Map<String, int> provincesByOwner,
  required List<Player> players,
  List<MinorNation> minorNations = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
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
  return Game(
    id: 'g-quota-met-below-quota-peace',
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
}) {
  return AIWorldSnapshot(
    playerId: 'focus',
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(oldWorldProvincesOwned: focusOw),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group(
    'quotaMetBelowQuotaAtWarPeaceTargets — own-OW below-quota guard',
    () {
      test('returns const [] at own == quota - 1 even with two below-quota '
          'GP enemies at war', () {
        final game = _buildGame(
          provincesByOwner: {
            'focus': kObserverConquestMinOwProvincesPerGp - 1,
            'gp_low_a': 5,
            'gp_low_b': 6,
          },
          players: const [
            Player(id: 'focus', displayName: 'Focus', isHuman: false),
            Player(id: 'gp_low_a', displayName: 'A', isHuman: false),
            Player(id: 'gp_low_b', displayName: 'B', isHuman: false),
          ],
        );
        final snapshot = _focusSnapshot(
          focusOw: kObserverConquestMinOwProvincesPerGp - 1,
          atWarWith: const ['gp_low_a', 'gp_low_b'],
        );

        expect(
          quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Below the observer quota the helper must short-circuit before '
              'evaluating targets. A regression that flipped `<` to `<=` '
              'here would silently re-engage quota-met peace one province '
              'early and weaken the observer gate sequencing the SPEC '
              'requires.',
        );
      });
    },
  );

  group('quotaMetBelowQuotaAtWarPeaceTargets — at-quota fire path', () {
    test('returns the sole below-quota GP enemy at own == quota boundary', () {
      final game = _buildGame(
        provincesByOwner: {
          'focus': kObserverConquestMinOwProvincesPerGp,
          'gp_low_a': 5,
        },
        players: const [
          Player(id: 'focus', displayName: 'Focus', isHuman: false),
          Player(id: 'gp_low_a', displayName: 'A', isHuman: false),
        ],
      );
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const ['gp_low_a'],
      );

      expect(
        quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
        ['gp_low_a'],
        reason:
            'Exactly at kObserverConquestMinOwProvincesPerGp (10 OW today) '
            'the helper must fire toward a below-quota GP enemy. A regression '
            'that pushed the threshold to `> quota` would silently delay the '
            'futile-bullying-war exit by one province.',
      );
    });
  });

  group(
    'quotaMetBelowQuotaAtWarPeaceTargets — at-war faction filters',
    () {
      test('filters out at-war minors (only GP targets are returned)', () {
        final game = _buildGame(
          provincesByOwner: {
            'focus': kObserverConquestMinOwProvincesPerGp + 2,
            'minor_low': 3,
          },
          players: const [
            Player(id: 'focus', displayName: 'Focus', isHuman: false),
          ],
          minorNations: const [
            MinorNation(id: 'minor_low', displayName: 'M'),
          ],
        );
        final snapshot = _focusSnapshot(
          focusOw: kObserverConquestMinOwProvincesPerGp + 2,
          atWarWith: const ['minor_low'],
        );

        expect(
          quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
          reason:
              'Minors and tribes are not in the GP-vs-GP futile-bullying war '
              'family this helper exits. A regression that dropped the '
              '`game.playerById(...) != null` guard would silently sweep a '
              'minor war into the GP peace list and consume the offer-peace '
              'cap intended for GPs.',
        );
      });

      test('filters out a GP target whose own holdings are at observer quota',
          () {
        // Two enemies: one above quota (filtered) and one strictly below
        // quota (kept) so the surviving result also pins ordering.
        final game = _buildGame(
          provincesByOwner: {
            'focus': kObserverConquestMinOwProvincesPerGp + 2,
            'gp_at_quota': kObserverConquestMinOwProvincesPerGp,
            'gp_low': kObserverConquestMinOwProvincesPerGp - 1,
          },
          players: const [
            Player(id: 'focus', displayName: 'Focus', isHuman: false),
            Player(id: 'gp_at_quota', displayName: 'Q', isHuman: false),
            Player(id: 'gp_low', displayName: 'L', isHuman: false),
          ],
        );
        final snapshot = _focusSnapshot(
          focusOw: kObserverConquestMinOwProvincesPerGp + 2,
          atWarWith: const ['gp_at_quota', 'gp_low'],
        );

        expect(
          quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
          ['gp_low'],
          reason:
              'A GP exactly at kObserverConquestMinOwProvincesPerGp is no '
              'longer below the quota and must not appear in the futile-'
              'bullying peace list. A regression that flipped `<` to `<=` '
              'on the target side would silently sweep in peers who already '
              'completed their own observer quota.',
        );
      });
    },
  );

  group('quotaMetBelowQuotaAtWarPeaceTargets — sort determinism', () {
    test('returns ascending factionId order regardless of at-war list order',
        () {
      final game = _buildGame(
        provincesByOwner: {
          'focus': kObserverConquestMinOwProvincesPerGp + 1,
          'gp_a': 4,
          'gp_b': 5,
        },
        players: const [
          Player(id: 'focus', displayName: 'Focus', isHuman: false),
          Player(id: 'gp_a', displayName: 'A', isHuman: false),
          Player(id: 'gp_b', displayName: 'B', isHuman: false),
        ],
      );
      // Intentionally pass the at-war list in reverse sort order so a
      // regression that dropped the `..sort()` would surface as a flipped
      // result.
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestMinOwProvincesPerGp + 1,
        atWarWith: const ['gp_b', 'gp_a'],
      );

      expect(
        quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
        ['gp_a', 'gp_b'],
        reason:
            'Multi-target results must be sorted ascending so downstream '
            'offer-peace scoring and trace logs are independent of the '
            'iteration order of snapshot.threats.atWarWith. Dropping the '
            'sort would surface as ["gp_b", "gp_a"] here.',
      );
    });
  });
}
