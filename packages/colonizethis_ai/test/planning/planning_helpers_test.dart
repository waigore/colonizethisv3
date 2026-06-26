// Unit tests for `planning_helpers.dart` (Refs #3278).
//
// Pins the shared dedup helpers:
//   - `gpFactionIdsAtWarWith` — GP-only filter, sort/determinism, non-GP exclusion
//   - `isAtWarWithAnyGreatPower` — GP-war presence check, non-GP exclusion,
//     empty-set false, equivalence with `gpFactionIdsAtWarWith.isNotEmpty`
//     (Refs #3717)
//   - `isOwnOldWorldExpansionStalled` / `isOwnOldWorldBelowConquestQuota` —
//     own-OW snapshot projections: stall-band / quota boundaries, negative
//     cases, equivalence with the underlying int predicates (Refs #3717)
//   - `gpAtWarPeaceTargetsWhere` — predicate-filtered GP at-war peace-target
//     collector: keep-subset filtering, ascending sort/determinism, non-GP
//     exclusion, keep-all/keep-none edges, one keep call per GP (Refs #3717)
//   - `scaleWeightedBonus` — `<= 0.0` guard, `> 1.0` clamp, rounding
//   - `resolvePhaseColonialPressureActive` — COLONIAL-only gate
//   - `resolvePhaseExpandOrColonialLiteActive` — EXPAND / COLONIAL-lite gate
//   - `hasRecentDiplomaticEventWithinCooldown` — newest-match-wins reversed
//     history scan, strict `<` cooldown window, predicate filtering (Refs #3717)
//   - `atWarPeaceTargetBonus` — at-war GP eligibility gate, lazy predicate
//     short-circuit, flat-bonus emission (Refs #3717)
//   - `factionOwnsInvadableOldWorldProvince` — single-faction invadable-frontier
//     ownership scan, `.any` short-circuit, absent/other-owner exclusion
//     (Refs #3717)

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart'
    show PhasePlanOutcome;
import 'package:colonizethis_ai/src/planning/phase_priority_weights.dart'
    show PhasePriorityWeights;
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        isBelowObserverConquestQuota,
        isStalledOldWorldExpansion,
        kObserverConquestMinOwProvincesPerGp,
        kStalledOldWorldProvinceThreshold;
import 'package:colonizethis_ai/src/util/faction_query.dart'
    show isMinorFaction;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Distinct per-field values so a slot mix-up (e.g. a projection that
// returns `oldWorldCivilian` instead of `oldWorldConquest`) fails hard
// rather than silently matching a shared default.
const PhasePriorityWeights _weights = PhasePriorityWeights(
  oldWorldConquest: 0.11,
  newWorldAcquisition: 0.22,
  oldWorldCivilian: 0.33,
  newWorldCivilian: 0.44,
);

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

Game _gameWithGps() {
  return Game(
    id: 'g-3278-planning-helpers',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
    ),
    players: const [
      Player(id: _gp1, displayName: 'GP1', isHuman: false),
      Player(id: _gp2, displayName: 'GP2', isHuman: false),
      Player(id: _gp3, displayName: 'GP3', isHuman: false),
    ],
    minorNations: const [MinorNation(id: _minor1, displayName: 'Minor1')],
    tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
  );
}

AIWorldSnapshot _snapshotWithAtWar(List<String> atWarWith) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

AIWorldSnapshot _snapshotWithOwnOw(int oldWorldProvincesOwned) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: const ThreatSummary(atWarWith: []),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(oldWorldProvincesOwned: oldWorldProvincesOwned),
    economy: const EconomySummary(),
    relations: const {},
  );
}

AIWorldSnapshot _snapshotWithInvadable(List<String> invadableProvinceIds) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: const ThreatSummary(atWarWith: []),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(invadableProvinceIdsSorted: invadableProvinceIds),
    economy: const EconomySummary(),
    relations: const {},
  );
}

Game _gameWithEvents(List<DiplomaticEvent> events) {
  return Game(
    id: 'g-3717-cooldown-scan',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
    ),
    players: const [
      Player(id: _gp1, displayName: 'GP1', isHuman: false),
      Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
    diplomaticHistoryEvents: events,
  );
}

DiplomaticEvent _ev(
  int turn, {
  DiplomaticEventType type = DiplomaticEventType.declareWar,
  String from = _gp1,
  String to = _gp2,
}) {
  return DiplomaticEvent(
    turn: turn,
    intraTurnIndex: 0,
    type: type,
    participants: {from, to},
    fromFactionId: from,
    toFactionId: to,
  );
}

bool _warFromGp1ToGp2(DiplomaticEvent e) =>
    e.type == DiplomaticEventType.declareWar &&
    e.fromFactionId == _gp1 &&
    e.toFactionId == _gp2;

void main() {
  group('gpFactionIdsAtWarWith', () {
    test('filters to Great Powers only and sorts ascending', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp3, _tribe1, _gp1, _minor1, _gp2]);
      expect(gpFactionIdsAtWarWith(game, snapshot), [_gp1, _gp2, _gp3]);
    });

    test('returns empty when no GP wars are active', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_tribe1, _minor1]);
      expect(gpFactionIdsAtWarWith(game, snapshot), isEmpty);
    });

    test('sorts regardless of atWarWith iteration order', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp3, _gp2, _gp1]);
      final a = gpFactionIdsAtWarWith(game, snapshot);
      final b = gpFactionIdsAtWarWith(game, snapshot);
      expect(a, [_gp1, _gp2, _gp3]);
      expect(b, a);
    });
  });

  group('isAtWarWithAnyGreatPower (Refs #3717)', () {
    test('true when at least one at-war faction is a Great Power', () {
      final game = _gameWithGps();
      expect(
        isAtWarWithAnyGreatPower(game, _snapshotWithAtWar([_tribe1, _gp2])),
        isTrue,
      );
    });

    test('false when no at-war faction resolves to a Great Power', () {
      final game = _gameWithGps();
      expect(
        isAtWarWithAnyGreatPower(game, _snapshotWithAtWar([_tribe1, _minor1])),
        isFalse,
      );
    });

    test('false on an empty atWarWith set', () {
      final game = _gameWithGps();
      expect(
        isAtWarWithAnyGreatPower(game, _snapshotWithAtWar(const [])),
        isFalse,
      );
    });

    test('agrees with gpFactionIdsAtWarWith.isNotEmpty (equivalence)', () {
      final game = _gameWithGps();
      for (final atWar in <List<String>>[
        const [],
        [_tribe1],
        [_minor1, _tribe1],
        [_gp1],
        [_gp3, _tribe1, _gp1, _minor1, _gp2],
      ]) {
        final snapshot = _snapshotWithAtWar(atWar);
        expect(
          isAtWarWithAnyGreatPower(game, snapshot),
          gpFactionIdsAtWarWith(game, snapshot).isNotEmpty,
          reason: 'mismatch for atWarWith=$atWar',
        );
      }
    });
  });

  group('isOwnOldWorldExpansionStalled (Refs #3717)', () {
    test('true inside the stalled OW band (0 < ow <= threshold)', () {
      expect(isOwnOldWorldExpansionStalled(_snapshotWithOwnOw(1)), isTrue);
      expect(
        isOwnOldWorldExpansionStalled(
          _snapshotWithOwnOw(kStalledOldWorldProvinceThreshold),
        ),
        isTrue,
      );
    });

    test('false at zero OW and above the stall band (negative cases)', () {
      expect(isOwnOldWorldExpansionStalled(_snapshotWithOwnOw(0)), isFalse);
      expect(
        isOwnOldWorldExpansionStalled(
          _snapshotWithOwnOw(kStalledOldWorldProvinceThreshold + 1),
        ),
        isFalse,
      );
    });

    test('matches isStalledOldWorldExpansion(ownOw) across a range', () {
      for (var ow = 0; ow <= kStalledOldWorldProvinceThreshold + 3; ow++) {
        expect(
          isOwnOldWorldExpansionStalled(_snapshotWithOwnOw(ow)),
          isStalledOldWorldExpansion(ow),
          reason: 'mismatch for ownOw=$ow',
        );
      }
    });
  });

  group('isOwnOldWorldBelowConquestQuota (Refs #3717)', () {
    test('true below the observer conquest quota', () {
      expect(isOwnOldWorldBelowConquestQuota(_snapshotWithOwnOw(0)), isTrue);
      expect(
        isOwnOldWorldBelowConquestQuota(
          _snapshotWithOwnOw(kObserverConquestMinOwProvincesPerGp - 1),
        ),
        isTrue,
      );
    });

    test('false at and above the quota (boundary negative cases)', () {
      expect(
        isOwnOldWorldBelowConquestQuota(
          _snapshotWithOwnOw(kObserverConquestMinOwProvincesPerGp),
        ),
        isFalse,
      );
      expect(
        isOwnOldWorldBelowConquestQuota(
          _snapshotWithOwnOw(kObserverConquestMinOwProvincesPerGp + 5),
        ),
        isFalse,
      );
    });

    test('matches isBelowObserverConquestQuota(ownOw) across a range', () {
      for (var ow = 0; ow <= kObserverConquestMinOwProvincesPerGp + 3; ow++) {
        expect(
          isOwnOldWorldBelowConquestQuota(_snapshotWithOwnOw(ow)),
          isBelowObserverConquestQuota(ow),
          reason: 'mismatch for ownOw=$ow',
        );
      }
    });
  });

  group('gpAtWarPeaceTargetsWhere (Refs #3717)', () {
    test('keeps only GP at-war factions matching the predicate, sorted', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp3, _tribe1, _gp1, _minor1, _gp2]);
      expect(
        gpAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (factionId) => factionId != _gp2,
        ),
        [_gp1, _gp3],
      );
    });

    test('keep-all equals gpFactionIdsAtWarWith (GP filter + sort)', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp3, _tribe1, _gp1, _minor1, _gp2]);
      expect(
        gpAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => true,
        ),
        gpFactionIdsAtWarWith(game, snapshot),
      );
    });

    test('keep-none returns empty', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp1, _gp2, _gp3]);
      expect(
        gpAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => false,
        ),
        isEmpty,
      );
    });

    test('never offers a non-GP even when the predicate would keep it', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_tribe1, _minor1]);
      expect(
        gpAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => true,
        ),
        isEmpty,
      );
    });

    test('result is sorted ascending regardless of atWarWith order', () {
      final game = _gameWithGps();
      expect(
        gpAtWarPeaceTargetsWhere(
          game: game,
          snapshot: _snapshotWithAtWar([_gp3, _gp1, _gp2]),
          keep: (_) => true,
        ),
        [_gp1, _gp2, _gp3],
      );
    });

    test('invokes keep exactly once per at-war GP in ascending order', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp3, _tribe1, _gp1, _gp2]);
      final seen = <String>[];
      gpAtWarPeaceTargetsWhere(
        game: game,
        snapshot: snapshot,
        keep: (factionId) {
          seen.add(factionId);
          return true;
        },
      );
      expect(seen, [_gp1, _gp2, _gp3]);
    });
  });

  group('scaleWeightedBonus', () {
    test('returns 0 when weight <= 0.0', () {
      expect(scaleWeightedBonus(0.0, 45), 0);
      expect(scaleWeightedBonus(-0.5, 45), 0);
    });

    test('returns baseConstant exactly when weight == 1.0', () {
      expect(scaleWeightedBonus(1.0, 45), 45);
      expect(scaleWeightedBonus(1.0, 360), 360);
    });

    test('clamps weight > 1.0 to 1.0', () {
      expect(scaleWeightedBonus(1.5, 45), 45);
      expect(scaleWeightedBonus(2.0, 100), 100);
    });

    test('rounds intermediate weights', () {
      expect(scaleWeightedBonus(0.05, 45), 2);
      expect(scaleWeightedBonus(0.6, 50), 30);
    });
  });

  group('resolvePhaseColonialPressureActive', () {
    test('true only under COLONIAL', () {
      expect(
        resolvePhaseColonialPressureActive(ObserverGoalPhase.colonial),
        isTrue,
      );
      expect(
        resolvePhaseColonialPressureActive(ObserverGoalPhase.expand),
        isFalse,
      );
      expect(
        resolvePhaseColonialPressureActive(ObserverGoalPhase.colonialLite),
        isFalse,
      );
      expect(
        resolvePhaseColonialPressureActive(ObserverGoalPhase.develop),
        isFalse,
      );
    });
  });

  group('resolvePhaseExpandOrColonialLiteActive', () {
    test('true under EXPAND and COLONIAL-lite only', () {
      expect(
        resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase.expand),
        isTrue,
      );
      expect(
        resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase.colonialLite),
        isTrue,
      );
      expect(
        resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase.colonial),
        isFalse,
      );
      expect(
        resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase.develop),
        isFalse,
      );
    });
  });

  group('phase-plan weight projections (Refs #3717)', () {
    PhasePlanOutcome outcome({
      ObserverGoalPhase phase = ObserverGoalPhase.expand,
      PhasePriorityWeights weights = _weights,
    }) => PhasePlanOutcome(phase: phase, priorityWeights: weights);

    test('each projection returns exactly its named priorityWeights slot', () {
      final o = outcome();
      expect(
        resolvePhaseNewWorldAcquisitionWeight(o),
        equals(_weights.newWorldAcquisition),
      );
      expect(
        resolvePhaseOldWorldConquestWeight(o),
        equals(_weights.oldWorldConquest),
      );
      expect(
        resolvePhaseOldWorldCivilianWeight(o),
        equals(_weights.oldWorldCivilian),
      );
      expect(
        resolvePhaseNewWorldCivilianWeight(o),
        equals(_weights.newWorldCivilian),
      );
    });

    test('projections do not read sibling slots (no field confusion)', () {
      final o = outcome();
      // Each of the four distinct slot values is returned by exactly one
      // projection; a swapped accessor would match the wrong value here.
      expect(
        resolvePhaseNewWorldAcquisitionWeight(o),
        isNot(equals(_weights.oldWorldConquest)),
      );
      expect(
        resolvePhaseOldWorldConquestWeight(o),
        isNot(equals(_weights.newWorldAcquisition)),
      );
      expect(
        resolvePhaseOldWorldCivilianWeight(o),
        isNot(equals(_weights.newWorldCivilian)),
      );
      expect(
        resolvePhaseNewWorldCivilianWeight(o),
        isNot(equals(_weights.oldWorldCivilian)),
      );
    });

    test('projections are phase-independent and deterministic', () {
      final results = <double>{
        for (final phase in ObserverGoalPhase.values)
          resolvePhaseNewWorldAcquisitionWeight(outcome(phase: phase)),
      };
      expect(results, <double>{_weights.newWorldAcquisition});

      final o = outcome();
      expect(
        resolvePhaseOldWorldConquestWeight(o),
        equals(resolvePhaseOldWorldConquestWeight(o)),
      );
    });

    test('flipping a single slot changes only that slot projection', () {
      const bumped = PhasePriorityWeights(
        oldWorldConquest: 0.99,
        newWorldAcquisition: 0.22,
        oldWorldCivilian: 0.33,
        newWorldCivilian: 0.44,
      );
      final base = outcome();
      final next = outcome(weights: bumped);
      expect(
        resolvePhaseOldWorldConquestWeight(next),
        isNot(equals(resolvePhaseOldWorldConquestWeight(base))),
      );
      expect(
        resolvePhaseNewWorldAcquisitionWeight(next),
        equals(resolvePhaseNewWorldAcquisitionWeight(base)),
      );
      expect(
        resolvePhaseOldWorldCivilianWeight(next),
        equals(resolvePhaseOldWorldCivilianWeight(base)),
      );
      expect(
        resolvePhaseNewWorldCivilianWeight(next),
        equals(resolvePhaseNewWorldCivilianWeight(base)),
      );
    });
  });

  group('hasRecentDiplomaticEventWithinCooldown (Refs #3717)', () {
    test('true when the newest matching event is inside the window', () {
      final game = _gameWithEvents([_ev(2)]);
      expect(
        hasRecentDiplomaticEventWithinCooldown(
          game: game,
          currentTurn: 5,
          cooldownTurns: 4,
          matches: _warFromGp1ToGp2,
        ),
        isTrue, // 5 - 2 = 3 < 4
      );
    });

    test(
      'false when matching event is exactly cooldownTurns old (strict <)',
      () {
        final game = _gameWithEvents([_ev(1)]);
        expect(
          hasRecentDiplomaticEventWithinCooldown(
            game: game,
            currentTurn: 5,
            cooldownTurns: 4,
            matches: _warFromGp1ToGp2,
          ),
          isFalse, // 5 - 1 = 4, not < 4
        );
      },
    );

    test('false when no event satisfies the predicate', () {
      final game = _gameWithEvents([_ev(4, type: DiplomaticEventType.peace)]);
      expect(
        hasRecentDiplomaticEventWithinCooldown(
          game: game,
          currentTurn: 5,
          cooldownTurns: 4,
          matches: _warFromGp1ToGp2,
        ),
        isFalse,
      );
    });

    test('false on empty diplomatic history', () {
      final game = _gameWithEvents(const []);
      expect(
        hasRecentDiplomaticEventWithinCooldown(
          game: game,
          currentTurn: 5,
          cooldownTurns: 4,
          matches: _warFromGp1ToGp2,
        ),
        isFalse,
      );
    });

    test(
      'newest matching event decides; non-matching newer events skipped',
      () {
        // History ascending by turn; `.reversed` visits turn 5 (peace, no
        // match) first and must continue to the older matching declare-war at
        // turn 4 rather than stopping at the first non-match.
        final game = _gameWithEvents([
          _ev(4),
          _ev(5, type: DiplomaticEventType.peace),
        ]);
        expect(
          hasRecentDiplomaticEventWithinCooldown(
            game: game,
            currentTurn: 6,
            cooldownTurns: 4,
            matches: _warFromGp1ToGp2,
          ),
          isTrue, // newest matching is turn 4: 6 - 4 = 2 < 4
        );
      },
    );

    test('directional predicate ignores the reverse-direction event', () {
      final game = _gameWithEvents([_ev(4, from: _gp2, to: _gp1)]);
      expect(
        hasRecentDiplomaticEventWithinCooldown(
          game: game,
          currentTurn: 5,
          cooldownTurns: 4,
          matches: _warFromGp1ToGp2,
        ),
        isFalse,
      );
    });
  });

  group('atWarPeaceTargetBonus (Refs #3717)', () {
    test('returns the bonus when eligible and the predicate matches', () {
      expect(
        atWarPeaceTargetBonus(
          atWarGreatPowerTarget: true,
          isPeaceTarget: () => true,
          bonus: 7,
        ),
        equals(7),
      );
    });

    test('returns 0 when eligible but the predicate does not match', () {
      expect(
        atWarPeaceTargetBonus(
          atWarGreatPowerTarget: true,
          isPeaceTarget: () => false,
          bonus: 7,
        ),
        equals(0),
      );
    });

    test('returns 0 when not an at-war Great Power target', () {
      expect(
        atWarPeaceTargetBonus(
          atWarGreatPowerTarget: false,
          isPeaceTarget: () => true,
          bonus: 7,
        ),
        equals(0),
      );
    });

    test('skips the predicate (short-circuit) when ineligible', () {
      var calls = 0;
      final result = atWarPeaceTargetBonus(
        atWarGreatPowerTarget: false,
        isPeaceTarget: () {
          calls++;
          return true;
        },
        bonus: 7,
      );
      expect(result, equals(0));
      expect(calls, equals(0));
    });

    test('evaluates the predicate exactly once when eligible', () {
      var calls = 0;
      final result = atWarPeaceTargetBonus(
        atWarGreatPowerTarget: true,
        isPeaceTarget: () {
          calls++;
          return true;
        },
        bonus: 7,
      );
      expect(result, equals(7));
      expect(calls, equals(1));
    });
  });

  group('atWarGreatPowerOrderTarget (Refs #3717)', () {
    const Player gp = Player(id: _gp2, displayName: 'GP2', isHuman: false);

    test('true when target is a Great Power we are at war with', () {
      expect(
        atWarGreatPowerOrderTarget(
          targetGp: gp,
          snapshot: _snapshotWithAtWar([_gp2]),
          targetFactionId: _gp2,
        ),
        isTrue,
      );
    });

    test('false when the target is not a Great Power (targetGp null)', () {
      // A minor/tribe target the player is at war with still fails the gate:
      // only Player Great Powers are eligible offer-peace candidates here.
      expect(
        atWarGreatPowerOrderTarget(
          targetGp: null,
          snapshot: _snapshotWithAtWar([_minor1]),
          targetFactionId: _minor1,
        ),
        isFalse,
      );
    });

    test('false when the Great Power target is not currently at war', () {
      expect(
        atWarGreatPowerOrderTarget(
          targetGp: gp,
          snapshot: _snapshotWithAtWar([_gp3]),
          targetFactionId: _gp2,
        ),
        isFalse,
      );
    });

    test('false when both eligibility conditions fail', () {
      expect(
        atWarGreatPowerOrderTarget(
          targetGp: null,
          snapshot: _snapshotWithAtWar(const []),
          targetFactionId: _gp2,
        ),
        isFalse,
      );
    });
  });

  group('anyInvadableProvinceOwnedByMinor (Refs #3717)', () {
    const String pA = 'provA';
    const String pB = 'provB';

    test('true when an invadable province is owned by a minor nation', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA]);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _minor1},
        ),
        isTrue,
      );
    });

    test('false when invadable provinces are owned only by GPs / tribes', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA, pB]);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _gp2, pB: _tribe1},
        ),
        isFalse,
      );
    });

    test('false when an invadable province owner is absent from the map', () {
      // Unowned / not-yet-mapped invadable province: lookup is null, no match.
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA]);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {},
        ),
        isFalse,
      );
    });

    test('false when there are no invadable provinces', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable(const []);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _minor1},
        ),
        isFalse,
      );
    });

    test('true when only a non-first invadable province is minor-owned', () {
      // The .any short-circuit must still find a minor owner that is not the
      // first scanned entry (GP first, minor second) -> deterministic true.
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA, pB]);
      expect(
        anyInvadableProvinceOwnedByMinor(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _gp2, pB: _minor1},
        ),
        isTrue,
      );
    });
  });

  group('anyInvadableProvinceOwnedByGreatPower (Refs #3717)', () {
    const String pA = 'provA';
    const String pB = 'provB';

    test('true when an invadable province is owned by a Great Power', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA]);
      expect(
        anyInvadableProvinceOwnedByGreatPower(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _gp2},
        ),
        isTrue,
      );
    });

    test(
      'false when invadable provinces are owned only by minors / tribes',
      () {
        final game = _gameWithGps();
        final snapshot = _snapshotWithInvadable([pA, pB]);
        expect(
          anyInvadableProvinceOwnedByGreatPower(
            game: game,
            snapshot: snapshot,
            provinceOwner: const {pA: _minor1, pB: _tribe1},
          ),
          isFalse,
        );
      },
    );

    test('false when an invadable province owner is absent from the map', () {
      // Unowned / not-yet-mapped invadable province: `?? ''` -> playerById null.
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA]);
      expect(
        anyInvadableProvinceOwnedByGreatPower(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {},
        ),
        isFalse,
      );
    });

    test('false when there are no invadable provinces', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable(const []);
      expect(
        anyInvadableProvinceOwnedByGreatPower(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _gp2},
        ),
        isFalse,
      );
    });

    test('true when only a non-first invadable province is GP-owned', () {
      // The .any short-circuit must still find a GP owner that is not the
      // first scanned entry (minor first, GP second) -> deterministic true.
      final game = _gameWithGps();
      final snapshot = _snapshotWithInvadable([pA, pB]);
      expect(
        anyInvadableProvinceOwnedByGreatPower(
          game: game,
          snapshot: snapshot,
          provinceOwner: const {pA: _minor1, pB: _gp2},
        ),
        isTrue,
      );
    });
  });

  group('factionOwnsInvadableOldWorldProvince (Refs #3717)', () {
    const String pA = 'provA';
    const String pB = 'provB';

    test('true when the faction owns an invadable province', () {
      final snapshot = _snapshotWithInvadable([pA]);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {pA: _gp2},
          factionId: _gp2,
        ),
        isTrue,
      );
    });

    test('false when invadable provinces are owned by other factions', () {
      final snapshot = _snapshotWithInvadable([pA, pB]);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {pA: _gp3, pB: _minor1},
          factionId: _gp2,
        ),
        isFalse,
      );
    });

    test('false when the owner lookup is absent from the map', () {
      // Unowned / not-yet-mapped invadable province: lookup is null, no match.
      final snapshot = _snapshotWithInvadable([pA]);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {},
          factionId: _gp2,
        ),
        isFalse,
      );
    });

    test('false when there are no invadable provinces', () {
      final snapshot = _snapshotWithInvadable(const []);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {pA: _gp2},
          factionId: _gp2,
        ),
        isFalse,
      );
    });

    test('true when only a non-first invadable province is faction-owned', () {
      // The .any short-circuit must still find the faction owner that is not
      // the first scanned entry (other GP first, target second) -> true.
      final snapshot = _snapshotWithInvadable([pA, pB]);
      expect(
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: const {pA: _gp3, pB: _gp2},
          factionId: _gp2,
        ),
        isTrue,
      );
    });

    test('agrees with the inline scan it replaces (equivalence)', () {
      final snapshot = _snapshotWithInvadable([pA, pB]);
      for (final owner in <Map<String, String>>[
        const {},
        const {pA: _gp2},
        const {pA: _gp3, pB: _gp2},
        const {pA: _gp3, pB: _minor1},
      ]) {
        expect(
          factionOwnsInvadableOldWorldProvince(
            snapshot: snapshot,
            provinceOwner: owner,
            factionId: _gp2,
          ),
          snapshot.conquest.invadableProvinceIdsSorted.any(
            (pid) => owner[pid] == _gp2,
          ),
          reason: 'mismatch for provinceOwner=$owner',
        );
      }
    });
  });

  group('addInvadableProvinceMinorOwnersNotAtWar (Refs #3717)', () {
    const String pA = 'provA';
    const String pB = 'provB';
    const String pC = 'provC';
    const String _minor2 = 'minor2';

    Game gameWithTwoMinors() => Game(
      id: 'g-3717-minor-collector',
      worldState: WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: const RegionData(provinces: []),
        newWorld: const RegionData(provinces: []),
      ),
      players: const [Player(id: _gp1, displayName: 'GP1', isHuman: false)],
      minorNations: const [
        MinorNation(id: _minor1, displayName: 'Minor1'),
        MinorNation(id: _minor2, displayName: 'Minor2'),
      ],
      tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
    );

    AIWorldSnapshot snapshot(List<String> invadable, List<String> atWarWith) =>
        AIWorldSnapshot(
          playerId: _gp1,
          threats: ThreatSummary(atWarWith: atWarWith),
          opportunities: const OpportunitySummary(),
          conquest: ConquestSummary(invadableProvinceIdsSorted: invadable),
          economy: const EconomySummary(),
          relations: const {},
        );

    test('collects minor owners of invadable provinces not already at war', () {
      final into = <String>{};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: gameWithTwoMinors(),
        snapshot: snapshot([pA, pB], const []),
        provinceOwner: const {pA: _minor1, pB: _minor2},
        into: into,
      );
      expect(into, <String>{_minor1, _minor2});
    });

    test('skips minors already at war', () {
      final into = <String>{};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: gameWithTwoMinors(),
        snapshot: snapshot([pA, pB], [_minor1]),
        provinceOwner: const {pA: _minor1, pB: _minor2},
        into: into,
      );
      expect(into, <String>{_minor2});
    });

    test('skips Great-Power, tribe, and unowned invadable provinces', () {
      final into = <String>{};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: gameWithTwoMinors(),
        snapshot: snapshot([pA, pB, pC], const []),
        // pA: GP, pB: tribe, pC: absent from the owner map (null lookup).
        provinceOwner: const {pA: _gp1, pB: _tribe1},
        into: into,
      );
      expect(into, isEmpty);
    });

    test('adds nothing when there are no invadable provinces', () {
      final into = <String>{};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: gameWithTwoMinors(),
        snapshot: snapshot(const [], const []),
        provinceOwner: const {pA: _minor1},
        into: into,
      );
      expect(into, isEmpty);
    });

    test('preserves pre-seeded entries and de-duplicates via set', () {
      // Mirrors the plateau decider seeding adjacent-owner candidates first.
      final into = <String>{_minor1};
      addInvadableProvinceMinorOwnersNotAtWar(
        game: gameWithTwoMinors(),
        snapshot: snapshot([pA, pB], const []),
        provinceOwner: const {pA: _minor1, pB: _minor2},
        into: into,
      );
      expect(into, <String>{_minor1, _minor2});
    });

    test('agrees with the inline collector loop it replaces (equivalence)', () {
      final game = gameWithTwoMinors();
      for (final atWar in <List<String>>[
        const [],
        [_minor1],
        [_minor1, _minor2],
      ]) {
        for (final owner in <Map<String, String>>[
          const {},
          const {pA: _minor1, pB: _minor2},
          const {pA: _gp1, pB: _minor2},
          const {pA: _tribe1, pB: _minor1},
        ]) {
          final snap = snapshot([pA, pB], atWar);
          final viaHelper = <String>{};
          addInvadableProvinceMinorOwnersNotAtWar(
            game: game,
            snapshot: snap,
            provinceOwner: owner,
            into: viaHelper,
          );
          final viaInline = <String>{};
          for (final pid in snap.conquest.invadableProvinceIdsSorted) {
            final o = owner[pid];
            if (o == null ||
                !isMinorFaction(game, o) ||
                snap.threats.atWarWith.contains(o)) {
              continue;
            }
            viaInline.add(o);
          }
          expect(
            viaHelper,
            viaInline,
            reason: 'mismatch for atWar=$atWar owner=$owner',
          );
        }
      }
    });
  });
}
