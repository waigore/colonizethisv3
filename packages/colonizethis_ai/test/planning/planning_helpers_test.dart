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
//   - `minorAtWarPeaceTargetsWhere` — predicate-filtered minor at-war
//     peace-target collector: null-keep keep-all, keep-subset filtering,
//     GP/tribe exclusion, keep-none edge, ascending sort/determinism
//     (Refs #3717)
//   - `tribeAtWarPeaceTargetsWhere` — predicate-filtered tribe at-war
//     peace-target collector: null-keep keep-all, keep-subset filtering,
//     GP/minor exclusion, keep-none edge, ascending sort/determinism
//     (Refs #3717)
//   - `peaceTargetsExcludingBlocker` — drop-blocker-then-sort peace-target
//     skeleton: blocker exclusion, null/absent blocker keep-all, empty input,
//     input-order independence, Set (atWarWith) input (Refs #3717)
//   - `scaleWeightedBonus` — `<= 0.0` guard, `> 1.0` clamp, rounding
//   - `resolvePhaseColonialPressureActive` — COLONIAL-only gate
//   - `resolvePhaseExpandOrColonialLiteActive` — EXPAND / COLONIAL-lite gate
//   - `hasRecentDiplomaticEventWithinCooldown` — newest-match-wins reversed
//     history scan, strict `<` cooldown window, predicate filtering (Refs #3717)
//   - `atWarPeaceTargetBonus` — at-war GP eligibility gate, lazy predicate
//     short-circuit, flat-bonus emission (Refs #3717)
//
// Invadable-province ownership helpers (`anyInvadableProvinceOwnedByMinor`,
// `anyInvadableProvinceOwnedByGreatPower`, `factionOwnsInvadableOldWorldProvince`,
// `addInvadableProvinceMinorOwnersNotAtWar`) are pinned in the sibling
// `planning_helpers_part2_test.dart` to keep each file within the repo
// non-comment line limit.

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

  group('minorAtWarPeaceTargetsWhere (Refs #3717)', () {
    Game gameWithMinors() => Game(
      id: 'g-3717-minor-peace',
      worldState: WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: const RegionData(provinces: []),
        newWorld: const RegionData(provinces: []),
      ),
      players: const [Player(id: _gp1, displayName: 'GP1', isHuman: false)],
      minorNations: const [
        MinorNation(id: 'minorA', displayName: 'MinorA'),
        MinorNation(id: 'minorB', displayName: 'MinorB'),
        MinorNation(id: 'minorC', displayName: 'MinorC'),
      ],
      tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
    );

    test('keep == null keeps every at-war minor, sorted ascending', () {
      final game = gameWithMinors();
      final snapshot = _snapshotWithAtWar([
        'minorC',
        _gp1,
        'minorA',
        _tribe1,
        'minorB',
      ]);
      expect(minorAtWarPeaceTargetsWhere(game: game, snapshot: snapshot), [
        'minorA',
        'minorB',
        'minorC',
      ]);
    });

    test('keeps only minors matching the predicate, sorted', () {
      final game = gameWithMinors();
      final snapshot = _snapshotWithAtWar(['minorC', 'minorA', 'minorB']);
      expect(
        minorAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (factionId) => factionId != 'minorB',
        ),
        ['minorA', 'minorC'],
      );
    });

    test('never offers a GP or tribe even with a keep-all predicate', () {
      final game = gameWithMinors();
      final snapshot = _snapshotWithAtWar([_gp1, _tribe1, 'minorA']);
      expect(
        minorAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => true,
        ),
        ['minorA'],
      );
    });

    test('keep-none returns empty', () {
      final game = gameWithMinors();
      final snapshot = _snapshotWithAtWar(['minorA', 'minorB']);
      expect(
        minorAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => false,
        ),
        isEmpty,
      );
    });

    test('returns empty when no at-war minor is present', () {
      final game = gameWithMinors();
      final snapshot = _snapshotWithAtWar([_gp1, _tribe1]);
      expect(
        minorAtWarPeaceTargetsWhere(game: game, snapshot: snapshot),
        isEmpty,
      );
    });

    test('result is sorted ascending regardless of atWarWith order', () {
      final game = gameWithMinors();
      expect(
        minorAtWarPeaceTargetsWhere(
          game: game,
          snapshot: _snapshotWithAtWar(['minorC', 'minorA', 'minorB']),
        ),
        ['minorA', 'minorB', 'minorC'],
      );
    });
  });

  group('tribeAtWarPeaceTargetsWhere (Refs #3717)', () {
    Game gameWithTribes() => Game(
      id: 'g-3717-tribe-peace',
      worldState: WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: const RegionData(provinces: []),
        newWorld: const RegionData(provinces: []),
      ),
      players: const [Player(id: _gp1, displayName: 'GP1', isHuman: false)],
      minorNations: const [MinorNation(id: 'minorA', displayName: 'MinorA')],
      tribes: const [
        Tribe(id: 'tribeA', displayName: 'TribeA'),
        Tribe(id: 'tribeB', displayName: 'TribeB'),
        Tribe(id: 'tribeC', displayName: 'TribeC'),
      ],
    );

    test('keep == null keeps every at-war tribe, sorted ascending', () {
      final game = gameWithTribes();
      final snapshot = _snapshotWithAtWar([
        'tribeC',
        _gp1,
        'tribeA',
        'minorA',
        'tribeB',
      ]);
      expect(tribeAtWarPeaceTargetsWhere(game: game, snapshot: snapshot), [
        'tribeA',
        'tribeB',
        'tribeC',
      ]);
    });

    test('keeps only tribes matching the predicate, sorted', () {
      final game = gameWithTribes();
      final snapshot = _snapshotWithAtWar(['tribeC', 'tribeA', 'tribeB']);
      expect(
        tribeAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (factionId) => factionId != 'tribeB',
        ),
        ['tribeA', 'tribeC'],
      );
    });

    test('never offers a GP or minor even with a keep-all predicate', () {
      final game = gameWithTribes();
      final snapshot = _snapshotWithAtWar([_gp1, 'minorA', 'tribeA']);
      expect(
        tribeAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => true,
        ),
        ['tribeA'],
      );
    });

    test('keep-none returns empty', () {
      final game = gameWithTribes();
      final snapshot = _snapshotWithAtWar(['tribeA', 'tribeB']);
      expect(
        tribeAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => false,
        ),
        isEmpty,
      );
    });

    test('returns empty when no at-war tribe is present', () {
      final game = gameWithTribes();
      final snapshot = _snapshotWithAtWar([_gp1, 'minorA']);
      expect(
        tribeAtWarPeaceTargetsWhere(game: game, snapshot: snapshot),
        isEmpty,
      );
    });

    test('result is sorted ascending regardless of atWarWith order', () {
      final game = gameWithTribes();
      expect(
        tribeAtWarPeaceTargetsWhere(
          game: game,
          snapshot: _snapshotWithAtWar(['tribeC', 'tribeA', 'tribeB']),
        ),
        ['tribeA', 'tribeB', 'tribeC'],
      );
    });
  });

  group('peaceTargetsExcludingBlocker (Refs #3717)', () {
    test('excludes the blocker and sorts ascending', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: [_gp3, _gp1, _gp2],
          blocker: _gp2,
        ),
        [_gp1, _gp3],
      );
    });

    test('null blocker keeps every faction, sorted ascending', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: [_gp3, _gp1, _gp2],
          blocker: null,
        ),
        [_gp1, _gp2, _gp3],
      );
    });

    test('blocker absent from the list keeps every faction, sorted', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: [_gp3, _gp1],
          blocker: _gp2,
        ),
        [_gp1, _gp3],
      );
    });

    test('empty input returns empty', () {
      expect(
        peaceTargetsExcludingBlocker(factionIds: const [], blocker: _gp1),
        isEmpty,
      );
    });

    test('result order is independent of input order', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: [_gp1, _gp3, _gp2],
          blocker: _gp2,
        ),
        peaceTargetsExcludingBlocker(
          factionIds: [_gp3, _gp2, _gp1],
          blocker: _gp2,
        ),
      );
    });

    test('accepts a Set (threats.atWarWith) input and excludes blocker', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: <String>{_gp2, _minor1, _gp1},
          blocker: _gp2,
        ),
        [_gp1, _minor1],
      );
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

}
