// Unit tests for `planning_ow_tech_helpers.dart` (Refs #3941 topic split).
// Pins tech-steal posture, own-OW projections, and mutual-exhausted GP gates.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show
        isBelowObserverConquestQuota,
        isStalledOldWorldExpansion,
        kMutualExhaustedGpRegimentMax,
        kMutualExhaustedGpStalemateMinOw,
        kMutualExhaustedGpTreasuryMax,
        kObserverConquestMinOwProvincesPerGp,
        kStalledOldWorldProvinceThreshold;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planning_ow_tech_helpers_test_support.dart';

const String _gp1 = planningOwTechHelpersGp1;
const String _gp2 = planningOwTechHelpersGp2;
const String _gp3 = planningOwTechHelpersGp3;
const String _gpExhausted = planningOwTechHelpersGpExhausted;

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

void registerPlanningOwTechHelpersTailCases() {

  group('unlockedTechCount (Refs #3793)', () {
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

  group('oldWorldProvinceLeadOver (Refs #3717)', () {
    test('positive when the faction owns more than the own OW count', () {
      final game = planningOwTechHelpersGameOwning({_gp2: 5});
      expect(
        oldWorldProvinceLeadOver(
          game: game,
          snapshot: _snapshotWithOwnOw(3),
          factionId: _gp2,
        ),
        2,
      );
    });

    test('negative (deficit view) when the faction owns fewer', () {
      final game = planningOwTechHelpersGameOwning({_gp2: 1});
      expect(
        oldWorldProvinceLeadOver(
          game: game,
          snapshot: _snapshotWithOwnOw(4),
          factionId: _gp2,
        ),
        -3,
      );
    });

    test('zero when the faction owns exactly the own OW count', () {
      final game = planningOwTechHelpersGameOwning({_gp2: 4});
      expect(
        oldWorldProvinceLeadOver(
          game: game,
          snapshot: _snapshotWithOwnOw(4),
          factionId: _gp2,
        ),
        0,
      );
    });

    test('counts only the queried faction (other owners excluded)', () {
      final game = planningOwTechHelpersGameOwning({_gp2: 6, _gp3: 9});
      expect(
        oldWorldProvinceLeadOver(
          game: game,
          snapshot: _snapshotWithOwnOw(2),
          factionId: _gp2,
        ),
        4,
      );
    });

    test('unowned faction yields a pure deficit (count 0)', () {
      final game = planningOwTechHelpersGameOwning({_gp2: 3});
      expect(
        oldWorldProvinceLeadOver(
          game: game,
          snapshot: _snapshotWithOwnOw(5),
          factionId: _gp3,
        ),
        -5,
      );
    });

    test('deterministic for fixed inputs', () {
      final game = planningOwTechHelpersGameOwning({_gp2: 7});
      final snapshot = _snapshotWithOwnOw(3);
      final a = oldWorldProvinceLeadOver(
        game: game,
        snapshot: snapshot,
        factionId: _gp2,
      );
      final b = oldWorldProvinceLeadOver(
        game: game,
        snapshot: snapshot,
        factionId: _gp2,
      );
      expect(a, 4);
      expect(b, a);
    });
  });

  group('mutualExhaustedGpStalemateSideQualifies (Refs #3717)', () {
    // 8 OW provinces sits in the late-stalled "8-9 plateau": at/above the
    // min-OW floor, below the observer quota (10), and inside the stall band
    // (<= 9), so it satisfies the three OW gates simultaneously.
    final int qualifyingOw = kMutualExhaustedGpStalemateMinOw;

    test('true at the min-OW / treasury / regiment exhaustion boundary', () {
      final game = planningOwTechHelpersGameWithExhaustedGp(
        treasury: kMutualExhaustedGpTreasuryMax,
        regiments: kMutualExhaustedGpRegimentMax,
      );
      expect(
        mutualExhaustedGpStalemateSideQualifies(
          game: game,
          factionId: _gpExhausted,
          ow: qualifyingOw,
        ),
        isTrue,
      );
    });

    test('false below the min-OW floor (even while stalled and below quota)', () {
      final game = planningOwTechHelpersGameWithExhaustedGp();
      expect(
        mutualExhaustedGpStalemateSideQualifies(
          game: game,
          factionId: _gpExhausted,
          ow: kMutualExhaustedGpStalemateMinOw - 1,
        ),
        isFalse,
      );
    });

    test('false at the observer conquest quota (not below quota / not stalled)', () {
      final game = planningOwTechHelpersGameWithExhaustedGp();
      expect(
        mutualExhaustedGpStalemateSideQualifies(
          game: game,
          factionId: _gpExhausted,
          ow: kObserverConquestMinOwProvincesPerGp,
        ),
        isFalse,
      );
    });

    test('false when treasury exceeds the exhaustion ceiling', () {
      final game = planningOwTechHelpersGameWithExhaustedGp(
        treasury: kMutualExhaustedGpTreasuryMax + 1,
      );
      expect(
        mutualExhaustedGpStalemateSideQualifies(
          game: game,
          factionId: _gpExhausted,
          ow: qualifyingOw,
        ),
        isFalse,
      );
    });

    test('false when standing regiments exceed the exhaustion ceiling', () {
      final game = planningOwTechHelpersGameWithExhaustedGp(
        regiments: kMutualExhaustedGpRegimentMax + 1,
      );
      expect(
        mutualExhaustedGpStalemateSideQualifies(
          game: game,
          factionId: _gpExhausted,
          ow: qualifyingOw,
        ),
        isFalse,
      );
    });

    test('false for a faction id that does not resolve to a Great Power', () {
      final game = planningOwTechHelpersGameWithExhaustedGp(
        treasury: kMutualExhaustedGpTreasuryMax,
        regiments: kMutualExhaustedGpRegimentMax,
      );
      expect(
        mutualExhaustedGpStalemateSideQualifies(
          game: game,
          factionId: 'ghost',
          ow: qualifyingOw,
        ),
        isFalse,
      );
    });
  });
}
